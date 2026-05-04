--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local AdminClient = require(script.Parent.Network.AdminClient)
local Theme = require(script.Parent.UI.Theme)
local Button = require(script.Parent.UI.Components.Button)
local Dashboard = require(script.Parent.UI.Pages.Dashboard)
local PlayersPage = require(script.Parent.UI.Pages.Players)
local LogsPage = require(script.Parent.UI.Pages.Logs)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues
local OnEvent = Fusion.OnEvent

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local client = AdminClient.new()

local state = {
	open = Value(false),
	page = Value("Dashboard"),
	players = Value({}),
	logs = Value({}),
	commands = Value({}),
	rank = Value(nil),
}

local bootstrap = client:invoke("bootstrap", {})
if not bootstrap.success then
	return
end

local function playersArrayToMap(playersArray: { any }): { [number]: any }
	local map = {}
	for _, snapshot in playersArray do
		map[snapshot.userId] = snapshot
	end
	return map
end

local function logsArrayToMap(logsArray: { any }): { [string]: any }
	local map = {}
	for _, log in logsArray do
		map[log.id] = log
	end
	return map
end

state.players:set(playersArrayToMap(bootstrap.payload.players or {}))
state.logs:set(logsArrayToMap(bootstrap.payload.logs or {}))
state.commands:set(bootstrap.payload.commands or {})
state.rank:set(bootstrap.payload.rank)

client:on("playersUpdated", function(payload)
	state.players:set(playersArrayToMap(payload.players or {}))
end)

client:on("logAdded", function(payload)
	local logs = table.clone(state.logs:get())
	logs[payload.entry.id] = payload.entry
	state.logs:set(logs)
end)

local pages = { "Dashboard", "Players", "Commands", "Logs", "Settings" }

local function renderContent()
	return Computed(function()
		local page = state.page:get()
		if page == "Dashboard" then
			return Dashboard({ State = state })
		elseif page == "Players" then
			return PlayersPage({ State = state, Client = client })
		elseif page == "Logs" then
			return LogsPage({ State = state })
		else
			return New("TextLabel")({
				Text = `{page} is ready for extension through ModuleScripts.`,
				Font = Theme.Font,
				TextSize = 16,
				TextColor3 = Theme.Text,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			})
		end
	end)
end

local gui = New("ScreenGui")({
	Name = "ForgeXAdmin",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = playerGui,
	[Children] = {
		New("Frame")({
			Visible = state.open,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.35,
			[Children] = {
				New("Frame")({
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(0.82, 0.78),
					BackgroundColor3 = Theme.Background,
					BorderSizePixel = 0,
					[Children] = {
						New("UICorner")({ CornerRadius = UDim.new(0, 18) }),
						New("UIStroke")({ Color = Theme.Accent, Thickness = 1, Transparency = 0.35 }),
						New("Frame")({
							Size = UDim2.new(0, 180, 1, 0),
							BackgroundColor3 = Theme.Surface,
							BorderSizePixel = 0,
							[Children] = {
								New("UICorner")({ CornerRadius = UDim.new(0, 18) }),
								New("TextLabel")({
									Text = "Forge X Admin",
									Font = Theme.BoldFont,
									TextSize = 18,
									TextColor3 = Theme.Text,
									BackgroundTransparency = 1,
									Size = UDim2.new(1, -24, 0, 56),
									Position = UDim2.fromOffset(12, 8),
								}),
								New("Frame")({
									BackgroundTransparency = 1,
									Position = UDim2.fromOffset(14, 76),
									Size = UDim2.new(1, -28, 1, -90),
									[Children] = {
										New("UIListLayout")({ Padding = UDim.new(0, 8) }),
										ForValues(pages, function(page)
											return Button({
												Text = page,
												Color = Computed(function()
													return if state.page:get() == page
														then Theme.Accent
														else Theme.SurfaceAlt
												end),
												Size = UDim2.new(1, 0, 0, 36),
												OnClick = function()
													state.page:set(page)
												end,
											})
										end),
									},
								}),
							},
						}),
						New("Frame")({
							BackgroundTransparency = 1,
							Position = UDim2.fromOffset(200, 24),
							Size = UDim2.new(1, -224, 1, -48),
							[Children] = { renderContent() },
						}),
						New("TextButton")({
							Text = "×",
							Font = Theme.BoldFont,
							TextSize = 24,
							TextColor3 = Theme.Text,
							BackgroundTransparency = 1,
							AnchorPoint = Vector2.new(1, 0),
							Position = UDim2.new(1, -14, 0, 8),
							Size = UDim2.fromOffset(42, 42),
							[OnEvent("Activated")] = function()
								state.open:set(false)
							end,
						}),
					},
				}),
			},
		}),
	},
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Semicolon and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		state.open:set(not state.open:get())
	end
end)

return gui
