from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal

from .types import HeirType


@dataclass(frozen=True)
class Heir:
    type: HeirType
    count: int


@dataclass
class ShareAllocation:
    heir_type: HeirType
    count: int
    numerator: int
    denominator: int
    total_amount: Decimal
    amount_per_heir: Decimal
    basis: str
    reason_code: str
