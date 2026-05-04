--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "rank",
	aliases = { "setrank" },
	description = "Assign an admin rank to a player.",
	category = "Moderation",
	minRank = 200,
	cooldownSeconds = 3,
	args = {
		{ name = "target", kind = "player", required = true, description = "Target player" },
		{ name = "rank", kind = "rank", required = true, description = "Rank ID or name" },
		{
			name = "reason",
			kind = "string",
			required = false,
			description = "Assignment reason",
			default = "Rank updated",
		},
	},
	run = function(context)
		local target = context.args[1] :: Player
		local rankId = context.args[2] :: number
		local reason = context.args[3] :: string
		local serviceRef = ServerScriptService.AdminPanel:FindFirstChild("Runtime")
		if serviceRef == nil then
			return { success = false, message = "Rank service unavailable" }
		end
		local rankServiceValue = serviceRef:FindFirstChild("RankService")
		if rankServiceValue == nil or not rankServiceValue:IsA("ObjectValue") then
			return { success = false, message = "Rank service unavailable" }
		end
		local binder = rankServiceValue.Value
		if binder == nil or not binder:IsA("BindableFunction") then
			return { success = false, message = "Rank service unavailable" }
		end
		local ok, message = binder:Invoke("assignRank", target.UserId, rankId, context.executor.UserId, reason, nil)
		return { success = ok, message = if ok then `Assigned rank {rankId} to {target.Name}` else message }
	end,
}

return command
