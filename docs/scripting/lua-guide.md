# LandSandBoat Lua Scripting Guide

## Overview

LandSandBoat uses **Lua/LuaJIT** for gameplay content scripting, comprising approximately 63% of the codebase. Lua provides a flexible, hot-reloadable scripting layer on top of the C++ engine.

## Lua Environment

**Version**: LuaJIT (Lua 5.1 compatible with JIT compilation)
**Bridge**: sol2 library (C++ to Lua binding with all safety checks enabled)
**Location**: Scripts in `/scripts/` directory

### Advantages of Lua Scripting

1. **Hot-Reloadable**: Scripts can be reloaded without server restart
2. **Rapid Development**: Quick iteration on content
3. **Accessible**: Easier to write than C++ for content creators
4. **Safe**: Sandboxed environment, can't crash server
5. **Flexible**: Dynamic typing and metaprogramming

## Script Organization

### Directory Structure

```
/scripts/
  /zones/           - 297 zone directories with NPCs, mobs, quests
  /quests/          - Quest implementations by region
  /missions/        - Mission frameworks
  /globals/         - 127 shared functionality files
  /enum/            - 110 enumeration files (game constants)
  /actions/         - Player/NPC actions
    /abilities/     - Job abilities
    /weaponskills/  - Weapon skills
    /spells/        - Magic spells
    /mobskills/     - Mob TP moves
  /battlefields/    - Battlefield/BCNM logic
  /commands/        - In-game commands (GM and player)
  /effects/         - Status effect implementations
  /items/           - Item-specific behaviors
  /mixins/          - Reusable component modules
  /utils/           - Helper utilities
```

## Zone Scripting

### Zone Structure

Each zone has a dedicated directory:

```
/scripts/zones/[zone_name]/
  Zone.lua          - Zone initialization and events
  IDs.lua           - Entity IDs and text constants
  /npcs/            - NPC scripts
  /mobs/            - Mob scripts
  /bcnms/           - Battlefield instances
  /quests/          - Zone-specific quests (optional)
```

### Zone.lua Example

```lua
-- /scripts/zones/Southern_San_dOria/Zone.lua

local zone_object = {}

zone_object.onInitialize = function(zone)
    -- Zone initialization
    -- Set conquest ownership, weather, etc.
end

zone_object.onZoneIn = function(player, prevZone)
    -- Player zones in
    local cs = -1  -- Cutscene ID (-1 = none)

    -- Check for mission cutscenes
    if player:getCurrentMission(xi.mission.log_id.SANDORIA) == xi.mission.id.sandoria.СМILING_BACK then
        cs = 100  -- Play mission cutscene
    end

    return cs
end

zone_object.onConquestUpdate = function(zone, updatetype)
    -- Conquest update event
    xi.conq.onConquestUpdate(zone, updatetype)
end

zone_object.onRegionEnter = function(player, region)
    -- Player enters region within zone
end

zone_object.onEventUpdate = function(player, csid, option)
    -- Cutscene update
end

zone_object.onEventFinish = function(player, csid, option)
    -- Cutscene finished
    if csid == 100 then
        player:completeMission(xi.mission.log_id.SANDORIA, xi.mission.id.sandoria.SMILING_JACK)
        player:addMission(xi.mission.log_id.SANDORIA, xi.mission.id.sandoria.THE_RESCUE)
    end
end

return zone_object
```

### IDs.lua Example

```lua
-- /scripts/zones/Southern_San_dOria/IDs.lua

return {
    text = {
        ITEM_CANNOT_BE_OBTAINED = 6382,
        ITEM_OBTAINED           = 6388,
        GIL_OBTAINED            = 6389,
        KEYITEM_OBTAINED        = 6391,
        -- ... more text IDs
    },
    npc = {
        AMAURA          = 17719310,
        MERCHANT        = 17719311,
        -- ... more NPC IDs
    },
    mob = {
        EXAMPLE_NM      = 17719500,
        -- ... more mob IDs
    }
}
```

## NPC Scripting

### NPC Script Structure

```lua
-- /scripts/zones/[zone]/npcs/[NPC_Name].lua

local entity = {}

entity.onTrade = function(player, npc, trade)
    -- Player trades items to NPC
end

entity.onTrigger = function(player, npc)
    -- Player interacts with NPC
end

entity.onEventUpdate = function(player, csid, option)
    -- Cutscene update during interaction
end

entity.onEventFinish = function(player, csid, option)
    -- Cutscene finished
end

return entity
```

