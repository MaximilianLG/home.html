--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "unjail",
	aliases = {},
	description = "Remove Forge X jails for target players.",
	category = "Moderation",
	minRank = 50,
	cooldownSeconds = 1,
	args = {
		{ name = "targets", kind = "players", required = true, description = "Target players" },
	},
	run = function(context)
		local targets = context.args[1] :: { Player }
		for _, target in targets do
			local jail = workspace:FindFirstChild(`ForgeXJail_{target.UserId}`)
			if jail ~= nil then
				jail:Destroy()
			end
		end
		return { success = true, message = `Unjailed {#targets} player(s)` }
	end,
}

return command
