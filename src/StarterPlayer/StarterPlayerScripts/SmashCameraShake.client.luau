local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local event = ReplicatedStorage:WaitForChild("SmashCameraShake")
local camera = workspace.CurrentCamera
local shakeUntil = 0
local strength = 0
local shakeDuration = 0.5

event.OnClientEvent:Connect(function(worldPosition: Vector3, source: string?)
	if (camera.CFrame.Position - worldPosition).Magnitude <= 90 then
		shakeDuration = source == "Sphere" and 0.85 or 0.5
		shakeUntil = os.clock() + shakeDuration
		strength = source == "Sphere" and 1.15 or 0.5
	end
end)

RunService:BindToRenderStep("SmashTrapCameraShake", Enum.RenderPriority.Camera.Value + 1, function()
	if os.clock() >= shakeUntil then return end
	local fade = math.max(0, (shakeUntil - os.clock()) / shakeDuration)
	local offset = Vector3.new(
		(math.random() - 0.5) * strength * fade,
		(math.random() - 0.5) * strength * fade,
		0
	)
	camera.CFrame = camera.CFrame * CFrame.new(offset)
end)
