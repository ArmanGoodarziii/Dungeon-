local RotatingBladeModule = require(game:GetService("ServerScriptService"):WaitForChild("RotatingBladeModule"))

local cell = workspace
	:WaitForChild("Cells_Zone-3")
	:WaitForChild("Cell_2")

for _, child in ipairs(cell:GetChildren()) do
	if child:IsA("Model") and child.Name == "Trap_02_GroundSpinningBlades_Modular" then
		RotatingBladeModule.Start(child)
	end
end
