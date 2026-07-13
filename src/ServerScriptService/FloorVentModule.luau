local FloorVentModule = {}

function FloorVentModule.Start()
	local function findHumanoid(part)
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

	local function setupVentTrap(ventModel)
		local grateCollision = ventModel:FindFirstChild("InvisibleGrateCollision")
		if not grateCollision or not grateCollision:IsA("BasePart") then return end

		grateCollision.CanTouch = true

		local triggered = false

		grateCollision.Touched:Connect(function(hit)
			if triggered then return end
			local humanoid = findHumanoid(hit)
			if not humanoid then return end

			triggered = true
			grateCollision.CanCollide = false

			for _, descendant in ventModel:GetDescendants() do
				if descendant:IsA("BasePart") then
					local name = descendant.Name
					if string.find(name, "GrateBar") then
						descendant.CanCollide = false
						descendant.Anchored = false
					elseif string.find(name, "MetalRim") then
						descendant.Anchored = false
					end
				end
			end

			task.delay(5, function()
				for _, descendant in ventModel:GetDescendants() do
					if descendant:IsA("BasePart") then
						local name = descendant.Name
						if string.find(name, "GrateBar") or string.find(name, "MetalRim") then
							descendant.Parent = nil
						end
					end
				end
				grateCollision.Parent = nil
			end)
		end)
	end

	local function scanForVents(parent)
		for _, child in parent:GetChildren() do
			if child:IsA("Model") then
				local assetType = child:GetAttribute("AssetType")
				if assetType == "RealFloorVent" or string.find(child.Name, "FloorVent") then
					setupVentTrap(child)
				end
			end
			scanForVents(child)
		end
	end

	scanForVents(workspace)

	local function findHumanoid(part)
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

	local function setupVentTrap(ventModel)
		local grateCollision = ventModel:FindFirstChild("InvisibleGrateCollision")
		if not grateCollision or not grateCollision:IsA("BasePart") then return end

		local triggered = false

		grateCollision.Touched:Connect(function(hit)
			if triggered then return end
			local humanoid = findHumanoid(hit)
			if not humanoid then return end

			triggered = true
			grateCollision.CanCollide = false

			for _, descendant in ventModel:GetDescendants() do
				if descendant:IsA("BasePart") then
					local name = descendant.Name
					if string.find(name, "GrateBar") or string.find(name, "MetalRim") then
						descendant.Anchored = false
					end
				end
			end

			task.delay(5, function()
				for _, descendant in ventModel:GetDescendants() do
					if descendant:IsA("BasePart") then
						local name = descendant.Name
						if string.find(name, "GrateBar") or string.find(name, "MetalRim") then
							descendant.Parent = nil
						end
					end
				end
				grateCollision.Parent = nil
			end)
		end)
	end

	local function scanForVents(parent)
		for _, child in parent:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("AssetType") == "RealFloorVent" then
				setupVentTrap(child)
			end
			if child:IsA("Model") and string.find(child.Name, "FloorVent") then
				setupVentTrap(child)
			end
			scanForVents(child)
		end
	end

	scanForVents(workspace)
end

return FloorVentModule
