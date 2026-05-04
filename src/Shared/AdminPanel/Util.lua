--!strict

local HttpService = game:GetService("HttpService")

local Util = {}

function Util.now(): number
	return DateTime.now().UnixTimestamp
end

function Util.uuid(): string
	return HttpService:GenerateGUID(false)
end

function Util.deepFreeze<T>(value: T): T
	if typeof(value) == "table" then
		for _, child in value :: any do
			Util.deepFreeze(child)
		end
		table.freeze(value :: any)
	end
	return value
end

function Util.copyArray<T>(source: { T }): { T }
	local result = table.create(#source)
	for index, value in source do
		result[index] = value
	end
	return result
end

function Util.trim(value: string): string
	return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

function Util.splitWords(input: string): { string }
	local words = {}
	local current = ""
	local inQuote = false
	local quoteChar = ""
	local escaped = false

	for index = 1, #input do
		local char = string.sub(input, index, index)
		if escaped then
			current ..= char
			escaped = false
		elseif char == "\\" then
			escaped = true
		elseif inQuote then
			if char == quoteChar then
				inQuote = false
				quoteChar = ""
			else
				current ..= char
			end
		elseif char == '"' or char == "'" then
			inQuote = true
			quoteChar = char
		elseif string.match(char, "%s") then
			if current ~= "" then
				table.insert(words, current)
				current = ""
			end
		else
			current ..= char
		end
	end

	if current ~= "" then
		table.insert(words, current)
	end

	return words
end

function Util.sanitizeForLog(value: any): string
	local text = tostring(value)
	text = string.gsub(text, "[%c]", "")
	if #text > 256 then
		return string.sub(text, 1, 253) .. "..."
	end
	return text
end

function Util.clampNumber(value: number, min: number?, max: number?): number
	local result = value
	if min ~= nil and result < min then
		result = min
	end
	if max ~= nil and result > max then
		result = max
	end
	return result
end

function Util.parseDuration(input: string): number?
	local text = string.lower(Util.trim(input))
	if text == "perm" or text == "permanent" or text == "forever" then
		return nil
	end

	local total = 0
	local matched = false
	for amountText, unit in string.gmatch(text, "(%d+)%s*([smhdw])") do
		local amount = tonumber(amountText)
		if amount == nil then
			return nil
		end
		matched = true
		if unit == "s" then
			total += amount
		elseif unit == "m" then
			total += amount * 60
		elseif unit == "h" then
			total += amount * 3600
		elseif unit == "d" then
			total += amount * 86400
		elseif unit == "w" then
			total += amount * 604800
		end
	end

	if matched then
		return total
	end

	local numeric = tonumber(text)
	if numeric ~= nil then
		return math.max(0, math.floor(numeric))
	end

	return nil
end

function Util.formatDuration(seconds: number?): string
	if seconds == nil then
		return "permanent"
	end
	if seconds < 60 then
		return `{seconds}s`
	end
	if seconds < 3600 then
		return `{math.floor(seconds / 60)}m`
	end
	if seconds < 86400 then
		return `{math.floor(seconds / 3600)}h`
	end
	return `{math.floor(seconds / 86400)}d`
end

return Util
