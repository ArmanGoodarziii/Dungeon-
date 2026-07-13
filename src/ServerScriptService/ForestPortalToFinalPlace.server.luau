local Players = game:GetService("Players")

local function findChildByTrimmedName(parent: Instance, expectedName: string): Instance?
	for _, child in ipairs(parent:GetChildren()) do
		if string.gsub(child.Name, "^%s*(.-)%s*$", "%1") == expectedName then
			return child
		end
	end
	return nil
end

local forest = findChildByTrimmedName(workspace, "Forest")
local finalPlace = findChildByTrimmedName(workspace, "FinalPlace")
local teleportModel = forest and forest:FindFirstChild("Teleport")
local portal = teleportModel and teleportModel:FindFirstChild("Portal")

if not finalPlace or not finalPlace:IsA("Model") or not portal or not portal:IsA("BasePart") then
	warn("[ForestPortal] Teleport.Portal or FinalPlace was not found.")
	return
end

local debounce: {[Player]: boolean} = {}
portal.Touched:Connect(function(hit: BasePart)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player or debounce[player] then
		return
	end

	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	debounce[player] = true
	-- Use only the destination's world position.  FinalPlace has a rotated model
	-- pivot, so copying its full CFrame can rotate a character onto their head.
	local finalCFrame, finalSize = finalPlace:GetBoundingBox()
	local uprightSpawnPosition = finalCFrame.Position + Vector3.new(0, finalSize.Y / 2 + 4, 0)
	character:PivotTo(CFrame.new(uprightSpawnPosition))
	task.delay(1, function()
		debounce[player] = nil
	end)
end)
