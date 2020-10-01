require("util")

UI = {}
UI.Selection = {} -- TODO - redo caption names

UI.Selection.FRAME_NAME = Util.MOD_PREFIX .. "selection_frame"
UI.Selection.BUTTON_PREFIX_DIFF = "button_"
UI.Selection.BUTTON_PREFIX = Util.MOD_PREFIX .. UI.Selection.BUTTON_PREFIX_DIFF
UI.Selection.CLOSE_BUTTON = Util.MOD_PREFIX .. "close"

-- Returns whether the Selection UI was drawn or not
-- If it was not drawn then the chest should just be considered a normal chest
function UI.Selection.draw(player, replacements)
	if player and player.valid and not UI.Selection.isOpen(player) then
		Util.debugLog("Drawing selection UI for " .. player.name)
		
		-- The frame to hold everything
		local selectionGUI = player.gui.center.add{type="frame", name=UI.Selection.FRAME_NAME, direction="vertical", caption={"generic-chest-select-chest"}}
		
		-- The flow to hold the buttons
		local selectionButtonFlow = selectionGUI.add{type="flow", direction="horizontal"}
		
		-- The selection buttons
		for _, replacement in ipairs(replacements) do
			selectionButtonFlow.add {
				type="sprite-button",
				name=UI.Selection.BUTTON_PREFIX .. replacement,
				sprite="entity/" .. replacement,
				tooltip={"entity-name." .. replacement}
			}
		end
		
		-- Close button
		selectionGUI.add{type="button", name=UI.Selection.CLOSE_BUTTON, caption={"generic-chest-close"}}
		return true
	end
	
	Util.debugLog("Could not draw selection UI for " .. player.name)
	return false
end

function UI.Selection.destroy(player)
	if player and player.valid and UI.Selection.isOpen(player) then
		Util.debugLog("Destroying selection UI for " .. player.name)
		player.gui.center.genericChestSelectionFrame.destroy()
	end
end

function UI.Selection.isOpen(player)
	return player.gui.center.genericChestSelectionFrame and player.gui.center.genericChestSelectionFrame.valid
end

