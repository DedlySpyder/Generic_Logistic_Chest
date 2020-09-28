function dummy()
	return {
		type = "item",
		icon = "__Generic_Logistic_Chest__/graphics/icon/generic-logistic-chest.png",
		icon_size = 32,
		flags = {"hidden"},
		stack_size = 1
	}
end

local passive_provider_dummy = dummy()
local active_provider_dummy = dummy()
local storage_dummy = dummy()
local requester_dummy = dummy()
local buffer_dummy = dummy()

passive_provider_dummy.name = "passive_provider_dummy"
active_provider_dummy.name = "active_provider_dummy"
storage_dummy.name = "storage_dummy"
requester_dummy.name = "requester_dummy"
buffer_dummy.name = "buffer_dummy"

passive_provider_dummy.place_result =  "generic-logistic-chest-passive-provider"
active_provider_dummy.place_result = "generic-logistic-chest-active-provider"
storage_dummy.place_result = "generic-logistic-chest-storage"
requester_dummy.place_result = "generic-logistic-chest-requester"
buffer_dummy.place_result = "generic-logistic-chest-buffer"

data:extend({passive_provider_dummy, active_provider_dummy, storage_dummy, requester_dummy, buffer_dummy})

data:extend({

  {
    type = "item",
    name = "generic-logistic-chest",
    icon = "__Generic_Logistic_Chest__/graphics/icon/generic-logistic-chest.png",
	icon_size = 32,
    subgroup = "logistic-network",
    order = "b[storage]-b[generic-logistic-chest]",
    place_result = "generic-logistic-chest",
    stack_size = 50
  }
})