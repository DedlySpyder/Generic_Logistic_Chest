local Logger = require("__DedLib__/modules/logger").create{modName = "Generic_Logistic_Chest"}
local DataUtil = require("scripts/data_util")

if Logger.FILE_LOG_LEVEL == "trace" then
	Logger:trace_block(DataUtil.dumpLogisticChests())
end
