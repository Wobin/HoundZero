local mod = get_mod("Hound Zero")

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
				type = "group",
				sub_widgets = {
					{ setting_id = "outline_colour_R", type = "numeric", default_value = 0,   range = {0, 255} },
					{ setting_id = "outline_colour_G", type = "numeric", default_value = 0,   range = {0, 255} },
					{ setting_id = "outline_colour_B", type = "numeric", default_value = 255, range = {0, 255} },
				},
			},
			{
				setting_id = "ring_colour",
				type = "group",
				sub_widgets = {
					{ setting_id = "ring_colour_R", type = "numeric", default_value = 0,   range = {0, 255} },
					{ setting_id = "ring_colour_G", type = "numeric", default_value = 0,   range = {0, 255} },
					{ setting_id = "ring_colour_B", type = "numeric", default_value = 255, range = {0, 255} },
				},
			},

		},
	},
}
