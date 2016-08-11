function images(fileName) 
	return {
      type = "monolith",
	  monolith_image = {
         filename = fileName,
         width = 32,
         height = 32
    }
	}
end

data.raw["gui-style"].default["generic_passive_provider_chest_button"] =
{
    type = "button_style",
    parent = "button_style",
    width = 32,
    height = 32,
    top_padding = 0,
    right_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
	default_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/passive-provider.png"),
	hovered_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/passive-provider-hover.png"),
	clicked_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/passive-provider-clicked.png")
}

data.raw["gui-style"].default["generic_active_provider_chest_button"] =
{
    type = "button_style",
    parent = "button_style",
    width = 32,
    height = 32,
    top_padding = 0,
    right_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
	default_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/active-provider.png"),
	hovered_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/active-provider-hover.png"),
	clicked_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/active-provider-clicked.png")
}

data.raw["gui-style"].default["generic_storage_chest_button"] =
{
    type = "button_style",
    parent = "button_style",
    width = 32,
    height = 32,
    top_padding = 0,
    right_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
	default_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/storage.png"),
	hovered_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/storage-hover.png"),
	clicked_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/storage-clicked.png")
}

data.raw["gui-style"].default["generic_requester_chest_button"] =
{
    type = "button_style",
    parent = "button_style",
    width = 32,
    height = 32,
    top_padding = 0,
    right_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
	default_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/requester.png"),
	hovered_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/requester-hover.png"),
	clicked_graphical_set = images("__Generic_Logistic_Chest__/graphics/gui/requester-clicked.png")
}