local GuardFollowModule = {}

local activeChases: {[Model]: number} = {}
local activePatrols: {[Model]: number} = {}
local activeWalkTracks: {[Model]: AnimationTrack} = {}
local random = Random.new()
local DEFAULT_R6_WALK_ANIMATION = "rbxassetid://180426354"
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local captureAnimationId: string? = nil

local function playGuardAttackSound(parent: Instance)
	local template = SoundService:FindFirstChild("Guard Attack")
	if not template or not template:IsA("Sound") or template.SoundId == "" then return end
	local sound = template:Clone()
	sound.Name = "Guard Attack_Playback"
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

local function playCaptureAnimation(humanoid: Humanoid): AnimationTrack?
	if not captureAnimationId then
		local swordAnimations = ServerStorage:FindFirstChild("R6SwordAnimations")
		local sequence = swordAnimations and swordAnimations:FindFirstChild("Sword Swing", true)
		sequence = sequence or ServerStorage:FindFirstChild("Automatic Save", true)
		if not sequence or not sequence:IsA("KeyframeSequence") then
			warn("[GuardFollow] No capture KeyframeSequence was found in ServerStorage.")
			return nil
		end

		local success, registeredId = pcall(function()
			return KeyframeSequenceProvider:RegisterKeyframeSequence(sequence)
		end)
		if not success then
			warn("[GuardFollow] Could not register the capture KeyframeSequence.")
			return nil
		end
		captureAnimationId = registeredId
	end

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local animation = Instance.new("Animation")
	animation.AnimationId = captureAnimationId
	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not success or not track then
		animation:Destroy()
		return nil
	end

	track.Looped = false
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0.1)
	return track
end

local function startWalkAnimation(guard: Model, humanoid: Humanoid): AnimationTrack?
	if not guard:FindFirstChildWhichIsA("Motor6D", true) then
		return nil
	end

	local previousTrack = activeWalkTracks[guard]
	if previousTrack then
		previousTrack:Stop(0.1)
		activeWalkTracks[guard] = nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local animation = Instance.new("Animation")
	animation.AnimationId = guard:GetAttribute("WalkAnimationId") or DEFAULT_R6_WALK_ANIMATION
	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not success or not track then
		animation:Destroy()
		return nil
	end

	track.Looped = true
	track.Priority = Enum.AnimationPriority.Movement
	track:Play(0.15)
	activeWalkTracks[guard] = track
	return track
end

local function stopWalkAnimation(guard: Model, track: AnimationTrack?)
	if not track then
		return
	end
	track:Stop(0.15)
	track:Destroy()
	if activeWalkTracks[guard] == track then
		activeWalkTracks[guard] = nil
	end
end

