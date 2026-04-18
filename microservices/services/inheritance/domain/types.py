from __future__ import annotations

from enum import Enum


class HeirType(str, Enum):
    husband = 'husband'
    wife = 'wife'
    son = 'son'
    daughter = 'daughter'
    grandson = 'grandson'
    granddaughter = 'granddaughter'
    father = 'father'
    grandfather = 'grandfather'
    mother = 'mother'
    grandmother_maternal = 'grandmother_maternal'
    grandmother_paternal = 'grandmother_paternal'

    full_brother = 'full_brother'
    full_sister = 'full_sister'
    paternal_brother = 'paternal_brother'
    paternal_sister = 'paternal_sister'
    maternal_brother = 'maternal_brother'
    maternal_sister = 'maternal_sister'

    full_nephew = 'full_nephew'
    paternal_nephew = 'paternal_nephew'
    full_uncle = 'full_uncle'
    paternal_uncle = 'paternal_uncle'
    full_cousin = 'full_cousin'
    paternal_cousin = 'paternal_cousin'
