local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")

local ARROW_NAME = "Arrow that I thought looked really good"
local arrowTemplate = workspace:FindFirstChild(ARROW_NAME) or ServerStorage:FindFirstChild("InteractionArrowTemplate")
if not arrowTemplate or not arrowTemplate:IsA("Model") then
	warn("[InteractionArrow] Arrow model was not found in Workspace.")
	return
end

local templatePivot = arrowTemplate:GetPivot()
local templateRotation = templatePivot - templatePivot.Position
arrowTemplate.Parent = ServerStorage
arrowTemplate.Name = "InteractionArrowTemplate"

local function makeArrow(name: string, target: BasePart, offset: Vector3)
	local arrow = arrowTemplate:Clone()
	arrow.Name = name
	arrow.Parent = workspace
	arrow:PivotTo(CFrame.new(target.Position + offset) * templateRotation)

	for _, descendant in ipairs(arrow:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Color = Color3.fromRGB(60, 255, 100)
			local originalTransparency = descendant.Transparency
			TweenService:Create(descendant, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Transparency = math.clamp(originalTransparency + 0.45, 0, 1),
			}):Play()
		end
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "Flash"
	highlight.FillColor = Color3.fromRGB(60, 255, 100)
	highlight.OutlineColor = Color3.fromRGB(180, 255, 190)
	highlight.FillTransparency = 0.35
	highlight.OutlineTransparency = 0.1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = arrow
	TweenService:Create(highlight, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		FillTransparency = 0.8,
		OutlineTransparency = 0.55,
	}):Play()

	return arrow
end

local function connectDismiss(target: BasePart, arrow: Model)
	target.Touched:Connect(function(hit)
		if hit:FindFirstAncestorOfClass("Model") then
			arrow:Destroy()
		end
	end)
end

local door = workspace:FindFirstChild("Door 3")
local openButton = door and door:FindFirstChild("OpenButton")
if openButton and openButton:IsA("BasePart") then
	local arrow = makeArrow("OpenInteractionArrow", openButton, Vector3.new(0, 4, 0))
	connectDismiss(openButton, arrow)
end

local cells = workspace:FindFirstChild("Cells_Zone-3")
local cell2 = cells and cells:FindFirstChild("Cell_2")
local vent = cell2 and cell2:FindFirstChild("FloorVent_REAL_GratedShaft_A")
local ventAnchor = vent and (vent.PrimaryPart or vent:FindFirstChildWhichIsA("BasePart", true))
if ventAnchor and ventAnchor:IsA("BasePart") then
	local arrow = makeArrow("FloorVentInteractionArrow", ventAnchor, Vector3.new(4.12, 12, 0))
	connectDismiss(ventAnchor, arrow)
end

local forest
for _, child in ipairs(workspace:GetChildren()) do
	if string.gsub(child.Name, "^%s*(.-)%s*$", "%1") == "Forest" then forest = child break end
end
local teleport = forest and forest:FindFirstChild("Teleport")
local portal = teleport and teleport:FindFirstChild("Portal")
if portal and portal:IsA("BasePart") then
	local arrow = makeArrow("TeleportInteractionArrow", portal, Vector3.new(0, 5, 0))
	connectDismiss(portal, arrow)
end