### NPC Example: Simple Shop

```lua
local entity = {}

entity.onTrade = function(player, npc, trade)
    -- No trading with this NPC
end

entity.onTrigger = function(player, npc)
    local stock = {
        4096,   100,    -- Potion, 100 gil
        4112,   500,    -- Hi-Potion, 500 gil
        4128,   4500,   -- X-Potion, 4500 gil
    }

    player:showText(npc, ID.text.MERCHANT_GREETING)
    xi.shop.general(player, stock)
end

entity.onEventUpdate = function(player, csid, option)
end

entity.onEventFinish = function(player, csid, option)
end

return entity
```

### NPC Example: Quest Giver

```lua
local ID = zones[xi.zone.SOUTHERN_SAN_DORIA]

local entity = {}

entity.onTrade = function(player, npc, trade)
    local questStatus = player:getQuestStatus(xi.quest.log_id.SANDORIA, xi.quest.id.sandoria.THE_MERCHANT)

    -- Check if player is trading required items for quest
    if questStatus == QUEST_ACCEPTED then
        if npcUtil.tradeHasExactly(trade, {4509, 4509, 4509}) then  -- 3x Phoenix Down
            player:messageSpecial(ID.text.ITEM_OBTAINED, 13446)  -- Bronze Sword
            player:addItem(13446)
            player:confirmTrade()
            player:completeQuest(xi.quest.log_id.SANDORIA, xi.quest.id.sandoria.THE_MERCHANT)
            player:addFame(xi.quest.log_id.SANDORIA, 30)
            player:addGil(1000)
        end
    end
end

entity.onTrigger = function(player, npc)
    local questStatus = player:getQuestStatus(xi.quest.log_id.SANDORIA, xi.quest.id.sandoria.THE_MERCHANT)

    if questStatus == QUEST_AVAILABLE then
        -- Offer quest
        player:startEvent(100)  -- Quest offer cutscene
    elseif questStatus == QUEST_ACCEPTED then
        -- Remind about quest
        player:messageSpecial(ID.text.QUEST_REMINDER)
    else
        -- Quest completed
        player:startEvent(101)  -- Thank you message
    end
end

entity.onEventFinish = function(player, csid, option)
    if csid == 100 and option == 1 then
        -- Player accepted quest
        player:addQuest(xi.quest.log_id.SANDORIA, xi.quest.id.sandoria.THE_MERCHANT)
    end
end

return entity
```

## Mob Scripting

### Mob Script Structure

```lua
-- /scripts/zones/[zone]/mobs/[Mob_Name].lua

local entity = {}

entity.onMobSpawn = function(mob)
    -- Mob spawns
end

entity.onMobRoam = function(mob)
    -- Mob roaming behavior
end

entity.onMobEngage = function(mob, target)
    -- Mob engages in combat
end

entity.onMobFight = function(mob, target)
    -- During combat (called frequently)
end

entity.onMobDisengage = function(mob)
    -- Mob disengages from combat
end

entity.onMobDeath = function(mob, player, optParams)
    -- Mob dies
end

entity.onMobDespawn = function(mob)
    -- Mob despawns
end

return entity
```

### Mob Example: Notorious Monster

```lua
local entity = {}

entity.onMobSpawn = function(mob)
    -- Set special stats
    mob:setMobMod(xi.mobMod.ADD_EFFECT, 1)
    mob:setMod(xi.mod.REGEN, 50)
    mob:setMod(xi.mod.REGAIN, 10)
end

entity.onMobFight = function(mob, target)
    -- Use special TP move at 50% HP
    if mob:getHPP() <= 50 and mob:getLocalVar("used_special") == 0 then
        mob:useMobAbility(689)  -- Special TP move
        mob:setLocalVar("used_special", 1)
    end
end

entity.onMobDeath = function(mob, player, optParams)
    -- Grant title on kill
    player:addTitle(xi.title.NM_SLAYER)

    -- Drop special item (100% drop)
    player:addItem(1234, 1)
    player:messageSpecial(ID.text.ITEM_OBTAINED, 1234)

    -- Set respawn timer (21-24 hours)
    mob:setRespawnTime(math.random(75600, 86400))
end

return entity
```

## Quest Scripting

### Quest File Structure

