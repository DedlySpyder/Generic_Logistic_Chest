Config = {}



-- Doesn't exist during the data stage
if settings.global then
	function Config.refresh()
		Config.PLAYER_FAST_REPLACE_WINDOW = 15
	end
	
	Config.refresh()
end

--[[
Config.MANUAL_MODE = settings.startup["Powered_Entities_00_manual_mode"].value
Config.MINIMUM_WIRE_REACH = settings.startup["Powered_Entities_01_minimum_wire_reach"].value

Config.DEBUG_MODE = settings.startup["Powered_Entities_90_debug_mode"].value
Config.TRACE_MODE = settings.startup["Powered_Entities_91_trace_mode"].value
Config.DEBUG_TYPE = settings.startup["Powered_Entities_99_debug_type"].value

-- Doesn't exist during the data stage
if settings.global then
	function Config.refresh()
		Config.SHOW_RECALCULATE_NAME = "Powered_Entities_80_recalculate_show"
		
		Config.ENABLE_INSERTER = settings.global["Powered_Entities_00_enable_inserter"].value
		Config.ENABLE_SOLAR = settings.global["Powered_Entities_05_enable_solar"].value
		Config.ENABLE_ACCUMULATOR = settings.global["Powered_Entities_10_enable_accumulator"].value
		Config.ENABLE_PRODUCER = settings.global["Powered_Entities_15_enable_producers"].value
		Config.SHOW_RECALCULATE = settings.global[Config.SHOW_RECALCULATE_NAME].value
		Config.ENTITY_NAME_EXCLUSION_LIST = parseCsv(settings.global["Powered_Entities_entity_name_exclusion_list"].value)
		
		Config.REPORT_LOCALIZED_NAMES = settings.global["Powered_Entities_report_localized_items"].value
		Config.RECALCULATE_BATCH_SIZE = settings.global["Powered_Entities_90_recalculate_batch_size"].value
		Config.SKIP_RECALCULATE_ON_MOD_CHANGES = settings.global["Powered_Entities_skip_recalculate_on_mod_changes"].value
	end
	
	Config.refresh()
end
]]--