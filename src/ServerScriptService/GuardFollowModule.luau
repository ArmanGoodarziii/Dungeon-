local Players = game:GetService("Players")

local GuardFollowModule = {}

local activeChases: {[Model]: number} = {}

local function getCharacterParts(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and root:IsA("BasePart") then
		return humanoid, root
	end
	return nil, nil
end

local function getGuardParts(guard: Model): (Humanoid?, BasePart?)
	local humanoid = guard:FindFirstChildWhichIsA("Humanoid", true)
	local root = guard:FindFirstChild("HumanoidRootPart", true)
	if humanoid and root and root:IsA("BasePart") then
		return humanoid, root
	end
	return nil, nil
end

function GuardFollowModule.Stop(guard: Model)
	activeChases[guard] = nil
	local humanoid = guard:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		humanoid:Move(Vector3.zero)
	end
end

function GuardFollowModule.Start(guard: Model, player: Player, options: {[string]: number}?)
	local guardHumanoid, guardRoot = getGuardParts(guard)
	if not guardHumanoid or not guardRoot then
		warn(("[GuardFollow] %s needs a Humanoid and HumanoidRootPart."):format(guard:GetFullName()))
		return
	end

	local token = (activeChases[guard] or 0) + 1
	activeChases[guard] = token
	local captureDistance = (options and options.CaptureDistance) or 5
	local walkSpeed = (options and options.WalkSpeed) or guard:GetAttribute("ChaseSpeed") or 13

	for _, descendant in ipairs(guard:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		end
	end
	guardRoot.Anchored = false
	guard.PrimaryPart = guardRoot
	guardHumanoid.WalkSpeed = walkSpeed
	pcall(function()
		guardRoot:SetNetworkOwner(nil)
	end)

	task.spawn(function()
		while guard.Parent and guardHumanoid.Health > 0 and activeChases[guard] == token do
			local playerHumanoid, playerRoot = getCharacterParts(player)
			if not playerHumanoid or not playerRoot or playerHumanoid.Health <= 0 then
				break
			end

			local distance = (playerRoot.Position - guardRoot.Position).Magnitude
			if distance <= captureDistance then
				playerHumanoid.Health = 0
				break
			end

			guardHumanoid:MoveTo(playerRoot.Position)
			task.wait(0.15)
		end

		if activeChases[guard] == token then
			activeChases[guard] = nil
		end
	end)
end

return GuardFollowModule