```lua
-- /scripts/quests/[region]/[quest_name].lua

local quest = Quest:new(xi.quest.log_id.SANDORIA, xi.quest.id.sandoria.THE_EXAMPLE_QUEST)

quest.reward = {
    gil = 1000,
    fame = 30,
    item = { 13446 },  -- Bronze Sword
}

quest.sections = {
    {
        check = function(player, currentMission, missionStatus, vars)
            -- Check if quest is available
            return player:getMainLvl() >= 5 and
                   player:getFameLevel(xi.quest.log_id.SANDORIA) >= 1
        end,

        [xi.zone.SOUTHERN_SAN_DORIA] = {
            ['Questgiver_NPC'] = {
                onTrigger = function(player, npc)
                    -- Offer quest
                    return quest:progressEvent(100)
                end,
            },

            onEventFinish = {
                [100] = function(player, csid, option, npc)
                    -- Quest accepted
                    if option == 1 then
                        quest:begin(player)
                    end
                end,
            },
        },
    },

    {
        check = function(player, currentMission, missionStatus, vars)
            -- Check quest progress
            return quest:getVar(player, 'Prog') == 1
        end,

        [xi.zone.SOUTHERN_SAN_DORIA] = {
            ['Questgiver_NPC'] = {
                onTrade = function(player, npc, trade)
                    -- Turn in quest items
                    if npcUtil.tradeHasExactly(trade, {4509, 4509, 4509}) then
                        return quest:progressEvent(101)
                    end
                end,
            },

            onEventFinish = {
                [101] = function(player, csid, option, npc)
                    -- Complete quest
                    if quest:complete(player) then
                        player:confirmTrade()
                    end
                end,
            },
        },
    },
}

return quest
```

## Ability and Spell Scripting

### Ability Script Structure

```lua
-- /scripts/actions/abilities/[ability_name].lua

return {
    name = "Ability Name",

    onAbilityCheck = function(player, target, ability)
        -- Check if ability can be used
        -- Return 0 if OK, error code otherwise
        return 0
    end,

    onUseAbility = function(player, target, ability)
        -- Execute ability effect
        local result = doSomething()
        return result
    end
}
```

### Ability Example: Simple Buff

```lua
-- /scripts/actions/abilities/berserk.lua

return {
    name = "Berserk",

    onAbilityCheck = function(player, target, ability)
        return 0, 0
    end,

    onUseAbility = function(player, target, ability)
        local power = 25  -- 25% attack bonus
        local duration = 180  -- 3 minutes

        target:addStatusEffect(xi.effect.BERSERK, power, 0, duration)

        return xi.effect.BERSERK
    end
}
```

### Spell Script Structure

```lua
-- /scripts/actions/spells/[spell_name].lua

return {
    onMagicCastingCheck = function(caster, target, spell)
        -- Check if spell can be cast
        return 0
    end,

    onSpellCast = function(caster, target, spell)
        -- Execute spell effect
        return result
    end
}
```

### Spell Example: Healing Spell

```lua
-- /scripts/actions/spells/cure.lua

return {
    onMagicCastingCheck = function(caster, target, spell)
        return 0
    end,

    onSpellCast = function(caster, target, spell)
        local minCure = 10
        local divisor = 1
        local constant = 10
        local power = math.floor(caster:getSkillLevel(xi.skill.HEALING_MAGIC) / divisor) + constant
        power = power * (1 + caster:getMod(xi.mod.CURE_POTENCY) / 100)

        if caster:hasStatusEffect(xi.effect.AFFLATUS_SOLACE) and caster:isMob() == false then
            power = power * 1.25
        end

        local final = math.max(minCure, power)

        final = adjustForTarget(target, final, spell:getElement())
        final = target:addHP(final)

        target:wakeUp()

        return final
    end
}
```

## Global Functions and Utilities

### Common Utilities Location

**`/scripts/globals/npc_util.lua`**: NPC helper functions
**`/scripts/globals/common.lua`**: Common utilities
**`/scripts/globals/utils.lua`**: General utilities
**`/scripts/globals/magic.lua`**: Magic calculation functions

### npc_util Functions

