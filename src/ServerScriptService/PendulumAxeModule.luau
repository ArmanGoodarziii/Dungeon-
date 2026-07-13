local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PendulumAxeModule = {}

function PendulumAxeModule.Start()
	local trapData = {}
	local startTime = os.clock()
	local dungeonStorages = workspace:FindFirstChild("DungeonStorages")
	local corridor4 = dungeonStorages and dungeonStorages:FindFirstChild("Corrider-4")

	local function setupTrap(trapModel, phaseOffset)
		local pivot = trapModel:FindFirstChild("Pivot")
		local assembly = trapModel:FindFirstChild("SwingAssembly")
		if not pivot or not assembly then return end

		local basePivot = pivot.CFrame
		local parts = {}
		local localCFrames = {}
		local killParts = {}

		for _, item in ipairs(assembly:GetDescendants()) do
			if item:IsA("BasePart") then
				table.insert(parts, item)
				localCFrames[item] = basePivot:ToObjectSpace(item.CFrame)
				if item:GetAttribute("KillsPlayer") or item.Name == "Bearded Axe" then
					table.insert(killParts, item)
				end
			end
		end

		table.insert(trapData, {
			model = trapModel,
			basePivot = basePivot,
			parts = parts,
			localCFrames = localCFrames,
			killParts = killParts,
			phaseOffset = phaseOffset,
		})
	end

	local trapsByParent = {}

	for _, desc in ipairs(workspace:GetDescendants()) do
		if (desc.Name == "Trap_03_PendulumAxe_Modular" or desc.Name == "New_Trap_03_PendulumAxe_Modular")
			and desc:IsA("Model")
			and (not corridor4 or not desc:IsDescendantOf(corridor4)) then
			local pivot = desc:FindFirstChild("Pivot")
			if pivot then
				local parentName = desc.Parent.Name
				if not trapsByParent[parentName] then
					trapsByParent[parentName] = {}
				end
				table.insert(trapsByParent[parentName], {
					model = desc,
					x = pivot.CFrame.Position.X,
				})
			end
		end
	end

	for _, group in pairs(trapsByParent) do
		table.sort(group, function(a, b) return a.x < b.x end)
		for i, trapInfo in ipairs(group) do
			local phaseOffset = (i % 2 == 1) and 0 or math.pi
			setupTrap(trapInfo.model, phaseOffset)
		end
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	local recentlyKilled = {}

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
					return workspace:GetPartsInPart(killPart, overlapParams)
				end)
				if not success then continue end

				for _, hit in ipairs(touching) do
					local character = findCharacter(hit)
					if character then
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 and not recentlyKilled[character] then
							recentlyKilled[character] = true
							local killSound = killPart:FindFirstChild("kill")
							if killSound and killSound:IsA("Sound") then
								killSound:Play()
							end
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
			local swingDegrees = trap.model:GetAttribute("SwingDegrees") or 55
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

	print("[PendulumAxeModule] Initialized with " .. #trapData .. " traps")
end

return PendulumAxeModule
