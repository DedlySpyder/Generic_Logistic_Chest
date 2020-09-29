require("scripts.generic_generation")
require("scripts.chest_groups")

for _, group in ipairs(ChestGroups.getGroups()) do
	Generic_Logistic_Generator.addGenericGroup(group)
end

Generic_Logistic_Generator.generate()


--[[ TODO ------ delete me
Ok, so because it's going to be too unpredicatable to dynamically support any other mod, let's just make it trivial to do

make a function that just takes the following:
	- entity name to generate the generic chest off of
	- list of entity names to create replacement chests (will need to also include the generic chest's root entity)

These will all be cached, then run at once, so it can cache all necessary elements on fewer interations of data.raw
]]--