local workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- ============================================
-- Stable dungeon lighting properties
-- Balanced for consistent visibility across all zones
-- ============================================
Lighting.ClockTime = 14              -- Daytime base for stable ambient
Lighting.Brightness = 1.5            -- Moderate brightness
Lighting.ExposureCompensation = 0    -- No exposure adjustment for stability
Lighting.EnvironmentDiffuseScale = 0.6
Lighting.EnvironmentSpecularScale = 0.6
Lighting.Ambient = Color3.fromRGB(70, 65, 80)        -- Warm grey-purple ambient for consistent base
Lighting.OutdoorAmbient = Color3.fromRGB(60, 55, 70) -- Slightly darker outdoor
Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.5        -- Softer shadows for stable look
Lighting.FogEnd = 200                 -- Moderate fog distance
Lighting.FogStart = 50               -- Fog starts further out
Lighting.FogColor = Color3.fromRGB(30, 25, 35)      -- Dark purple-grey fog

-- ============================================
-- SUBTLE flicker for torch lights only
-- Fill lights and chandelier lights stay stable
-- ============================================
local torchesFolder = workspace:FindFirstChild("WallTorches")

local flickerLights = {}
local flickerFlames = {}
local bonfireLights = {}

if torchesFolder then
	for _, torchModel in torchesFolder:GetChildren() do
		local torchPart = torchModel:FindFirstChild("TorchMesh")
		if torchPart then
			local light = torchPart:FindFirstChildOfClass("PointLight")
			local flame = torchModel:FindFirstChild("Flame")
			if light then
				table.insert(flickerLights, {
					light = light,
					baseBrightness = light.Brightness,
					phase = math.random() * math.pi * 2,
					speed = 3 + math.random() * 2,  -- Slower, more stable speed
				})
			end
			if flame then
				table.insert(flickerFlames, {
					flame = flame,
					baseSize = flame.Size,
					baseColor = flame.Color,
					phase = math.random() * math.pi * 2,
					speed = 3 + math.random() * 2,
				})
			end
		end
		
		-- Handle bonfire lights (on the torch mesh directly, not in a model)
		if torchModel:IsA("BasePart") and torchModel.Name:match("Bonfire") then
			local light = torchModel:FindFirstChildOfClass("PointLight")
			if light then
				table.insert(bonfireLights, {
					light = light,
					baseBrightness = light.Brightness,
					phase = math.random() * math.pi * 2,
				})
			end
		end
	end
end

-- ============================================
-- Pulsing effect for checkpoint candle lights (slow, subtle)
-- Searches the Checkpoints folder for Candle lights
-- ============================================
local checkpointLights = {}
local checkpointsFolder = workspace:FindFirstChild("Checkpoints")
if checkpointsFolder then
	for _, cpModel in checkpointsFolder:GetChildren() do
		local candle = cpModel:FindFirstChild("Candle")
		if candle then
			local light = candle:FindFirstChildOfClass("PointLight")
			if light then
				table.insert(checkpointLights, {
					light = light,
					baseBrightness = light.Brightness,
				})
			end
		end
	end
end

-- ============================================
-- Main animation loop - SUBTLE effects only
-- ============================================
local runService = game:GetService("RunService")

runService.Heartbeat:Connect(function(time)
	-- Subtle torch flicker (very small amplitude for stability)
	for _, data in ipairs(flickerLights) do
		local flicker = math.sin(time * data.speed + data.phase) * 0.06
		flicker += math.sin(time * data.speed * 1.8 + data.phase * 1.3) * 0.04
		data.light.Brightness = data.baseBrightness + flicker
	end
	
	-- Subtle flame mesh flicker
	for _, data in ipairs(flickerFlames) do
		local flicker = math.sin(time * data.speed + data.phase) * 0.08
		flicker += math.sin(time * data.speed * 1.5 + data.phase * 1.1) * 0.05
		local scale = 1 + flicker * 0.08
		data.flame.Size = Vector3.new(
			data.baseSize.X * scale,
			data.baseSize.Y * (1 + flicker * 0.1),
			data.baseSize.Z * scale
		)
	end
	
	-- Subtle bonfire flicker
	for _, data in ipairs(bonfireLights) do
		local flicker = math.sin(time * 3 + data.phase) * 0.15
		flicker += math.sin(time * 2 + data.phase * 1.5) * 0.1
		data.light.Brightness = data.baseBrightness + flicker
	end
	
	-- Subtle checkpoint light pulse
	for _, data in ipairs(checkpointLights) do
		local pulse = math.sin(time * 1.5) * 0.2 + 0.8  -- Range: 0.6 to 1.0
		data.light.Brightness = data.baseBrightness * pulse
	end
	
	-- NOTE: Fill lights and chandelier lights are NOT flickered - they stay stable
end)