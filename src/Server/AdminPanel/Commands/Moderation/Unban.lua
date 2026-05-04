--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "unban",
	aliases = {},
	description = "Unban a user by UserId.",
	category = "Moderation",
	minRank = 50,
	cooldownSeconds = 2,
	args = {
		{ name = "userId", kind = "number", required = true, description = "Roblox UserId", min = 1 },
		{
			name = "reason",
			kind = "string",
			required = false,
			description = "Unban reason",
			default = "Unbanned by an administrator",
		},
	},
	run = function(context)
		local userId = math.floor(context.args[1] :: number)
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
		local ok, message = (value.Value :: BindableFunction):Invoke("unban", userId, context.executor.UserId, reason)
		return { success = ok, message = message }
	end,
}

return command
