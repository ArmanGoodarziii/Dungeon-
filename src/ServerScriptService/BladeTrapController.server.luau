-- BladeTrapController: Blades rotate around a central pole continuously
-- Supports multiple BladeTrap instances anywhere in the workspace

local RunService = game:GetService("RunService")

local function findHumanoid(hit)
	local node = hit
	for _ = 1, 6 do
		if not node then return nil end
		local humanoid = node:FindFirstChildOfClass("Humanoid")
		if humanoid then return humanoid end
		node = node.Parent
	end
	return nil
end

local recentlyKilled = {}
local function killFromTouch(hit)
	local humanoid = findHumanoid(hit)
	if not humanoid or humanoid.Health <= 0 then return end
	local character = humanoid.Parent
	if recentlyKilled[character] then return end
	recentlyKilled[character] = true
	humanoid.Health = 0
	task.delay(1, function()
		recentlyKilled[character] = nil
	end)
end

local traps = {}

local function setupTrap(procModel)
	if procModel.Name ~= "BladeTrap" then return end
	local generated = procModel:FindFirstChild("Generated")
	local model = generated and generated:FindFirstChild("BladeTrap")
	if not model then return end

	local blades = model:FindFirstChild("Blades")
	if not blades then return end

	local degreesPerSecond = procModel:GetAttribute("DegreesPerSecond") or 120
	local speed = math.rad(degreesPerSecond)

	for _, item in ipairs(blades:GetDescendants()) do
		if item:IsA("BasePart") then
			item.Touched:Connect(killFromTouch)
		end
	end

	table.insert(traps, {
		blades = blades,
		speed = speed,
	})
end

local function scanForTraps(parent, skipName)
	for _, child in parent:GetChildren() do
		if child.Name == skipName then continue end
		if child:IsA("Model") and child.Name == "BladeTrap" then
			setupTrap(child)
		end
		scanForTraps(child, skipName)
	end
end

scanForTraps(workspace, "Assets ")

workspace.DescendantAdded:Connect(function(descendant)
	local node = descendant
	for _ = 1, 5 do
		if not node then break end
		if node:IsA("Model") and node.Name == "BladeTrap" then
			local alreadySetup = false
			for _, t in ipairs(traps) do
				if t.blades:IsDescendantOf(node) then
					alreadySetup = true
					break
				end
			end
			if not alreadySetup then
				setupTrap(node)
			end
			break
		end
		node = node.Parent
	end
end)

RunService.Heartbeat:Connect(function(dt)
	for _, trap in ipairs(traps) do
		trap.blades:PivotTo(trap.blades:GetPivot() * CFrame.Angles(0, trap.speed * dt, 0))
	end
end)

print("[BladeTrapController] Initialized with " .. #traps .. " blade traps")