local Logger = require("__DedLib__/modules/logger").create{modName = "Generic_Logistic_Chest"}

local Config = {}

Config.MOD_PREFIX = "Generic_Logistic_"

-- Doesn't exist during the data stage
if settings.global then
	function Config.refresh()
		Logger:info("Refreshing config values...")
		Config.DATA_PURGE_PERIOD = settings.global["Generic_Logistic_chest_data_purge_period"].value
		Config.PLAYER_FAST_REPLACE_LAG = settings.global["Generic_Logistic_fast_replace_lag"].value
		Logger:trace_block("New config: %s", Config)
	end
	
	Config.refresh()
end

return Config
