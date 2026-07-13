local GuardFollowModule = {}

local activeChases: {[Model]: number} = {}

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
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {guard}
	params.IgnoreWater = true
	local floor = workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -100, 0), params)
	if floor then
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

	local token = (activeChases[guard] or 0) + 1
	activeChases[guard] = token
	prepareGuard(guard, humanoid, root)
	humanoid.WalkSpeed = (options and options.WalkSpeed) or guard:GetAttribute("ChaseSpeed") or 13
	local captureDistance = (options and options.CaptureDistance) or 5
	local isTargetValid = options and options.IsTargetValid

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
				targetHumanoid.Health = 0
				break
			end
			humanoid:MoveTo(Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
			task.wait(0.15)
		end

		if activeChases[guard] == token then
			activeChases[guard] = nil
			humanoid:Move(Vector3.zero)
		end
	end)
end

return GuardFollowModule
