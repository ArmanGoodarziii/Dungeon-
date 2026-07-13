-- ArrowTrapController: Arrows shoot out from wall slits on a cycle, damaging players in their path
-- Supports multiple ArrowTrap instances anywhere in the workspace
--
-- CHANGED: two independent layers of alternation now exist:
--   1. Cluster-level (within a single trap): e.g. LeftCluster vs RightCluster arrows
--      alternate with each other, same as before.
--   2. Trap-level (across traps): each trap gets assigned to an alternating phase group
--      based on the order it was discovered - trap 1 and trap 2 are opposite, trap 2 and
--      trap 3 are opposite, etc. So while trap 1's arrows are out, trap 2's are retracted,
--      and vice versa. This can be overridden per-trap with a "SyncGroup" (number) attribute
--      if you want explicit control over which traps stay in sync with each other.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include

local recentlyDamaged = {}

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

-- Derives a cluster key from a part's name so parts belonging to the same physical arrow
-- assembly (e.g. "LeftCluster_Shaft_1", "LeftCluster_Tip_1") are grouped together and
-- animated with the same phase, while other clusters get an alternating phase.
local function getClusterKey(name)
	return name:match("^(.-)_Shaft_%d+$") or name:match("^(.-)_Tip_%d+$") or name
end

-- CHANGED: setupTrap now accepts the trap's discovery order (trapIndex) so it can assign
-- an alternating phase relative to other traps.
local function setupTrap(procModel, trapIndex)
	if procModel.Name ~= "ArrowTrap" then return end
	local generated = procModel:FindFirstChild("Generated")
	local model = generated and generated:FindFirstChild("ArrowTrap")
	if not model then return end

	local wall = model:FindFirstChild("Wall")
	local slits = model:FindFirstChild("Slits")
	local mechanism = model:FindFirstChild("Mechanism")
	if not wall or not slits then return end

	local cycleSpeed = procModel:GetAttribute("CycleSpeed") or 1.5
	local shootDistance = procModel:GetAttribute("ShootDistance") or 3
	local damage = procModel:GetAttribute("Damage") or 40

	local isActive = procModel:GetAttribute("Active")
	if isActive == nil then isActive = true end
	if not isActive then return end

	-- CHANGED: trap-level phase group. If a "SyncGroup" attribute is set, its parity
	-- decides the phase (so you can force specific traps to share or oppose a phase
	-- regardless of discovery order). Otherwise it falls back to the trap's discovery
	-- order, so consecutively-found traps automatically alternate.
	local syncGroup = procModel:GetAttribute("SyncGroup")
	local trapPhase
	if syncGroup ~= nil then
		trapPhase = (syncGroup % 2 == 0) and 0 or math.pi
	else
		trapPhase = (trapIndex % 2 == 0) and 0 or math.pi
	end

	local wallCF, wallSize = wall:GetBoundingBox()

	local thinAxis, thinDim, thinIdx
	if wallSize.X <= wallSize.Y and wallSize.X <= wallSize.Z then
		thinAxis = wallCF.XVector
		thinDim = wallSize.X
		thinIdx = 1
	elseif wallSize.Y <= wallSize.X and wallSize.Y <= wallSize.Z then
		thinAxis = wallCF.YVector
		thinDim = wallSize.Y
		thinIdx = 2
	else
		thinAxis = wallCF.ZVector
		thinDim = wallSize.Z
		thinIdx = 3
	end

	local firstSlit = slits:GetChildren()[1]
	if not firstSlit then return end

	local testShaft = firstSlit:FindFirstChild("LeftCluster_Shaft_1")
	local testTip = firstSlit:FindFirstChild("LeftCluster_Tip_1")
	local shootDir = thinAxis
	if testShaft and testTip then
		local tipDir = (testTip.Position - testShaft.Position).Unit
		if tipDir:Dot(thinAxis) < 0 then
			shootDir = -thinAxis
		end
	end

	local shootSign = 1
	if shootDir:Dot(thinAxis) < 0 then shootSign = -1 end

	-- arrowParts = every shaft/tip part, used purely for animating the CFrame each frame.
	-- killParts  = only the "Tip" parts, used for actual damage detection so that
	-- only real contact with the arrowhead can hurt the player (not just proximity to the wall).
	-- Each part stores its own CFrame plus its cluster-level phase.
	local arrowParts = {}
	local killParts = {}

	local clusterOrder = {}
	local clusterIndexOf = {}
	local function getClusterIndex(name)
		local cluster = getClusterKey(name)
		if not clusterIndexOf[cluster] then
			table.insert(clusterOrder, cluster)
			clusterIndexOf[cluster] = #clusterOrder - 1 -- zero-based
		end
		return clusterIndexOf[cluster]
	end

	for _, slit in ipairs(slits:GetChildren()) do
		if slit:IsA("Model") then
			for _, item in ipairs(slit:GetDescendants()) do
				if item:IsA("BasePart") and (string.find(item.Name, "Shaft") or string.find(item.Name, "Tip")) then
					-- Alternate clusters within this trap get a phase offset of pi, so while
					-- one cluster's cycle value is near 1 (fully out) the other's is near 0.
					local clusterIndex = getClusterIndex(item.Name)
					local clusterPhase = (clusterIndex % 2 == 0) and 0 or math.pi

					arrowParts[item] = { cframe = item.CFrame, phase = clusterPhase }
					if string.find(item.Name, "Tip") then
						table.insert(killParts, item)
					end
				end
			end
		end
	end

	local gearLeft = mechanism and mechanism:FindFirstChild("GearLeft")
	local gearRight = mechanism and mechanism:FindFirstChild("GearRight")
	local pressurePlate = mechanism and mechanism:FindFirstChild("PressurePlate")

	local gearLeftCF = gearLeft and gearLeft.CFrame
	local gearRightCF = gearRight and gearRight.CFrame
	local plateCF = pressurePlate and pressurePlate.CFrame

	return {
		arrowParts = arrowParts,
		killParts = killParts,
		gearLeft = gearLeft,
		gearRight = gearRight,
		gearLeftCF = gearLeftCF,
		gearRightCF = gearRightCF,
		pressurePlate = pressurePlate,
		plateCF = plateCF,
		shootDir = shootDir,
		cycleSpeed = cycleSpeed,
		shootDistance = shootDistance,
		damage = damage,
		trapPhase = trapPhase, -- CHANGED: this trap's phase relative to other traps
		startTime = os.clock(),
	}
