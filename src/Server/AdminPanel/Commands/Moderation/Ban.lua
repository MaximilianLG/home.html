--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "ban",
	aliases = { "tempban", "permban" },
	description = "Ban a player for a duration or permanently.",
	category = "Moderation",
	minRank = 50,
	cooldownSeconds = 3,
	args = {
		{ name = "target", kind = "player", required = true, description = "Target player" },
		{
			name = "duration",
			kind = "duration",
			required = false,
			description = "Duration like 1h, 7d, permanent",
			default = nil,
		},
		{
			name = "reason",
			kind = "string",
			required = false,
			description = "Ban reason",
			default = "Banned by an administrator",
		},
	},
	run = function(context)
		local target = context.args[1] :: Player
		local duration = context.args[2] :: number?
		local reason = context.args[3] :: string
		local runtime = ServerScriptService.AdminPanel:FindFirstChild("Runtime")
		local value = if runtime ~= nil then runtime:FindFirstChild("BanService") else nil
		if
			value == nil
			or not value:IsA("ObjectValue")
			or value.Value == nil
			or not value.Value:IsA("BindableFunction")
		then
			return { success = false, message = "Ban service unavailable" }
		end
		local ok, message = (value.Value :: BindableFunction):Invoke(
			"ban",
			target.UserId,
			context.executor.UserId,
			reason,
			duration
		)
		return { success = ok, message = if ok then `Banned {target.Name}: {reason}` else message }
	end,
}

return command
