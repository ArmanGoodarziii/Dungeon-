local forest
for _, child in ipairs(workspace:GetChildren()) do
	if string.gsub(child.Name, "^%s*(.-)%s*$", "%1") == "Forest" then
		forest = child
		break
	end
end

local teleport = forest and forest:FindFirstChild("Teleport")
local portal = teleport and teleport:FindFirstChild("Portal")
if not portal or not portal:IsA("BasePart") then
	warn("[ForestTeleportVisibility] Forest.Teleport.Portal was not found.")
	return
end

portal.Material = Enum.Material.Neon
portal.Color = Color3.fromRGB(80, 45, 180)

local glow = portal:FindFirstChild("PortalGlow")
if not glow or not glow:IsA("PointLight") then
	if glow then glow:Destroy() end
	glow = Instance.new("PointLight")
	glow.Name = "PortalGlow"
	glow.Parent = portal
end
glow.Color = Color3.fromRGB(95, 130, 255)
glow.Brightness = 4.5
glow.Range = 40
glow.Shadows = true

local highlight = teleport:FindFirstChild("PortalVisibilityHighlight")
if not highlight then
	highlight = Instance.new("Highlight")
	highlight.Name = "PortalVisibilityHighlight"
	highlight.Adornee = teleport
	highlight.FillColor = Color3.fromRGB(70, 85, 255)
	highlight.OutlineColor = Color3.fromRGB(160, 180, 255)
	highlight.FillTransparency = 0.82
	highlight.OutlineTransparency = 0.15
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = teleport
end
