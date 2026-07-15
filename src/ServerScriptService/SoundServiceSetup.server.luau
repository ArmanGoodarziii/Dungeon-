local SoundService = game:GetService("SoundService")

local soundNames = {
	"Dungeon Ambient Loop", "Checkpoint Activated", "Respawn on Checkpoint",
	"Door Opening", "Portal Teleport", "Success Jingle", "Arrow Trap Shoot",
	"Pendulum Axe Swing", "Flame Trap Ignite", "Rotating Blade Spin", "Smash Trap Slam",
	"Falling Floor Collapse", "Floor Vent Opening", "Sphere Trap Roll", "Guard Alert", "Guard Attack",
}

for _, name in ipairs(soundNames) do
	local sound = SoundService:FindFirstChild(name)
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = ""
		sound.Volume = 0.5
		sound.Parent = SoundService
	end
	if name == "Dungeon Ambient Loop" then
		sound.Looped = true
		sound.Volume = 0.25
		sound.Playing = true
	end
end
