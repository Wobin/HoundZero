-- Mod: Hound Zero
-- Author: Wobin
-- Date: 20/08/2026

local mod = get_mod("Hound Zero")

mod.colour_channel = function(id, index, default)
	local c = mod:get(id)

	if type(c) == "table" and #c >= 4 then
		return c[index + 1]
	end

	local suffix = (index == 1 and "_R") or (index == 2 and "_G") or "_B"
	local v = mod:get(id .. suffix)

	return type(v) == "number" and v or default
end

mod.version = mod.get_metadata and mod:get_metadata("version") or "unknown"

local Unit = Unit
local table = table
local Promise = Promise
local Managers = Managers
local delay = Promise.delay
local ScriptUnit = ScriptUnit
local vector3 = Vector3.distance
local table_find_by_key = table.find_by_key
local playerManager = Managers.player
local unitLocalPosition = Unit.local_position
local unitSetLocalPosition = Unit.set_local_position
local unitIsValid = Unit.is_valid
local has_extension = ScriptUnit.has_extension
local managers_state = Managers.state
local game_mode_manager = Managers.state.game_mode
local HEALTH_ALIVE = HEALTH_ALIVE
local CLASS = CLASS

mod.player = nil
mod.outline_visible = false

-- Defined before the modules load; both of them call it.
local function live_player()
    local player = mod.player
    if player and not player.__deleted then
        return player
    end
    return nil
end
mod.live_player = live_player

local function live_player_unit()
    local player = live_player()
    return player and player.player_unit or nil
end

mod:io_dofile("Hound Zero/scripts/mods/Hound Zero/modules/Outlines")
mod:io_dofile("Hound Zero/scripts/mods/Hound Zero/modules/Zone")

local function find_enemies_in_radius(center, radius)
    local state_extension = managers_state.extension
    local side_system = state_extension and state_extension:system("side_system")
    local player_side = side_system and side_system:get_side_from_name("heroes")
    if not player_side then return {} end
    local enemy_units_list = player_side:relation_units("enemy")
    local enemy_units = {}

    for _, unit in ipairs(enemy_units_list) do
        if HEALTH_ALIVE[unit] and vector3(center, unitLocalPosition(unit, 1)) <= radius then
            enemy_units[unit] = true
        end
    end
    return enemy_units
end

local retrieve_profile = function()
    local localplayer = playerManager:local_player_safe(1) or nil
    if not localplayer then return end
    local profile = localplayer:profile()
    mod.player = (profile and profile.archetype.name == "adamant" and profile.talents.adamant_whistle == 1) and localplayer or nil
end

local acceptable_locations = {}
acceptable_locations["coop_complete_objective"] = true
acceptable_locations["survival"] = true
acceptable_locations["shooting_range"] = true
acceptable_locations["expedition"] = true

mod.on_all_mods_loaded = function()
    mod:info(mod.version)
    mod:init()
end

mod.on_unload = function(exit_game)
    if mod.remove_all_outlines then mod.remove_all_outlines() end
    if mod.remove_zone then mod.remove_zone() end
    if mod.release_zone_package then mod.release_zone_package() end
    mod.player = nil
    mod.hound = nil
    mod.radius = nil
    mod.aiming = nil
    mod.outline_visible = false
end

mod.on_disabled = function()
    mod.on_unload()
end

mod.on_enabled = function(initial_call)
    if not initial_call then mod:init() end
end

mod.on_setting_changed = function(setting_id)
    if not setting_id then return end
    if setting_id:find("^outline_colour") then
        if mod.refresh_outline_colour then mod.refresh_outline_colour() end
        mod.remove_all_outlines()
    elseif setting_id:find("^ring_colour") then
        mod.remove_zone()
    end
end

mod.on_game_state_changed = function(status, sub_state_name)
	if sub_state_name == "GameplayStateRun" and status == "enter" then
        mod:init()
    end
    if status == "exit" then mod.on_unload() end
end

