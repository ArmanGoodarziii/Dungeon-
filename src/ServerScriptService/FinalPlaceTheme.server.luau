local function trimmed(name: string): string
	return string.gsub(name, "^%s*(.-)%s*$", "%1")
end

local finalPlace
for _, child in ipairs(workspace:GetChildren()) do
	if trimmed(child.Name) == "FinalPlace" then
		finalPlace = child
		break
	end
end
if not finalPlace then
	warn("[FinalPlaceTheme] FinalPlace was not found.")
	return
end

for _, part in ipairs(finalPlace:GetDescendants()) do
	if part:IsA("BasePart") then
		local ancestorNames = {}
		local parent = part.Parent
		while parent and parent ~= finalPlace do
			ancestorNames[trimmed(parent.Name)] = true
			parent = parent.Parent
		end

		if part.Name == "MeshBoard" then
			part.Material = Enum.Material.WoodPlanks
			part.Color = Color3.fromRGB(86, 45, 28)
		elseif ancestorNames["Stud Grass Platform"] then
			part.Material = Enum.Material.Grass
			part.Color = Color3.fromRGB(72, 112, 46)
		elseif part.Color.G > part.Color.R * 1.25 and part.Color.G > part.Color.B * 1.15 then
			part.Material = Enum.Material.Grass
		elseif part.Color.R > part.Color.B * 1.35 and part.Color.G > part.Color.B * 1.15 then
			part.Material = Enum.Material.WoodPlanks
		else
			part.Material = Enum.Material.Slate
			part.Color = Color3.fromRGB(68, 73, 84)
		end
	end
end

local platform = finalPlace:FindFirstChild("Stud Grass Platform")
local lightPart = platform and platform:FindFirstChildWhichIsA("BasePart", true)
if lightPart and not lightPart:FindFirstChild("VictoryGlow") then
	local light = Instance.new("PointLight")
	light.Name = "VictoryGlow"
	light.Color = Color3.fromRGB(255, 221, 145)
	light.Brightness = 1.2
	light.Range = 18
	light.Shadows = true
	light.Parent = lightPart
end
