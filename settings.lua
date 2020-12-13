data:extend({
	{
		name = "Generic_Logistic_chest_data_purge_period",
		type = "double-setting",
		setting_type = "runtime-global",
		default_value = 10,
		order = "100"
	},
	{
		name = "Generic_Logistic_fast_replace_lag",
		type = "int-setting",
		setting_type = "runtime-global",
		default_value = 15,
		order = "200"
	},
	{
		name = "Generic_Logistic_debug_mode",
		type = "bool-setting",
		setting_type = "startup",
		default_value = false,
		order = "900"
	}
})
