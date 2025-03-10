#include "SkillTester.h"
#include "skill_definitions.event"

s8 AreUnitsAllied(int left, int right);
s8 AreUnitsAllied(int left, int right) {
    int a = left & 0x80;
    int b = right & 0x80;
    return (a == b);
}
s8 IsSameAllegiance(int left, int right);
s8 IsSameAllegiance(int left, int right) {
    int ret;
    if ((left & 0xc0) == (right & 0xc0)) {
        ret = 1;
    } else {
        ret = 0;
    };
    return ret;
}

struct UnitUsageStats {
    /* 000 */ unsigned lossAmt     : 8;
    /* 008 */ unsigned favval      : 16;
    /* 024 */ unsigned actAmt      : 8;
    /* 032 */ unsigned statViewAmt : 8;
    /* 040 */ unsigned deathLoc    : 6;
    /* 046 */ unsigned deathTurn   : 10;
    /* 056 */ unsigned deployAmt   : 6;
    /* 062 */ unsigned moveAmt     : 10;
    /* 072 */ unsigned deathCause  : 4;
    /* 076 */ unsigned expGained   : 12;
    /* 088 */ unsigned winAmt      : 10;
    /* 098 */ unsigned battleAmt   : 12;
    /* 110 */ unsigned killerPid   : 9;
    /* 119 */ unsigned deathSkirm  : 1;
    /* 120 */ /* 8bit pad */
} BITPACKED;

#define BWL_ARRAY_NUM 0x46
#define EWRAM_DATA __attribute__((section("ewram_data")))
EWRAM_DATA struct UnitUsageStats gPidStatsData[BWL_ARRAY_NUM] = {0};
#define gBWLDataArray (&gPidStatsData[0])

struct UnitUsageStats* GetPidStats(u8 pid);
inline struct UnitUsageStats *GetPidStats(u8 pid)
{
    if (pid >= BWL_ARRAY_NUM)
        return 0;
    else if (0 == GetCharacterData(pid)->affinity)
        return 0;
    else
        return &gBWLDataArray[pid];  
}

/*Helper functions*/
static int  absolute(int value)        {return value < 0 ? -value : value;}
static bool IsSkillIDValid(u8 skillID) {return skillID != 0 && skillID != 255;}
static bool IsBattleReal() {
    return gBattleStats.config & (BATTLE_CONFIG_REAL | BATTLE_CONFIG_SIMULATE);
}

//Checks if given unit is on the field
static bool IsUnitOnField(struct Unit* unit) {
    if (!unit || !unit->pCharacterData)
        return FALSE;

    if (unit->state & (US_RESCUED | US_NOT_DEPLOYED | US_DEAD | 0x00010000))
        return FALSE;

    if ((unit->state & US_UNDER_A_ROOF) && (!gSkillTestConfig.roofUnitAuras)) {
        return FALSE;
    }

    return TRUE;
}

//Checks if given skillID is in given skill buffer
bool IsSkillInBuffer(SkillBuffer* buffer, u8 skillID) {
    for (int i = 0; buffer->skills[i] != 0; ++i) {
        if (buffer->skills[i] == skillID) {
            return TRUE;
        }
    }
    return FALSE;
}

//Checks if the given skillID is negated by Nihil
//If it is, the unit's opponent's skill buffer is searched through for nihil
bool NihilTester(struct Unit* unit, u8 skillID) {
    //Check if in battle and if the skill in question can be negated
    if ((gBattleStats.config & 3) && NegatedSkills[skillID]) {
        SkillBuffer* buffer = &gDefenderSkillBuffer;

        //If unit is the defender, check the attacker skill buffer instead
        if (unit->index == gBattleTarget.unit.index) {
            buffer = &gAttackerSkillBuffer;
        }

        return IsSkillInBuffer(buffer, NihilIDLink);
    }
    return FALSE;
}

ItemDataExt* GetItemDataExt(u16 item) {
	ItemDataExt* e = (ItemDataExt*)GetItemData(item);
	return e;
}

/*Main functions*/

