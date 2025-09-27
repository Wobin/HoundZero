local mod = get_mod("Hound Zero")

local Managers = Managers
local table_contains = table.contains
local manager_state = Managers.state
local outline_system
local outlined_units = {}
local tag_colour = "houndzero"

local get_outline_system = function()
    local state_extension = manager_state.extension
    if not outline_system then
        outline_system = state_extension and state_extension:system("outline_system")
    end
    return outline_system
end

mod.remove_outline = function(unit)
        outline_system:remove_outline(unit, tag_colour, true)
        outlined_units[unit] = nil
end

mod.remove_all_outlines = function()
    for unit,_ in pairs(outlined_units) do
        mod.remove_outline(unit)
    end
end

mod:hook_require("scripts/settings/outline/outline_settings", function(settings)    
     settings.MinionOutlineExtension.houndzero = {
        priority = 3,
        color = {0,0,1},
        material_layers = {
            "minion_outline",
			"minion_outline_reversed_depth",       
        },
        visibility_check = function() return mod.aiming or mod.hasCharges() end
    }
end)

mod.manage_outlines = function(enemies)
        outline_system = outline_system or get_outline_system()        
        if not mod:get("show_outline") or not outline_system then return end
        for unit, _ in pairs(outlined_units) do

            if not table_contains(enemies, unit) then
                mod.remove_outline(unit)
            end
        end
        
        for _, unit in ipairs(enemies) do
            if not outlined_units[unit] then
                outline_system:remove_outline(unit, tag_colour)
                outline_system:add_outline(unit, tag_colour)
                outlined_units[unit] = true
            end
        end
end
