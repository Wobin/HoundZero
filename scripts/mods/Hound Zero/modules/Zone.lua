local mod = get_mod("Hound Zero")
local decal_path = "content/levels/training_grounds/fx/decal_aoe_indicator"
local package_path = "content/levels/training_grounds/missions/mission_tg_basic_combat_01"

local Unit = Unit
local World = World
local Vector3 = Vector3
local Quaternion = Quaternion
local HEALTH_ALIVE = HEALTH_ALIVE
local is_valid = Unit.is_valid

mod.init_zone = function()
    if not mod.live_player or not mod.live_player() then return end
    if mod.zone_loaded or mod:package_status(package_path) then return end
    mod:load_package(package_path, function()
        mod.zone_loaded = true
    end)
end

mod.release_zone_package = function()
    mod.zone_loaded = false
    if mod:package_status(package_path) then
        mod:unload_package(package_path)
    end
end

mod.manage_zone = function()
    if not mod.hound or not mod.zone_loaded then return end
    if not HEALTH_ALIVE[mod.hound] or not is_valid(mod.hound) then
        mod.get_dog()
    end
    if mod.decal then mod.remove_zone() end
    if not mod.hound or not is_valid(mod.hound) then
        mod.hound = nil
        return
    end

    local unit = mod.hound
    local world = Unit.world(unit)
	local unit_position = Unit.local_position(unit, 1)

	local decal_unit = World.spawn_unit_ex(world, decal_path, nil, unit_position)

	local diameter = mod.radius * 2
	Unit.set_local_scale(decal_unit, 1, Vector3(diameter, diameter, 1))

	local material_value = Quaternion.identity()
	Quaternion.set_xyzw(material_value,
		(mod.colour_channel("ring_colour", 1, 0)) / 255,
		(mod.colour_channel("ring_colour", 2, 0)) / 255,
		(mod.colour_channel("ring_colour", 3, 255)) / 255,
		0.5)
	Unit.set_vector4_for_material(decal_unit, "projector", "particle_color", material_value, true)

	Unit.set_scalar_for_material(decal_unit, "projector", "color_multiplier", 0.5)

	mod.decal = decal_unit
    mod.zoned = true
    mod.zoned_unit = unit
end

mod.remove_zone = function()
    local decal = mod.decal
    mod.decal = nil
    mod.zoned = false
    mod.zoned_unit = nil
    if decal and is_valid(decal) then
        World.destroy_unit(Unit.world(decal), decal)
    end
end
