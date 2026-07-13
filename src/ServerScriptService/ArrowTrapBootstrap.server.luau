local ArrowTrap = require(game:GetService("ServerScriptService"):WaitForChild("ArrowTrapModule"))

local corridor = workspace
	:WaitForChild("DungeonEntrance_Zone-2")
	:WaitForChild("Corrider-1")

for _, child in ipairs(corridor:GetChildren()) do
	if child:IsA("Model") and child.Name == "Trap_05_ArrowTrap_WithTriggerPlate_Modular" then
		ArrowTrap.Start(child)
	end
end
