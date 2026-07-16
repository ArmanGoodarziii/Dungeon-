-- Applies the wood finish to every falling-floor piece while preserving
-- the trap's existing collapse scripts, physics, and collision settings.

local function findTrimmed(parent: Instance, wanted: string): Instance?
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name:match("^%s*(.-)%s*$") == wanted then
			return child
		end
	end
	return nil
end

local dungeonExit = findTrimmed(workspace, "DungeonExit")
local fallingFloors = dungeonExit and findTrimmed(dungeonExit, "FallingFloors")

if not fallingFloors then
	warn("[FallingFloorsTheme] FallingFloors model was not found")
	return
end

local woodColor = Color3.fromRGB(92, 61, 38)
local count = 0
for _, descendant in ipairs(fallingFloors:GetDescendants()) do
	if descendant:IsA("BasePart") then
		descendant.Material = Enum.Material.WoodPlanks
		descendant.Color = woodColor
		count += 1
	end
end

print(string.format("[FallingFloorsTheme] Applied wood finish to %d floor parts", count))
