--!strict

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type Bucket = {
	windowStart: number,
	count: number,
	blockedUntil: number,
}

export type RateLimiter = typeof(setmetatable({
	_windowSeconds = 0,
	_defaultLimit = 0,
	_buckets = {} :: { [string]: Bucket },
}, RateLimiter))

function RateLimiter.new(windowSeconds: number, defaultLimit: number): RateLimiter
	return setmetatable({
		_windowSeconds = windowSeconds,
		_defaultLimit = defaultLimit,
		_buckets = {},
	}, RateLimiter)
end

function RateLimiter.check(self: RateLimiter, key: string, limitOverride: number?): (boolean, number)
	local now = os.clock()
	local bucket = self._buckets[key]
	if bucket == nil then
		bucket = {
			windowStart = now,
			count = 0,
			blockedUntil = 0,
		}
		self._buckets[key] = bucket
	end

	if bucket.blockedUntil > now then
		return false, bucket.blockedUntil - now
	end

	if now - bucket.windowStart >= self._windowSeconds then
		bucket.windowStart = now
		bucket.count = 0
	end

	bucket.count += 1
	local limit = limitOverride or self._defaultLimit
	if limit <= 0 or bucket.count > limit then
		bucket.blockedUntil = now + self._windowSeconds
		return false, self._windowSeconds
	end

	return true, 0
end

function RateLimiter.clear(self: RateLimiter, key: string)
	self._buckets[key] = nil
end

function RateLimiter.sweep(self: RateLimiter)
	local now = os.clock()
	for key, bucket in self._buckets do
		if now - bucket.windowStart > self._windowSeconds * 4 then
			self._buckets[key] = nil
		end
	end
end

return RateLimiter
