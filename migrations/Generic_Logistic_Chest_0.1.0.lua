for _, force in pairs(game.forces) do 
	force.reset_technologies()
	
	if force.technologies["logistic-system"].researched and force.recipes["generic-logistic-chest"] then
		force.recipes["generic-logistic-chest"].enabled = true
	end
end