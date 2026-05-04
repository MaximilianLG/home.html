--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "invisible",
	aliases = { "invis" },
	description = "Make target player characters invisible server-side.",
	category = "Moderation",
	minRank = 100,
	cooldownSeconds = 1,
	args = {
		{ name = "targets", kind = "players", required = true, description = "Target players" },
	},
	run = function(context)
		local targets = context.args[1] :: { Player }
		for _, target in targets do
			local character = target.Character
			if character ~= nil then
				for _, descendant in character:GetDescendants() do
					if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
						descendant.Transparency = 1
					elseif descendant:IsA("Decal") then
						descendant.Transparency = 1
					end
				end
			end
		end
		return { success = true, message = `Made {#targets} player(s) invisible` }
	end,
}

return command