mod.init = function()
    game_mode_manager = Managers.state.game_mode
    if game_mode_manager then
	    if acceptable_locations[game_mode_manager:game_mode_name()] then
            mod.correct_area = true
            delay(3):next(retrieve_profile):next(mod.get_dog):next(mod.init_zone)
        else
            mod.correct_area = false
            mod.on_unload()
        end
    end
end


local getRadius = function()
    local player_unit = live_player_unit()
    local buff_extension = player_unit and has_extension(player_unit, "buff_system")
    local buffs = buff_extension and buff_extension._buffs
    if buffs then
        local _, buff = table_find_by_key(buffs, "_template_name", "weapon_trait_bespoke_boltpistol_p1_close_explosion")
        if buff then
            mod.radius = 5
        else
            mod.radius = 4
        end
    end
end

mod.hasCharges = function()
    if not mod:get("show_while_charged") then return false end
    local player_unit = live_player_unit()
    if not player_unit then return false end
    local ability_system = has_extension(player_unit, "ability_system")
    if not ability_system then return false end
    return ability_system:remaining_ability_charges("grenade_ability") > 0
end

mod:hook_safe(CLASS.InventoryBackgroundView, "on_exit", function()
    delay(3):next(retrieve_profile)
end)

local manage_outlines = mod.manage_outlines
local manage_zone = mod.manage_zone
local delta = 0


mod.update = function(dt)
    if not mod.correct_area or not mod:is_enabled() then return end
    if mod.zoned and mod.decal and unitIsValid(mod.decal) and mod.hound and unitIsValid(mod.hound) then
        unitSetLocalPosition(mod.decal, 1, unitLocalPosition(mod.hound, 1))
    end
    if delta > 0.5 then
        if not mod.radius then getRadius() end

        -- Cached once per tick; visibility_check reads it per outlined unit per FRAME.
        local visible = false
        if mod.aiming or mod.hasCharges() then visible = true end
        mod.outline_visible = visible

        if mod:get("show_outline") and live_player() and visible
            and mod.hound and unitIsValid(mod.hound) then
            local dog_position = unitLocalPosition(mod.hound, 1)
            manage_outlines(find_enemies_in_radius(dog_position, mod.radius))
        else
            mod.remove_all_outlines()
        end

        -- The decal is spawned against a specific hound; a respawn gives a new unit.
        if mod.zoned and mod.zoned_unit ~= mod.hound then
            mod.remove_zone()
        end
        if not mod.zoned then
            if mod:get("show_zone") and mod:get("show_while_charged") and mod.hasCharges() then
                manage_zone()
            end
        else
            if not visible then mod.remove_zone() end
        end
        delta = 0
    else
        delta = delta + dt
    end
end

local actions = {}
actions["action_aim"] = true
actions["action_order_companion"] = false



mod:hook_safe(CLASS.ActionHandler, "start_action", function(_, _, _, action_name, _, action_settings)
    if not mod:get("show_while_charged") then
        if not live_player() or not (actions[action_name] ~= nil and action_settings.ability_type == "grenade_ability") then return end

        mod.aiming = actions[action_name]

        if not mod.hound and action_name == "action_aim" then
            mod.get_dog()
        end

        manage_zone()
        if action_name == "action_order_companion" then
            delay(0.5):next(mod.remove_all_outlines):next(mod.remove_zone)
        end
    end
end)

mod.get_dog = function()
    local player_unit = live_player_unit()
    if not player_unit then return end
    local companion_spawner_extension = has_extension(player_unit, "companion_spawner_system")
    local spawned_units = companion_spawner_extension and companion_spawner_extension._spawned_units
    local companion_unit = spawned_units and spawned_units[1]

    if companion_unit then
        mod.hound = companion_unit
    end
end


mod.on_settings_reset = function()
    if mod.refresh_outline_colour then mod.refresh_outline_colour() end
    mod.remove_all_outlines()
    mod.remove_zone()
end