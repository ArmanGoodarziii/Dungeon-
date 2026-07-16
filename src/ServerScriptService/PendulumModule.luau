-- PendulumModule: shared pendulum animation and instant-kill behavior.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local PendulumModule = {}

local function playImpactSound(parent: Instance)
	local template = SoundService:FindFirstChild("Pendulum Obstacle Impact")
	if not template or not template:IsA("Sound") or template.SoundId == "" then return end
	local sound = template:Clone()
	sound.Name = "Pendulum Obstacle Impact_Playback"
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

local function findCharacter(part)
	local node = part
	for _ = 1, 6 do
		if not node then return nil end
		if node:FindFirstChildOfClass("Humanoid") then
			return node
		end
		node = node.Parent
	end
	return nil
end

function PendulumModule.Start(container)
	local trapData = {}
	local startTime = os.clock()

	local function setupTrap(model, phaseOffset)
		if model.Name ~= "PendulumObstacle" or not model:GetAttribute("PendulumConverted") then return end

		local ceilingMount = model:FindFirstChild("CeilingMount")
		local chain = model:FindFirstChild("Chain")
		local head = model:FindFirstChild("Head")
		if not ceilingMount or not chain or not head then return end

		local isActive = model:GetAttribute("Active")
		if isActive == nil then isActive = true end
		if not isActive then return end

		local mountRing = ceilingMount:FindFirstChild("MountRing")
		local basePivot
		if mountRing and mountRing:IsA("BasePart") then
			basePivot = mountRing.CFrame
		else
			basePivot = ceilingMount:GetPivot()
		end

		local parts = {}
		local localCFrames = {}
		local killParts = {}

		for _, item in ipairs(chain:GetDescendants()) do
			if item:IsA("BasePart") then
				table.insert(parts, item)
				localCFrames[item] = basePivot:ToObjectSpace(item.CFrame)
			end
		end

		for _, item in ipairs(head:GetDescendants()) do
			if item:IsA("BasePart") then
				table.insert(parts, item)
				localCFrames[item] = basePivot:ToObjectSpace(item.CFrame)
				table.insert(killParts, item)
			end
		end

		table.insert(trapData, {
			model = model,
			basePivot = basePivot,
			parts = parts,
			localCFrames = localCFrames,
			killParts = killParts,
			phaseOffset = phaseOffset,
		})
	end

	local function scanForTraps(parent)
		for _, child in parent:GetChildren() do
			if child:IsA("Model") and child.Name == "PendulumObstacle" and child:GetAttribute("PendulumConverted") then
				local ceilingMount = child:FindFirstChild("CeilingMount")
				if ceilingMount then
					local mountRing = ceilingMount:FindFirstChild("MountRing")
					local pivotPos = mountRing and mountRing.Position or ceilingMount:GetPivot().Position
					table.insert(trapData, {
						pendingModel = child,
						x = pivotPos.X,
					})
				end
			end
		end
	end

	scanForTraps(container)

	local pendingTraps = trapData
	trapData = {}
	table.sort(pendingTraps, function(a, b) return a.x < b.x end)
	for i, trapInfo in ipairs(pendingTraps) do
		local phaseOffset = (i % 2 == 1) and 0 or math.pi
		setupTrap(trapInfo.pendingModel, phaseOffset)
	end

	container.ChildAdded:Connect(function(child)
		if child:IsA("Model") and child.Name == "PendulumObstacle" and child:GetAttribute("PendulumConverted") then
			setupTrap(child, 0)
		end
	end)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	local recentlyKilled = {}

	local function checkKills()
		local characters = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				table.insert(characters, player.Character)
			end
		end

		if #characters == 0 then return end

		overlapParams.FilterDescendantsInstances = characters

		for _, trap in ipairs(trapData) do
			for _, killPart in ipairs(trap.killParts) do
				local success, touching = pcall(function()
					-- Use a slightly inset query volume so the visual head can swing
					-- near a player without counting its decorative outer edges as a hit.
					return workspace:GetPartBoundsInBox(killPart.CFrame, killPart.Size * 0.82, overlapParams)
				end)
				if not success then continue end

				for _, hit in ipairs(touching) do
					local character = findCharacter(hit)
					if character then
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 and not recentlyKilled[character] then
							recentlyKilled[character] = true
							playImpactSound(killPart)
							humanoid.Health = 0
							task.delay(1, function()
								recentlyKilled[character] = nil
							end)
						end
					end
				end
			end
		end
	end

	RunService.Heartbeat:Connect(function()
		local currentTime = os.clock() - startTime
		for _, trap in ipairs(trapData) do
			local swingDegrees = trap.model:GetAttribute("SwingAngle") or 45
			local swingSpeed = trap.model:GetAttribute("SwingSpeed") or 1.25
			local angle = math.rad(swingDegrees) * math.sin(currentTime * swingSpeed + trap.phaseOffset)
			local rotation = CFrame.Angles(0, 0, angle)
			for _, part in ipairs(trap.parts) do
				part.CFrame = trap.basePivot * rotation * trap.localCFrames[part]
			end
		end
	end)

	task.spawn(function()
		while task.wait(0.1) do
			checkKills()
		end
	end)

	print("[PendulumModule] Initialized with " .. #trapData .. " pendulum traps")
end

return PendulumModule
