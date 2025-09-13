local mod = get_mod("Hound Zero")
local decal_path = "content/levels/training_grounds/fx/decal_aoe_indicator"
local package_path = "content/levels/training_grounds/missions/mission_tg_basic_combat_01"

local Managers = Managers
local package = Managers.package
local Unit = Unit
local World = World
local Vector3 = Vector3
local Quaternion = Quaternion

mod.init_zone = function(has_loaded)
    if not package:has_loaded(package_path) and not has_loaded then
        package:load(package_path, "Hound Zero", function()
            mod.init_zone(true)
        end)
        return
    end    
    mod.zone_loaded = true
end

mod.manage_zone = function()
    if not mod.hound or not mod.zone_loaded then return end
    if mod.decal then mod.remove_zone() end

    local unit = mod.hound
    local world = Unit.world(unit)
	local unit_position = Unit.local_position(unit, 1)

	-- Create decal unit
	local decal_unit = World.spawn_unit_ex(world, decal_path, nil, unit_position)
    World.link_unit(world, decal_unit, 1, unit, 1)
    
	-- Set size of unit
	local diameter = mod.radius * 2
	Unit.set_local_scale(decal_unit, 1, Vector3(diameter, diameter, 1))

	-- Set color of unit
	local material_value = Quaternion.identity()
	Quaternion.set_xyzw(material_value, 0, 0, 1, 0.5)
	Unit.set_vector4_for_material(decal_unit, "projector", "particle_color", material_value, true)

	-- Set low opacity
	Unit.set_scalar_for_material(decal_unit, "projector", "color_multiplier", 0.5)
    
	mod.decal = decal_unit 
end

mod.remove_zone = function()    
   if mod.decal then
        World.destroy_unit(Unit.world(mod.decal), mod.decal)                 
        mod.decal = nil
    end
end