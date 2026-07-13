local Players = game:GetService("Players")

-- Swinging Log Trap Controller
local trap = workspace:FindFirstChild("SwingingLogTrap")
if not trap then return end

local log = trap:FindFirstChild("Log")
local trigger = trap:FindFirstChild("TriggerPlate")
if not log or not trigger then return end

local damage = trap:GetAttribute("Damage") or 75
local swingRange = trap:GetAttribute("SwingRange") or 5
local swingSpeed = trap:GetAttribute("SwingSpeed") or 4
local resetTime = trap:GetAttribute("ResetTime") or 3
local triggerDelay = trap:GetAttribute("TriggerDelay") or 0.4
local pivotY = trap:GetAttribute("PivotY") or 10
local logLength = trap:GetAttribute("LogLength") or 5

local xPos = 625
local zPos = 620
local trapActive = false

-- Collect log spikes so they move with the log
local logSpikes = {}
for _, child in trap:GetChildren() do
	if child.Name:match("^LogSpike_") then
		logSpikes[#logSpikes + 1] = child
		logSpikes[child] = child.Position - log.Position
	end
end

local function getLogPositions(angle)
	-- angle is radians from vertical; log swings along X axis
	local x = xPos + math.sin(angle) * logLength
	local y = pivotY - math.cos(angle) * logLength
	return x, y
end

local function moveLog(angle)
	local x, y = getLogPositions(angle)
	log.CFrame = CFrame.new(x, y, zPos) * CFrame.Angles(0, 0, angle)
	
	-- Move spikes with the log
	for _, spike in ipairs(logSpikes) do
		local offset = logSpikes[spike]
		local worldOffset = CFrame.Angles(0, 0, angle) * offset
		spike.Position = Vector3.new(x + worldOffset.X, y + worldOffset.Y, zPos + worldOffset.Z)
	end
end

local function damagePlayersNearLog()
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum and hrp and hum.Health > 0 then
			local dist = (hrp.Position - log.Position).Magnitude
			if dist < 4 then
				hum:TakeDamage(damage)
				hrp.AssemblyLinearVelocity = Vector3.new(
					math.sign(hrp.Position.X - log.Position.X) * 30,
					20,
					math.sign(hrp.Position.Z - zPos) * 10
				)
			end
		end
	end
end

local function swingLog()
	if trapActive then return end
	trapActive = true
	
	task.wait(triggerDelay)
	
	-- Swing forward (positive angle = swing along +X)
	local swingAngle = math.rad(swingRange * 10) -- max swing angle
	local halfSwingDuration = math.pi / (swingSpeed * 2)
	
	-- Forward swing
	local startTime = os.clock()
	local lastDamageTime = 0
	while os.clock() - startTime < halfSwingDuration do
		local alpha = (os.clock() - startTime) / halfSwingDuration
		-- Ease-in (accelerate like a pendulum)
		local angle = swingAngle * (1 - math.cos(alpha * math.pi) * 0.5 - 0.5) * 2
		moveLog(angle)
		if os.clock() - lastDamageTime > 0.1 then
			damagePlayersNearLog()
			lastDamageTime = os.clock()
		end
		task.wait()
	end
	
	-- Backward swing (return)
	startTime = os.clock()
	while os.clock() - startTime < halfSwingDuration * 1.5 do
		local alpha = (os.clock() - startTime) / (halfSwingDuration * 1.5)
		local angle = swingAngle * (1 - alpha)
		moveLog(angle)
		if os.clock() - lastDamageTime > 0.1 then
			damagePlayersNearLog()
			lastDamageTime = os.clock()
		end
		task.wait()
	end
	
	-- Reset to neutral
	moveLog(0)
	task.wait(resetTime)
	trapActive = false
end

trigger.Touched:Connect(function(otherPart)
	local char = otherPart.Parent
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and not trapActive then
		task.spawn(swingLog)
	end
end)

print("SwingingLogTrap controller initialized")