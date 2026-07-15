local FallingFloorModule = {}
local SoundService = game:GetService("SoundService")

local function playCollapseSound(parent: Instance)
	local template = SoundService:FindFirstChild("Falling Floor Collapse")
	if not template or not template:IsA("Sound") or template.SoundId == "" then return end
	local sound = template:Clone()
	sound.Name = "Falling Floor Collapse_Playback"
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

function FallingFloorModule.Start()
-- Falling Floor Trap Script - No Falling Animation
-- Each floor falls after the player touches that same floor 2 times.
-- First touch: floor turns red.
-- Second touch: floor instantly drops down, no shake/tilt/fall animation.
-- If player dies, floors that started/fell reset from Floor_1 onward.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Configuration
local TOUCHES_TO_FALL = 1.5
local VALID_TOUCH_COOLDOWN = 0.25

local RESET_TWEEN_TIME = 0.6
local DROP_DISTANCE = 18

local WARNING_COLOR = Color3.fromRGB(255, 50, 50)

-- Finds DungeonExit with or without accidental space
local dungeonExit =
	Workspace:FindFirstChild("DungeonExit")
	or Workspace:FindFirstChild("DungeonExit ")

if not dungeonExit then
	warn("DungeonExit not found!")
	return
end

local FallingFloors = dungeonExit:FindFirstChild("FallingFloors")

if not FallingFloors then
	warn("FallingFloors model not found!")
	return
end

local function findHumanoid(hit)
	local node = hit

	for _ = 1, 8 do
		if not node then
			return nil
		end

		local humanoid = node:FindFirstChildOfClass("Humanoid")

		if humanoid then
			return humanoid
		end

		node = node.Parent
	end

	return nil
end

local function getBaseParts(object)
	local parts = {}

	if object:IsA("BasePart") then
		table.insert(parts, object)
	end

	for _, item in ipairs(object:GetDescendants()) do
		if item:IsA("BasePart") then
			table.insert(parts, item)
		end
	end

	return parts
end

local function getMainFloorPart(floorObject)
	if floorObject:IsA("BasePart") then
		return floorObject
	end

	return floorObject:FindFirstChild("Floor")
end

local function getObjectPivot(object)
	if object:IsA("BasePart") then
		return object.CFrame
	end

	return object:GetPivot()
end

local function pivotObject(object, cf)
	if object:IsA("BasePart") then
		object.CFrame = cf
	else
		object:PivotTo(cf)
	end
end

local function getFloorNumber(objectName)
	local numberText = string.match(objectName, "^Floor_(%d+)$")

	if numberText then
		return tonumber(numberText)
	end

	return nil
end

-- Save original floor data once
local floors = {}

for _, child in ipairs(FallingFloors:GetChildren()) do
	if child:IsA("Model") or child:IsA("BasePart") then
		local floorNumber = getFloorNumber(child.Name)
		local mainPart = getMainFloorPart(child)

		if floorNumber and mainPart and mainPart:IsA("BasePart") then
			local parts = getBaseParts(child)

			local data = {
				object = child,
				mainPart = mainPart,
				number = floorNumber,
				parts = parts,

				originalPivot = getObjectPivot(child),
				partStates = {},

				touchCount = 0,
				lastTouchByCharacter = {},

				hasStarted = false,
				hasFallen = false,
				isResetting = false,
			}

			for _, part in ipairs(parts) do
				data.partStates[part] = {
					Color = part.Color,
					Transparency = part.Transparency,
					Anchored = part.Anchored,
					CanCollide = part.CanCollide,
					CanTouch = part.CanTouch,
				}

				part.Anchored = true
				part.CanCollide = true
				part.CanTouch = true
			end

			table.insert(floors, data)
		end
	end
end

-- Sort by floor number: Floor_1, Floor_2, Floor_3...
table.sort(floors, function(a, b)
	return a.number < b.number
end)

local resetActive = false
local deathConnections = {}

local function disconnectDeathConnections()
	for humanoid, connection in pairs(deathConnections) do
		if connection then
			connection:Disconnect()
		end

		deathConnections[humanoid] = nil
	end
end

local function resetFloor(data)
	data.touchCount = 0
	data.lastTouchByCharacter = {}

	data.hasStarted = false
	data.hasFallen = false
	data.isResetting = true

	for _, part in ipairs(data.parts) do
		local state = data.partStates[part]

		if part and part.Parent and state then
			part.Anchored = true
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero

			part.CanCollide = state.CanCollide
			part.CanTouch = state.CanTouch
			part.Color = state.Color

			part.Transparency = 0.7
		end
	end

	-- Return floor/model to original position
	pivotObject(data.object, data.originalPivot)

	-- Fade back in
	for _, part in ipairs(data.parts) do
		local state = data.partStates[part]

		if part and part.Parent and state then
			local fadeTween = TweenService:Create(
				part,
				TweenInfo.new(RESET_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = state.Transparency }
			)

			fadeTween:Play()
		end
	end

	data.isResetting = false
end

local function resetStartedFloorsFromFirst()
	if resetActive then
		return
	end

	resetActive = true
	disconnectDeathConnections()

	for _, floorData in ipairs(floors) do
		if floorData.hasStarted or floorData.hasFallen or floorData.touchCount > 0 then
			resetFloor(floorData)
			task.wait(0.05)
		end
	end

	resetActive = false
end

local function connectDeathReset(humanoid)
	if deathConnections[humanoid] then
		return
	end

	deathConnections[humanoid] = humanoid.Died:Connect(function()
		resetStartedFloorsFromFirst()
	end)
end

local function markFloorArmed(data)
	data.hasStarted = true

	for _, part in ipairs(data.parts) do
		if part and part.Parent then
			part.Color = WARNING_COLOR
		end
	end
end

local function dropFloorInstantly(data)
	if data.hasFallen or data.isResetting then
		return
	end

	data.hasStarted = true
	data.hasFallen = true

	for _, part in ipairs(data.parts) do
		if part and part.Parent then
			part.CanCollide = false
			part.CanTouch = false
			part.Color = WARNING_COLOR
		end
	end

	-- No animation: instantly move the floor down
	pivotObject(
		data.object,
		data.originalPivot * CFrame.new(0, -DROP_DISTANCE, 0)
	)
end

local function handleFloorTouched(data, otherPart)
	if resetActive then
		return
	end

	if data.hasFallen or data.isResetting then
		return
	end

	local humanoid = findHumanoid(otherPart)

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local character = humanoid.Parent

	if not character then
		return
	end

	local now = os.clock()
	local lastTouch = data.lastTouchByCharacter[character] or 0

	-- Prevent one touch from counting many times because of multiple body parts
	if now - lastTouch < VALID_TOUCH_COOLDOWN then
		return
	end

	data.lastTouchByCharacter[character] = now

	connectDeathReset(humanoid)

	data.touchCount += 1
	data.hasStarted = true

	if data.touchCount < TOUCHES_TO_FALL then
		markFloorArmed(data)
		return
	end

	dropFloorInstantly(data)
	playCollapseSound(data.mainPart)
end

-- Connect every floor independently
for _, floorData in ipairs(floors) do
	floorData.mainPart.Touched:Connect(function(otherPart)
		handleFloorTouched(floorData, otherPart)
	end)
end

print("No-animation second-touch falling floor trap loaded. Floors saved:", #floors)
end

return FallingFloorModule
