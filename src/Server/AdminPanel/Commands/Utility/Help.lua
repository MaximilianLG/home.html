--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "help",
	aliases = { "commands", "cmds" },
	description = "Show command help in the audit result.",
	category = "Utility",
	minRank = 10,
	cooldownSeconds = 1,
	args = {},
	run = function(_context)
		return { success = true, message = "Open the Forge X Admin panel with Ctrl+; to view commands." }
	end,
}

return command
