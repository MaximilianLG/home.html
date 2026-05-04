--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "gravity",
	aliases = { "grav" },
	description = "Set workspace gravity.",
	category = "Server",
	minRank = 100,
	cooldownSeconds = 2,
	args = {
		{ name = "gravity", kind = "number", required = true, description = "Gravity value", min = 0, max = 1000 },
	},
	run = function(context)
		local gravity = context.args[1] :: number
		workspace.Gravity = gravity
		return { success = true, message = `Set gravity to {gravity}` }
	end,
}

return command
