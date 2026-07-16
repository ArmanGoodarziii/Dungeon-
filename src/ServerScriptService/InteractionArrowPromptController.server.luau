-- Subdued, top-down guidance arrows for interaction points.
local function createArrow(name: string, target: BasePart, offset: Vector3): Model
	local arrow = Instance.new("Model")
	arrow.Name = name
	arrow.Parent = workspace
	local origin = CFrame.new(target.Position + offset)

	local shaft = Instance.new("Part")
	shaft.Name = "ArrowShaft"
	shaft.Size = Vector3.new(0.32, 3.2, 0.32)
	shaft.CFrame = origin
	shaft.Anchored = true
	shaft.CanCollide = false
	shaft.CanTouch = false
	shaft.CanQuery = false
	shaft.Material = Enum.Material.SmoothPlastic
	shaft.Color = Color3.fromRGB(42, 69, 56)
	shaft.Parent = arrow

	local head = Instance.new("WedgePart")
	head.Name = "ArrowHead"
	head.Size = Vector3.new(1.35, 1.1, 0.8)
	-- The point is down toward the object being guided to.
	head.CFrame = origin * CFrame.new(0, -2.05, 0) * CFrame.Angles(math.rad(180), 0, 0)
	head.Anchored = true
	head.CanCollide = false
	head.CanTouch = false
	head.CanQuery = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(42, 69, 56)
	head.Parent = arrow

	local highlight = Instance.new("Highlight")
	highlight.Name = "ArrowOutline"
	highlight.FillColor = Color3.fromRGB(54, 94, 70)
	highlight.OutlineColor = Color3.fromRGB(104, 140, 112)
	highlight.FillTransparency = 0.94
	highlight.OutlineTransparency = 0.5
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = arrow

	task.spawn(function()
		local started = os.clock()
		while arrow.Parent do
			arrow:ScaleTo(1 + math.sin((os.clock() - started) * math.pi * 1.2) * 0.08)
			task.wait(0.06)
		end
	end)
	return arrow
end

local function connectDismiss(target: BasePart, arrow: Model)
	target.Touched:Connect(function(hit)
		if hit:FindFirstAncestorOfClass("Model") then arrow:Destroy() end
	end)
end

for _, child in ipairs(workspace:GetChildren()) do
	if child:IsA("Model") and (child.Name:match("InteractionArrow$") or child.Name:match("InteractionSign$")) then
		child:Destroy()
	end
end

local door = workspace:FindFirstChild("Door 3")
local container = door and (door:FindFirstChild("OpenButton") or door:FindFirstChild("OpenButton "))
local button = container and (container:IsA("BasePart") and container or container:FindFirstChild("button1", true) or container:FindFirstChildWhichIsA("BasePart", true))
if button and button:IsA("BasePart") then
	connectDismiss(button, createArrow("OpenInteractionArrow", button, Vector3.new(0, 5, 0)))
end

local cells = workspace:FindFirstChild("Cells_Zone-3")
local cell2 = cells and cells:FindFirstChild("Cell_2")
local vent = cell2 and cell2:FindFirstChild("FloorVent_REAL_GratedShaft_A")
local ventAnchor = vent and (vent.PrimaryPart or vent:FindFirstChildWhichIsA("BasePart", true))
if ventAnchor and ventAnchor:IsA("BasePart") then
	connectDismiss(ventAnchor, createArrow("FloorVentInteractionArrow", ventAnchor, Vector3.new(4.12, 13, 0)))
end

local forest
for _, child in ipairs(workspace:GetChildren()) do
	if string.gsub(child.Name, "^%s*(.-)%s*$", "%1") == "Forest" then forest = child break end
end
local portal = forest and forest:FindFirstChild("Teleport") and forest.Teleport:FindFirstChild("Portal")
if portal and portal:IsA("BasePart") then
	connectDismiss(portal, createArrow("TeleportInteractionArrow", portal, Vector3.new(0, 6, 0)))
end
