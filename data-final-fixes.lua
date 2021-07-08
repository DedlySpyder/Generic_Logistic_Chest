local Logger = require("__DedLib__/modules/logger").create{modName = "Generic_Logistic_Chest"}
require("scripts/util")

if Logger.FILE_LOG_LEVEL == "trace" then
	Logger:trace_block(Util.dumpLogisticChests())
end