//Makes skill buffer at a given location.
SkillBuffer* MakeSkillBuffer(struct Unit* unit, SkillBuffer* buffer) {
    int unitNum = unit->pCharacterData->number;
    int count = 0, temp = 0;
    buffer->lastUnitChecked = unit->index;

    //Personal skill
    temp = PersonalSkillTable[unitNum];
    if (IsSkillIDValid(temp)) {
        buffer->skills[count++] = temp;
    }

    //Class skill
    temp = ClassSkillTable[unit->pClassData->number];
    if (IsSkillIDValid(temp)) {
        buffer->skills[count++] = temp;
    }

    //Learned skills (In BWL data)
    BWLData* unitBWL = (BWLData*)GetPidStats(unitNum);
    if (unitBWL) {
        for (int i = 0; i < 4; ++i) {
            if (!IsSkillIDValid(unitBWL->skills[i])) {
                break;
            }
            buffer->skills[count++] = unitBWL->skills[i];
        }
    }

    //If generic, load skills from learned list
    else {
        u8* tempBuffer = GetInitialSkillList_Pointer(unit, gTempSkillBuffer);
        for (int i = 0; i < gSkillTestConfig.genericLearnedSkillLimit; ++i) {
            if (!IsSkillIDValid(tempBuffer[i])) {
                break;
            }
            buffer->skills[count++] = tempBuffer[i];
        }
    }

    //Item passive skills
    for (int i = 0; i < 5 && unit->items[i]; ++i) {
        temp = unit->items[i];
        if ((GetItemAttributes(temp) & PassiveSkillBit)) {
            if (IsSkillIDValid(GetItemDataExt(temp & 0xFF)->skill)) {
                buffer->skills[count++] = GetItemDataExt(temp & 0xFF)->skill;
                //If passive skills don't stack, stop looping
                if (!gSkillTestConfig.passiveSkillStack) {
                    break;
                }
            }
        }
    }

    //Equipped weapon skills
    //If unit is in combat, use the equipped weapon short
    if (unit->index == gBattleActor.unit.index && IsBattleReal()) {
        temp = GetItemDataExt(gBattleActor.weaponBefore & 0xFF)->skill;
    }
    else if (unit->index == gBattleTarget.unit.index && IsBattleReal()) {
        temp = GetItemDataExt(gBattleTarget.weaponBefore & 0xFF)->skill;
    }
    //Otherwise, get the equipped weapon via a vanilla function
    else {
        temp = GetItemDataExt(GetUnitEquippedWeapon(unit) & 0xFF)->skill;
    }

    //Check if equipped weapon skill is valid
    if (IsSkillIDValid(temp)) {
        buffer->skills[count++] = temp;
    }

    //Add terminator to end of list
    buffer->skills[count++] = 0;

    return buffer;
}

//Creates an aura skill buffer with skill coordinates relative to a unit
AuraSkillBuffer* MakeAuraSkillBuffer(struct Unit* unit) {
    SkillBuffer* buffer = &gAttackerSkillBuffer;
    AuraSkillBuffer* auraBuffer = gAuraSkillBuffer;
    int count = 0;
    int distance = 0;
    u8 unitIndex = unit->index; //Loading as unsigned to prevent faulty comparisons

    for (int i = 0; i < 0x100; ++i) {
        struct Unit* other = gUnitLookup[i];

        if (!IsUnitOnField(other) || unitIndex == i) {
            continue;
        }

        //If the unit is actually on the field, make a skill buffer for them
        buffer = MakeSkillBuffer(other, buffer);

        //For every skill in the buffer, index AuraSkillTable to find a match
        for (int j = 0; buffer->skills[j] != 0; ++j) {
            if (AuraSkillTable[buffer->skills[j]] && count < gSkillTestConfig.auraSkillBufferLimit) {
                auraBuffer[count].skillID = buffer->skills[j];

                distance = absolute(other->xPos - unit->xPos) +
                           absolute(other->yPos - unit->yPos);

                if (distance > 63) {
                    distance = 63;
                }

                //No need to `& 0x3F` because of the limit
                auraBuffer[count].distance = distance;
                //Shifting for storage
                auraBuffer[count].faction = UNIT_FACTION(other) >> 6;
                ++count;
            }
        }
    }

    //Cleanup to avoid caching issues
    buffer->lastUnitChecked = 0;
    gAuraSkillBuffer[count++].skillID = 0;

    return gAuraSkillBuffer;
}

//Checks for skills in an in progress buffer
//Used by the weapon usability calc loop
bool CheckSkillBuffer(struct Unit* unit, u8 skillID) {
    if (skillID == 0)   {return TRUE;}
    if (skillID == 255) {return FALSE;}

    SkillBuffer* buffer = &gAttackerSkillBuffer;

    //lastUnitChecked is already set, so no need for extra checks
    if (unit->index == gDefenderSkillBuffer.lastUnitChecked) {
        buffer = &gDefenderSkillBuffer;
    }

    return IsSkillInBuffer(buffer, skillID);
}

