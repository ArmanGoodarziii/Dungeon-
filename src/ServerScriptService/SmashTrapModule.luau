local SmashTrapModule = {}

function SmashTrapModule.Start()
-- Sequential SmashTrap Controller
-- All traps activate in sequence automatically on a loop.
-- Walls slide toward each other along whatever axis they were generated on
-- (no forced repositioning or rotation — uses native trap orientation/axis).

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cameraShakeEvent = ReplicatedStorage:FindFirstChild("SmashCameraShake")
if not cameraShakeEvent then
	cameraShakeEvent = Instance.new("RemoteEvent")
	cameraShakeEvent.Name = "SmashCameraShake"
	cameraShakeEvent.Parent = ReplicatedStorage
end

local function playSlamEffects(trap)
	local wallPart = trap.leftWall:FindFirstChildWhichIsA("BasePart", true)
	local origin = wallPart and wallPart.Position or trap.leftWall:GetPivot().Position
	local nearby = false
	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - origin).Magnitude <= 100 then
			nearby = true
			break
		end
	end
	if not nearby then
		cameraShakeEvent:FireAllClients(origin)
		return
	end
	local template = SoundService:FindFirstChild("Smash Trap Slam")
	if template and template:IsA("Sound") and template.SoundId ~= "" then
		local sound = template:Clone()
		sound.Name = "Smash Trap Slam_Playback"
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 10
		sound.RollOffMaxDistance = 100
		sound.EmitterSize = 8
		sound.Parent = wallPart or workspace.Terrain
		sound:Play()
		sound.Ended:Connect(function() sound:Destroy() end)
	end
	cameraShakeEvent:FireAllClients(origin)
end

-- ========== CONFIGURATION ==========
local TRAP_DELAY = 1.5   -- Seconds between each trap activation
local SLAM_TIME = 0.02      -- How fast walls slam together (twice as fast)
local HOLD_TIME = 0.4        -- How long walls stay closed after slamming
local RETRACT_TIME = 1.2     -- How long walls take to retract back
local PAUSE_TIME = 1       -- Pause after full sequence before looping again
-- ====================================

-- ========== FIND AND SETUP ALL SMASHTRAPS ==========
local traps = {}

for _, child in workspace:GetChildren() do
	if child.Name == "SmashTrap" and child:IsA("ProceduralModel") then
		local generated = child:FindFirstChild("Generated")
		if generated then
			local model = generated:FindFirstChild("SmashTrap")
			if model then
				local leftWall = model:FindFirstChild("LeftWall")
				local rightWall = model:FindFirstChild("RightWall")
				if leftWall and rightWall then
					-- Ensure all wall parts are anchored (required for PivotTo movement)
					for _, wall in ipairs({leftWall, rightWall}) do
						for _, desc in wall:GetDescendants() do
							if desc:IsA("BasePart") then
								desc.Anchored = true
							end
						end
					end

					-- Use the walls exactly as generated — no repositioning, no rotation.
					local leftPivot = leftWall:GetPivot()
					local rightPivot = rightWall:GetPivot()

					-- Determine the gap axis + distance directly from the generated positions.
					-- This automatically works whether the trap was built along X, Z, or any axis.
					local gapVector = rightPivot.Position - leftPivot.Position
					local gapDist = gapVector.Magnitude

					if gapDist > 0.01 then
						local direction = gapVector.Unit -- world-space unit vector from Left toward Right
						local moveDistance = math.max(0, (gapDist / 2) - 1) -- leave small overlap

						table.insert(traps, {
							leftWall = leftWall,
							rightWall = rightWall,
							leftStart = leftPivot,
							rightStart = rightPivot,
							moveDistance = moveDistance,
							direction = direction,
						})
					else
						warn("[SmashTrapController] Skipping trap with zero gap distance:", model:GetFullName())
					end
				end
			end
		end
	end
end

for _, child in workspace:GetChildren() do
	if child.Name == "SmashTrap" and child:IsA("Model") and child:GetAttribute("SmashTrapConverted") then
		local model = child
		local leftWall = model:FindFirstChild("LeftWall")
		local rightWall = model:FindFirstChild("RightWall")
		if leftWall and rightWall then
			for _, wall in ipairs({leftWall, rightWall}) do
				for _, desc in wall:GetDescendants() do
					if desc:IsA("BasePart") then
						desc.Anchored = true
					end
				end
			end

			local leftPivot = leftWall:GetPivot()
			local rightPivot = rightWall:GetPivot()
			local gapVector = rightPivot.Position - leftPivot.Position
			local gapDist = gapVector.Magnitude

			if gapDist > 0.01 then
				local direction = gapVector.Unit
				local moveDistance = math.max(0, (gapDist / 2) - 1)

				table.insert(traps, {
					leftWall = leftWall,
					rightWall = rightWall,
					leftStart = leftPivot,
					rightStart = rightPivot,
					moveDistance = moveDistance,
					direction = direction,
				})
			else
				warn("[SmashTrapController] Skipping trap with zero gap distance:", model:GetFullName())
			end
		end
	end
