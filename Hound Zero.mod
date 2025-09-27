return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Hound Zero` encountered an error loading the Darktide Mod Framework.")

		new_mod("Hound Zero", {
			mod_script       = "Hound Zero/scripts/mods/Hound Zero/Hound Zero",
			mod_data         = "Hound Zero/scripts/mods/Hound Zero/Hound Zero_data",
			mod_localization = "Hound Zero/scripts/mods/Hound Zero/Hound Zero_localization",
		})
	end,
	version = "1.4",
	packages = {},
}
