local Players = game:GetService("Players")
local GuardFollowModule = require(game:GetService("ServerScriptService"):WaitForChild("GuardFollowModule"))

local GUARD_BY_INDEX = {
	["1"] = "NewKnight",
	["2"] = "Knight",
	["3"] = "Undead Knight",
}

local activePlayers: {[BasePart]: {[Player]: boolean}} = {}

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

local function getGuard(trigger: BasePart): Model?
	local name = GUARD_BY_INDEX[getTriggerIndex(trigger)]
	local guard = name and workspace:FindFirstChild(name)
	return guard and guard:IsA("Model") and guard or nil
end

local function startChase(trigger: BasePart, player: Player)
	activePlayers[trigger] = activePlayers[trigger] or {}
	if activePlayers[trigger][player] then
		return
	end
	local guard = getGuard(trigger)
	if not guard then
		return
	end
	activePlayers[trigger][player] = true
	GuardFollowModule.Start(guard, player, {
		CaptureDistance = 5,
		IsTargetValid = function(targetPlayer: Player)
			return playerIsInside(targetPlayer, trigger)
		end,
	})
end

local function stopChase(trigger: BasePart, player: Player)
	if not activePlayers[trigger] or not activePlayers[trigger][player] then
		return
	end
	activePlayers[trigger][player] = nil
	local guard = getGuard(trigger)
	if guard then
		GuardFollowModule.Stop(guard)
	end
end

local function patrolTrigger(trigger: BasePart)
	local guard = getGuard(trigger)
	if guard then
		GuardFollowModule.StartPatrol(guard, trigger, {
			WalkSpeed = guard:GetAttribute("PatrolSpeed") or 6,
		})
	end
end

while true do
	local folder = getTriggerFolder()
	if folder then
		for _, trigger in ipairs(folder:GetDescendants()) do
			if trigger:IsA("BasePart") and GUARD_BY_INDEX[getTriggerIndex(trigger)] then
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
					startChase(trigger, playerInside)
					for player in pairs(activePlayers[trigger] or {}) do
						if player ~= playerInside then
							stopChase(trigger, player)
						end
					end
				else
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
