local RunService = game:GetService("RunService")

local ArrowTrap = {}

function ArrowTrap.Start(model)
	local triggerPlate = model:WaitForChild("TriggerPlate")
	local muzzle = model:WaitForChild("Muzzle")
	local template = model:WaitForChild("ArrowProjectile_Template")

	template.Parent = model

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

	local firing = false
	local function fireArrow()
		if firing then return end
		firing = true

		local projectile = template:Clone()
		projectile.Name = "Live_ArrowProjectile"
		projectile.Parent = workspace
		projectile:PivotTo(muzzle.CFrame)

		for _, item in ipairs(projectile:GetDescendants()) do
			if item:IsA("BasePart") then
				item.Anchored = true
				item.CanCollide = false
				item.CanTouch = true
				if item.Name == "ArrowRoot" then
					item.Transparency = 1
				else
					item.Transparency = 0
				end
				if item:GetAttribute("KillsPlayer") then
					item.Touched:Connect(killFromTouch)
				end
			end
		end

		local startCF = muzzle.CFrame
		local direction = startCF.LookVector
		local speed = model:GetAttribute("ArrowSpeed") or 58
		local range = model:GetAttribute("ArrowRange") or 24
		local duration = range / speed
		local elapsed = 0

		while elapsed < duration and projectile.Parent do
			local dt = RunService.Heartbeat:Wait()
			elapsed = elapsed + dt
			projectile:PivotTo(startCF + direction * (elapsed * speed))
		end

		if projectile.Parent then
			projectile:Destroy()
		end
		task.wait(model:GetAttribute("ReloadSeconds") or 1.1)
		firing = false
	end

	triggerPlate.Touched:Connect(function(hit)
		if findHumanoid(hit) then
			task.spawn(fireArrow)
		end
	end)
end

return ArrowTrap
