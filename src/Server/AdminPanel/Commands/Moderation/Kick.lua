--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "kick",
	aliases = { "boot" },
	description = "Kick a player from the server with a reason.",
	category = "Moderation",
	minRank = 50,
	cooldownSeconds = 2,
	args = {
		{ name = "target", kind = "player", required = true, description = "Player to kick" },
		{
			name = "reason",
			kind = "string",
			required = false,
			description = "Kick reason",
			default = "Kicked by an administrator",
		},
	},
	run = function(context)
		local target = context.args[1] :: Player
		local reason = context.args[2] :: string
		target:Kick(`Kicked: {reason}`)
		return { success = true, message = `Kicked {target.Name}: {reason}` }
	end,
}

return command