```lua
-- Check trade contents
npcUtil.tradeHas(trade, itemId)
npcUtil.tradeHasExactly(trade, {item1, item2, item3})

-- Give items to player
npcUtil.giveItem(player, itemId, quantity)
npcUtil.giveKeyItem(player, keyItemId)

-- Pop NM (force spawn notorious monster)
npcUtil.popFromQM(player, qm, nmId, {look = true, hide = 0})

-- Completions
npcUtil.completeQuest(player, questId, reward)
```

### Player Helper Functions

```lua
-- Quest status
player:hasCompletedQuest(log, questId)
player:getQuestStatus(log, questId)
player:addQuest(log, questId)
player:completeQuest(log, questId)

-- Key items
player:hasKeyItem(keyItemId)
player:addKeyItem(keyItemId)
player:delKeyItem(keyItemId)

-- Character variables (persistent storage)
player:setCharVar(name, value)
player:getCharVar(name)
player:setLocalVar(name, value)  -- Non-persistent (session only)
player:getLocalVar(name)

-- Position and zone
player:getZoneID()
player:getPos()
player:setPos(x, y, z, rot, zoneId)

-- Stats and progression
player:getMainJob()
player:getMainLvl()
player:getSubJob()
player:getSubLvl()
player:getExp()
player:addExp(amount)
player:giveGil(amount)
player:delGil(amount)

-- Fame
player:getFameLevel(region)
player:addFame(region, amount)

-- Inventory
player:hasItem(itemId, location)
player:addItem(itemId, quantity, location)
player:delItem(itemId, quantity, location)
player:getFreeSlotsCount(location)

-- Messages
player:messageSpecial(textId, ...)
player:printToPlayer(text, chatType)
player:showText(npc, textId)
```

### Mob Helper Functions

```lua
-- Stats
mob:getHP()
mob:getHPP()  -- HP percentage
mob:setHP(value)
mob:addHP(value)

-- Modifiers
mob:setMod(modId, value)
mob:getMod(modId)
mob:addMod(modId, value)
mob:delMod(modId, value)

-- Mob-specific mods
mob:setMobMod(mobModId, value)
mob:getMobMod(mobModId)

-- Variables
mob:setLocalVar(name, value)
mob:getLocalVar(name)

-- Behavior
mob:setMobLevel(level)
mob:setAutoAttackEnabled(enabled)
mob:setMagicCastingEnabled(enabled)
mob:setMobAbilityEnabled(enabled)

-- Abilities
mob:useMobAbility(abilityId)
mob:hasSpellList()
mob:setSpellList(listId)

-- Spawn/Despawn
mob:setRespawnTime(seconds)
mob:spawn()
mob:despawn()
```

## Enumerations

### Accessing Enums

Enumerations are defined in `/scripts/enum/` (110 files).

**Common Enums**:
- `xi.zone.*` - Zone IDs
- `xi.job.*` - Job IDs
- `xi.race.*` - Race IDs
- `xi.item.*` - Item IDs (organized by category)
- `xi.ki.*` - Key item IDs
- `xi.mob.*` - Mob constants
- `xi.spell.*` - Spell IDs
- `xi.ability.*` - Ability IDs
- `xi.effect.*` - Status effect IDs
- `xi.mod.*` - Modifier IDs
- `xi.mobMod.*` - Mob modifier IDs
- `xi.quest.id.*` - Quest IDs
- `xi.mission.id.*` - Mission IDs

### Enum Example Usage

```lua
-- Zone IDs
if player:getZoneID() == xi.zone.SOUTHERN_SAN_DORIA then
    -- Player is in Southern San d'Oria
end

-- Job IDs
if player:getMainJob() == xi.job.WAR then
    -- Player is warrior
end

-- Item IDs
player:addItem(xi.item.PHOENIX_DOWN)

-- Status effects
player:addStatusEffect(xi.effect.PROTECT, 40, 0, 1800)

-- Modifiers
player:addMod(xi.mod.STR, 10)
```

## Mixins

### What are Mixins?

Mixins are reusable Lua modules that can be included in scripts to add common functionality.

**Location**: `/scripts/mixins/`

### Common Mixins

- **families/\*.lua**: Mob family behaviors
- **job_special.lua**: Job 2-hour abilities
- **rage.lua**: NM rage timer
- **gil_rat.lua**: Gil-dropping behavior

### Using Mixins

