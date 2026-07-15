local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local event = ReplicatedStorage:WaitForChild("MovementLockCountdown")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "MovementLockCountdown"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.42)
label.Size = UDim2.fromOffset(180, 100)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBlack
label.TextColor3 = Color3.fromRGB(255, 220, 90)
label.TextStrokeTransparency = 0.15
label.TextScaled = true
label.Visible = false
label.Parent = gui

event.OnClientEvent:Connect(function(duration)
	duration = tonumber(duration) or 0
	local finish = os.clock() + duration
	label.Visible = true
	while os.clock() < finish do
		local remaining = math.max(0, finish - os.clock())
		label.Text = tostring(math.ceil(remaining))
		label.TextTransparency = 0
		local tween = TweenService:Create(label, TweenInfo.new(0.18), {TextTransparency = 0.35})
		tween:Play()
		tween.Completed:Wait()
		task.wait(0.65)
	end
	label.Visible = false
end)
