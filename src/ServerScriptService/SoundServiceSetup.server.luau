local SoundService = game:GetService("SoundService")

local soundNames = {
	"Dungeon Ambient Loop", "Dungeon Room Ambience", "Forest Ambient Loop", "Final Place Ambient Loop",
	"Player Footsteps - Stone", "Player Footsteps - Grass", "Timer Start", "Timer Tick", "Timer Warning", "Timer Complete",
	"Checkpoint Activated", "Checkpoint Respawn", "Door Opening", "Door Closing", "Portal Activation", "Teleport Whoosh",
	"Success Jingle", "Victory Dance Music", "Arrow Trap Shoot", "Arrow Trap Impact", "Pendulum Axe Swing", "Pendulum Axe Impact",
	"Pendulum Swing", "Flame Trap Ignite", "Flame Trap Burst", "Rotating Blade Spin", "Blade Trap Impact", "Smash Trap Slam",
	"Smash Trap Retract", "Falling Floor Crack", "Falling Floor Collapse", "Floor Vent Opening", "Sphere Trap Roll",
	"Sphere Trap Impact", "Guard Footsteps", "Guard Alert", "Guard Attack", "Guard Capture", "Player Death",
	"UI Button Hover", "UI Button Click",
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
