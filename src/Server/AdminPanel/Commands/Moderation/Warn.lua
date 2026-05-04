--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "warn",
	aliases = {},
	description = "Issue a warning to a player.",
	category = "Moderation",
	minRank = 25,
	cooldownSeconds = 2,
	args = {
		{ name = "target", kind = "player", required = true, description = "Target player" },
		{ name = "reason", kind = "string", required = true, description = "Warning reason" },
	},
	run = function(context)
		local target = context.args[1] :: Player
		local reason = context.args[2] :: string
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
			"warn",
			target.UserId,
			context.executor.UserId,
			reason
		)
		return { success = ok, message = if ok then `Warned {target.Name}: {reason}` else message }
	end,
}

return command
