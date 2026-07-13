local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local GuardFollowModule = require(ServerScriptService:WaitForChild("GuardFollowModule"))

local GUARD_BY_TRIGGER_NAME = {
	["Trigger 1"] = "DungeonGuard_03_ChiefWarden",
	["Trigger 2"] = "DungeonGuard_01_PrisonJailer",
	["Trigger 3"] = "DungeonGuard_02_ArmoredSpearman",
}

local boundTriggers: {[BasePart]: boolean} = {}
local debounce: {[Player]: number} = {}

local function trim(text: string): string
	return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function getForest(): Instance?
	for _, child in ipairs(workspace:GetChildren()) do
		if trim(child.Name) == "Forest" then
			return child
		end
	end
	return nil
end

local function getGuardFolder(): Folder?
	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("Folder") and instance.Name == "01_GuardCharacters" then
			return instance
		end
	end
	return nil
end

local function getGuard(triggerName: string): Model?
	local guardFolder = getGuardFolder()
	local guardName = GUARD_BY_TRIGGER_NAME[triggerName]
	local guard = guardFolder and guardName and guardFolder:FindFirstChild(guardName)
	if guard and guard:IsA("Model") then
		return guard
	end
	return nil
end

local function bindTrigger(trigger: BasePart)
	if boundTriggers[trigger] or not GUARD_BY_TRIGGER_NAME[trigger.Name] then
		return
	end
	boundTriggers[trigger] = true
	trigger.Touched:Connect(function(hit: BasePart)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local now = os.clock()
		if debounce[player] and now - debounce[player] < 0.5 then
			return
		end
		debounce[player] = now

		local guard = getGuard(trigger.Name)
		if guard then
			GuardFollowModule.Start(guard, player, {CaptureDistance = 5})
		else
			warn(("[ForestGuardTrigger] No guard is assigned to %s."):format(trigger.Name))
		end
	end)
	warn(("[ForestGuardTrigger] %s is bound to %s."):format(trigger.Name, GUARD_BY_TRIGGER_NAME[trigger.Name]))
end

task.spawn(function()
	while true do
		local forest = getForest()
		local triggerFolder = forest and forest:FindFirstChild("FollowPlayerTrigger")
		if triggerFolder then
			for _, instance in ipairs(triggerFolder:GetDescendants()) do
				if instance:IsA("BasePart") then
					bindTrigger(instance)
				end
			end
		end
		task.wait(1)
	end
end)
