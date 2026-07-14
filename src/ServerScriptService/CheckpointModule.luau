local Players = game:GetService("Players")

local CheckpointModule = {}
local playerCheckpoints: {[Player]: {order: number, cframe: CFrame}} = {}
local configuredCheckpoints: {[Instance]: boolean} = {}
local totalCheckpoints = 0
local checkpointEvent: RemoteEvent

local function getCheckpointCFrame(checkpoint: Instance): CFrame?
	if checkpoint:IsA("Model") then
		local base = checkpoint:FindFirstChild("Base")
		if not (base and base:IsA("BasePart")) then
			base = checkpoint:FindFirstChildWhichIsA("BasePart", true)
		end
		if base and base:IsA("BasePart") then
			return base.CFrame + Vector3.new(0, 4, 0)
		end
		return checkpoint:GetPivot() + Vector3.new(0, 4, 0)
	elseif checkpoint:IsA("BasePart") then
		return checkpoint.CFrame + Vector3.new(0, 4, 0)
	end
	return nil
end

local function getTouchPart(checkpoint: Instance): BasePart?
	if checkpoint:IsA("Model") then
		local base = checkpoint:FindFirstChild("Base")
		if base and base:IsA("BasePart") then
			return base
		end
		-- Keep checkpoints compatible with models whose Base is nested or renamed.
		return checkpoint:FindFirstChildWhichIsA("BasePart", true)
	elseif checkpoint:IsA("BasePart") then
		return checkpoint
	end
	return nil
end

local function setupCheckpoint(checkpoint: Instance)
	if configuredCheckpoints[checkpoint] then
		return
	end
	local orderValue = checkpoint:FindFirstChild("Order")
	if not orderValue then
		orderValue = checkpoint:WaitForChild("Order", 2)
	end
	local touchPart = getTouchPart(checkpoint)
	if not orderValue or not orderValue:IsA("IntValue") then
		warn("[Checkpoints] Missing IntValue Order on " .. checkpoint:GetFullName())
		return
	end
	if not touchPart then
		warn("[Checkpoints] Missing Base touch part on " .. checkpoint:GetFullName())
		return
	end

	configuredCheckpoints[checkpoint] = true
	touchPart.CanTouch = true
	local order = orderValue.Value
	if order <= 0 then
		warn("[Checkpoints] Order must be greater than zero on " .. checkpoint:GetFullName())
		return
	end
	touchPart.Touched:Connect(function(hit: BasePart)
		local character = hit:FindFirstAncestorOfClass("Model")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or not humanoid or humanoid.Health <= 0 then
			return
		end

		local current = playerCheckpoints[player]
		if current and order <= current.order then
			return
		end

		local checkpointCFrame = getCheckpointCFrame(checkpoint)
		if not checkpointCFrame then
			return
		end
		playerCheckpoints[player] = {order = order, cframe = checkpointCFrame}
		checkpointEvent:FireClient(player, order, totalCheckpoints)
	end)
end

function CheckpointModule.Initialize(folder: Folder, event: RemoteEvent)
	checkpointEvent = event
	totalCheckpoints = 0
	for _, checkpoint in ipairs(folder:GetChildren()) do
		if checkpoint:FindFirstChild("Order") then
			totalCheckpoints += 1
		end
		setupCheckpoint(checkpoint)
	end

	folder.ChildAdded:Connect(function(checkpoint)
		if checkpoint:FindFirstChild("Order") then
			totalCheckpoints += 1
		end
		setupCheckpoint(checkpoint)
	end)

	local function onCharacterAdded(player: Player, character: Model)
		local saved = playerCheckpoints[player]
		if not saved then
			return
		end
		local root = character:WaitForChild("HumanoidRootPart", 5)
		if root and root:IsA("BasePart") then
			root.CFrame = saved.cframe
		end
	end

	local function onPlayerAdded(player: Player)
		playerCheckpoints[player] = nil
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		playerCheckpoints[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

return CheckpointModule
