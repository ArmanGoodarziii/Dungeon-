local players = game:GetService("Players")

local RedGreenFloorModule = {}

function RedGreenFloorModule.Start()
	local floorFolder = game.Workspace:WaitForChild("RedGreenFloors")

	local function IsRed(part)
		local color = part.Color
		-- The placed red tiles use a dark crimson (R ~= 0.20), so an
		-- absolute R > 0.4 check never matched them.
		return color.R > 0.1 and color.R > color.G * 1.5 and color.R > color.B * 1.5
	end

	local function KillPlayerFromCharacter(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.Health = 0
		end
	end

	local function SetupFloor(part)
		if not part:IsA("BasePart") then return end
		if not IsRed(part) then return end
		if part:GetAttribute("RedFloorConnected") then return end
		part:SetAttribute("RedFloorConnected", true)

		part.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = players:GetPlayerFromCharacter(character)

			if player then
				KillPlayerFromCharacter(character)
			end
		end)
	end

	for _, model in pairs(floorFolder:GetChildren()) do
		if model:IsA("Model") then
			for _, part in ipairs(model:GetDescendants()) do
				SetupFloor(part)
			end
		elseif model:IsA("BasePart") then
			SetupFloor(model)
		end
	end

	floorFolder.ChildAdded:Connect(function(model)
		if model:IsA("Model") then
			for _, part in ipairs(model:GetDescendants()) do
				SetupFloor(part)
			end
		elseif model:IsA("BasePart") then
			SetupFloor(model)
		end
	end)
end

return RedGreenFloorModule
