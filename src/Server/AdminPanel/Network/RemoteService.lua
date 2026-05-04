--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.AdminPanel.Constants)
local Types = require(ReplicatedStorage.AdminPanel.Types)
local RateLimiter = require(script.Parent.Parent.Core.RateLimiter)

local RemoteService = {}
RemoteService.__index = RemoteService

type CommandService = any
type RankService = any

export type RemoteService = typeof(setmetatable({
	_commandService = nil :: CommandService?,
	_rankService = nil :: RankService?,
	_folder = nil :: Folder?,
	_event = nil :: RemoteEvent?,
	_function = nil :: RemoteFunction?,
	_limiter = RateLimiter.new(10, 30),
}, RemoteService))

local function publicCommand(command: Types.CommandDefinition): { [string]: any }
	local args = {}
	for _, arg in command.args do
		table.insert(args, {
			name = arg.name,
			kind = arg.kind,
			required = arg.required,
			description = arg.description,
			values = arg.values,
		})
	end
	return {
		name = command.name,
		aliases = command.aliases,
		description = command.description,
		category = command.category,
		minRank = command.minRank,
		args = args,
		cooldownSeconds = command.cooldownSeconds,
	}
end

function RemoteService.new(commandService: CommandService, rankService: RankService): RemoteService
	return setmetatable({
		_commandService = commandService,
		_rankService = rankService,
		_folder = nil,
		_event = nil,
		_function = nil,
		_limiter = RateLimiter.new(10, 30),
	}, RemoteService)
end

function RemoteService._ensureRemotes(self: RemoteService)
	local folder = ReplicatedStorage:FindFirstChild(Constants.REMOTE_FOLDER_NAME)
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = Constants.REMOTE_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	local event = folder:FindFirstChild(Constants.NETWORK_EVENT_NAME)
	if event == nil then
		event = Instance.new("RemoteEvent")
		event.Name = Constants.NETWORK_EVENT_NAME
		event.Parent = folder
	end

	local remoteFunction = folder:FindFirstChild(Constants.NETWORK_FUNCTION_NAME)
	if remoteFunction == nil then
		remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = Constants.NETWORK_FUNCTION_NAME
		remoteFunction.Parent = folder
	end

	self._folder = folder :: Folder
	self._event = event :: RemoteEvent
	self._function = remoteFunction :: RemoteFunction
end

function RemoteService._canUsePanel(self: RemoteService, player: Player): boolean
	local rankService = self._rankService :: RankService
	return rankService:hasRank(player.UserId, 10)
end

function RemoteService._handleInvoke(self: RemoteService, player: Player, request: any): Types.RemoteResponse
	if typeof(request) ~= "table" then
		return { success = false, requestId = "", message = "Invalid request" }
	end

	local requestId = if typeof(request.requestId) == "string" then request.requestId else ""
	local action = if typeof(request.action) == "string" then request.action else ""
	local allowed = self._limiter:check(`remote:{player.UserId}`, 30)
	if not allowed then
		return { success = false, requestId = requestId, message = "Rate limited" }
	end
	if not self:_canUsePanel(player) then
		return { success = false, requestId = requestId, message = "Insufficient permissions" }
	end

	local commandService = self._commandService :: CommandService
	local rankService = self._rankService :: RankService

	if action == "bootstrap" then
		local commands = {}
		for _, command in commandService:getCommandsForPlayer(player) do
			table.insert(commands, publicCommand(command))
		end
		return {
			success = true,
			requestId = requestId,
			message = "OK",
			payload = {
				rank = rankService:getPlayerRank(player),
				commands = commands,
				logs = commandService:getAuditLog():getRecent(100),
				players = self:_getPlayerSnapshots(),
			},
		}
	elseif action == "executeCommand" then
		local payload = if typeof(request.payload) == "table" then request.payload else {}
		local commandName = if typeof(payload.commandName) == "string" then payload.commandName else ""
		local args = if typeof(payload.args) == "table" then payload.args else {}
		local stringArgs = {}
		for _, arg in args do
			table.insert(stringArgs, tostring(arg))
		end
		local result = commandService:executeParsed(player, commandName, stringArgs, commandName)
		return {
			success = result.success,
			requestId = requestId,
			message = result.message,
			payload = { data = result.data },
		}
	end

	return { success = false, requestId = requestId, message = "Unknown action" }
end

function RemoteService._getPlayerSnapshots(self: RemoteService): { { [string]: any } }
	local rankService = self._rankService :: RankService
	local snapshots = {}
	for _, player in Players:GetPlayers() do
		local rank = rankService:getPlayerRank(player)
		table.insert(snapshots, {
			userId = player.UserId,
			name = player.Name,
			displayName = player.DisplayName,
			rankId = rank.id,
			rankName = rank.name,
			team = if player.Team ~= nil then player.Team.Name else "",
			ping = math.floor(player:GetNetworkPing() * 1000),
		})
	end
	return snapshots
end

function RemoteService.broadcast(self: RemoteService, action: string, payload: { [string]: any })
	local event = self._event :: RemoteEvent
	for _, player in Players:GetPlayers() do
		if self:_canUsePanel(player) then
			event:FireClient(player, action, payload)
		end
	end
end

function RemoteService.start(self: RemoteService)
	self:_ensureRemotes()
	local remoteFunction = self._function :: RemoteFunction
	remoteFunction.OnServerInvoke = function(player: Player, request: any)
		return self:_handleInvoke(player, request)
	end

	local commandService = self._commandService :: CommandService
	commandService:getAuditLog():getLogAddedSignal():Connect(function(entry: Types.AuditLogEntry)
		self:broadcast("logAdded", { entry = entry })
	end)

	Players.PlayerAdded:Connect(function()
		self:broadcast("playersUpdated", { players = self:_getPlayerSnapshots() })
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(function()
			self:broadcast("playersUpdated", { players = self:_getPlayerSnapshots() })
		end)
	end)
end

return RemoteService
