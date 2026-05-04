--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.AdminPanel.Constants)
local Types = require(ReplicatedStorage.AdminPanel.Types)
local Util = require(ReplicatedStorage.AdminPanel.Util)
local DataStoreWrapper = require(script.Parent.DataStoreServiceWrapper)

type BanRecord = Types.BanRecord
type WarningRecord = Types.WarningRecord

local BanService = {}
BanService.__index = BanService

export type BanService = typeof(setmetatable({
	_store = DataStoreWrapper.new(Constants.BAN_DATASTORE),
}, BanService))

local function banKey(userId: number): string
	return `ban:{userId}`
end

local function warnKey(userId: number): string
	return `warns:{userId}`
end

local function normalizeBan(userId: number, value: any): BanRecord?
	if typeof(value) ~= "table" then
		return nil
	end
	return {
		userId = userId,
		reason = if typeof(value.reason) == "string" then value.reason else "No reason provided",
		createdAt = if typeof(value.createdAt) == "number" then value.createdAt else Util.now(),
		createdBy = if typeof(value.createdBy) == "number" then value.createdBy else 0,
		expiresAt = if typeof(value.expiresAt) == "number" then value.expiresAt else nil,
		active = if typeof(value.active) == "boolean" then value.active else true,
		version = Constants.DATASTORE_VERSION,
	}
end

function BanService.new(): BanService
	return setmetatable({
		_store = DataStoreWrapper.new(Constants.BAN_DATASTORE),
	}, BanService)
end

function BanService.getBan(self: BanService, userId: number): BanRecord?
	local result = self._store:getAsync(banKey(userId))
	if not result.success then
		return nil
	end
	local ban = normalizeBan(userId, result.value)
	if ban == nil or not ban.active then
		return nil
	end
	if ban.expiresAt ~= nil and ban.expiresAt <= Util.now() then
		self:unban(userId, 0, "Expired automatically")
		return nil
	end
	return ban
end

function BanService.ban(
	self: BanService,
	userId: number,
	createdBy: number,
	reason: string,
	durationSeconds: number?
): (boolean, string)
	local record: BanRecord = {
		userId = userId,
		reason = reason,
		createdAt = Util.now(),
		createdBy = createdBy,
		expiresAt = if durationSeconds == nil then nil else Util.now() + durationSeconds,
		active = true,
		version = Constants.DATASTORE_VERSION,
	}
	local result = self._store:setAsync(banKey(userId), record)
	if not result.success then
		return false, result.error or "Failed to save ban"
	end
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		player:Kick(`Banned: {reason}`)
	end
	return true, "Ban saved"
end

function BanService.unban(self: BanService, userId: number, actorUserId: number, reason: string): (boolean, string)
	local result = self._store:updateAsync(banKey(userId), function(old: any)
		local existing = normalizeBan(userId, old)
		if existing == nil then
			return nil
		end
		existing.active = false
		existing.reason = `{existing.reason} | Unbanned by {actorUserId}: {reason}`
		return existing
	end)
	if not result.success then
		return false, result.error or "Failed to unban"
	end
	return true, "User unbanned"
end

function BanService.warn(
	self: BanService,
	userId: number,
	createdBy: number,
	reason: string
): (boolean, string, WarningRecord?)
	local warning: WarningRecord = {
		id = Util.uuid(),
		userId = userId,
		reason = reason,
		createdAt = Util.now(),
		createdBy = createdBy,
		active = true,
	}
	local result = self._store:updateAsync(warnKey(userId), function(old: any)
		local warnings = if typeof(old) == "table" then old else {}
		table.insert(warnings, warning)
		return warnings
	end)
	if not result.success then
		return false, result.error or "Failed to save warning", nil
	end
	return true, "Warning saved", warning
end

function BanService.onPlayerAdded(self: BanService, player: Player)
	task.spawn(function()
		local ban = self:getBan(player.UserId)
		if ban ~= nil then
			player:Kick(`Banned: {ban.reason}`)
		end
	end)
end

function BanService.start(self: BanService)
	for _, player in Players:GetPlayers() do
		self:onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerAdded(player)
	end)
end

return BanService
