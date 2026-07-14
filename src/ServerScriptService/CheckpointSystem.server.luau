local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CheckpointModule = require(script.Parent:WaitForChild("CheckpointModule"))

local checkpointEvent = ReplicatedStorage:FindFirstChild("CheckpointEvent")
if not checkpointEvent then
	checkpointEvent = Instance.new("RemoteEvent")
	checkpointEvent.Name = "CheckpointEvent"
	checkpointEvent.Parent = ReplicatedStorage
end

CheckpointModule.Initialize(workspace:WaitForChild("Checkpoints"), checkpointEvent)
