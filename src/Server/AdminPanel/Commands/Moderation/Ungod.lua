--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "ungod",
	aliases = {},
	description = "Reset target players to normal health.",
	category = "Moderation",
	minRank = 100,
	cooldownSeconds = 1,
	args = {
		{ name = "targets", kind = "players", required = true, description = "Target players" },
	},
	run = function(context)
		local targets = context.args[1] :: { Player }
		for _, target in targets do
			local humanoid = if target.Character ~= nil then target.Character:FindFirstChildOfClass("Humanoid") else nil
			if humanoid ~= nil then
				humanoid.MaxHealth = 100
				humanoid.Health = 100
			end
		end
		return { success = true, message = `Disabled godmode for {#targets} player(s)` }
	end,
}

return command
