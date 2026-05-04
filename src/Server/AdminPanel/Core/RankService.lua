--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.AdminPanel.Constants)
local Types = require(ReplicatedStorage.AdminPanel.Types)
local Util = require(ReplicatedStorage.AdminPanel.Util)
local Config = require(script.Parent.Config)
local DataStoreWrapper = require(script.Parent.DataStoreServiceWrapper)

type RankDefinition = Types.RankDefinition
type UserRankRecord = Types.UserRankRecord

local RankService = {}
RankService.__index = RankService

export type RankService = typeof(setmetatable({
	_rankStore = DataStoreWrapper.new(Constants.RANK_DATASTORE),
	_playerRanks = {} :: { [number]: UserRankRecord },
	_rankChanged = Instance.new("BindableEvent"),
}, RankService))

local DEFAULT_RANK_RECORD: UserRankRecord = table.freeze({
	userId = 0,
	rankId = 0,
	assignedBy = 0,
	assignedAt = 0,
	expiresAt = nil,
	reason = "Default player rank",
	version = Constants.DATASTORE_VERSION,
}) :: UserRankRecord

local function getRankKey(userId: number): string
	return `user:{userId}`
end

local function normalizeRecord(userId: number, value: any): UserRankRecord
	if typeof(value) ~= "table" then
		local record = table.clone(DEFAULT_RANK_RECORD)
		record.userId = userId
		return record
	end

	local rankId = if typeof(value.rankId) == "number" then value.rankId else 0
	if Config.Ranks[rankId] == nil then
		rankId = 0
	end

	return {
		userId = userId,
		rankId = rankId,
		assignedBy = if typeof(value.assignedBy) == "number" then value.assignedBy else 0,
		assignedAt = if typeof(value.assignedAt) == "number" then value.assignedAt else 0,
		expiresAt = if typeof(value.expiresAt) == "number" then value.expiresAt else nil,
		reason = if typeof(value.reason) == "string" then value.reason else "Migrated rank record",
		version = Constants.DATASTORE_VERSION,
	}
end

function RankService.new(): RankService
	return setmetatable({
		_rankStore = DataStoreWrapper.new(Constants.RANK_DATASTORE),
		_playerRanks = {},
		_rankChanged = Instance.new("BindableEvent"),
	}, RankService)
end

function RankService.getRankChangedSignal(self: RankService): RBXScriptSignal
	return self._rankChanged.Event
end

function RankService.getRankDefinition(_self: RankService, rankId: number): RankDefinition
	local definition = Config.Ranks[rankId]
	if definition ~= nil then
		return definition
	end
	return Config.Ranks[0]
end

function RankService.getRankRecord(self: RankService, userId: number): UserRankRecord
	local cached = self._playerRanks[userId]
	if cached ~= nil then
		local now = Util.now()
		if cached.expiresAt ~= nil and cached.expiresAt <= now then
			self._playerRanks[userId] = normalizeRecord(userId, nil)
			return self._playerRanks[userId]
		end
		return cached
	end

	return normalizeRecord(userId, nil)
end

function RankService.getPlayerRank(self: RankService, player: Player): RankDefinition
	if Config.OwnerUserIds[player.UserId] == true then
		return self:getRankDefinition(255)
	end
	return self:getRankDefinition(self:getRankRecord(player.UserId).rankId)
end

function RankService.getUserRankId(self: RankService, userId: number): number
	if Config.OwnerUserIds[userId] == true then
		return 255
	end
	return self:getRankRecord(userId).rankId
end

function RankService.hasRank(self: RankService, userId: number, minimumRankId: number): boolean
	local actual = self:getRankDefinition(self:getUserRankId(userId))
	local required = self:getRankDefinition(minimumRankId)
	return actual.priority >= required.priority
end

function RankService.canTarget(self: RankService, actorUserId: number, targetUserId: number): (boolean, string)
	if actorUserId == targetUserId then
		return true, "Self-target"
	end
	if not Config.AdminProtectionEnabled then
		return true, "Protection disabled"
	end

	local actorRank = self:getRankDefinition(self:getUserRankId(actorUserId))
	local targetRank = self:getRankDefinition(self:getUserRankId(targetUserId))
	if targetRank.priority <= 0 then
		return true, "Target is player"
	end
	if targetRank.priority > actorRank.priority then
		if actorRank.canTargetHigherRank then
			return true, "Override can target higher rank"
		end
		return false, `Cannot target higher rank {targetRank.name}`
	end
	if targetRank.priority == actorRank.priority and not actorRank.canTargetSameRank then
		return false, `Cannot target same rank {targetRank.name}`
	end
	return true, "Allowed"
end

function RankService.loadUserRank(self: RankService, userId: number): UserRankRecord
	local result = self._rankStore:getAsync(getRankKey(userId))
	local record = normalizeRecord(userId, if result.success then result.value else nil)
	if record.expiresAt ~= nil and record.expiresAt <= Util.now() then
		record = normalizeRecord(userId, nil)
		task.spawn(function()
			self._rankStore:setAsync(getRankKey(userId), record)
		end)
	end
	self._playerRanks[userId] = record
	return record
end

function RankService.assignRank(
	self: RankService,
	targetUserId: number,
	rankId: number,
	assignedBy: number,
	reason: string,
	expiresAt: number?
): (boolean, string, UserRankRecord?)
	if Config.Ranks[rankId] == nil then
		return false, `Unknown rank id {rankId}`, nil
	end

	local record: UserRankRecord = {
		userId = targetUserId,
		rankId = rankId,
		assignedBy = assignedBy,
		assignedAt = Util.now(),
		expiresAt = expiresAt,
		reason = reason,
		version = Constants.DATASTORE_VERSION,
	}

	local result = self._rankStore:updateAsync(getRankKey(targetUserId), function(_old: any)
		return record
	end)
	if not result.success then
		return false, result.error or "Failed to save rank", nil
	end

	self._playerRanks[targetUserId] = record
	self._rankChanged:Fire(targetUserId, record)
	return true, "Rank assigned", record
end

function RankService.clearRank(
	self: RankService,
	targetUserId: number,
	assignedBy: number,
	reason: string
): (boolean, string)
	local ok, message = self:assignRank(targetUserId, 0, assignedBy, reason, nil)
	return ok, message
end

function RankService.onPlayerAdded(self: RankService, player: Player)
	task.spawn(function()
		self:loadUserRank(player.UserId)
		self._rankChanged:Fire(player.UserId, self:getRankRecord(player.UserId))
	end)
end

function RankService.onPlayerRemoving(self: RankService, player: Player)
	self._playerRanks[player.UserId] = nil
end

function RankService.start(self: RankService)
	for _, player in Players:GetPlayers() do
		self:onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerRemoving(player)
	end)
end

return RankService
