local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local event = ReplicatedStorage:WaitForChild("SmashCameraShake")
local camera = workspace.CurrentCamera
local shakeUntil = 0
local strength = 0

event.OnClientEvent:Connect(function(worldPosition: Vector3)
	if (camera.CFrame.Position - worldPosition).Magnitude <= 90 then
		shakeUntil = os.clock() + 0.5
		strength = 0.5
	end
end)

RunService:BindToRenderStep("SmashTrapCameraShake", Enum.RenderPriority.Camera.Value + 1, function()
	if os.clock() >= shakeUntil then return end
	local fade = math.max(0, (shakeUntil - os.clock()) / 0.5)
	local offset = Vector3.new(
		(math.random() - 0.5) * strength * fade,
		(math.random() - 0.5) * strength * fade,
		0
	)
	camera.CFrame = camera.CFrame * CFrame.new(offset)
end)
