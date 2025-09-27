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
			
		},
	},
}
