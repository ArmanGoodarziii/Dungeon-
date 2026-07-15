--!strict
-- SphereTrapModule
-- A reusable module for creating sphere trap mechanics.
-- Each trap expects a folder/model with a "Sphere" part (Ball shape) and a "Trigger" part.
-- Configuration can be set via attributes on the trap folder:
--   Speed      (number)  - Roll speed in studs/sec (default: 10)
--   ResetTime  (number)  - Seconds before the trap resets (default: 5)
--   KillDamage (number) - Damage dealt on contact, 0 = instant kill (default: 0)

local SphereTrapModule = {}
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
SphereTrapModule.__index = SphereTrapModule

local cameraShakeEvent = ReplicatedStorage:FindFirstChild("SmashCameraShake")
if not cameraShakeEvent then
	cameraShakeEvent = Instance.new("RemoteEvent")
	cameraShakeEvent.Name = "SmashCameraShake"
	cameraShakeEvent.Parent = ReplicatedStorage
end

-- Default configuration values
local DEFAULT_SPEED = 20
local DEFAULT_RESET_TIME = 5
local DEFAULT_KILL_DAMAGE = 0

-- Creates a new SphereTrap controller from a trap folder.
-- @param trapFolder Instance - A folder containing a "Sphere" part and a "Trigger" part
-- @return SphereTrap - The trap controller object
function SphereTrapModule.new(trapFolder: Instance)
	local self = setmetatable({}, SphereTrapModule)

	self.trapFolder = trapFolder
	self.sphere = trapFolder:FindFirstChild("Sphere") :: BasePart?
	self.trigger = trapFolder:FindFirstChild("Trigger") :: BasePart?

	-- Read configuration from attributes or use defaults
	self.speed = trapFolder:GetAttribute("Speed") or DEFAULT_SPEED
	self.resetTime = trapFolder:GetAttribute("ResetTime") or DEFAULT_RESET_TIME
	self.killDamage = trapFolder:GetAttribute("KillDamage") or DEFAULT_KILL_DAMAGE

	self.isActive = false
	self.connections = {}

	if not self.sphere or not self.trigger then
		warn("[SphereTrapModule] Missing 'Sphere' or 'Trigger' part in: " .. trapFolder:GetFullName())
		return self
	end

	-- Store the original CFrame so we can reset the sphere to its starting position
	self.originalCFrame = self.sphere.CFrame

	-- Ensure the sphere starts in its idle (hidden) state
	self:_setIdleState()

	-- Connect events
	self:_connectEvents()

	return self
end

-- Sets the sphere to its idle (hidden, anchored, non-collidable) state
function SphereTrapModule:_setIdleState()
	if not self.sphere then return end
	self.sphere.Transparency = 1
	self.sphere.CanCollide = false
	self.sphere.Anchored = true
	self.sphere.AssemblyLinearVelocity = Vector3.zero
	self.sphere.CFrame = self.originalCFrame
end

-- Sets the sphere to its active (visible, unanchored, collidable) state
function SphereTrapModule:_setActiveState()
	if not self.sphere then return end
	self.sphere.Transparency = 0
	self.sphere.CanCollide = true
	self.sphere.Anchored = false
end

-- Connects the trigger touch and sphere kill events
function SphereTrapModule:_connectEvents()
	-- Use a proximity loop to detect players standing on the trigger.
	-- This is more reliable than Touched for re-triggering after a reset,
	-- because Touched only fires on new physical contact.
	if self.trigger and self.sphere then
		task.spawn(function()
			while self.sphere and self.sphere.Parent do
				task.wait(0.3)
				if not self.isActive and not self.onCooldown then
					local triggerSize = self.trigger.Size
					local triggerCFrame = self.trigger.CFrame

					for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
						local character = player.Character
						if character then
							local humanoid = character:FindFirstChildOfClass("Humanoid")
							local hrp = character:FindFirstChild("HumanoidRootPart")
							if humanoid and humanoid.Health > 0 and hrp then
								-- Check if the player is within the trigger's bounding box (with small margin)
								local offset = triggerCFrame:ToObjectSpace(hrp.CFrame).Position
								local margin = 1
								if math.abs(offset.X) <= triggerSize.X/2 + margin
									and math.abs(offset.Y) <= triggerSize.Y/2 + 2
									and math.abs(offset.Z) <= triggerSize.Z/2 + margin then
									self:Activate()
									break
								end
							end
						end
					end
				end
			end
		end)
	end

	if self.sphere then
		table.insert(self.connections, self.sphere.Touched:Connect(function(hit)
			local character = hit.Parent
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				if self.killDamage > 0 then
					humanoid:TakeDamage(self.killDamage)
				else
					humanoid.Health = 0
				end
			end
		end))
	end
end

-- Activates the trap: reveals the sphere, unanchors it, and sends it rolling.
function SphereTrapModule:Activate()
	if self.isActive or self.onCooldown or not self.sphere then return end
	self.isActive = true
	local template = SoundService:FindFirstChild("Sphere Trap Roll")
	if template and template:IsA("Sound") and template.SoundId ~= "" then
		local sound = template:Clone()
		sound.Name = "Sphere Trap Roll_Playback"
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 8
		sound.RollOffMaxDistance = 90
		sound.EmitterSize = 6
		sound.Parent = self.sphere
		sound:Play()
		sound.Ended:Connect(function() sound:Destroy() end)
	end
	cameraShakeEvent:FireAllClients(self.sphere.Position)

	self:_setActiveState()

	-- Launch the sphere forward along its LookVector
	local direction = self.sphere.CFrame.LookVector
	self.sphere.AssemblyLinearVelocity = direction * self.speed

	-- Schedule reset after the configured delay
	task.delay(self.resetTime, function()
		self:Reset()
	end)
end

-- Resets the trap back to its idle state, ready to be triggered again.
-- After reset, a brief cooldown prevents instant re-triggering.
function SphereTrapModule:Reset()
	if not self.sphere then return end
	self:_setIdleState()
	self.isActive = false

	-- Brief cooldown so the trap doesn't instantly re-fire when the player is still on the pad
	self.onCooldown = true
	task.delay(1, function()
		self.onCooldown = false
	end)
end

-- Returns whether the trap is currently active.
function SphereTrapModule:IsActive(): boolean
	return self.isActive
end

-- Disconnects all events and cleans up. Call this if the trap is destroyed at runtime.
function SphereTrapModule:Destroy()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	self.connections = {}
	self:Reset()
end

-- Scans the workspace for all folders/models named "SphereTrap" and creates controllers for each.
-- @return table - Array of SphereTrap controller objects
function SphereTrapModule.createAllFromWorkspace(): {SphereTrap}
	local traps = {}
	for _, descendant in ipairs(game.Workspace:GetDescendants()) do
		if descendant.Name == "SphereTrap" and descendant:FindFirstChild("Sphere") and descendant:FindFirstChild("Trigger") then
			table.insert(traps, SphereTrapModule.new(descendant))
		end
	end
	return traps
end

return SphereTrapModule
