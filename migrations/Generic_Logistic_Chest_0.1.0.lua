for _, force in pairs(game.forces) do 
	force.reset_technologies()
	
	if force.technologies["logistic-system"].researched then
		force.recipes["generic-logistic-chest"].enabled = true
	end
end