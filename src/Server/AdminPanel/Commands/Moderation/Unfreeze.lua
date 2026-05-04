--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "unfreeze",
	aliases = { "unanchor" },
	description = "Unfreeze target players.",
	category = "Moderation",
	minRank = 50,
	cooldownSeconds = 1,
	args = {
		{ name = "targets", kind = "players", required = true, description = "Players to unfreeze" },
	},
	run = function(context)
		local targets = context.args[1] :: { Player }
		for _, target in targets do
			local character = target.Character
			local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
			if root ~= nil and root:IsA("BasePart") then
				root.Anchored = false
			end
		end
		return { success = true, message = `Unfroze {#targets} player(s)` }
	end,
}

return command