end

-- Sort traps by position along their own gap axis isn't meaningful across traps with
-- different axes, so sort by distance from origin along the dominant world axis instead.
table.sort(traps, function(a, b)
	return a.leftStart.Position.Magnitude < b.leftStart.Position.Magnitude
end)

print(string.format("[SmashTrapController] Found %d SmashTraps using native generated orientation/axis. Delay: %.1fs between each.", #traps, TRAP_DELAY))

-- ========== KILL DETECTION ==========
local function getHumanoidFromPart(part)
	local current = part.Parent
	for _ = 1, 6 do
		if not current then break end
		if current:IsA("Model") then
			local humanoid = current:FindFirstChildOfClass("Humanoid")
			if humanoid then return humanoid end
		end
		current = current.Parent
	end
	return nil
end

local function killPlayer(humanoid)
	if humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

local overlapParams = OverlapParams.new()
overlapParams.MaxParts = 30

local function checkKillZone(trap)
	local leftPivot = trap.leftWall:GetPivot()
	local rightPivot = trap.rightWall:GetPivot()
	local leftPos = leftPivot.Position
	local rightPos = rightPivot.Position

	local midPos = (leftPos + rightPos) / 2
	local diff = rightPos - leftPos
	local gapLength = diff.Magnitude

	if gapLength > 0 then
		local zoneCFrame = CFrame.lookAt(midPos, rightPos)
		local zoneSize = Vector3.new(12, 20, gapLength)
		local touching = workspace:GetPartBoundsInBox(zoneCFrame, zoneSize, overlapParams)
		for _, part in touching do
			local humanoid = getHumanoidFromPart(part)
			if humanoid then
				killPlayer(humanoid)
			end
		end
	end
end

for _, trap in ipairs(traps) do
	trap.isActive = false
	for _, wall in ipairs({trap.leftWall, trap.rightWall}) do
		for _, desc in wall:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Touched:Connect(function(otherPart)
					if not trap.isActive then return end
					local humanoid = getHumanoidFromPart(otherPart)
					if humanoid then
						killPlayer(humanoid)
					end
				end)
			end
		end
	end
end

-- ========== ACTIVATE A SINGLE TRAP ==========
local function activateTrap(trap)
	trap.isActive = true

	local leftValue = Instance.new("CFrameValue")
	leftValue.Value = trap.leftStart
	local rightValue = Instance.new("CFrameValue")
	rightValue.Value = trap.rightStart

	leftValue.Changed:Connect(function(cf)
		trap.leftWall:PivotTo(cf)
		checkKillZone(trap)
	end)
	rightValue.Changed:Connect(function(cf)
		trap.rightWall:PivotTo(cf)
	end)

	-- LeftWall moves toward RightWall (+direction), RightWall moves toward LeftWall (-direction)
	local leftGoal = trap.leftStart + (trap.direction * trap.moveDistance)
	local rightGoal = trap.rightStart - (trap.direction * trap.moveDistance)

	local leftSlam = TweenService:Create(leftValue, TweenInfo.new(SLAM_TIME), {Value = leftGoal})
	local rightSlam = TweenService:Create(rightValue, TweenInfo.new(SLAM_TIME), {Value = rightGoal})
	leftSlam:Play()
	rightSlam:Play()

	leftSlam.Completed:Wait()
	playSlamEffects(trap)

	checkKillZone(trap)

	local holdStart = os.clock()
	while os.clock() - holdStart < HOLD_TIME do
		checkKillZone(trap)
		task.wait(0.1)
	end

	trap.isActive = false

	local leftRetract = TweenService:Create(
		leftValue,
		TweenInfo.new(RETRACT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Value = trap.leftStart}
	)
	local rightRetract = TweenService:Create(
		rightValue,
		TweenInfo.new(RETRACT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Value = trap.rightStart}
	)
	leftRetract:Play()
	rightRetract:Play()

	leftRetract.Completed:Wait()

	leftValue:Destroy()
	rightValue:Destroy()
end

-- ========== MAIN LOOP ==========
print("[SmashTrapController] Running! Traps activate forward, then in reverse, in a loop.")

while true do
	-- Forward pass: start to end
	for i, trap in ipairs(traps) do
		task.spawn(function()
			activateTrap(trap)
		end)

		if i < #traps then
			task.wait(TRAP_DELAY)
		end
	end

	task.wait(PAUSE_TIME)

	-- Reverse pass: end to start
	for i = #traps, 1, -1 do
		local trap = traps[i]
		task.spawn(function()
			activateTrap(trap)
		end)

		if i > 1 then
			task.wait(TRAP_DELAY)
		end
	end

	task.wait(PAUSE_TIME)
end
end

return SmashTrapModule
