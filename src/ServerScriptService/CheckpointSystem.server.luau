local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent to notify clients when they reach a new checkpoint
local checkpointEvent = ReplicatedStorage:FindFirstChild("CheckpointEvent")
if not checkpointEvent then
	checkpointEvent = Instance.new("RemoteEvent")
	checkpointEvent.Name = "CheckpointEvent"
	checkpointEvent.Parent = ReplicatedStorage
end

local checkpointsFolder = workspace:WaitForChild("Checkpoints")

-- Store each player's current checkpoint: [player] = {order = number, position = Vector3}
local playerCheckpoints = {}

-- Total checkpoint count (used to show "X / Total" in the UI)
local totalCheckpoints = 0
for _, cp in checkpointsFolder:GetChildren() do
	if cp:FindFirstChild("Order") then
		totalCheckpoints += 1
	end
end

-- Get the checkpoint position (works for both Model and Part checkpoints)
local function GetCheckpointCFrame(cp)
	if cp:IsA("Model") then
		local base = cp:FindFirstChild("Base")
		if base then
			return base.CFrame + Vector3.new(0,4,0)
		end

		return cp:GetPivot() + Vector3.new(0,4,0)

	elseif cp:IsA("BasePart") then
		return cp.CFrame + Vector3.new(0,4,0)
	end

	return nil
end

-- Set up touch detection for a single checkpoint
local function setupCheckpoint(checkpoint)
	local orderVal = checkpoint:FindFirstChild("Order")
	if not orderVal then
		warn("[Checkpoints] Missing 'Order' value on:", checkpoint:GetFullName())
		return
	end
	local order = orderVal.Value

	local touchPart
	if checkpoint:IsA("Model") then
		touchPart = checkpoint:FindFirstChild("Base")
		if not touchPart or not touchPart:IsA("BasePart") then
			warn("[Checkpoints] Missing 'Base' part on:", checkpoint:GetFullName())
			return
		end
	elseif checkpoint:IsA("BasePart") then
		touchPart = checkpoint
	else
		return
	end

	touchPart.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local currentData = playerCheckpoints[player]
		local currentOrder = currentData and currentData.order or 0

		if order > currentOrder then
			playerCheckpoints[player] = {
				order = order,
				cframe = GetCheckpointCFrame(checkpoint),
			}

			-- Notify the client to show the checkpoint UI
			checkpointEvent:FireClient(player, order, totalCheckpoints)
		end
	end)
end

for _, cp in checkpointsFolder:GetChildren() do
	setupCheckpoint(cp)
end

checkpointsFolder.ChildAdded:Connect(function(cp)
	if cp:FindFirstChild("Order") then
		totalCheckpoints += 1
	end
	setupCheckpoint(cp)
end)

-- When a player's character spawns, teleport them to their saved checkpoint (if any)
local function onCharacterAdded(player, character)
	local data = playerCheckpoints[player]
	if data and data.cframe then
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if hrp then
			hrp.CFrame = data.cframe
		end
	end
end

local function onPlayerAdded(player)
	playerCheckpoints[player] = nil

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end

	player.AncestryChanged:Connect(function()
		if not player:IsDescendantOf(game) then
			playerCheckpoints[player] = nil
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end