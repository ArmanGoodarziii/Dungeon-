local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local updateTimerEvent = ReplicatedStorage:WaitForChild("UpdateTimer")

local startPortal = workspace:WaitForChild("StartPortal")
local startTrigger = startPortal:WaitForChild("TriggerPart")
local stopPortal = workspace:WaitForChild("StopPortal")
local stopTrigger = stopPortal:WaitForChild("TriggerPart")

-- Stores each player's start time
local playerStartTimes = {}

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

-- Stop the timer
stopTrigger.Touched:Connect(function(hit)

	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if not player then
		return
	end

	local startTime = playerStartTimes[player]

	if not startTime then
		return
	end

	local totalTime = os.clock() - startTime

	playerStartTimes[player] = nil

	updateTimerEvent:FireClient(player, "Stop")

	print(player.Name .. " finished in " .. string.format("%.2f", totalTime) .. " seconds.")

end)

-- Clean up if a player leaves
Players.PlayerRemoving:Connect(function(player)
	playerStartTimes[player] = nil
end)
