local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local door = workspace:WaitForChild("Door 3")
local doorPanel = door:WaitForChild("Middle Part")
local button = door:WaitForChild("OpenButton")
local buttonText = button:FindFirstChild("ButtonText")
local textScale = buttonText and buttonText:FindFirstChild("Label") and buttonText.Label:FindFirstChildOfClass("UIScale")

local prompt = button:FindFirstChildOfClass("ProximityPrompt")
if prompt then
	prompt:Destroy()
end
button.CanTouch = true

local doorParts = {doorPanel}
for _, descendant in ipairs(doorPanel:GetDescendants()) do
	if descendant:IsA("BasePart") then
		table.insert(doorParts, descendant)
	end
end

local closedPanelCFrame = doorPanel.CFrame
local relativeCFrames: {[BasePart]: CFrame} = {}
for _, part in ipairs(doorParts) do
	part.Anchored = true
	relativeCFrames[part] = closedPanelCFrame:ToObjectSpace(part.CFrame)
end

-- Treat the left edge of the panel as its hinge and swing the whole panel,
-- including the handles, open around that vertical pivot.
local hingeCFrame = closedPanelCFrame * CFrame.new(-doorPanel.Size.X / 2, 0, 0)
local openedPanelCFrame = hingeCFrame * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(doorPanel.Size.X / 2, 0, 0)

local opened = false
local opening = false
local textPulse: Tween? = nil

if textScale then
	textPulse = TweenService:Create(textScale, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Scale = 1.12,
	})
	textPulse:Play()
end

local function openDoor()
	if opened or opening then
		return
	end

	opening = true
	if textPulse then
		textPulse:Cancel()
	end
	if buttonText and buttonText:IsA("LayerCollector") then
		buttonText.Enabled = false
	end
	button.Color = Color3.fromRGB(54, 170, 75)

	local tweens = {}
	for _, part in ipairs(doorParts) do
		local targetCFrame = openedPanelCFrame * relativeCFrames[part]
		local tween = TweenService:Create(part, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = targetCFrame,
		})
		table.insert(tweens, tween)
		tween:Play()
	end

	if tweens[1] then
		tweens[1].Completed:Wait()
	end
	opened = true
	opening = false
end

button.Touched:Connect(function(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if player then
		openDoor()
	end
end)
