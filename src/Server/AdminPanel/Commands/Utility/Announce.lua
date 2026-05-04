--!strict

local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "announce",
	aliases = { "broadcast" },
	description = "Broadcast an announcement to all players.",
	category = "Utility",
	minRank = 50,
	cooldownSeconds = 5,
	args = {
		{ name = "message", kind = "string", required = true, description = "Announcement text" },
	},
	run = function(context)
		local message = context.args[1] :: string
		local channel = TextChatService:FindFirstChild("TextChannels")
		local general = if channel ~= nil then channel:FindFirstChild("RBXGeneral") else nil
		if general ~= nil and general:IsA("TextChannel") then
			general:DisplaySystemMessage(`[ADMIN] {message}`)
		end
		return { success = true, message = `Announced: {message}` }
	end,
}

return command
