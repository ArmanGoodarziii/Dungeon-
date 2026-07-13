-- SphereTrapScript
-- Uses SphereTrapModule to manage all sphere traps found in the workspace.
-- NOTE: This must be a Script (Server Script), not a LocalScript, since it
-- reads Workspace, controls physics (CanCollide/Anchored/Velocity), and
-- kills players via Humanoid.Health — none of which should run on the client.

local SphereTrapModule = require(script.Parent.SphereTrapModule)

-- Create controllers for all existing sphere traps
local traps = SphereTrapModule.createAllFromWorkspace()
print("[SphereTrapScript] Loaded " .. #traps .. " sphere trap(s)")

-- Handle sphere traps added to the workspace later (e.g., during dungeon generation)
game.Workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "SphereTrap" and descendant:FindFirstChild("Sphere") and descendant:FindFirstChild("Trigger") then
		local trap = SphereTrapModule.new(descendant)
		table.insert(traps, trap)
		print("[SphereTrapScript] New sphere trap detected: " .. descendant:GetFullName())
	end
end)