-- Mod: Hound Zero
-- Author: Wobin
-- Date: 05/10/2026

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

mod.opts = {
    show_outline = false,
    show_zone = false,
    show_while_charged = false,
}
local opts = mod.opts

local function refresh_opts()
    opts.show_outline = mod:get("show_outline") and true or false
    opts.show_zone = mod:get("show_zone") and true or false
    opts.show_while_charged = mod:get("show_while_charged") and true or false
end

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

local enemy_units = {}

local function find_enemies_in_radius(center, radius)
    table.clear(enemy_units)

    local state_extension = managers_state.extension
    local side_system = state_extension and state_extension:system("side_system")
    local player_side = side_system and side_system:get_side_from_name("heroes")
    if not player_side then return enemy_units end
    local enemy_units_list = player_side:relation_units("enemy")

    for _, unit in ipairs(enemy_units_list) do
        if HEALTH_ALIVE[unit] and vector3(center, unitLocalPosition(unit, 1)) <= radius then
            enemy_units[unit] = true
        end
    end
    return enemy_units
end

local retrieve_profile = function()
    local localplayer = playerManager:local_player_safe(1)
    if not localplayer then return end

    local profile = localplayer:profile()
    local archetype = profile and profile.archetype
    local talents = profile and profile.talents

    local whistle = talents and talents.adamant_whistle
    local whistle_tier = type(whistle) == "table" and whistle.tier or whistle

    if archetype and archetype.name == "adamant" and type(whistle_tier) == "number" and whistle_tier > 0 then
        mod.player = localplayer
    else
        mod.player = nil
    end
end

local acceptable_locations = {}
acceptable_locations["coop_complete_objective"] = true
acceptable_locations["survival"] = true
acceptable_locations["shooting_range"] = true
acceptable_locations["expedition"] = true

mod.on_all_mods_loaded = function()
    mod:info(mod.version)
    refresh_opts()
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
    mod.correct_area = false
    mod.outline_visible = false
end

mod.on_disabled = function()
    mod.on_unload()
end

mod.on_enabled = function(initial_call)
    if not initial_call then mod:init() end
end

mod.on_setting_changed = function(setting_id)
    refresh_opts()
    if not setting_id then return end
    if setting_id:find("^outline_colour") then
        if mod.refresh_outline_colour then mod.refresh_outline_colour() end
        mod.remove_all_outlines()
    elseif setting_id:find("^ring_colour") then
        mod.remove_zone()
    end
end

mod.on_game_state_changed = function(status, sub_state_name)
    if sub_state_name ~= "GameplayStateRun" then return end

    if status == "enter" then
        mod:init()
    elseif status == "exit" then
        mod.on_unload()
    end
end

mod.init = function()
    refresh_opts()
    game_mode_manager = Managers.state.game_mode
    if game_mode_manager then
	    if acceptable_locations[game_mode_manager:game_mode_name()] then
            mod.correct_area = true
            retrieve_profile()
            mod.get_dog()
            mod.init_zone()
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
    if not opts.show_while_charged then return false end
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

        local visible = false
        if mod.aiming or mod.hasCharges() then visible = true end
        mod.outline_visible = visible

        if opts.show_outline and live_player() and visible
            and mod.hound and unitIsValid(mod.hound) then
            local dog_position = unitLocalPosition(mod.hound, 1)
            manage_outlines(find_enemies_in_radius(dog_position, mod.radius))
        else
            mod.remove_all_outlines()
        end

        if mod.zoned and mod.zoned_unit ~= mod.hound then
            mod.remove_zone()
        end
        if not mod.zoned then
            if opts.show_zone and opts.show_while_charged and mod.hasCharges() then
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



mod:hook_safe(CLASS.ActionHandler, "start_action", function(_, _, _, action_name, action_params, action_settings)
    if not opts.show_while_charged then
        if not live_player() or actions[action_name] == nil then return end
        local ability_type = (action_params and action_params.ability_type) or (action_settings and action_settings.ability_type)
        if ability_type ~= "grenade_ability" then return end

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
    local spawned_units = companion_spawner_extension and companion_spawner_extension:companion_units()
    local companion_unit = spawned_units and spawned_units[1]

    if companion_unit then
        mod.hound = companion_unit
    end
end

mod:hook_safe(CLASS.CompanionSpawnerExtension, "register_spawned_companion_unit", function(self, spawned_unit)
    if not mod.correct_area or not spawned_unit then return end
    if not self._is_local_unit then return end

    if not live_player() then retrieve_profile() end
    if not live_player() then return end

    mod.hound = spawned_unit
end)


mod.on_settings_reset = function()
    refresh_opts()
    if mod.refresh_outline_colour then mod.refresh_outline_colour() end
    mod.remove_all_outlines()
    mod.remove_zone()
end