--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.AdminPanel.Constants)
local Util = require(ReplicatedStorage.AdminPanel.Util)

local AdminClient = {}
AdminClient.__index = AdminClient

export type AdminClient = typeof(setmetatable({
	_event = nil :: RemoteEvent?,
	_function = nil :: RemoteFunction?,
	_listeners = {} :: { [string]: { (any) -> () } },
}, AdminClient))

function AdminClient.new(): AdminClient
	local folder = ReplicatedStorage:WaitForChild(Constants.REMOTE_FOLDER_NAME)
	local event = folder:WaitForChild(Constants.NETWORK_EVENT_NAME) :: RemoteEvent
	local remoteFunction = folder:WaitForChild(Constants.NETWORK_FUNCTION_NAME) :: RemoteFunction
	local self = setmetatable({
		_event = event,
		_function = remoteFunction,
		_listeners = {},
	}, AdminClient)
	event.OnClientEvent:Connect(function(action: string, payload: any)
		local listeners = self._listeners[action]
		if listeners ~= nil then
			for _, listener in listeners do
				listener(payload)
			end
		end
	end)
	return self
end

function AdminClient.on(self: AdminClient, action: string, callback: (any) -> ())
	local listeners = self._listeners[action]
	if listeners == nil then
		listeners = {}
		self._listeners[action] = listeners
	end
	table.insert(listeners, callback)
	return function()
		local index = table.find(listeners, callback)
		if index ~= nil then
			table.remove(listeners, index)
		end
	end
end

function AdminClient.invoke(self: AdminClient, action: string, payload: { [string]: any }): any
	local remoteFunction = self._function :: RemoteFunction
	return remoteFunction:InvokeServer({
		action = action,
		requestId = Util.uuid(),
		payload = payload,
		clientTimestamp = os.clock(),
	})
end

return AdminClient
