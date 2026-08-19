local mod = get_mod("Hound Zero")
local function migrate_colour(id)
	if mod:get(id) ~= nil then
		return
	end

	local r = mod:get(id .. "_R")
	local g = mod:get(id .. "_G")
	local b = mod:get(id .. "_B")

	if type(r) == "number" and type(g) == "number" and type(b) == "number" then
		mod:set(id, { 255, r, g, b })
	end
end

migrate_colour("outline_colour")
migrate_colour("ring_colour")



return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "show_outline",			
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_zone",			
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_while_charged",
				type = "checkbox",
				default_value = false,
			},
			{
				setting_id = "outline_colour",
				type = "color",
				default_value = { 255, 0, 0, 255 },
				has_alpha = false,
			},
			{
				setting_id = "ring_colour",
				type = "color",
				default_value = { 255, 0, 0, 255 },
				has_alpha = false,
			},

		},
	},
}
