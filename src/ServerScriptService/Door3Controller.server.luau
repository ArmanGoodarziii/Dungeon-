local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ServerStorage = game:GetService("ServerStorage")

local door = workspace:WaitForChild("Door 3")
local doorPanel = door:WaitForChild("Middle Part")
local buttonContainer
for _, child in ipairs(door:GetChildren()) do
	if string.gsub(child.Name, "^%s*(.-)%s*$", "%1") == "OpenButton" then
		buttonContainer = child
		break
	end
end
local button = buttonContainer and (buttonContainer:IsA("BasePart") and buttonContainer or buttonContainer:FindFirstChild("button1", true) or buttonContainer:FindFirstChildWhichIsA("BasePart", true))
if not button or not button:IsA("BasePart") then
	warn("[Door3Controller] OpenButton/button1 was not found.")
	return
end
local buttonText = button:FindFirstChild("ButtonText")
local textScale = buttonText and buttonText:FindFirstChild("Label") and buttonText.Label:FindFirstChildOfClass("UIScale")
local textLabel = buttonText and buttonText:FindFirstChild("Label")
local buttonPressAnimation = ServerStorage:FindFirstChild("ButtonPressAnimation")

if buttonText then
	buttonText:Destroy()
	buttonText = nil
	textScale = nil
	textLabel = nil
end

-- Give the interaction object a readable physical button shape instead of a
-- flat neon plate.  Keep its existing position and touch behavior unchanged.
if button:IsA("Part") then
	button.Shape = Enum.PartType.Cylinder
	button.Size = Vector3.new(4.5, 0.9, 4.5)
	button.Orientation = Vector3.new(0, 0, 90)
end
button.Material = Enum.Material.Metal
button.Color = Color3.fromRGB(26, 105, 45)
button.Reflectance = 0.08

local buttonBase = door:FindFirstChild("OpenButtonBase")
if not buttonBase then
	buttonBase = Instance.new("Part")
	buttonBase.Name = "OpenButtonBase"
	buttonBase.Shape = Enum.PartType.Cylinder
	buttonBase.Size = Vector3.new(5.2, 0.55, 5.2)
	buttonBase.CFrame = button.CFrame * CFrame.new(0, -0.38, 0)
	buttonBase.Anchored = true
	buttonBase.CanCollide = false
	buttonBase.CanTouch = false
	buttonBase.CanQuery = false
	buttonBase.Material = Enum.Material.Metal
	buttonBase.Color = Color3.fromRGB(38, 42, 48)
	buttonBase.Reflectance = 0.18
	buttonBase.Parent = door
end

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
local textFlash: Tween? = nil

local function playButtonPressAnimation(character: Model)
	if not buttonPressAnimation or not buttonPressAnimation:IsA("Animation") then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local ok, track = pcall(function()
		return animator:LoadAnimation(buttonPressAnimation)
	end)
	if not ok or not track then return end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	track:Play(0.1)
	track.Ended:Connect(function() track:Destroy() end)
end

if textScale then
	textPulse = TweenService:Create(textScale, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Scale = 1.12,
	})
	textPulse:Play()
end
if textLabel and textLabel:IsA("TextLabel") then
	textFlash = TweenService:Create(textLabel, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		TextTransparency = 0.65,
	})
	textFlash:Play()
end

local function openDoor()
	if opened or opening then
		return
	end

	opening = true
	local template = SoundService:FindFirstChild("Door Opening")
	if template and template:IsA("Sound") and template.SoundId ~= "" then
		local sound = template:Clone()
		sound.Name = "Door Opening_Playback"
		sound.Parent = button
		sound:Play()
		sound.Ended:Connect(function() sound:Destroy() end)
	end
	if textPulse then
		textPulse:Cancel()
	end
	if textFlash then textFlash:Cancel() end
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
		if character then playButtonPressAnimation(character) end
		openDoor()
	end
end)

local clickDetector = button:FindFirstChildOfClass("ClickDetector")
if not clickDetector then
	clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 18
	clickDetector.Parent = button
end
clickDetector.MouseClick:Connect(function(player)
	local character = player.Character
	if character then playButtonPressAnimation(character) end
	openDoor()
end)
