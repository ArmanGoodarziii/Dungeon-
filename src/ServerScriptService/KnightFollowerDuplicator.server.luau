local knightPairs = {
	{"NewKnight", "NewKnight_Follower"},
	{"Knight", "Knight_Follower"},
	{"Undead Knight", "Undead Knight_Follower"},
}

for _, pair in ipairs(knightPairs) do
	local original = workspace:FindFirstChild(pair[1])
	if original and original:IsA("Model") and not workspace:FindFirstChild(pair[2]) then
		local follower = original:Clone()
		follower.Name = pair[2]
		follower.Parent = workspace
		follower:PivotTo(original:GetPivot() * CFrame.new(4, 0, 0))
	end
end
