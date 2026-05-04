--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.AdminPanel.Constants)
local Types = require(ReplicatedStorage.AdminPanel.Types)
local Util = require(ReplicatedStorage.AdminPanel.Util)
local Config = require(script.Parent.Config)
local DataStoreWrapper = require(script.Parent.DataStoreServiceWrapper)

type AuditLogEntry = Types.AuditLogEntry

local AuditLogService = {}
AuditLogService.__index = AuditLogService

export type AuditLogService = typeof(setmetatable({
	_store = DataStoreWrapper.new(Constants.AUDIT_DATASTORE),
	_recent = {} :: { AuditLogEntry },
	_logAdded = Instance.new("BindableEvent"),
}, AuditLogService))

function AuditLogService.new(): AuditLogService
	return setmetatable({
		_store = DataStoreWrapper.new(Constants.AUDIT_DATASTORE),
		_recent = {},
		_logAdded = Instance.new("BindableEvent"),
	}, AuditLogService)
end

function AuditLogService.getLogAddedSignal(self: AuditLogService): RBXScriptSignal
	return self._logAdded.Event
end

function AuditLogService.getRecent(self: AuditLogService, limit: number?): { AuditLogEntry }
	local count = math.min(limit or Constants.MAX_RECENT_LOGS_REPLICATED, #self._recent)
	local result = table.create(count)
	for index = 1, count do
		result[index] = self._recent[#self._recent - count + index]
	end
	return result
end

function AuditLogService.add(self: AuditLogService, entry: AuditLogEntry)
	table.insert(self._recent, entry)
	while #self._recent > Constants.MAX_RECENT_LOGS_REPLICATED do
		table.remove(self._recent, 1)
	end
	self._logAdded:Fire(entry)

	task.spawn(function()
		local dayKey = os.date("!%Y-%m-%d", entry.timestamp)
		self._store:updateAsync(`logs:{dayKey}`, function(old: any)
			local logs = if typeof(old) == "table" then old else {}
			table.insert(logs, entry)
			if #logs > 1000 then
				table.remove(logs, 1)
			end
			return logs
		end)
	end)

	if
		Config.EnableDiscordWebhook
		and Config.DiscordWebhookUrl ~= ""
		and (entry.severity == "High" or entry.severity == "Critical")
	then
		task.spawn(function()
			local payload = {
				username = "Forge X Admin",
				embeds = {
					{
						title = `{entry.severity}: {entry.command}`,
						description = entry.result,
						color = if entry.severity == "Critical" then 16724787 else 16763904,
						fields = {
							{
								name = "Executor",
								value = `{entry.executorName} ({entry.executorUserId})`,
								inline = true,
							},
							{ name = "Server", value = game.JobId, inline = true },
							{ name = "Arguments", value = table.concat(entry.arguments, " "), inline = false },
						},
					},
				},
			}
			pcall(function()
				HttpService:PostAsync(
					Config.DiscordWebhookUrl,
					HttpService:JSONEncode(payload),
					Enum.HttpContentType.ApplicationJson
				)
			end)
		end)
	end
end

function AuditLogService.createCommandEntry(
	_executor: Player,
	executorRankId: number,
	command: string,
	arguments: { string },
	targetUserIds: { number },
	result: string,
	severity: Types.AuditSeverity,
	metadata: { [string]: any }?
): AuditLogEntry
	local safeArgs = {}
	for index, argument in arguments do
		if index > Constants.MAX_AUDIT_ARGUMENTS then
			break
		end
		table.insert(safeArgs, Util.sanitizeForLog(argument))
	end

	return {
		id = Util.uuid(),
		timestamp = Util.now(),
		serverJobId = game.JobId,
		placeId = game.PlaceId,
		executorUserId = _executor.UserId,
		executorName = _executor.Name,
		executorRankId = executorRankId,
		command = command,
		arguments = safeArgs,
		targetUserIds = targetUserIds,
		result = result,
		severity = severity,
		metadata = metadata or {},
	}
end

return AuditLogService
