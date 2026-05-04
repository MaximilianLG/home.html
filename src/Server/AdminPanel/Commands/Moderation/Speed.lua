--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "speed",
	aliases = { "walkspeed" },
	description = "Set WalkSpeed for target players.",
	category = "Moderation",
	minRank = 50,
	cooldownSeconds = 1,
	args = {
		{ name = "targets", kind = "players", required = true, description = "Target players" },
		{ name = "speed", kind = "number", required = true, description = "WalkSpeed", min = 0, max = 200 },
	},
	run = function(context)
		local targets = context.args[1] :: { Player }
		local speed = context.args[2] :: number
		for _, target in targets do
			local humanoid = if target.Character ~= nil then target.Character:FindFirstChildOfClass("Humanoid") else nil
			if humanoid ~= nil then
				humanoid.WalkSpeed = speed
			end
		end
		return { success = true, message = `Set speed to {speed} for {#targets} player(s)` }
	end,
}

return command
