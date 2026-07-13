local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local showFinalPlaceSuccess = ReplicatedStorage:WaitForChild("ShowFinalPlaceSuccess")
local danceAnimation = ServerStorage:WaitForChild("FinalPlaceDanceAnimation")

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

local function playFinalPlaceDance(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not danceAnimation:IsA("Animation") then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid

	local track = animator:LoadAnimation(danceAnimation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	track:Play(0.15)

	task.delay(20, function()
		if track.IsPlaying then
			track:Stop(0.2)
		end
		track:Destroy()
	end)
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
	showFinalPlaceSuccess:FireClient(player)
	playFinalPlaceDance(character)
	-- A character has several touching parts; keep this active while the success
	-- notification is on screen so one portal use cannot show it repeatedly.
	task.delay(6, function()
		debounce[player] = nil
	end)
end)
