local RunService = game:GetService("RunService")

local Corridor4PendulumAxeModule = {}

function Corridor4PendulumAxeModule.Start(model)
	local pivot = model:WaitForChild("Pivot")
	local assembly = model:WaitForChild("SwingAssembly")

	-- Adjacent axes swing in opposite directions, ordered by their X position.
	local traps = {}
	for _, sibling in ipairs(model.Parent:GetChildren()) do
		if sibling:IsA("Model") and sibling.Name == "New_Trap_03_PendulumAxe_Modular" then
			local siblingPivot = sibling:FindFirstChild("Pivot")
			if siblingPivot and siblingPivot:IsA("BasePart") then
				table.insert(traps, {
					model = sibling,
					x = siblingPivot.Position.X,
				})
			end
		end
	end
	table.sort(traps, function(a, b)
		return a.x < b.x
	end)

	local phaseOffset = 0
	for index, trap in ipairs(traps) do
		if trap.model == model then
			phaseOffset = (index % 2 == 1) and 0 or math.pi
			break
		end
	end

	local basePivot = pivot.CFrame
	local parts = {}
	local localCFrames = {}

	for _, item in ipairs(assembly:GetDescendants()) do
		if item:IsA("BasePart") then
			table.insert(parts, item)
			localCFrames[item] = basePivot:ToObjectSpace(item.CFrame)
		end
	end

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

	for _, item in ipairs(assembly:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("KillsPlayer") then
			item.Touched:Connect(killFromTouch)
		end
	end

	local startTime = os.clock()
	RunService.Heartbeat:Connect(function()
		local swingDegrees = model:GetAttribute("SwingDegrees") or 55
		local swingSpeed = model:GetAttribute("SwingSpeed") or 1.25
		local angle = math.rad(swingDegrees) * math.sin((os.clock() - startTime) * swingSpeed + phaseOffset)
		local rotation = CFrame.Angles(0, 0, angle)
		for _, part in ipairs(parts) do
			part.CFrame = basePivot * rotation * localCFrames[part]
		end
	end)
end

return Corridor4PendulumAxeModule
