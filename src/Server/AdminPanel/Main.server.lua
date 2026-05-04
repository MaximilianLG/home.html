--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RankService = require(script.Parent.Core.RankService)
local BanService = require(script.Parent.Core.BanService)
local CommandService = require(script.Parent.Core.CommandService)
local RemoteService = require(script.Parent.Network.RemoteService)

local rankService = RankService.new()
local banService = BanService.new()
local commandService = CommandService.new(rankService)
local remoteService = RemoteService.new(commandService, rankService)

local runtime = Instance.new("Folder")
runtime.Name = "Runtime"
runtime.Parent = script.Parent

local rankBinder = Instance.new("BindableFunction")
rankBinder.Name = "RankServiceBinder"
rankBinder.OnInvoke = function(action: string, ...)
	if action == "assignRank" then
		return rankService:assignRank(...)
	elseif action == "clearRank" then
		return rankService:clearRank(...)
	end
	return false, "Unknown rank action"
end
rankBinder.Parent = runtime

local rankServiceRef = Instance.new("ObjectValue")
rankServiceRef.Name = "RankService"
rankServiceRef.Value = rankBinder
rankServiceRef.Parent = runtime

local banBinder = Instance.new("BindableFunction")
banBinder.Name = "BanServiceBinder"
banBinder.OnInvoke = function(action: string, ...)
	if action == "ban" then
		return banService:ban(...)
	elseif action == "unban" then
		return banService:unban(...)
	elseif action == "warn" then
		return banService:warn(...)
	end
	return false, "Unknown ban action"
end
banBinder.Parent = runtime

local banServiceRef = Instance.new("ObjectValue")
banServiceRef.Name = "BanService"
banServiceRef.Value = banBinder
banServiceRef.Parent = runtime

rankService:start()
banService:start()
commandService:start()
remoteService:start()

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		commandService:executeText(player, message)
	end)
end)

for _, player in Players:GetPlayers() do
	player.Chatted:Connect(function(message)
		commandService:executeText(player, message)
	end)
end

print("Forge X Admin started")
