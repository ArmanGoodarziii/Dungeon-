local RunService = game:GetService("RunService")

local RotatingBladeModule = {}

function RotatingBladeModule.Start(model)
	local assemblykill = model:WaitForChild("BladeAssembly"):WaitForChild("BladeAssemblykill")
	local assembly = model:WaitForChild("BladeAssembly")

	local degreesPerSecond = 35
	local speed = math.rad(degreesPerSecond)

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

	for _, item in ipairs(assemblykill:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("KillsPlayer") then
			item.Touched:Connect(killFromTouch)
		end
	end

	RunService.Heartbeat:Connect(function(dt)
		assembly:PivotTo(assembly:GetPivot() * CFrame.Angles(0, speed * dt, 0))
	end)
end

return RotatingBladeModule
