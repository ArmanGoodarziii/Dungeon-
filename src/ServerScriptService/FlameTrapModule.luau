local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local FlameTrapModule = {}

local function playIgniteSound(parent: Instance)
	local template = SoundService:FindFirstChild("Flame Trap Ignite")
	if not template or not template:IsA("Sound") or template.SoundId == "" then return end
	local sound = template:Clone()
	sound.Name = "Flame Trap Ignite_Playback"
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = 80
	sound.EmitterSize = 6
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

function FlameTrapModule.Start()
	local FLAME_ON_TIME = 2
	local SEQUENCE_INTERVAL = 1
	local FLAME_SIZE = 30
	local CYCLE_PAUSE = 3
	local TRAP_HALF = 7
	local TRAP_HEIGHT = 12

	local trapModels = {}
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name == "FlameTrap" and child:IsA("Model") and child:GetAttribute("FlameTrapConverted") then
			table.insert(trapModels, child)
		end
	end

	if #trapModels == 0 then
		warn("[FlameTrapModule] No FlameTrap models found in workspace.")
		return
	end

	table.sort(trapModels, function(a, b)
		local posA = a:GetPivot().Position
		local posB = b:GetPivot().Position
		if math.abs(posA.X - posB.X) > 1 then
			return posA.X < posB.X
		end
		return posA.Z < posB.Z
	end)

	local traps = {}

	for _, trapModel in ipairs(trapModels) do
		local basePit = trapModel:FindFirstChild("BasePit")

		local centerX, centerY, centerZ
		if basePit then
			centerX = basePit.Position.X
			centerY = basePit.Position.Y
			centerZ = basePit.Position.Z
		else
			local pos = trapModel:GetPivot().Position
			centerX, centerY, centerZ = pos.X, pos.Y, pos.Z
		end

		local emitter = Instance.new("Part")
		emitter.Name = "FlameEmitter"
		emitter.Size = Vector3.new(8, 0.1, 8)
		emitter.Position = Vector3.new(centerX, centerY, centerZ)
		emitter.Anchored = true
		emitter.CanCollide = false
		emitter.CanTouch = false
		emitter.CanQuery = false
		emitter.Transparency = 1
		emitter.Parent = trapModel

		local fire = Instance.new("Fire")
		fire.Size = FLAME_SIZE
		fire.Heat = 15
		fire.Color = Color3.fromRGB(255, 120, 0)
		fire.SecondaryColor = Color3.fromRGB(255, 40, 0)
		fire.Enabled = false
		fire.Parent = emitter

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 100, 0)
		light.Brightness = 6
		light.Range = 25
		light.Enabled = false
		light.Parent = emitter

		local function isPlayerOnTrap(character)
			if not character or not character.Parent then return false end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then return false end
			local pos = hrp.Position
			return math.abs(pos.X - centerX) < TRAP_HALF + 1
				and math.abs(pos.Z - centerZ) < TRAP_HALF + 1
				and math.abs(pos.Y - centerY) < TRAP_HEIGHT
		end

		local function killCharacter(character)
			if not character or not character.Parent then return end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end

		local flamesActive = false
		local function setFlamesActive(active)
			flamesActive = active
			fire.Enabled = active
			light.Enabled = active
			if active then
				playIgniteSound(emitter)
				for _, player in ipairs(Players:GetPlayers()) do
					if isPlayerOnTrap(player.Character) then
						killCharacter(player.Character)
					end
				end
			end
		end

		local function killPlayersOnTrap()
			if not flamesActive then return end
			for _, player in ipairs(Players:GetPlayers()) do
				if isPlayerOnTrap(player.Character) then
					killCharacter(player.Character)
				end
			end
		end

		table.insert(traps, {
			setFlamesActive = setFlamesActive,
			killPlayersOnTrap = killPlayersOnTrap,
		})
	end

	print("[FlameTrapModule] Found " .. #traps .. " flame traps. Starting sequence.")

	for _, trap in ipairs(traps) do
		trap.setFlamesActive(false)
	end

	task.spawn(function()
		while true do
			for i, trap in ipairs(traps) do
				trap.setFlamesActive(true)

				local elapsed = 0
				while elapsed < FLAME_ON_TIME do
					trap.killPlayersOnTrap()
					task.wait(0.1)
					elapsed += 0.1
				end

				trap.setFlamesActive(false)

				if i < #traps then
					task.wait(SEQUENCE_INTERVAL)
				end
			end
			task.wait(CYCLE_PAUSE)
		end
	end)
end

return FlameTrapModule
