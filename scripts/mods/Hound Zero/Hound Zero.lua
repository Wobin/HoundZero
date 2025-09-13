-- Mod: Hound Zero
-- Author: Wobin
-- Date: 14/09/2025
-- Version: 1.1

local mod = get_mod("Hound Zero")
mod.version = "1.1"

local Unit = Unit
local table = table
local Promise = Promise
local Managers = Managers
local delay = Promise.delay
local ScriptUnit = ScriptUnit
local vector3 = Vector3.distance
local table_insert = table.insert
local table_find_by_key = table.find_by_key
local playerManager = Managers.player
local unitLocalPosition = Unit.local_position
local managers_state = Managers.state
local game_mode_manager = Managers.state.game_mode			
local extension = ScriptUnit.extension
local HEALTH_ALIVE = HEALTH_ALIVE
local CLASS = CLASS	

mod.player = nil

local function find_enemies_in_radius(center, radius)
    local state_extension = managers_state.extension or Managers.state.extension
    local side_system = state_extension:system("side_system")
    local player_side = side_system and side_system:get_side_from_name("heroes")
    if not player_side then return {} end
    local enemy_units_list = player_side:relation_units("enemy")
    local enemy_units = {}
    
    for _, unit in ipairs(enemy_units_list) do        
        if HEALTH_ALIVE and HEALTH_ALIVE[unit] and vector3(center, unitLocalPosition(unit, 1)) <= radius then
            table_insert(enemy_units, unit)
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

mod.on_all_mods_loaded = function()    
    mod:info(mod.version)
    mod:init()
end

mod.on_unload = function(exit_game)
    mod.remove_all_outlines()
    mod.remove_zone()
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
            delay(3):next(retrieve_profile):next(mod.get_dog):next(mod.init_zone)
        end
    end
end


local getRadius = function()
    local buff_extension = mod.player and ScriptUnit.has_extension(mod.player.player_unit, "buff_system")
    local buffs = buff_extension and buff_extension._buffs        
    if buffs then            
        local _, buff =  table_find_by_key(buffs, "_template_name", "weapon_trait_bespoke_boltpistol_p1_close_explosion")
        if buff then                
            mod.radius = 5
        else
            mod.radius = 4
        end
    end
end

mod:hook_safe(CLASS.InventoryBackgroundView, "on_exit", function()
    delay(3):next(retrieve_profile)
end)

mod:io_dofile("Hound Zero/scripts/mods/Hound Zero/modules/Outlines")
mod:io_dofile("Hound Zero/scripts/mods/Hound Zero/modules/Zone")

local manage_outlines = mod.manage_outlines
local manage_zone = mod.manage_zone
local delta = 0

mod.update = function(dt)    
    if mod:get("show_outline") and mod.player and mod.aiming and mod.hound then
        if delta > 0.5 and Unit.is_valid(mod.hound) then 
            delta = 0
            local dog_position = unitLocalPosition(mod.hound, 1)        
            local enemies = find_enemies_in_radius(dog_position, mod.radius)                     
            manage_outlines(enemies)
        else
            delta = delta + dt
        end
    end
end 

local actions = {}
actions["action_aim"] = true
actions["action_order_companion"] = false


mod:hook_safe(CLASS.ActionHandler, "start_action", function(_, _, _, action_name, _, action_settings)
    if not mod.player or not (actions[action_name] ~= nil and action_settings.ability_type == "grenade_ability" ) then return end        
    
    mod.aiming = actions[action_name]        
    
    if not mod.hound and action_name == "action_aim" then
        mod.get_dog()
    end        

    getRadius()

    if mod:get("show_zone") then
        manage_zone()
    end

    if action_name == "action_order_companion" then
        delay(0.5):next(mod.remove_all_outlines):next(mod.remove_zone)            
    end            
end)

mod.get_dog  = function()    
    local companion_spawner_extension = extension(mod.player.player_unit, "companion_spawner_system")
    local companion_unit = companion_spawner_extension:companion_unit()

    if companion_unit then                
        mod.hound = companion_unit                      
    end
end