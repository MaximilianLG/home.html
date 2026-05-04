--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)
local Config = require(script.Parent.Parent.Parent.Core.Config)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "execute",
	aliases = { "runlua" },
	description = "Execute a restricted Luau snippet when explicitly enabled in config.",
	category = "Developer",
	minRank = 255,
	cooldownSeconds = 10,
	args = {
		{ name = "code", kind = "string", required = true, description = "Luau source" },
	},
	run = function(context)
		if not Config.EnableScriptExecutor then
			return { success = false, message = "Script executor is disabled in Config.EnableScriptExecutor" }
		end
		local source = context.args[1] :: string
		if string.find(source, "require", 1, true) or string.find(source, "HttpService", 1, true) then
			return { success = false, message = "Rejected restricted source" }
		end
		local fn, compileError = loadstring(source)
		if fn == nil then
			return { success = false, message = compileError or "Compile failed" }
		end
		local ok, result = pcall(fn)
		return { success = ok, message = if ok then `Executed: {tostring(result)}` else `Runtime error: {result}` }
	end,
}

return command