local function getPlayerParts(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and root:IsA("BasePart") then
		return humanoid, root
	end
	return nil, nil
end

local function prepareGuard(guard: Model, humanoid: Humanoid, root: BasePart)
	-- The toolbox NPCs include separate animation controllers that fight the
	-- shared guard walk track.  Keep movement animation under this module only.
	for _, descendant in ipairs(guard:GetDescendants()) do
		if descendant:IsA("BaseScript") and (descendant.Name == "Animate" or descendant.Name == "NewKnightWalkAnimation") then
			descendant.Disabled = true
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {guard}
	params.IgnoreWater = true
	local configuredHipHeight = guard:GetAttribute("GuardHipHeight")
	local floor = workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -100, 0), params)
	if typeof(configuredHipHeight) == "number" then
		humanoid.HipHeight = configuredHipHeight
	elseif floor then
		humanoid.HipHeight = math.max(2, root.Position.Y - floor.Position.Y - root.Size.Y / 2)
	else
		humanoid.HipHeight = 2
	end

	for _, part in ipairs(guard:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	guard.PrimaryPart = root
	humanoid.PlatformStand = false
	humanoid:ChangeState(Enum.HumanoidStateType.Running)
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
end

function GuardFollowModule.Stop(guard: Model)
	activeChases[guard] = nil
	activePatrols[guard] = nil
	local humanoid = guard:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		humanoid:Move(Vector3.zero)
	end
end

function GuardFollowModule.Start(guard: Model, player: Player, options: {[string]: any}?)
	local humanoid = guard:FindFirstChildWhichIsA("Humanoid", true)
	local root = guard:FindFirstChild("HumanoidRootPart", true)
	if not humanoid or not root or not root:IsA("BasePart") then
		warn(("[GuardFollow] %s needs a Humanoid and HumanoidRootPart."):format(guard.Name))
		return
	end

	activePatrols[guard] = nil
	local token = (activeChases[guard] or 0) + 1
	activeChases[guard] = token
	prepareGuard(guard, humanoid, root)
	humanoid.WalkSpeed = (options and options.WalkSpeed) or guard:GetAttribute("ChaseSpeed") or 13
	local captureDistance = (options and options.CaptureDistance) or 5
	local isTargetValid = options and options.IsTargetValid
	local walkTrack = startWalkAnimation(guard, humanoid)

	task.spawn(function()
		while activeChases[guard] == token and guard.Parent and humanoid.Health > 0 do
			local targetHumanoid, targetRoot = getPlayerParts(player)
			if not targetHumanoid or not targetRoot or targetHumanoid.Health <= 0 then
				break
			end
			if type(isTargetValid) == "function" and not isTargetValid(player, targetRoot) then
				break
			end

			local flatOffset = Vector3.new(targetRoot.Position.X - root.Position.X, 0, targetRoot.Position.Z - root.Position.Z)
			if flatOffset.Magnitude <= captureDistance then
				playGuardAttackSound(root)
				local captureTrack = playCaptureAnimation(humanoid)
				task.wait(0.25)
				targetHumanoid.Health = 0
				if captureTrack then
					captureTrack:Stop(0.1)
				end
				break
			end
			humanoid:MoveTo(Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
			task.wait(0.15)
		end

		if activeChases[guard] == token then
			activeChases[guard] = nil
			humanoid:Move(Vector3.zero)
		end
	if walkTrack then
			stopWalkAnimation(guard, walkTrack)
		end
	end)
end

function GuardFollowModule.StartPatrol(guard: Model, patrolArea: BasePart, options: {[string]: any}?)
	if activeChases[guard] or activePatrols[guard] then
		return
	end

	local humanoid = guard:FindFirstChildWhichIsA("Humanoid", true)
	local root = guard:FindFirstChild("HumanoidRootPart", true)
	if not humanoid or not root or not root:IsA("BasePart") then
		warn(("[GuardFollow] %s needs a Humanoid and HumanoidRootPart."):format(guard.Name))
		return
	end

	local token = 1
	activePatrols[guard] = token
	prepareGuard(guard, humanoid, root)
	humanoid.WalkSpeed = (options and options.WalkSpeed) or guard:GetAttribute("PatrolSpeed") or 6
	local walkTrack = startWalkAnimation(guard, humanoid)

	task.spawn(function()
		while activePatrols[guard] == token and not activeChases[guard] and guard.Parent and humanoid.Health > 0 do
			-- Keep every patrol target safely inside the guard's own trigger area.
			local padding = math.min(3, patrolArea.Size.X / 4, patrolArea.Size.Z / 4)
			local x = random:NextNumber(-patrolArea.Size.X / 2 + padding, patrolArea.Size.X / 2 - padding)
			local z = random:NextNumber(-patrolArea.Size.Z / 2 + padding, patrolArea.Size.Z / 2 - padding)
			local worldPoint = patrolArea.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
			humanoid:MoveTo(Vector3.new(worldPoint.X, root.Position.Y, worldPoint.Z))

			-- Give the knight time to reach the point before selecting another one.
			local travelTime = math.clamp((Vector3.new(worldPoint.X, 0, worldPoint.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude / humanoid.WalkSpeed, 1.2, 5)
			local elapsed = 0
			while elapsed < travelTime and activePatrols[guard] == token and not activeChases[guard] do
				task.wait(0.15)
				elapsed += 0.15
			end
		end

		if activePatrols[guard] == token then
			activePatrols[guard] = nil
			humanoid:Move(Vector3.zero)
		end
		if walkTrack then
			stopWalkAnimation(guard, walkTrack)
		end
	end)
end

return GuardFollowModule
