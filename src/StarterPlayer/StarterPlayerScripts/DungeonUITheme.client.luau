local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local PANEL = Color3.fromRGB(22, 20, 27)
local PANEL_STROKE = Color3.fromRGB(116, 92, 62)
local TEXT = Color3.fromRGB(220, 205, 164)
local TEXT_MUTED = Color3.fromRGB(155, 143, 119)

local function corner(parent: Instance, radius: number)
	if not parent:FindFirstChild("DungeonCorner") then
		local c = Instance.new("UICorner")
		c.Name = "DungeonCorner"
		c.CornerRadius = UDim.new(0, radius)
		c.Parent = parent
	end
end

local function stroke(parent: Instance)
	if not parent:FindFirstChild("DungeonStroke") then
		local s = Instance.new("UIStroke")
		s.Name = "DungeonStroke"
		s.Color = PANEL_STROKE
		s.Thickness = 1.5
		s.Transparency = 0.25
		s.Parent = parent
	end
end

local function styleTimer(gui: ScreenGui)
	local frame = gui:FindFirstChild("TimerFrame", true)
	if not frame or not frame:IsA("Frame") then return end
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.fromScale(0.965, 0.965)
	frame.Size = UDim2.fromOffset(285, 74)
	frame.BackgroundColor3 = PANEL
	frame.BackgroundTransparency = 0.06
	corner(frame, 10)
	stroke(frame)
	local gradient = frame:FindFirstChild("DungeonGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Name = "DungeonGradient"
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 33, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 17, 23)),
		})
		gradient.Rotation = 90
		gradient.Parent = frame
	end
	local accent = frame:FindFirstChild("DungeonAccent")
	if not accent then
		accent = Instance.new("Frame")
		accent.Name = "DungeonAccent"
		accent.AnchorPoint = Vector2.new(0.5, 1)
		accent.Position = UDim2.fromScale(0.5, 1)
		accent.Size = UDim2.new(1, -28, 0, 2)
		accent.BackgroundColor3 = PANEL_STROKE
		accent.BorderSizePixel = 0
		accent.ZIndex = frame.ZIndex + 1
		accent.Parent = frame
	end
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("TextLabel") then
			child.Font = Enum.Font.GothamBold
			child.TextColor3 = child.Name:match("TimerTitle") and TEXT_MUTED or TEXT
			child.TextStrokeColor3 = Color3.fromRGB(8, 7, 11)
			child.TextStrokeTransparency = 0.45
			child.TextScaled = true
			child.AnchorPoint = Vector2.new(0, 0)
			if child.Name:match("TimerTitle") then
				child.Position = UDim2.fromScale(0.06, 0.06)
				child.Size = UDim2.fromScale(0.88, 0.25)
			else
				child.Position = UDim2.fromScale(0.06, 0.30)
				child.Size = UDim2.fromScale(0.88, 0.60)
			end
		end
	end
end

local function styleCheckpoint(gui: ScreenGui)
	local label = gui:FindFirstChild("CheckpointLabel", true)
	if not label or not label:IsA("TextLabel") then return end
	label.AnchorPoint = Vector2.new(0, 0)
	label.Position = UDim2.fromScale(0.035, 0.035)
	label.Size = UDim2.fromOffset(250, 44)
	label.BackgroundColor3 = PANEL
	label.BackgroundTransparency = 0.15
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = TEXT
	label.TextStrokeTransparency = 0.75
	label.TextScaled = true
	corner(label, 8)
	stroke(label)
end

local function styleCountdown(gui: ScreenGui)
	local label = gui:FindFirstChildWhichIsA("TextLabel", true)
	if not label then return end
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(214, 174, 106)
	label.TextStrokeColor3 = Color3.fromRGB(20, 16, 22)
	label.TextStrokeTransparency = 0.2
end

local function style(gui: Instance)
	if not gui:IsA("ScreenGui") then return end
	if gui.Name == "TimerGui" then styleTimer(gui)
	elseif gui.Name == "CheckpointUI" then styleCheckpoint(gui)
	elseif gui.Name == "MovementLockCountdown" then styleCountdown(gui) end
end

for _, child in ipairs(playerGui:GetChildren()) do style(child) end
playerGui.ChildAdded:Connect(function(child)
	task.defer(style, child)
end)
