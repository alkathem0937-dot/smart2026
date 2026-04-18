from __future__ import annotations

from decimal import Decimal
from typing import List, Optional

from pydantic import BaseModel, Field

from domain.types import HeirType


class HeirInput(BaseModel):
    type: HeirType
    count: int = Field(ge=1)


class EstateItem(BaseModel):
    category: str = Field(min_length=1)
    description: Optional[str] = None
    value: Decimal = Field(ge=0)


class DebtItem(BaseModel):
    creditor: Optional[str] = None
    description: Optional[str] = None
    amount: Decimal = Field(ge=0)


class BequestItem(BaseModel):
    beneficiary: Optional[str] = None
    description: Optional[str] = None
    amount: Decimal = Field(ge=0)


class InheritanceRequest(BaseModel):
    estate_value: Decimal = Field(ge=0)
    debts: Decimal = Field(default=Decimal('0'), ge=0)
    bequests: Decimal = Field(default=Decimal('0'), ge=0)
    estate_items: Optional[List[EstateItem]] = None
    debt_items: Optional[List[DebtItem]] = None
    bequest_items: Optional[List[BequestItem]] = None
    heirs: List[HeirInput]


class ShareItem(BaseModel):
    heir_type: HeirType
    count: int
    fraction_numerator: int
    fraction_denominator: int
    total_amount: Decimal
    amount_per_heir: Decimal
    basis: str
    reason_code: str


class InheritanceResponse(BaseModel):
    totals: dict
    shares: List[ShareItem]
    notes: List[str]
