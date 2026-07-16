local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local MAX_DISTANCE = 55
local MIN_VIEW_DOT = 0.35

local function setVisible(model: Model, visible: boolean)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = visible and 0 or 1
		end
	end
end

RunService.RenderStepped:Connect(function()
	camera = workspace.CurrentCamera or camera
	if not camera then return end
	local character = player.Character
	local ignore = {character}
	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("Model") and child.Name:match("InteractionArrow$") then
			table.insert(ignore, child)
		end
	end

	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("Model") and child.Name:match("InteractionArrow$") then
			local position = child:GetPivot().Position
			local toArrow = position - camera.CFrame.Position
			local distance = toArrow.Magnitude
			local facing = distance > 0 and camera.CFrame.LookVector:Dot(toArrow.Unit) >= MIN_VIEW_DOT
			local visible = distance <= MAX_DISTANCE and facing
			if visible then
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = ignore
				local hit = workspace:Raycast(camera.CFrame.Position, toArrow, rayParams)
				visible = not hit
			end
			setVisible(child, visible)
		end
	end
end)
