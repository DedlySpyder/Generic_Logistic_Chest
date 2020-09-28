Util = {}

Util.MOD_PREFIX = "Generic_Logistic_"

Util.DEBUG_MODE = settings.startup["Generic_Logistic_debug_mode"].value

if Util.DEBUG_MODE then
	Util.debugLog = function(message)
		if game then
			for _, player in pairs(game.players) do
				if player and player.valid then
					player.print("[" .. game.tick .. "] " .. message)
				end
			end
		else
			log(message)
		end
	end
else
	Util.debugLog = function(m) end
end


function Util.mathMin(nums)
	local t = {}
	for _, num in ipairs(nums) do
		if num ~= nil then
			table.insert(t, num)
		end
	end
	return math.min(unpack(t))
end

-- Filter either a table or an array, if the function returns true then the value will stay
function Util.filterTable(tbl, func)
	local newTable = {}
	local isArr = #tbl > 0
	for k, v in pairs(tbl) do
		if func(v) then
			if isArr then
				table.insert(newTable, v)
			else
				newTable[k] = v
			end
		end
	end
	return newTable
end

-- Returns {{x,y},{a,b}}
Util.standardizeSelectionBox = function(selectionBox)
	if selectionBox.left_top and selectionBox.right_bottom then
		return {
			{Util.standardizePosition(selectionBox.left_top)},
			{Util.standardizePosition(selectionBox.right_bottom)}
		}
	end
	return selectionBox
end

Util.genericLogisticChestName = function(class)
	return Util.MOD_PREFIX .. "generic_logistic_chest_class_" .. class
end

-- Returns {x,y}
Util.standardizePosition = function(position)
	if position.x and position.y then
		return {position.x, position.y}
	end
	return position
end

Util.Table = {}
Util.Table.contains = function(tbl, value)
	for _, v in pairs(tbl) do
		if v == value then return true end
	end
	return false
end

Util.String = {}
Util.String.split = function(str, sep)
	local t = {}
	for s in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(t, s)
	end
	return t
end

-- A chest class is an attempt to get a unique string for each set of logistic containers
-- Hopefully the inventory size and the selection box makes it unique enough
Util.ChestClass = {}
Util.ChestClass.calculateFromData = function(data)
	return Util.ChestClass._calculate(data.inventory_size, data.selection_box)
end

Util.ChestClass.calculateFrom___ = function(data) --TODO
	
end

Util.ChestClass._calculate = function(inventorySize, selectionBox)
	selectionBox = Util.standardizeSelectionBox(selectionBox)
	local x = tostring(math.abs(selectionBox[1][1]) + math.abs(selectionBox[2][1]))
	local y = tostring(math.abs(selectionBox[1][2]) + math.abs(selectionBox[2][2]))
	
	return tostring(inventorySize) .. "_" .. x .. "_" .. y
end

Util.ChestClass.prettyPrint = function(class)
	local parts = Util.String.split(class, "_")
	return "(" .. parts[2] .. "," .. parts[3] .. ") - " .. parts[1]
end
