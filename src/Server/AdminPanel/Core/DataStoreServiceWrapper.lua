--!strict

local DataStoreService = game:GetService("DataStoreService")
local Constants = require(game:GetService("ReplicatedStorage").AdminPanel.Constants)

local Wrapper = {}
Wrapper.__index = Wrapper

export type Result<T> = {
	success: boolean,
	value: T?,
	error: string?,
}

export type DataStoreWrapper = typeof(setmetatable({
	_name = "",
	_store = DataStoreService:GetDataStore(""),
}, Wrapper))

local function waitForRetry(attempt: number)
	local jitter = math.random() * 0.2
	task.wait((Constants.DATASTORE_RETRY_BASE_DELAY * (2 ^ (attempt - 1))) + jitter)
end

function Wrapper.new(name: string): DataStoreWrapper
	return setmetatable({
		_name = name,
		_store = DataStoreService:GetDataStore(name),
	}, Wrapper)
end

function Wrapper.getAsync<T>(self: DataStoreWrapper, key: string): Result<T>
	for attempt = 1, Constants.MAX_DATASTORE_RETRIES do
		local ok, value = pcall(function()
			return self._store:GetAsync(key)
		end)
		if ok then
			return { success = true, value = value :: T }
		end
		if attempt < Constants.MAX_DATASTORE_RETRIES then
			waitForRetry(attempt)
		else
			return { success = false, error = tostring(value) }
		end
	end

	return { success = false, error = "Unexpected DataStore failure" }
end

function Wrapper.setAsync<T>(self: DataStoreWrapper, key: string, value: T): Result<T>
	for attempt = 1, Constants.MAX_DATASTORE_RETRIES do
		local ok, err = pcall(function()
			self._store:SetAsync(key, value)
		end)
		if ok then
			return { success = true, value = value }
		end
		if attempt < Constants.MAX_DATASTORE_RETRIES then
			waitForRetry(attempt)
		else
			return { success = false, error = tostring(err) }
		end
	end

	return { success = false, error = "Unexpected DataStore failure" }
end

function Wrapper.updateAsync<T>(self: DataStoreWrapper, key: string, transform: (T?) -> T?): Result<T>
	for attempt = 1, Constants.MAX_DATASTORE_RETRIES do
		local ok, result = pcall(function()
			return self._store:UpdateAsync(key, transform)
		end)
		if ok then
			return { success = true, value = result :: T }
		end
		if attempt < Constants.MAX_DATASTORE_RETRIES then
			waitForRetry(attempt)
		else
			return { success = false, error = tostring(result) }
		end
	end

	return { success = false, error = "Unexpected DataStore failure" }
end

return Wrapper
