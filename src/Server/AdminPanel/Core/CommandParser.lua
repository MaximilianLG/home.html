--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.AdminPanel.Constants)
local Types = require(ReplicatedStorage.AdminPanel.Types)
local Util = require(ReplicatedStorage.AdminPanel.Util)
local Config = require(script.Parent.Config)

type CommandArgument = Types.CommandArgument

type ParseResult = {
	commandName: string,
	args: { string },
	isCommand: boolean,
	message: string,
}

local CommandParser = {}

function CommandParser.parseMessage(message: string): ParseResult
	if #message > Constants.MAX_COMMAND_LENGTH then
		return { commandName = "", args = {}, isCommand = false, message = "Command too long" }
	end

	local trimmed = Util.trim(message)
	local prefix = Config.Prefix
	local slashPrefix = Constants.SLASH_PREFIX
	local startsWithPrefix = string.sub(trimmed, 1, #prefix) == prefix
	local startsWithSlash = Config.AllowSlashCommands and string.sub(trimmed, 1, #slashPrefix) == slashPrefix
	if not startsWithPrefix and not startsWithSlash then
		return { commandName = "", args = {}, isCommand = false, message = "Not a command" }
	end

	local withoutPrefix = if startsWithPrefix
		then string.sub(trimmed, #prefix + 1)
		else string.sub(trimmed, #slashPrefix + 1)
	local parts = Util.splitWords(withoutPrefix)
	local commandName = string.lower(parts[1] or "")
	if commandName == "" then
		return { commandName = "", args = {}, isCommand = false, message = "Missing command name" }
	end
	table.remove(parts, 1)

	for index, arg in parts do
		if #arg > Constants.MAX_ARGUMENT_LENGTH then
			parts[index] = string.sub(arg, 1, Constants.MAX_ARGUMENT_LENGTH)
		end
	end

	return { commandName = commandName, args = parts, isCommand = true, message = "Parsed" }
end

local function parsePlayerToken(token: string): Player?
	local lower = string.lower(token)
	if lower == "me" then
		return nil
	end
	for _, player in Players:GetPlayers() do
		if string.lower(player.Name) == lower or string.lower(player.DisplayName) == lower then
			return player
		end
		if string.sub(string.lower(player.Name), 1, #lower) == lower then
			return player
		end
	end
	return nil
end

function CommandParser.resolveArgument(
	executor: Player,
	definition: CommandArgument,
	raw: string?
): (boolean, any, string)
	if raw == nil or raw == "" then
		if definition.required then
			return false, nil, `Missing required argument {definition.name}`
		end
		return true, definition.default, "Defaulted"
	end

	if definition.kind == "string" then
		return true, raw, "OK"
	elseif definition.kind == "number" then
		local value = tonumber(raw)
		if value == nil then
			return false, nil, `{definition.name} must be a number`
		end
		return true, Util.clampNumber(value, definition.min, definition.max), "OK"
	elseif definition.kind == "boolean" then
		local lower = string.lower(raw)
		if lower == "true" or lower == "yes" or lower == "1" or lower == "on" then
			return true, true, "OK"
		elseif lower == "false" or lower == "no" or lower == "0" or lower == "off" then
			return true, false, "OK"
		end
		return false, nil, `{definition.name} must be true or false`
	elseif definition.kind == "player" then
		local lower = string.lower(raw)
		if lower == "me" then
			return true, executor, "OK"
		end
		local player = parsePlayerToken(raw)
		if player == nil then
			return false, nil, `Could not find player {raw}`
		end
		return true, player, "OK"
	elseif definition.kind == "players" then
		local lower = string.lower(raw)
		if lower == "all" then
			return true, Players:GetPlayers(), "OK"
		elseif lower == "others" then
			local others = {}
			for _, player in Players:GetPlayers() do
				if player ~= executor then
					table.insert(others, player)
				end
			end
			return true, others, "OK"
		elseif lower == "me" then
			return true, { executor }, "OK"
		end
		local player = parsePlayerToken(raw)
		if player == nil then
			return false, nil, `Could not find player {raw}`
		end
		return true, { player }, "OK"
	elseif definition.kind == "duration" then
		local duration = Util.parseDuration(raw)
		if duration == nil and string.lower(raw) ~= "perm" and string.lower(raw) ~= "permanent" then
			return false, nil, `{definition.name} must be a duration like 10m, 2h, 7d, or permanent`
		end
		return true, duration, "OK"
	elseif definition.kind == "enum" then
		local values = definition.values or {}
		local lower = string.lower(raw)
		for _, value in values do
			if string.lower(value) == lower then
				return true, value, "OK"
			end
		end
		return false, nil, `{definition.name} must be one of: {table.concat(values, ", ")}`
	elseif definition.kind == "rank" then
		local rankId = tonumber(raw)
		if rankId ~= nil then
			return true, math.floor(rankId), "OK"
		end
		local lower = string.lower(raw)
		for id, rank in Config.Ranks do
			if string.lower(rank.name) == lower then
				return true, id, "OK"
			end
		end
		return false, nil, `Unknown rank {raw}`
	elseif definition.kind == "json" then
		local ok, decoded = pcall(function()
			return game:GetService("HttpService"):JSONDecode(raw)
		end)
		if not ok then
			return false, nil, `{definition.name} must be valid JSON`
		end
		return true, decoded, "OK"
	end

	return false, nil, `Unsupported argument kind {definition.kind}`
end

function CommandParser.resolveArguments(
	executor: Player,
	definitions: { CommandArgument },
	rawArgs: { string }
): (boolean, { any }, string)
	local resolved = {}
	for index, definition in definitions do
		local raw = rawArgs[index]
		if definition.kind == "string" and index == #definitions and raw ~= nil then
			raw = table.concat(rawArgs, " ", index)
		end
		local ok, value, message = CommandParser.resolveArgument(executor, definition, raw)
		if not ok then
			return false, {}, message
		end
		resolved[index] = value
	end
	return true, resolved, "OK"
end

return CommandParser
