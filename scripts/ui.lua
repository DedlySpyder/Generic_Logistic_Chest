local LoggerLib = require("__DedLib__/modules/logger")

local Config = require("config")
require("storage")

UI = {}
UI.Selection = {}
UI.Selection._LOGGER = LoggerLib.create("Selection")

UI.Selection.FRAME_NAME = Config.MOD_PREFIX .. "selection_frame"
UI.Selection.BUTTON_PREFIX_DIFF = "button_"
UI.Selection.BUTTON_PREFIX = Config.MOD_PREFIX .. UI.Selection.BUTTON_PREFIX_DIFF
UI.Selection.CLOSE_BUTTON = Config.MOD_PREFIX .. "close"

-- Returns whether the Selection UI was drawn or not
-- If it was not drawn then the chest should just be considered a normal chest
function UI.Selection.draw(player, replacements, chestEntity)
	Storage.PlayerUiOpen.add(player, chestEntity)
	
	if player and player.valid and not UI.Selection.isOpen(player) then
		UI.Selection._LOGGER:debug("Drawing selection UI for %s", player)

		-- The frame to hold everything
		local selectionGUI = player.gui.center.add{type="frame", name=UI.Selection.FRAME_NAME, direction="vertical", caption={"Generic_Logistic_select_chest_ui_title"}}
		
		-- The flow to hold the buttons
		local selectionButtonFlow = selectionGUI.add{type="flow", direction="horizontal"}
		
		-- The selection buttons
		for _, replacement in ipairs(replacements) do
			local replacementBaseName = string.sub(replacement, #Config.MOD_PREFIX + 1, #replacement)
			selectionButtonFlow.add {
				type="sprite-button",
				name=UI.Selection.BUTTON_PREFIX .. replacement,
				sprite="entity/" .. replacementBaseName,
				tooltip={"item-name." .. replacementBaseName}
			}
		end
		
		-- Close button
		selectionGUI.add{type="button", name=UI.Selection.CLOSE_BUTTON, caption={"Generic_Logistic_select_chest_ui_close"}}
		return true
	end

	UI.Selection._LOGGER:debug("Selection UI already exists for %s", player)
	return false
end

function UI.Selection.destroy(player)
	if player and player.valid and UI.Selection.isOpen(player) then
		UI.Selection._LOGGER:debug("Destroying selection UI for %s", player)
		player.gui.center[UI.Selection.FRAME_NAME].destroy()
	end
end

function UI.Selection.isOpen(player)
	return player.gui.center[UI.Selection.FRAME_NAME] and player.gui.center[UI.Selection.FRAME_NAME].valid
end