//Checks unit for a given skill.
//If the unit tested is the same as last time, uses the previous skill buffer
bool SkillTester(struct Unit* unit, u8 skillID) {
    if (skillID == 0)   {return TRUE;}
    if (skillID == 255) {return FALSE;}

    int index = unit->index;

    //Default to the attacker buffer
    SkillBuffer* buffer = &gAttackerSkillBuffer;

    //If unit is the defender, use the defender buffer
    if (index == gBattleTarget.unit.index && IsBattleReal()) {
        buffer = &gDefenderSkillBuffer;
    }

    if (index != buffer->lastUnitChecked) {
        MakeSkillBuffer(unit, buffer);
    }

    //Check if matching skill is in buffer
    if (IsSkillInBuffer(buffer, skillID)) {
        //Reverse check since NihilTester returns true if nihil is found
        return !NihilTester(unit, skillID);
    }

    return FALSE;
}



//Loops through premade aura skill buffer to find matching aura skills within range
bool NewAuraSkillCheck(struct Unit* unit, u8 skillID, int allyOption, int maxRange) {
    s8(*pAllegianceChecker)(int, int) = ((allyOption & 1) ? AreUnitsAllied : IsSameAllegiance);

// #if defined(SwordEdgeID)
//     if (skillID == SwordEdgeID && GetItemType(GetUnitEquippedWeapon(unit)) != ITYPE_SWORD)
//         return FALSE;
// #endif

// #if defined(LanceEdgeID)
//     if (skillID == LanceEdgeID && GetItemType(GetUnitEquippedWeapon(unit)) != ITYPE_LANCE)
//         return FALSE;
// #endif

// #if defined(AxeEdgeID)
//     if (skillID == AxeEdgeID && GetItemType(GetUnitEquippedWeapon(unit)) != ITYPE_AXE)
//         return FALSE;
// #endif

    if (skillID == 0)   {return TRUE;}
    if (skillID == 255) {return FALSE;}

    AuraSkillBuffer* auraBuffer = gAuraSkillBuffer;
    for (int i = 0; auraBuffer[i].skillID; ++i) {
        if (auraBuffer[i].distance <= maxRange && auraBuffer[i].skillID == skillID) {

            //NOTE: This is checking bits
            int check = pAllegianceChecker(unit->index, auraBuffer[i].faction << 6);

            if (allyOption & 2)
                check = !check;

            if (check || (allyOption & 4))
                return TRUE;
        }
    }

    return FALSE;
}

//Prepares buffers for prebattle loop
void InitializePreBattleLoop(struct Unit* attacker, struct Unit* defender) {
    MakeAuraSkillBuffer(attacker);
    MakeSkillBuffer(attacker, &gAttackerSkillBuffer);
    gDefenderSkillBuffer.lastUnitChecked = 0;

    if (IsBattleReal()) {
        MakeSkillBuffer(&gBattleTarget.unit, &gDefenderSkillBuffer);
    }
}

//Sets skill buffers to refresh next skill test
void InitSkillBuffers() {
    gAttackerSkillBuffer.lastUnitChecked = 0;
    gDefenderSkillBuffer.lastUnitChecked = 0;
}

//Finds units in a radius and returns a list of matching unit's indexes
u8* GetUnitsInRange(struct Unit* unit, int allyOption, int range) {
    s8(*pAllegianceChecker)(int, int) = ((allyOption & 1) ? AreUnitsAllied : IsSameAllegiance);

    int count = 0;
    int check = 0;
    u8 unitIndex = unit->index; //Loading as unsigned to prevent faulty comparisons

    for (int i = 0; i < 0x100; ++i) {
        struct Unit* other = gUnitLookup[i];

        if (!IsUnitOnField(other) || unitIndex == i) {
            continue;
        }

        //Check if other matches allyOption's criteria
        if (allyOption & 2) {
            check = !pAllegianceChecker(unit->index, other->index);
        }
        else {
            check =  pAllegianceChecker(unit->index, other->index);
        }

        if (check || (allyOption & 4)) {
            if ((absolute(other->xPos - unit->xPos)
               + absolute(other->yPos - unit->yPos)) <= range) {
                gUnitRangeBuffer[count++] = i;
            }
        }
    }

    //Terminator
    gUnitRangeBuffer[count++] = 0;
    if (!gUnitRangeBuffer[0])
        return FALSE;

    return gUnitRangeBuffer;
}
