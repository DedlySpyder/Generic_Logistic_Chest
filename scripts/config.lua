Config = {}

Config.DEBUG_MODE = settings.startup["Generic_Logistic_debug_mode"].value

-- Doesn't exist during the data stage
if settings.global then
	function Config.refresh()
		Config.DATA_PURGE_PERIOD = settings.global["Generic_Logistic_chest_data_purge_period"].value
		Config.PLAYER_FAST_REPLACE_WINDOW = settings.global["Generic_Logistic_fast_replace_window_lag"].value
	end
	
	Config.refresh()
end
