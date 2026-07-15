local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")

local showFinalPlaceSuccess = ReplicatedStorage:WaitForChild("ShowFinalPlaceSuccess")
local danceAnimation = ServerStorage:WaitForChild("FinalPlaceDanceAnimation")
local finishTimer = ServerScriptService:WaitForChild("FinishTimer")

local function playSoundOnce(name: string, parent: Instance)
	local template = SoundService:FindFirstChild(name)
	if not template or not template:IsA("Sound") or template.SoundId == "" then return end
	local sound = template:Clone()
	sound.Name = name .. "_Playback"
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

local function findChildByTrimmedName(parent: Instance, expectedName: string): Instance?
	for _, child in ipairs(parent:GetChildren()) do
		if string.gsub(child.Name, "^%s*(.-)%s*$", "%1") == expectedName then
			return child
		end
	end
	return nil
end

local forest = findChildByTrimmedName(workspace, "Forest")
local finalPlace = findChildByTrimmedName(workspace, "FinalPlace")
local teleportModel = forest and forest:FindFirstChild("Teleport")
local portal = teleportModel and teleportModel:FindFirstChild("Portal")
local dancePlatform = finalPlace and finalPlace:FindFirstChild("Stud Grass Platform")

if not finalPlace or not finalPlace:IsA("Model") or not portal or not portal:IsA("BasePart") then
	warn("[ForestPortal] Teleport.Portal or FinalPlace was not found.")
	return
end

local portalText = portal:FindFirstChild("PortalText")
if not portalText then
	portalText = Instance.new("BillboardGui")
	portalText.Name = "PortalText"
	portalText.Adornee = portal
	portalText.Size = UDim2.fromOffset(240, 70)
	portalText.StudsOffset = Vector3.new(0, 5, 0)
	portalText.AlwaysOnTop = false
	portalText.MaxDistance = 32
	portalText.LightInfluence = 0
	portalText.Parent = portal

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = "COME HERE"
	label.TextSize = 48
	label.TextColor3 = Color3.fromRGB(255, 225, 115)
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.2
	label.Parent = portalText
end

local activeDanceTracks: {[Player]: AnimationTrack} = {}
local danceDebounce: {[Player]: boolean} = {}

