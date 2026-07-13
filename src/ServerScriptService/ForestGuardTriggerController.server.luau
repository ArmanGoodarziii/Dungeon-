local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local GuardFollowModule = require(ServerScriptService:WaitForChild("GuardFollowModule"))

local function findChildIgnoringOuterSpaces(parent: Instance, expectedName: string): Instance?
	for _, child in ipairs(parent:GetChildren()) do
		if string.gsub(child.Name, "^%s*(.-)%s*$", "%1") == expectedName then
			return child
		end
	end
	return nil
end

local function findFirstPart(parent: Instance): BasePart?
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

local forest = findChildIgnoringOuterSpaces(workspace, "Forest")
if not forest then
	warn("[ForestGuardTrigger] Workspace.Forest was not found.")
	return
end

local triggerFolder = forest:WaitForChild("FollowPlayerTrigger")
local trigger = triggerFolder:FindFirstChild("Trigger 1")
if not trigger or not trigger:IsA("BasePart") then
	trigger = findFirstPart(triggerFolder)
end
if not trigger then
	warn("[ForestGuardTrigger] FollowPlayerTrigger needs a BasePart such as Trigger 1.")
	return
end

local guardFolder: Folder? = nil
for _, instance in ipairs(workspace:GetDescendants()) do
	if instance:IsA("Folder") and instance.Name == "01_GuardCharacters" then
		guardFolder = instance
		break
	end
end
if not guardFolder then
	warn("[ForestGuardTrigger] 01_GuardCharacters was not found.")
	return
end

local guards = {}
for _, child in ipairs(guardFolder:GetChildren()) do
	if child:IsA("Model") and child:FindFirstChildWhichIsA("Humanoid", true) then
		table.insert(guards, child)
	end
end
if #guards == 0 then
	warn("[ForestGuardTrigger] No Humanoid guard models were found.")
	return
end

local debounce: {[Player]: number} = {}
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

	for _, guard in ipairs(guards) do
		GuardFollowModule.Start(guard, player, {CaptureDistance = 5})
	end
end)
