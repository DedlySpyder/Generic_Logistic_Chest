require("scripts.generic_generation")
require("scripts.chest_groups")

for _, group in ipairs(ChestGroups.getGroups()) do
	Generic_Logistic_Generator.addGenericGroup(group)
end

Generic_Logistic_Generator.generate()
