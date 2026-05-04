--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "teleport",
	aliases = { "tp" },
	description = "Teleport one player to another player.",
	category = "Teleport",
	minRank = 50,
	cooldownSeconds = 1,
	args = {
		{ name = "target", kind = "player", required = true, description = "Player to move" },
		{ name = "destination", kind = "player", required = true, description = "Destination player" },
	},
	run = function(context)
		local target = context.args[1] :: Player
		local destination = context.args[2] :: Player
		local targetRoot = if target.Character ~= nil then target.Character:FindFirstChild("HumanoidRootPart") else nil
		local destinationRoot = if destination.Character ~= nil
			then destination.Character:FindFirstChild("HumanoidRootPart")
			else nil
		if
			targetRoot == nil
			or not targetRoot:IsA("BasePart")
			or destinationRoot == nil
			or not destinationRoot:IsA("BasePart")
		then
			return { success = false, message = "Missing character root part" }
		end
		targetRoot.CFrame = destinationRoot.CFrame * CFrame.new(2, 0, 0)
		return { success = true, message = `Teleported {target.Name} to {destination.Name}` }
	end,
}

return command
