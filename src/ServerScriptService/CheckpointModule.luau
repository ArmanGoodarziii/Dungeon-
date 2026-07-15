local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CheckpointModule = {}
local playerCheckpoints: {[Player]: {order: number, cframe: CFrame}} = {}
local initialSpawnHandled: {[Player]: boolean} = {}
local configuredCheckpoints: {[Instance]: boolean} = {}
local totalCheckpoints = 0
local checkpointEvent: RemoteEvent
local movementLockEvent: RemoteEvent

local function playCheckpointSound(parent: Instance)
	local template = SoundService:FindFirstChild("Checkpoint Activated")
	if not template or not template:IsA("Sound") or template.SoundId == "" then return end
	local sound = template:Clone()
	sound.Name = "Checkpoint Activated_Playback"
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

local function playRespawnSound(parent: Instance)
	local template = SoundService:FindFirstChild("Respawn on Checkpoint")
	if not template or not template:IsA("Sound") or template.SoundId == "" then return end
	local sound = template:Clone()
	sound.Name = "Respawn on Checkpoint_Playback"
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

local function freezeCharacter(player: Player, character: Model, duration: number)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local oldWalkSpeed = humanoid.WalkSpeed
	local oldJumpPower = humanoid.JumpPower
	local oldJumpHeight = humanoid.JumpHeight
	local oldAutoRotate = humanoid.AutoRotate
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	if movementLockEvent then movementLockEvent:FireClient(player, duration) end
	task.delay(duration, function()
		if humanoid.Parent and humanoid.Health > 0 then
			humanoid.WalkSpeed = oldWalkSpeed
			humanoid.JumpPower = oldJumpPower
			humanoid.JumpHeight = oldJumpHeight
			humanoid.AutoRotate = oldAutoRotate
		end
	end)
end

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
		playCheckpointSound(touchPart)
		checkpointEvent:FireClient(player, order, totalCheckpoints)
	end)
end

function CheckpointModule.Initialize(folder: Folder, event: RemoteEvent)
	checkpointEvent = event
	movementLockEvent = ReplicatedStorage:FindFirstChild("MovementLockCountdown")
	if not movementLockEvent then
		movementLockEvent = Instance.new("RemoteEvent")
		movementLockEvent.Name = "MovementLockCountdown"
		movementLockEvent.Parent = ReplicatedStorage
	end
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
			if not initialSpawnHandled[player] then
				initialSpawnHandled[player] = true
				freezeCharacter(player, character, 10)
			end
			return
		end
		local root = character:WaitForChild("HumanoidRootPart", 5)
		if root and root:IsA("BasePart") then
			root.CFrame = saved.cframe
			playRespawnSound(root)
		end
		freezeCharacter(player, character, 3)
	end

	local function onPlayerAdded(player: Player)
		playerCheckpoints[player] = nil
		initialSpawnHandled[player] = false
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
		initialSpawnHandled[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

return CheckpointModule