end

local traps = {}

local function scanForTraps(parent, skipName)
	for _, child in parent:GetChildren() do
		if child.Name == skipName then continue end
		if child:IsA("Model") and child.Name == "ArrowTrap" then
			-- CHANGED: pass the current trap count as this trap's discovery index
			local trap = setupTrap(child, #traps)
			if trap then
				table.insert(traps, trap)
			end
		end
		scanForTraps(child, skipName)
	end
end

scanForTraps(workspace, "Assets ")

workspace.DescendantAdded:Connect(function(descendant)
	local node = descendant
	for _ = 1, 5 do
		if not node then break end
		if node:IsA("Model") and node.Name == "ArrowTrap" then
			local alreadySetup = false
			for _, t in ipairs(traps) do
				for part in pairs(t.arrowParts) do
					if part:IsDescendantOf(node) then
						alreadySetup = true
						break
					end
				end
				if alreadySetup then break end
			end
			if not alreadySetup then
				-- CHANGED: pass the current trap count as this trap's discovery index
				local trap = setupTrap(node, #traps)
				if trap then
					table.insert(traps, trap)
				end
			end
			break
		end
		node = node.Parent
	end
end)

RunService.Heartbeat:Connect(function()
	local characters = {} -- gathered once per frame, reused across traps
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(characters, player.Character)
		end
	end
	if #characters > 0 then
		overlapParams.FilterDescendantsInstances = characters
	end

	for _, trap in ipairs(traps) do
		local t = os.clock() - trap.startTime

		-- CHANGED: each part's alpha now combines its cluster phase AND its trap's phase,
		-- so clusters alternate within a trap, and whole traps alternate with each other.
		for part, data in pairs(trap.arrowParts) do
			local partAlpha = (math.sin(t * trap.cycleSpeed + data.phase + trap.trapPhase) + 1) * 0.5
			local extension = trap.shootDistance * partAlpha
			part.CFrame = data.cframe + (trap.shootDir * extension)
		end

		-- Gear/plate cosmetic animation follows this trap's own phase group.
		local masterAlpha = (math.sin(t * trap.cycleSpeed + trap.trapPhase) + 1) * 0.5

		if trap.gearLeft and trap.gearLeftCF then
			local gearAngle = t * trap.cycleSpeed * 3
			trap.gearLeft.CFrame = trap.gearLeftCF * CFrame.Angles(0, 0, gearAngle)
		end
		if trap.gearRight and trap.gearRightCF then
			local gearAngle = t * trap.cycleSpeed * 3
			trap.gearRight.CFrame = trap.gearRightCF * CFrame.Angles(0, 0, -gearAngle)
		end

		if trap.pressurePlate and trap.plateCF then
			local plateOffset = -0.3 * masterAlpha
			trap.pressurePlate.CFrame = trap.plateCF + Vector3.new(0, plateOffset, 0)
		end

		-- Damage detection checks real overlap against the moving tip parts (trap.killParts),
		-- so it stays accurate for each cluster/trap regardless of its current phase.
		if #characters > 0 then
			for _, tip in ipairs(trap.killParts) do
				local success, touching = pcall(function()
					return workspace:GetPartsInPart(tip, overlapParams)
				end)
				if success then
					for _, hit in ipairs(touching) do
						local character = findCharacter(hit)
						if character then
							local humanoid = character:FindFirstChildOfClass("Humanoid")
							if humanoid and humanoid.Health > 0 and not recentlyDamaged[character] then
								recentlyDamaged[character] = true
								humanoid:TakeDamage(trap.damage)
								task.delay(1, function()
									recentlyDamaged[character] = nil
								end)
							end
						end
					end
				end
			end
		end
	end
end)

print("[ArrowTrapController] Initialized with " .. #traps .. " arrow traps")