```lua
-- /scripts/zones/example/mobs/Example_NM.lua

require("scripts/globals/mixins")

local entity = {}

entity.onMobInitialize = function(mob)
    mob:addMix(require("scripts/mixins/rage"))
    mob:setMobMod(xi.mobMod.RAGE_TIME, 1800)  -- 30 minute rage timer
end

entity.onMobSpawn = function(mob)
    mob:setLocalVar("rage", os.time() + mob:getMobMod(xi.mobMod.RAGE_TIME))
end

-- Rage mixin handles TP spam when timer expires

return entity
```

## Custom Commands

### Command Structure

```lua
-- /scripts/commands/[command_name].lua

cmdprops = {
    permission = 0,  -- 0 = player, 1+ = GM levels
    parameters = "s"  -- Parameter types: s=string, i=integer
}

function onTrigger(player, arg1, arg2)
    -- Command logic
    player:printToPlayer("Command executed!")
end
```

### Command Example

```lua
-- /scripts/commands/whereami.lua

cmdprops = {
    permission = 0,
    parameters = ""
}

function onTrigger(player)
    local pos = player:getPos()
    local zone = zones[player:getZoneID()]

    player:printToPlayer(string.format(
        "Zone: %s (%d) | Position: %.2f, %.2f, %.2f",
        zone.name,
        zone.id,
        pos.x,
        pos.y,
        pos.z
    ))
end
```

## Best Practices

### Performance

1. **Cache Lookups**: Store frequently accessed data in local variables
2. **Avoid Repeated Calculations**: Calculate once, store result
3. **Use Local Variables**: Local vars are faster than globals
4. **Limit Database Queries**: Cache results when possible

### Code Organization

1. **Use Globals**: Share common code via `/scripts/globals/`
2. **Consistent Naming**: Follow existing naming conventions
3. **Comment Complex Logic**: Explain non-obvious code
4. **Modular Design**: Break complex scripts into functions

### Error Handling

```lua
-- Check for nil before accessing
if player and player:isPC() then
    player:messageSpecial(ID.text.EXAMPLE)
end

-- Validate inputs
if itemId and itemId > 0 then
    player:addItem(itemId)
end

-- Use pcall for error-prone operations
local success, result = pcall(function()
    return doSomethingRisky()
end)

if not success then
    print("Error:", result)
end
```

### Debugging

```lua
-- Print debugging output
print("Debug: player HP =", player:getHP())

-- Log to server console
player:printToPlayer(string.format("Debug: variable = %s", tostring(var)))

-- Check script loading
print("Script loaded: example.lua")
```

## Advanced Topics

### Metatables and OOP

```lua
-- Define class
local MyClass = {}
MyClass.__index = MyClass

function MyClass:new()
    local obj = setmetatable({}, MyClass)
    obj.value = 0
    return obj
end

function MyClass:increment()
    self.value = self.value + 1
end

-- Use class
local instance = MyClass:new()
instance:increment()
```

### Coroutines

```lua
-- Create coroutine for multi-step events
local co = coroutine.create(function()
    step1()
    coroutine.yield()
    step2()
    coroutine.yield()
    step3()
end)

-- Resume coroutine
coroutine.resume(co)  -- Executes step1
coroutine.resume(co)  -- Executes step2
coroutine.resume(co)  -- Executes step3
```

### Module Pattern

```lua
-- /scripts/globals/my_module.lua
local M = {}

M.CONSTANT = 42

function M.myFunction(arg)
    return arg * 2
end

return M

-- Usage in other scripts
local myModule = require("scripts/globals/my_module")
print(myModule.CONSTANT)  -- 42
print(myModule.myFunction(5))  -- 10
```

## Testing Lua Scripts

### Manual Testing

1. Make changes to Lua script
2. Save file
3. Reload script in-game (automatic for most scripts)
4. Test functionality

### Automated Testing

**Location**: `/scripts/specs/`

```lua
-- /scripts/specs/core/example_spec.lua

return {
    test = function()
        describe("Example test suite", function()
            it("should do something", function()
                local result = doSomething()
                assert.are.equal(42, result)
            end)

            it("should handle errors", function()
                assert.has_error(function()
                    doSomethingRisky()
                end)
            end)
        end)
    end
}
```

## Resources

- LandSandBoat scripts directory: `/scripts/`
- Lua 5.1 reference: https://www.lua.org/manual/5.1/
- LuaJIT documentation: https://luajit.org/
- sol2 documentation: https://github.com/ThePhD/sol2
- FFXI game data: `/documentation/` in LandSandBoat repository
