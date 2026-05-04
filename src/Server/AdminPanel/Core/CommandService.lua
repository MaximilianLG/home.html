--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.AdminPanel.Constants)
local Types = require(ReplicatedStorage.AdminPanel.Types)
local Util = require(ReplicatedStorage.AdminPanel.Util)
local Config = require(script.Parent.Config)
local RateLimiter = require(script.Parent.RateLimiter)
local CommandParser = require(script.Parent.CommandParser)
local CommandRegistry = require(script.Parent.CommandRegistry)
local AuditLogService = require(script.Parent.AuditLogService)

type RankService = any
type CommandDefinition = Types.CommandDefinition
type CommandResult = Types.CommandResult
type CommandContext = Types.CommandContext

local CommandService = {}
CommandService.__index = CommandService

export type CommandService = typeof(setmetatable({
	_rankService = nil :: RankService?,
	_registry = CommandRegistry.new(),
	_auditLog = AuditLogService.new(),
	_rateLimiter = RateLimiter.new(Constants.RATE_LIMIT_WINDOW, Constants.DEFAULT_RATE_LIMIT_REQUESTS),
	_cooldowns = {} :: { [number]: { [string]: number } },
}, CommandService))

local function getTargetUserIds(values: { any }): { number }
	local ids = {}
	for _, value in values do
		if typeof(value) == "Instance" and value:IsA("Player") then
			table.insert(ids, value.UserId)
		elseif typeof(value) == "table" then
			for _, nested in value do
				if typeof(nested) == "Instance" and nested:IsA("Player") then
					table.insert(ids, nested.UserId)
				end
			end
		end
	end
	return ids
end

local function stringifyArgs(args: { any }): { string }
	local result = {}
	for _, arg in args do
		if typeof(arg) == "Instance" and arg:IsA("Player") then
			table.insert(result, arg.Name)
		elseif typeof(arg) == "table" then
			local names = {}
			for _, item in arg do
				if typeof(item) == "Instance" and item:IsA("Player") then
					table.insert(names, item.Name)
				else
					table.insert(names, Util.sanitizeForLog(item))
				end
			end
			table.insert(result, table.concat(names, ","))
		else
			table.insert(result, Util.sanitizeForLog(arg))
		end
	end
	return result
end

function CommandService.new(rankService: RankService): CommandService
	return setmetatable({
		_rankService = rankService,
		_registry = CommandRegistry.new(),
		_auditLog = AuditLogService.new(),
		_rateLimiter = RateLimiter.new(Constants.RATE_LIMIT_WINDOW, Constants.DEFAULT_RATE_LIMIT_REQUESTS),
		_cooldowns = {},
	}, CommandService)
end

function CommandService.getRegistry(self: CommandService): any
	return self._registry
end

function CommandService.getAuditLog(self: CommandService): any
	return self._auditLog
end

function CommandService.getCommandsForPlayer(self: CommandService, player: Player): { CommandDefinition }
	local commands = {}
	local rankService = self._rankService :: RankService
	for _, command in self._registry:getAll() do
		local minRank = Config.CommandRankOverrides[command.name] or command.minRank
		if rankService:hasRank(player.UserId, minRank) then
			table.insert(commands, command)
		end
	end
	return commands
end

function CommandService._checkCooldown(
	self: CommandService,
	player: Player,
	command: CommandDefinition
): (boolean, number)
	local rankService = self._rankService :: RankService
	local rank = rankService:getPlayerRank(player)
	local userCooldowns = self._cooldowns[player.UserId]
	if userCooldowns == nil then
		userCooldowns = {}
		self._cooldowns[player.UserId] = userCooldowns
	end

	local now = os.clock()
	local nextAllowed = userCooldowns[command.name] or 0
	if nextAllowed > now then
		return false, nextAllowed - now
	end

	local baseCooldown = Config.CommandCooldownOverrides[command.name] or command.cooldownSeconds
	local cooldown = math.max(0, baseCooldown * rank.commandCooldownMultiplier)
	userCooldowns[command.name] = now + cooldown
	return true, 0
end

function CommandService.executeText(self: CommandService, player: Player, rawText: string): CommandResult
	local parsed = CommandParser.parseMessage(rawText)
	if not parsed.isCommand then
		return { success = false, message = parsed.message }
	end
	return self:executeParsed(player, parsed.commandName, parsed.args, rawText)
end

function CommandService.executeParsed(
	self: CommandService,
	player: Player,
	commandName: string,
	rawArgs: { string },
	rawText: string?
): CommandResult
	local rankService = self._rankService :: RankService
	local rank = rankService:getPlayerRank(player)
	local rateLimit = Config.RateLimitsByRank[rank.id] or Constants.DEFAULT_RATE_LIMIT_REQUESTS
	local allowed, retryAfter = self._rateLimiter:check(`cmd:{player.UserId}`, rateLimit)
	if not allowed then
		return { success = false, message = `Rate limited. Try again in {math.ceil(retryAfter)}s.` }
	end

	local command = self._registry:get(commandName)
	if command == nil then
		return { success = false, message = `Unknown command {commandName}` }
	end

	local requiredRank = Config.CommandRankOverrides[command.name] or command.minRank
	if not rankService:hasRank(player.UserId, requiredRank) then
		self._auditLog:add(
			AuditLogService.createCommandEntry(
				player,
				rank.id,
				command.name,
				rawArgs,
				{},
				"Denied: insufficient rank",
				"Warning",
				{}
			)
		)
		return { success = false, message = "Insufficient permissions" }
	end

	local cooldownOk, cooldownRemaining = self:_checkCooldown(player, command)
	if not cooldownOk then
		return { success = false, message = `Command cooldown: {string.format("%.1f", cooldownRemaining)}s` }
	end

	local argsOk, resolvedArgs, argMessage = CommandParser.resolveArguments(player, command.args, rawArgs)
	if not argsOk then
		return { success = false, message = argMessage }
	end

	for _, targetUserId in getTargetUserIds(resolvedArgs) do
		local canTarget, reason = rankService:canTarget(player.UserId, targetUserId)
		if not canTarget then
			self._auditLog:add(
				AuditLogService.createCommandEntry(
					player,
					rank.id,
					command.name,
					rawArgs,
					{ targetUserId },
					`Denied: {reason}`,
					"Warning",
					{}
				)
			)
			return { success = false, message = reason }
		end
	end

	local context: CommandContext = {
		executor = player,
		executorRank = rank,
		rawText = rawText or command.name,
		commandName = command.name,
		args = resolvedArgs,
		metadata = {},
		createdAt = Util.now(),
	}

	local ok, result = pcall(function()
		return command.run(context)
	end)

	local finalResult: CommandResult
	if ok then
		finalResult = result :: CommandResult
	else
		finalResult = { success = false, message = `Command failed: {result}` }
	end

	self._auditLog:add(
		AuditLogService.createCommandEntry(
			player,
			rank.id,
			command.name,
			stringifyArgs(resolvedArgs),
			getTargetUserIds(resolvedArgs),
			finalResult.message,
			if finalResult.success then "Info" else "High",
			{ success = finalResult.success }
		)
	)

	return finalResult
end

function CommandService.start(self: CommandService)
	self._registry:loadDefaultCommands()
	Players.PlayerRemoving:Connect(function(player)
		self._cooldowns[player.UserId] = nil
		self._rateLimiter:clear(`cmd:{player.UserId}`)
	end)
end

return CommandService
