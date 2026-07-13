local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local playerGui = script.Parent
local showFinalPlaceSuccess = ReplicatedStorage:WaitForChild("ShowFinalPlaceSuccess")

local activeGui: ScreenGui? = nil

local function showSuccess()
	if activeGui then
		activeGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "FinalPlaceSuccessUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 20
	gui.Parent = playerGui
	activeGui = gui

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.AnchorPoint = Vector2.new(0.5, 0.5)
	message.Position = UDim2.fromScale(0.5, 0.25)
	message.Size = UDim2.fromOffset(440, 88)
	message.BackgroundColor3 = Color3.fromRGB(27, 88, 48)
	message.BackgroundTransparency = 0.15
	message.BorderSizePixel = 0
	message.Font = Enum.Font.GothamBold
	message.Text = "SUCCESS!"
	message.TextColor3 = Color3.fromRGB(255, 255, 255)
	message.TextScaled = true
	message.TextTransparency = 1
	message.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = message

	TweenService:Create(message, TweenInfo.new(0.25), {
		TextTransparency = 0,
	}):Play()

	-- Start the 0.3 second fade before the five-second lifetime ends.
	task.delay(4.7, function()
		if activeGui ~= gui then
			return
		end

		local fadeOut = TweenService:Create(message, TweenInfo.new(0.3), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
		fadeOut:Play()
		fadeOut.Completed:Wait()
		if gui.Parent then
			gui:Destroy()
		end
		if activeGui == gui then
			activeGui = nil
		end
	end)
end

showFinalPlaceSuccess.OnClientEvent:Connect(showSuccess)
