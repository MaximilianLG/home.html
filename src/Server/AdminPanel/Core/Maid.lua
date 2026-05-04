--!strict

export type MaidTask = RBXScriptConnection | Instance | thread | (() -> ())

local Maid = {}
Maid.__index = Maid

export type Maid = typeof(setmetatable({
	_tasks = {} :: { MaidTask },
}, Maid))

function Maid.new(): Maid
	return setmetatable({
		_tasks = {},
	}, Maid)
end

function Maid.give(self: Maid, task: MaidTask): MaidTask
	table.insert(self._tasks, task)
	return task
end

function Maid.cleanup(self: Maid)
	for index = #self._tasks, 1, -1 do
		local task = self._tasks[index]
		self._tasks[index] = nil
		local kind = typeof(task)
		if kind == "RBXScriptConnection" then
			(task :: RBXScriptConnection):Disconnect()
		elseif kind == "Instance" then
			(task :: Instance):Destroy()
		elseif kind == "thread" then
			task.cancel(task :: thread)
		elseif kind == "function" then
			(task :: () -> ())()
		end
	end
end

function Maid.destroy(self: Maid)
	self:cleanup()
end

return Maid
