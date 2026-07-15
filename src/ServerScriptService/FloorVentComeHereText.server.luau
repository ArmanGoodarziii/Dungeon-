local TweenService = game:GetService("TweenService")

local vent = workspace:WaitForChild("Cells_Zone-3"):WaitForChild("Cell_2"):WaitForChild("FloorVent_REAL_GratedShaft_A")
local anchor = vent.PrimaryPart or vent:FindFirstChildWhichIsA("BasePart", true)
if not anchor then
	warn("[FloorVentComeHereText] No BasePart found for vent")
	return
end

local existing = anchor:FindFirstChild("ComeHereText")
if existing then
	existing:Destroy()
end

local billboard = Instance.new("BillboardGui")
billboard.Name = "ComeHereText"
billboard.Adornee = anchor
billboard.AlwaysOnTop = false
billboard.MaxDistance = 32
billboard.LightInfluence = 0
billboard.Size = UDim2.fromOffset(220, 64)
-- Keep the label clearly above the vent opening, not beside the grate.
-- FloorFrame_Left is offset from the vent center, so compensate horizontally.
billboard.StudsOffsetWorldSpace = Vector3.new(4.12, 12, 0)
billboard.Parent = anchor

local label = Instance.new("TextLabel")
label.Name = "Label"
label.BackgroundTransparency = 1
label.Size = UDim2.fromScale(1, 1)
label.Font = Enum.Font.GothamBold
label.Text = "COME HERE"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
label.TextStrokeTransparency = 0.2
label.Parent = billboard

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = label

TweenService:Create(scale, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
	Scale = 1.12,
}):Play()
TweenService:Create(label, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
	TextTransparency = 0.65,
}):Play()

local grateCollision = vent:FindFirstChild("InvisibleGrateCollision")
if grateCollision and grateCollision:IsA("BasePart") then
	grateCollision.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and billboard.Parent then
			billboard:Destroy()
		end
	end)
end
