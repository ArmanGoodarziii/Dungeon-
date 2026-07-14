local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local updateTimerEvent = ReplicatedStorage:WaitForChild("UpdateTimer")

local startPortal = workspace:WaitForChild("StartPortal")
local startTrigger = startPortal:WaitForChild("TriggerPart")

-- Stores each player's start time
local playerStartTimes = {}

local function finishTimer(player: Player): number?
	local startTime = playerStartTimes[player]
	if not startTime then
		return nil
	end

	local totalTime = os.clock() - startTime
	playerStartTimes[player] = nil
	updateTimerEvent:FireClient(player, "Stop")
	return totalTime
end

local finishTimerFunction = ServerScriptService:FindFirstChild("FinishTimer")
if not finishTimerFunction then
	finishTimerFunction = Instance.new("BindableFunction")
	finishTimerFunction.Name = "FinishTimer"
	finishTimerFunction.Parent = ServerScriptService
end

if finishTimerFunction:IsA("BindableFunction") then
	finishTimerFunction.OnInvoke = finishTimer
end

-- Start the timer
startTrigger.Touched:Connect(function(hit)
	
	print("touched")

	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if not player then
		return
	end

	-- Prevent restarting the timer if it's already running
	if playerStartTimes[player] then
		return
	end

	playerStartTimes[player] = os.clock()

	updateTimerEvent:FireClient(player, "Start")

	print(player.Name .. " started the timer.")

end)

-- Clean up if a player leaves
Players.PlayerRemoving:Connect(function(player)
	playerStartTimes[player] = nil
end)
