require("scripts.generic_generation")
require("scripts.chest_groups")

for _, group in ipairs(ChestGroups.getGroups()) do
	Generic_Logistic_Generator.addGenericGroup(group)
end

Generic_Logistic_Generator.generate()


data:extend({
	{
		type = "custom-input",
		name = "Generic_Logistic_copy_chest",
		linked_game_control = "copy-entity-settings",
		key_sequence = ""
	},
	
	{
		type = "custom-input",
		name = "Generic_Logistic_select_scroll_up",
		key_sequence = "ALT + mouse-wheel-up",
		order = "100"
	},
	{
		type = "custom-input",
		name = "Generic_Logistic_select_scroll_down",
		key_sequence = "ALT + mouse-wheel-down",
		order = "200"
	}
})
