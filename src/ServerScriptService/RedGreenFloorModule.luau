local players = game:GetService("Players")

local RedGreenFloorModule = {}

function RedGreenFloorModule.Start()
	local floorFolder = game.Workspace:WaitForChild("RedGreenFloors")

	local redColor = Color3.fromRGB(117, 0, 0)

	local function IsRed(part)
		local color = part.Color
		return color.R > 0.4 and color.G < 0.3 and color.B < 0.3
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

		part.Touched:Connect(function(hit)
			local character = hit.Parent
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
