local generic_logistic_chest_passive_provider = util.table.deepcopy(data.raw["logistic-container"]["logistic-chest-passive-provider"])
local generic_logistic_chest_active_provider = util.table.deepcopy(data.raw["logistic-container"]["logistic-chest-active-provider"])
local generic_logistic_chest_storage = util.table.deepcopy(data.raw["logistic-container"]["logistic-chest-storage"])
local generic_logistic_chest_requester = util.table.deepcopy(data.raw["logistic-container"]["logistic-chest-requester"])
local generic_logistic_chest_buffer = util.table.deepcopy(data.raw["logistic-container"]["logistic-chest-buffer"])

generic_logistic_chest_passive_provider.name = "generic-logistic-chest-passive-provider"
generic_logistic_chest_active_provider.name = "generic-logistic-chest-active-provider"
generic_logistic_chest_storage.name = "generic-logistic-chest-storage"
generic_logistic_chest_requester.name = "generic-logistic-chest-requester"
generic_logistic_chest_buffer.name = "generic-logistic-chest-buffer"

generic_logistic_chest_passive_provider.minable.result = "generic-logistic-chest"
generic_logistic_chest_active_provider.minable.result = "generic-logistic-chest"
generic_logistic_chest_storage.minable.result = "generic-logistic-chest"
generic_logistic_chest_requester.minable.result = "generic-logistic-chest"
generic_logistic_chest_buffer.minable.result = "generic-logistic-chest"

generic_logistic_chest_passive_provider.order = "z"
generic_logistic_chest_active_provider.order = "z"
generic_logistic_chest_storage.order = "z"
generic_logistic_chest_requester.order = "z"
generic_logistic_chest_buffer.order = "z"

data:extend({	generic_logistic_chest_passive_provider, 
				generic_logistic_chest_active_provider, 
				generic_logistic_chest_storage, 
				generic_logistic_chest_requester,
				generic_logistic_chest_buffer})