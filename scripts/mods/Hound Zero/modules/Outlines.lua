local mod = get_mod("Hound Zero")

local Managers = Managers
local manager_state = Managers.state
local Unit = Unit
local unit_alive = Unit.alive
local HEALTH_ALIVE = HEALTH_ALIVE
local outline_system
local cached_extension_manager
local outlined_units = {}
local tag_colour = "houndzero"

local get_outline_system = function()
    local extension_manager = manager_state.extension
    if not extension_manager then
        outline_system = nil
        cached_extension_manager = nil
        return nil
    end
    if extension_manager ~= cached_extension_manager then
        cached_extension_manager = extension_manager
        outline_system = extension_manager:system("outline_system")
    end
    return outline_system
end

mod.remove_outline = function(unit)
    local system = get_outline_system()
    if system and unit_alive(unit) then
        system:remove_outline(unit, tag_colour)
    end
    outlined_units[unit] = nil
end

mod.remove_all_outlines = function()
    for unit, _ in pairs(outlined_units) do
        mod.remove_outline(unit)
    end
end

local function outline_colour()
    return {
        (mod.colour_channel("outline_colour", 1, 0)) / 255,
        (mod.colour_channel("outline_colour", 2, 0)) / 255,
        (mod.colour_channel("outline_colour", 3, 255)) / 255,
    }
end

mod:hook_require("scripts/settings/outline/outline_settings", function(settings)
     settings.MinionOutlineExtension.houndzero = {
        priority = 5,
        color = outline_colour(),
        material_layers = {
            "minion_outline",
			"minion_outline_reversed_depth",
        },
        visibility_check = function(unit)
            if not HEALTH_ALIVE[unit] then return false end
            if mod.outline_visible ~= true then return false end
            return true
        end
    }
    mod._houndzero_outline_cfg = settings.MinionOutlineExtension.houndzero
end)

mod.refresh_outline_colour = function()
    if mod._houndzero_outline_cfg then
        mod._houndzero_outline_cfg.color = outline_colour()
    end
end

mod.manage_outlines = function(enemies)
        local system = get_outline_system()
        if not system or not mod:get("show_outline") then return end

        for unit, _ in pairs(outlined_units) do
            if not enemies[unit] then
                mod.remove_outline(unit)
            end
        end

        for unit, _ in pairs(enemies) do
            if not outlined_units[unit] and unit_alive(unit) then
                system:remove_outline(unit, tag_colour)
                system:add_outline(unit, tag_colour)
                outlined_units[unit] = true
            end
        end
end
