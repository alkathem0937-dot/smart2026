from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP
from fractions import Fraction
from typing import Dict, List, Tuple

from .models import Heir, ShareAllocation
from .types import HeirType


_DEC_Q = Decimal('0.01')


def _q(v: Decimal) -> Decimal:
    return v.quantize(_DEC_Q, rounding=ROUND_HALF_UP)


def _dec_from_fraction(total: Decimal, frac: Fraction) -> Decimal:
    return total * Decimal(frac.numerator) / Decimal(frac.denominator)


def _sum_fractions(fracs: List[Fraction]) -> Fraction:
    out = Fraction(0, 1)
    for f in fracs:
        out += f
    return out


def calculate_inheritance(
    *,
    estate_value: Decimal,
    debts: Decimal,
    bequests: Decimal,
    heirs: List[Heir],
) -> Tuple[Dict[str, Decimal], List[ShareAllocation], List[str]]:
    notes: List[str] = []

    if estate_value < 0 or debts < 0 or bequests < 0:
        raise ValueError('Amounts must be non-negative')

    estate_after_debts = estate_value - debts
    if estate_after_debts < 0:
        estate_after_debts = Decimal('0')
        notes.append('DEBTS_EXCEED_ESTATE')

    max_bequest = estate_after_debts / Decimal('3')
    bequest_applied = bequests if bequests <= max_bequest else max_bequest
    if bequests > max_bequest:
        notes.append('BEQUEST_CAPPED_TO_ONE_THIRD')

    net_estate = estate_after_debts - bequest_applied
    if net_estate < 0:
        net_estate = Decimal('0')

    heir_counts: Dict[HeirType, int] = {}
    for h in heirs:
        if h.count <= 0:
            continue
        heir_counts[h.type] = heir_counts.get(h.type, 0) + h.count

    def c(t: HeirType) -> int:
        return heir_counts.get(t, 0)

    def has_any(types: List[HeirType]) -> bool:
        return any(c(t) > 0 for t in types)

    def total_siblings() -> int:
        return (
            c(HeirType.full_brother)
            + c(HeirType.full_sister)
            + c(HeirType.paternal_brother)
            + c(HeirType.paternal_sister)
            + c(HeirType.maternal_brother)
            + c(HeirType.maternal_sister)
        )

    def descendants_any() -> bool:
        return has_any([HeirType.son, HeirType.daughter, HeirType.grandson, HeirType.granddaughter])

    def descendants_male() -> bool:
        return has_any([HeirType.son, HeirType.grandson])

    def descendants_female() -> bool:
        return has_any([HeirType.daughter, HeirType.granddaughter])

    # Hajb (blocking)
    if c(HeirType.son) > 0:
        if c(HeirType.grandson) > 0:
            heir_counts[HeirType.grandson] = 0
            notes.append('HAJB_GRANDSON_BY_SON')
        if c(HeirType.granddaughter) > 0:
            heir_counts[HeirType.granddaughter] = 0
            notes.append('HAJB_GRANDDAUGHTER_BY_SON')

    if c(HeirType.father) > 0 and c(HeirType.grandfather) > 0:
        heir_counts[HeirType.grandfather] = 0
        notes.append('HAJB_GRANDFATHER_BY_FATHER')

    if c(HeirType.mother) > 0:
        if c(HeirType.grandmother_maternal) > 0:
            heir_counts[HeirType.grandmother_maternal] = 0
            notes.append('HAJB_GRANDMOTHER_MATERNAL_BY_MOTHER')
        if c(HeirType.grandmother_paternal) > 0:
            heir_counts[HeirType.grandmother_paternal] = 0
            notes.append('HAJB_GRANDMOTHER_PATERNAL_BY_MOTHER')

    if c(HeirType.father) > 0 and c(HeirType.grandmother_paternal) > 0:
        heir_counts[HeirType.grandmother_paternal] = 0
        notes.append('HAJB_GRANDMOTHER_PATERNAL_BY_FATHER')

    if c(HeirType.daughter) >= 2 and c(HeirType.son) == 0 and c(HeirType.grandson) == 0:
        if c(HeirType.granddaughter) > 0:
            heir_counts[HeirType.granddaughter] = 0
            notes.append('HAJB_GRANDDAUGHTER_BY_TWO_DAUGHTERS')

    # Fixed shares (فروض)
    fixed_ratios: Dict[HeirType, Fraction] = {}
    fixed_reason: Dict[HeirType, str] = {}
    resid_ratios: Dict[HeirType, Fraction] = {}
    resid_reason: Dict[HeirType, str] = {}

    # Special case: المسألة المشتركة (limited)
    allowed_mushtaraka = {
        HeirType.husband,
        HeirType.grandmother_maternal,
        HeirType.grandmother_paternal,
        HeirType.maternal_brother,
        HeirType.maternal_sister,
        HeirType.full_brother,
        HeirType.full_sister,
    }
    has_only_allowed = all((ht in allowed_mushtaraka) for ht, cnt in heir_counts.items() if cnt > 0)
    if (
        has_only_allowed
        and c(HeirType.husband) > 0
        and (c(HeirType.grandmother_maternal) + c(HeirType.grandmother_paternal)) > 0
        and (c(HeirType.maternal_brother) + c(HeirType.maternal_sister)) > 0
        and (c(HeirType.full_brother) + c(HeirType.full_sister)) > 0
    ):
        fixed_ratios[HeirType.husband] = Fraction(1, 2)
        fixed_reason[HeirType.husband] = 'HUSBAND_HALF'
        gm_total = c(HeirType.grandmother_maternal) + c(HeirType.grandmother_paternal)
        gm_ratio_total = Fraction(1, 6)
        if c(HeirType.grandmother_maternal) > 0:
            fixed_ratios[HeirType.grandmother_maternal] = gm_ratio_total * Fraction(c(HeirType.grandmother_maternal), gm_total)
            fixed_reason[HeirType.grandmother_maternal] = 'GRANDMOTHER_SIXTH'
        if c(HeirType.grandmother_paternal) > 0:
            fixed_ratios[HeirType.grandmother_paternal] = gm_ratio_total * Fraction(c(HeirType.grandmother_paternal), gm_total)
            fixed_reason[HeirType.grandmother_paternal] = 'GRANDMOTHER_SIXTH'
        pool = Fraction(1, 3)
        heads = (
            c(HeirType.maternal_brother)
            + c(HeirType.maternal_sister)
            + c(HeirType.full_brother)
            + c(HeirType.full_sister)
        )
        if c(HeirType.maternal_brother) > 0:
            fixed_ratios[HeirType.maternal_brother] = pool * Fraction(c(HeirType.maternal_brother), heads)
            fixed_reason[HeirType.maternal_brother] = 'MUSHTARAKA_SHARED_THIRD'
        if c(HeirType.maternal_sister) > 0:
            fixed_ratios[HeirType.maternal_sister] = pool * Fraction(c(HeirType.maternal_sister), heads)
            fixed_reason[HeirType.maternal_sister] = 'MUSHTARAKA_SHARED_THIRD'
        if c(HeirType.full_brother) > 0:
            fixed_ratios[HeirType.full_brother] = pool * Fraction(c(HeirType.full_brother), heads)
            fixed_reason[HeirType.full_brother] = 'MUSHTARAKA_SHARED_THIRD'
        if c(HeirType.full_sister) > 0:
            fixed_ratios[HeirType.full_sister] = pool * Fraction(c(HeirType.full_sister), heads)
            fixed_reason[HeirType.full_sister] = 'MUSHTARAKA_SHARED_THIRD'
        notes.append('MUSHTARAKA_APPLIED')
    else:
        # Spouse
        spouse_ratio = Fraction(0, 1)
        if c(HeirType.husband) > 0:
            spouse_ratio = Fraction(1, 4) if descendants_any() else Fraction(1, 2)
            fixed_ratios[HeirType.husband] = spouse_ratio
            fixed_reason[HeirType.husband] = 'HUSBAND_QUARTER' if descendants_any() else 'HUSBAND_HALF'
        elif c(HeirType.wife) > 0:
            spouse_ratio = Fraction(1, 8) if descendants_any() else Fraction(1, 4)
            fixed_ratios[HeirType.wife] = spouse_ratio
            fixed_reason[HeirType.wife] = 'WIFE_EIGHTH' if descendants_any() else 'WIFE_QUARTER'

        # Mother
        mother_ratio = Fraction(0, 1)
        other_non_parents = [
            ht
            for ht, cnt in heir_counts.items()
            if cnt > 0 and ht not in (HeirType.husband, HeirType.wife, HeirType.father, HeirType.mother)
        ]
        only_spouse_and_parents = (
            spouse_ratio > 0
            and c(HeirType.father) > 0
            and c(HeirType.mother) > 0
            and not descendants_any()
            and total_siblings() == 0
            and len(other_non_parents) == 0
        )

        if c(HeirType.mother) > 0:
            if descendants_any() or total_siblings() >= 2:
                mother_ratio = Fraction(1, 6)
                fixed_reason[HeirType.mother] = 'MOTHER_SIXTH'
            elif only_spouse_and_parents:
                mother_ratio = (Fraction(1, 1) - spouse_ratio) * Fraction(1, 3)
                fixed_reason[HeirType.mother] = 'MOTHER_THIRD_REMAINDER'
                notes.append('UMARIYYA_APPLIED')
            else:
                mother_ratio = Fraction(1, 3)
                fixed_reason[HeirType.mother] = 'MOTHER_THIRD'
            fixed_ratios[HeirType.mother] = mother_ratio

        # Grandmothers (if mother absent)
        if c(HeirType.mother) == 0:
            gm_total = c(HeirType.grandmother_maternal) + c(HeirType.grandmother_paternal)
            if gm_total > 0:
                gm_ratio_total = Fraction(1, 6)
                if c(HeirType.grandmother_maternal) > 0:
                    fixed_ratios[HeirType.grandmother_maternal] = gm_ratio_total * Fraction(c(HeirType.grandmother_maternal), gm_total)
                    fixed_reason[HeirType.grandmother_maternal] = 'GRANDMOTHER_SIXTH'
                if c(HeirType.grandmother_paternal) > 0:
                    fixed_ratios[HeirType.grandmother_paternal] = gm_ratio_total * Fraction(c(HeirType.grandmother_paternal), gm_total)
                    fixed_reason[HeirType.grandmother_paternal] = 'GRANDMOTHER_SIXTH'

        # Daughters
        if c(HeirType.son) == 0 and c(HeirType.daughter) > 0:
            if c(HeirType.daughter) == 1:
                fixed_ratios[HeirType.daughter] = Fraction(1, 2)
                fixed_reason[HeirType.daughter] = 'DAUGHTER_HALF'
            else:
                fixed_ratios[HeirType.daughter] = Fraction(2, 3)
                fixed_reason[HeirType.daughter] = 'DAUGHTERS_TWO_THIRDS'

        # Granddaughters (sons' daughters)
        if c(HeirType.son) == 0 and c(HeirType.grandson) == 0 and c(HeirType.granddaughter) > 0:
            if c(HeirType.daughter) == 0:
                if c(HeirType.granddaughter) == 1:
                    fixed_ratios[HeirType.granddaughter] = Fraction(1, 2)
                    fixed_reason[HeirType.granddaughter] = 'GRANDDAUGHTER_HALF'
                else:
                    fixed_ratios[HeirType.granddaughter] = Fraction(2, 3)
                    fixed_reason[HeirType.granddaughter] = 'GRANDDAUGHTERS_TWO_THIRDS'
            elif c(HeirType.daughter) == 1:
                fixed_ratios[HeirType.granddaughter] = Fraction(1, 6)
                fixed_reason[HeirType.granddaughter] = 'GRANDDAUGHTER_SIXTH_WITH_DAUGHTER'

        # Father / Grandfather fixed sixth with descendants
        if c(HeirType.father) > 0 and descendants_any():
            fixed_ratios[HeirType.father] = Fraction(1, 6)
            fixed_reason[HeirType.father] = 'FATHER_SIXTH'
        if c(HeirType.father) == 0 and c(HeirType.grandfather) > 0 and descendants_any():
            fixed_ratios[HeirType.grandfather] = Fraction(1, 6)
            fixed_reason[HeirType.grandfather] = 'GRANDFATHER_SIXTH'

        # Maternal siblings
        ms_total = c(HeirType.maternal_brother) + c(HeirType.maternal_sister)
        if ms_total > 0 and not descendants_any() and c(HeirType.father) == 0 and c(HeirType.grandfather) == 0:
            pool = Fraction(1, 6) if ms_total == 1 else Fraction(1, 3)
            if c(HeirType.maternal_brother) > 0:
                fixed_ratios[HeirType.maternal_brother] = pool * Fraction(c(HeirType.maternal_brother), ms_total)
                fixed_reason[HeirType.maternal_brother] = 'MATERNAL_SIBLING_SIXTH' if ms_total == 1 else 'MATERNAL_SIBLINGS_THIRD'
            if c(HeirType.maternal_sister) > 0:
                fixed_ratios[HeirType.maternal_sister] = pool * Fraction(c(HeirType.maternal_sister), ms_total)
                fixed_reason[HeirType.maternal_sister] = 'MATERNAL_SIBLING_SIXTH' if ms_total == 1 else 'MATERNAL_SIBLINGS_THIRD'

        # Full sisters (fixed)
        if (
            c(HeirType.full_sister) > 0
            and c(HeirType.full_brother) == 0
            and not descendants_any()
            and c(HeirType.father) == 0
            and c(HeirType.grandfather) == 0
        ):
            if c(HeirType.full_sister) == 1:
                fixed_ratios[HeirType.full_sister] = Fraction(1, 2)
                fixed_reason[HeirType.full_sister] = 'FULL_SISTER_HALF'
            else:
                fixed_ratios[HeirType.full_sister] = Fraction(2, 3)
                fixed_reason[HeirType.full_sister] = 'FULL_SISTERS_TWO_THIRDS'

        # Paternal sisters (fixed)
        if (
            c(HeirType.paternal_sister) > 0
            and c(HeirType.paternal_brother) == 0
            and not descendants_any()
            and c(HeirType.father) == 0
            and c(HeirType.grandfather) == 0
            and c(HeirType.full_brother) == 0
        ):
            if c(HeirType.full_sister) == 1:
                fixed_ratios[HeirType.paternal_sister] = Fraction(1, 6)
                fixed_reason[HeirType.paternal_sister] = 'PATERNAL_SISTER_SIXTH_WITH_FULL_SISTER'
            elif c(HeirType.full_sister) == 0:
                if c(HeirType.paternal_sister) == 1:
                    fixed_ratios[HeirType.paternal_sister] = Fraction(1, 2)
                    fixed_reason[HeirType.paternal_sister] = 'PATERNAL_SISTER_HALF'
                else:
                    fixed_ratios[HeirType.paternal_sister] = Fraction(2, 3)
                    fixed_reason[HeirType.paternal_sister] = 'PATERNAL_SISTERS_TWO_THIRDS'
            elif c(HeirType.full_sister) >= 2:
                notes.append('HAJB_PATERNAL_SISTER_BY_FULL_SISTERS')

        # Awl
        fixed_sum = _sum_fractions(list(fixed_ratios.values()))
        if fixed_sum > 1:
            factor = Fraction(1, 1) / fixed_sum
            for k in list(fixed_ratios.keys()):
                fixed_ratios[k] *= factor
            notes.append('AWL_APPLIED')
            fixed_sum = _sum_fractions(list(fixed_ratios.values()))

        remainder_ratio = Fraction(1, 1) - fixed_sum
        if remainder_ratio < 0:
            remainder_ratio = Fraction(0, 1)

        # Residuary (عصبة)
        if remainder_ratio > 0:
            sons = c(HeirType.son)
            daughters = c(HeirType.daughter)
            grandsons = c(HeirType.grandson)
            granddaughters = c(HeirType.granddaughter)

            # Sons / daughters asaba bil-ghayr
            if sons > 0:
                units = sons * 2 + daughters
                if units > 0:
                    if sons > 0:
                        resid_ratios[HeirType.son] = remainder_ratio * Fraction(sons * 2, units)
                        resid_reason[HeirType.son] = 'SON_RESIDUARY'
                    if daughters > 0:
                        resid_ratios[HeirType.daughter] = remainder_ratio * Fraction(daughters, units)
                        resid_reason[HeirType.daughter] = 'DAUGHTER_WITH_SON_RESIDUARY'
                    remainder_ratio = Fraction(0, 1)

            # Grandsons / granddaughters
            elif grandsons > 0:
                units = grandsons * 2 + granddaughters
                if units > 0:
                    resid_ratios[HeirType.grandson] = remainder_ratio * Fraction(grandsons * 2, units)
                    resid_reason[HeirType.grandson] = 'GRANDSON_RESIDUARY'
                    if granddaughters > 0:
                        resid_ratios[HeirType.granddaughter] = remainder_ratio * Fraction(granddaughters, units)
                        resid_reason[HeirType.granddaughter] = 'GRANDDAUGHTER_WITH_GRANDSON_RESIDUARY'
                    remainder_ratio = Fraction(0, 1)

            # Father / grandfather
            elif c(HeirType.father) > 0:
                if not (descendants_any() and descendants_male()):
                    resid_ratios[HeirType.father] = remainder_ratio
                    resid_reason[HeirType.father] = 'FATHER_RESIDUARY'
                    remainder_ratio = Fraction(0, 1)
            elif c(HeirType.grandfather) > 0:
                if (
                    c(HeirType.full_brother)
                    + c(HeirType.full_sister)
                    + c(HeirType.paternal_brother)
                    + c(HeirType.paternal_sister)
                ) > 0:
                    notes.append('GRANDFATHER_WITH_SIBLINGS_NOT_IMPLEMENTED')
                    resid_ratios[HeirType.grandfather] = remainder_ratio
                    resid_reason[HeirType.grandfather] = 'GRANDFATHER_RESIDUARY'
                    remainder_ratio = Fraction(0, 1)
                elif not (descendants_any() and descendants_male()):
                    resid_ratios[HeirType.grandfather] = remainder_ratio
                    resid_reason[HeirType.grandfather] = 'GRANDFATHER_RESIDUARY'
                    remainder_ratio = Fraction(0, 1)

            # Sisters asaba ma'al-ghayr
            if remainder_ratio > 0 and descendants_female() and not descendants_male() and c(HeirType.father) == 0 and c(HeirType.grandfather) == 0:
                if c(HeirType.full_sister) > 0 and c(HeirType.full_brother) == 0:
                    resid_ratios[HeirType.full_sister] = remainder_ratio
                    resid_reason[HeirType.full_sister] = 'FULL_SISTER_ASABA_MAAL_GHAYR'
                    remainder_ratio = Fraction(0, 1)
                elif (
                    c(HeirType.paternal_sister) > 0
                    and c(HeirType.paternal_brother) == 0
                    and c(HeirType.full_brother) == 0
                    and c(HeirType.full_sister) == 0
                ):
                    resid_ratios[HeirType.paternal_sister] = remainder_ratio
                    resid_reason[HeirType.paternal_sister] = 'PATERNAL_SISTER_ASABA_MAAL_GHAYR'
                    remainder_ratio = Fraction(0, 1)

            # Siblings asaba bil-ghayr
            if remainder_ratio > 0 and c(HeirType.father) == 0 and c(HeirType.grandfather) == 0 and not descendants_male():
                if c(HeirType.full_brother) > 0:
                    brothers = c(HeirType.full_brother)
                    sisters = c(HeirType.full_sister)
                    units = brothers * 2 + sisters
                    resid_ratios[HeirType.full_brother] = remainder_ratio * Fraction(brothers * 2, units)
                    resid_reason[HeirType.full_brother] = 'FULL_BROTHER_RESIDUARY'
                    if sisters > 0:
                        resid_ratios[HeirType.full_sister] = remainder_ratio * Fraction(sisters, units)
                        resid_reason[HeirType.full_sister] = 'FULL_SISTER_WITH_BROTHER_RESIDUARY'
                    remainder_ratio = Fraction(0, 1)
                elif c(HeirType.paternal_brother) > 0 and c(HeirType.full_brother) == 0:
                    brothers = c(HeirType.paternal_brother)
                    sisters = c(HeirType.paternal_sister)
                    units = brothers * 2 + sisters
                    resid_ratios[HeirType.paternal_brother] = remainder_ratio * Fraction(brothers * 2, units)
                    resid_reason[HeirType.paternal_brother] = 'PATERNAL_BROTHER_RESIDUARY'
                    if sisters > 0:
                        resid_ratios[HeirType.paternal_sister] = remainder_ratio * Fraction(sisters, units)
                        resid_reason[HeirType.paternal_sister] = 'PATERNAL_SISTER_WITH_BROTHER_RESIDUARY'
                    remainder_ratio = Fraction(0, 1)

            # Remaining agnates in order
            if remainder_ratio > 0 and c(HeirType.father) == 0 and c(HeirType.grandfather) == 0 and not descendants_male():
                for t, reason in (
                    (HeirType.full_nephew, 'FULL_NEPHEW_RESIDUARY'),
                    (HeirType.paternal_nephew, 'PATERNAL_NEPHEW_RESIDUARY'),
                    (HeirType.full_uncle, 'FULL_UNCLE_RESIDUARY'),
                    (HeirType.paternal_uncle, 'PATERNAL_UNCLE_RESIDUARY'),
                    (HeirType.full_cousin, 'FULL_COUSIN_RESIDUARY'),
                    (HeirType.paternal_cousin, 'PATERNAL_COUSIN_RESIDUARY'),
                ):
                    if c(t) > 0:
                        resid_ratios[t] = remainder_ratio
                        resid_reason[t] = reason
                        remainder_ratio = Fraction(0, 1)
                        break

        # Radd (no radd for spouses)
        if remainder_ratio > 0 and len(resid_ratios) == 0:
            eligible = {k: v for k, v in fixed_ratios.items() if k not in (HeirType.husband, HeirType.wife)}
            eligible_sum = _sum_fractions(list(eligible.values()))
            if eligible_sum > 0:
                for k in list(eligible.keys()):
                    fixed_ratios[k] = fixed_ratios.get(k, Fraction(0, 1)) + remainder_ratio * (eligible[k] / eligible_sum)
                notes.append('RADD_APPLIED')
                remainder_ratio = Fraction(0, 1)
            else:
                notes.append('REMAINDER_WITH_NO_RADD_ELIGIBLE')

    # Build allocations
    allocations: List[ShareAllocation] = []

    def _basis_and_reason(ht: HeirType) -> Tuple[str, str, Fraction]:
        f = fixed_ratios.get(ht, Fraction(0, 1))
        r = resid_ratios.get(ht, Fraction(0, 1))
        total = f + r
        if f > 0 and r > 0:
            if ht == HeirType.father:
                return 'mixed', 'FATHER_SIXTH_PLUS_RESIDUARY', total
            if ht == HeirType.grandfather:
                return 'mixed', 'GRANDFATHER_SIXTH_PLUS_RESIDUARY', total
            return 'mixed', 'MIXED', total
        if f > 0:
            return 'fixed', fixed_reason.get(ht, 'FIXED'), total
        if r > 0:
            return 'residuary', resid_reason.get(ht, 'RESIDUARY'), total
        return '', '', total

    for ht, cnt in heir_counts.items():
        if cnt <= 0:
            continue
        basis, reason, ratio = _basis_and_reason(ht)
        if ratio <= 0:
            continue
        total_amt = _dec_from_fraction(net_estate, ratio)
        total_amt_q = _q(total_amt)
        per = _q(total_amt_q / Decimal(cnt)) if cnt else Decimal('0')
        allocations.append(
            ShareAllocation(
                heir_type=ht,
                count=cnt,
                numerator=ratio.numerator,
                denominator=ratio.denominator,
                total_amount=total_amt_q,
                amount_per_heir=per,
                basis=basis,
                reason_code=reason,
            )
        )

    allocated_total = sum((a.total_amount for a in allocations), Decimal('0'))
    unallocated_amount = net_estate - allocated_total
    if unallocated_amount < 0:
        unallocated_amount = Decimal('0')

    totals = {
        'estate_value': _q(estate_value),
        'debts': _q(debts),
        'bequests_requested': _q(bequests),
        'bequest_applied': _q(bequest_applied),
        'net_estate': _q(net_estate),
        'unallocated_amount': _q(unallocated_amount),
    }

    return totals, allocations, notes