local function playFinalPlaceDance(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not danceAnimation:IsA("Animation") then
		return
	end

	local previousTrack = activeDanceTracks[player]
	if previousTrack then
		previousTrack:Stop(0.15)
		previousTrack:Destroy()
	end

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid

	local track = animator:LoadAnimation(danceAnimation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	track:Play(0.15)
	activeDanceTracks[player] = track

	task.delay(20, function()
		if activeDanceTracks[player] == track and track.IsPlaying then
			track:Stop(0.2)
		end
		if activeDanceTracks[player] == track then
			activeDanceTracks[player] = nil
		end
		if track.Parent then
			track:Destroy()
		end
		danceDebounce[player] = nil
	end)
end

if dancePlatform then
	for _, platformPart in ipairs(dancePlatform:GetDescendants()) do
		if platformPart:IsA("BasePart") then
			platformPart.CanTouch = true
			platformPart.Touched:Connect(function(hit: BasePart)
				local character = hit:FindFirstAncestorOfClass("Model")
				local player = character and Players:GetPlayerFromCharacter(character)
				if not player or danceDebounce[player] then
					return
				end
				danceDebounce[player] = true
				playSoundOnce("Success Jingle", platformPart)
				playFinalPlaceDance(player, character)
			end)
		end
	end
else
	warn("[ForestPortal] Stud Grass Platform was not found in FinalPlace.")
end

local recordsByUserId: {[number]: {playerName: string, totalTime: number}} = {}
local ROW_COUNT = 5

local function formatTime(totalTime: number): string
	local minutes = math.floor(totalTime / 60)
	local seconds = totalTime - minutes * 60
	return string.format("%02d:%05.2f", minutes, seconds)
end

local function getLeaderboardRows(): {TextLabel}?
	local leaderboard = finalPlace:FindFirstChild("Most Donated Leaderboard")
	local meshBoard = leaderboard and findChildByTrimmedName(leaderboard, "MeshBoard")
	if not meshBoard or not meshBoard:IsA("BasePart") then
		warn("[ForestPortal] Most Donated Leaderboard.MeshBoard was not found.")
		return nil
	end

	local gui = meshBoard:FindFirstChild("CompletionBoardUI")
	if not gui then
		gui = Instance.new("SurfaceGui")
		gui.Name = "CompletionBoardUI"
		gui.Face = Enum.NormalId.Left
		gui.AlwaysOnTop = false
		gui.LightInfluence = 0.4
		gui.PixelsPerStud = 45
		gui.Parent = meshBoard

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromScale(0.08, 0.05)
		title.Size = UDim2.fromScale(0.84, 0.14)
		title.Font = Enum.Font.GothamBlack
		title.Text = "ESCAPE RECORDS"
		title.TextColor3 = Color3.fromRGB(255, 220, 120)
		title.TextScaled = true
		title.Parent = gui

		local rowsFrame = Instance.new("Frame")
		rowsFrame.Name = "Rows"
		rowsFrame.BackgroundTransparency = 1
		rowsFrame.Position = UDim2.fromScale(0.08, 0.22)
		rowsFrame.Size = UDim2.fromScale(0.84, 0.7)
		rowsFrame.Parent = gui

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0.035, 0)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = rowsFrame

		for index = 1, ROW_COUNT do
			local row = Instance.new("TextLabel")
			row.Name = "Row" .. index
			row.LayoutOrder = index
			row.Size = UDim2.fromScale(1, 0.165)
			row.BackgroundColor3 = Color3.fromRGB(35, 24, 18)
			row.BackgroundTransparency = 0.25
			row.BorderSizePixel = 0
			row.Font = Enum.Font.GothamBold
			row.TextColor3 = Color3.fromRGB(245, 245, 245)
			row.TextScaled = true
			row.Text = string.format("%d. ---", index)
			row.Parent = rowsFrame
		end
	end

	local rows = {}
	for index = 1, ROW_COUNT do
		local row = gui:FindFirstChild("Rows") and gui.Rows:FindFirstChild("Row" .. index)
		if row and row:IsA("TextLabel") then
			table.insert(rows, row)
		end
	end
	return rows
end

local function updateLeaderboard(player: Player, totalTime: number)
	local previousRecord = recordsByUserId[player.UserId]
	if previousRecord and previousRecord.totalTime <= totalTime then
		return
	end
	recordsByUserId[player.UserId] = {playerName = player.Name, totalTime = totalTime}

	local records = {}
	for _, record in pairs(recordsByUserId) do
		table.insert(records, record)
	end
	table.sort(records, function(first, second)
		return first.totalTime < second.totalTime
	end)

	local rows = getLeaderboardRows()
	if not rows then
		return
	end

	for index, row in ipairs(rows) do
		local record = records[index]
		row.Text = record and string.format("%d. %s  %s", index, record.playerName, formatTime(record.totalTime))
			or string.format("%d. ---", index)
	end
end

local debounce: {[Player]: boolean} = {}
portal.Touched:Connect(function(hit: BasePart)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player or debounce[player] then
		return
	end

	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	debounce[player] = true
	local ambient = SoundService:FindFirstChild("Dungeon Ambient Loop")
	if ambient and ambient:IsA("Sound") then
		ambient:Stop()
	end
	local teleportSound = SoundService:FindFirstChild("Portal Teleport")
	if teleportSound and teleportSound:IsA("Sound") and teleportSound.SoundId ~= "" then
		local playback = teleportSound:Clone()
		playback.Name = "Portal Teleport_Playback"
		playback.Parent = portal
		playback:Play()
		playback.Ended:Connect(function() playback:Destroy() end)
	end
	-- Use only the destination's world position.  FinalPlace has a rotated model
	-- pivot, so copying its full CFrame can rotate a character onto their head.
	local finalCFrame, finalSize = finalPlace:GetBoundingBox()
	local uprightSpawnPosition = finalCFrame.Position + Vector3.new(0, finalSize.Y / 2 + 4, 0)
	character:PivotTo(CFrame.new(uprightSpawnPosition))
	if finishTimer:IsA("BindableFunction") then
		local totalTime = finishTimer:Invoke(player)
		if typeof(totalTime) == "number" then
			updateLeaderboard(player, totalTime)
		end
	end
	showFinalPlaceSuccess:FireClient(player)
	-- A character has several touching parts; keep this active while the success
	-- notification is on screen so one portal use cannot show it repeatedly.
	task.delay(6, function()
		debounce[player] = nil
	end)
end)
