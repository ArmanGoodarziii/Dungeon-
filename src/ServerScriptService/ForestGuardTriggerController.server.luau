local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local GuardFollowModule = require(game:GetService("ServerScriptService"):WaitForChild("GuardFollowModule"))

local GUARDS_BY_INDEX = {
	["1"] = {"NewKnight", "NewKnight_Follower"},
	["2"] = {"Knight", "Knight_Follower"},
	["3"] = {"Undead Knight", "Undead Knight_Follower"},
}

local activePlayers: {[BasePart]: {[Player]: boolean}} = {}
local alertSounds: {[Player]: Sound} = {}

local function startGuardAlert(player: Player)
	if alertSounds[player] then return end
	local template = SoundService:FindFirstChild("Guard Alert")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not template or not template:IsA("Sound") or template.SoundId == "" or not root then return end
	local sound = template:Clone()
	sound.Name = "Guard Alert_Playback"
	sound.Looped = true
	sound.Parent = root
	sound:Play()
	alertSounds[player] = sound
end

local function stopGuardAlert(player: Player)
	local sound = alertSounds[player]
	alertSounds[player] = nil
	if sound then sound:Destroy() end
end

local function trim(value: string): string
	return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function getTriggerIndex(trigger: BasePart): string?
	return string.match(trigger.Name, "(%d+)%s*$")
end

local function getTriggerFolder(): Instance?
	local forest: Instance? = nil
	for _, child in ipairs(workspace:GetChildren()) do
		if trim(child.Name) == "Forest" then
			forest = child
			break
		end
	end
	if not forest then
		return nil
	end

	for _, child in ipairs(forest:GetChildren()) do
		local normalized = string.lower(trim(child.Name)):gsub("[^%a]", "")
		if normalized == "followplayertrigger" or normalized == "followplayertriggers" then
			return child
		end
	end
	return nil
end

local function playerIsInside(player: Player, trigger: BasePart): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local point = trigger.CFrame:PointToObjectSpace(root.Position)
	local halfSize = trigger.Size / 2
	return math.abs(point.X) <= halfSize.X
		and math.abs(point.Z) <= halfSize.Z
		and math.abs(point.Y) <= halfSize.Y + 6
end

local function getGuards(trigger: BasePart): {Model}
	local guards = {}
	for _, name in ipairs(GUARDS_BY_INDEX[getTriggerIndex(trigger)] or {}) do
		local guard = workspace:FindFirstChild(name)
		if guard and guard:IsA("Model") then
			table.insert(guards, guard)
		end
	end
	return guards
end

local function startChase(trigger: BasePart, player: Player)
	activePlayers[trigger] = activePlayers[trigger] or {}
	if activePlayers[trigger][player] then
		return
	end
	local guards = getGuards(trigger)
	if #guards == 0 then
		return
	end
	activePlayers[trigger][player] = true
	for _, guard in ipairs(guards) do
		GuardFollowModule.Start(guard, player, {
			CaptureDistance = 5,
			IsTargetValid = function(targetPlayer: Player)
				return playerIsInside(targetPlayer, trigger)
			end,
		})
	end
end

local function stopChase(trigger: BasePart, player: Player)
	if not activePlayers[trigger] or not activePlayers[trigger][player] then
		return
	end
	activePlayers[trigger][player] = nil
	for _, guard in ipairs(getGuards(trigger)) do
		GuardFollowModule.Stop(guard)
	end
end

local function patrolTrigger(trigger: BasePart)
	for _, guard in ipairs(getGuards(trigger)) do
		GuardFollowModule.StartPatrol(guard, trigger, {
			WalkSpeed = guard:GetAttribute("PatrolSpeed") or 6,
		})
	end
end

while true do
	local folder = getTriggerFolder()
	if folder then
		for _, trigger in ipairs(folder:GetDescendants()) do
			if trigger:IsA("BasePart") and GUARDS_BY_INDEX[getTriggerIndex(trigger)] then
				trigger.Anchored = true
				trigger.CanCollide = false
				trigger.CanTouch = true
				trigger.CanQuery = false
				local playerInside: Player? = nil
				for _, player in ipairs(Players:GetPlayers()) do
					if playerIsInside(player, trigger) then
						playerInside = player
						break
					end
				end

				if playerInside then
					if getTriggerIndex(trigger) == "1" then
						startGuardAlert(playerInside)
					elseif getTriggerIndex(trigger) == "3" then
						-- Keep the alert active through the final trigger; stop it on exit.
					end
					startChase(trigger, playerInside)
					for player in pairs(activePlayers[trigger] or {}) do
						if player ~= playerInside then
							stopChase(trigger, player)
						end
					end
				else
					if getTriggerIndex(trigger) == "3" then
						for player in pairs(activePlayers[trigger] or {}) do
							stopGuardAlert(player)
						end
					end
					for player in pairs(activePlayers[trigger] or {}) do
						stopChase(trigger, player)
					end
					patrolTrigger(trigger)
				end
			end
		end
	end
	task.wait(0.2)
end
