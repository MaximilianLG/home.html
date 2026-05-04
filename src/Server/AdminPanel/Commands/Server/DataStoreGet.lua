--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)
local Config = require(script.Parent.Parent.Parent.Core.Config)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "datastoreget",
	aliases = { "dsget" },
	description = "Read a DataStore key for high-rank admins.",
	category = "Developer",
	minRank = 200,
	cooldownSeconds = 5,
	args = {
		{ name = "store", kind = "string", required = true, description = "Store name" },
		{ name = "key", kind = "string", required = true, description = "Key" },
	},
	run = function(context)
		if not Config.EnableDataStoreEditor then
			return { success = false, message = "DataStore editor disabled" }
		end
		local storeName = context.args[1] :: string
		local key = context.args[2] :: string
		local store = DataStoreService:GetDataStore(storeName)
		local ok, value = pcall(function()
			return store:GetAsync(key)
		end)
		return { success = ok, message = if ok then `Read {storeName}/{key}` else `Read failed: {value}`, data = value }
	end,
}

return command
