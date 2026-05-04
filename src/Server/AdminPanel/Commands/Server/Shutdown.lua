--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "shutdown",
	aliases = { "stopserver" },
	description = "Shutdown this server with a reason.",
	category = "Server",
	minRank = 200,
	cooldownSeconds = 10,
	args = {
		{
			name = "reason",
			kind = "string",
			required = false,
			description = "Shutdown reason",
			default = "Server shutdown by administrator",
		},
	},
	run = function(context)
		local reason = context.args[1] :: string
		for _, player in Players:GetPlayers() do
			player:Kick(`Server shutdown: {reason}`)
		end
		return { success = true, message = `Shutdown initiated: {reason}` }
	end,
}

return command
