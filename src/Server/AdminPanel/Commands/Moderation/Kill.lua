--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "kill",
	aliases = { "slay" },
	description = "Set target player health to zero.",
	category = "Moderation",
	minRank = 50,
	cooldownSeconds = 1,
	args = {
		{ name = "targets", kind = "players", required = true, description = "Players to kill" },
	},
	run = function(context)
		local targets = context.args[1] :: { Player }
		for _, target in targets do
			local character = target.Character
			local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
			if humanoid ~= nil then
				humanoid.Health = 0
			end
		end
		return { success = true, message = `Killed {#targets} player(s)` }
	end,
}

return command
