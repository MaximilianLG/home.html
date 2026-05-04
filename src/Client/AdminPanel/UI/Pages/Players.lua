--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.Components.Button)

local New = Fusion.New
local Children = Fusion.Children
local ForPairs = Fusion.ForPairs

return function(props: { State: any, Client: any })
	local players = props.State.players
	return New("ScrollingFrame")({
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		[Children] = {
			New("UIListLayout")({ Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical }),
			ForPairs(players, function(userId, snapshot)
				return userId,
					New("Frame")({
						Size = UDim2.new(1, -8, 0, 74),
						BackgroundColor3 = Theme.Surface,
						BorderSizePixel = 0,
						[Children] = {
							New("UICorner")({ CornerRadius = Theme.Radius }),
							New("TextLabel")({
								Text = `{snapshot.displayName} (@{snapshot.name})`,
								Font = Theme.BoldFont,
								TextSize = 15,
								TextColor3 = Theme.Text,
								BackgroundTransparency = 1,
								Position = UDim2.fromOffset(14, 8),
								Size = UDim2.new(1, -360, 0, 24),
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
							New("TextLabel")({
								Text = `{snapshot.rankName} • {snapshot.team} • {snapshot.ping}ms`,
								Font = Theme.Font,
								TextSize = 13,
								TextColor3 = Theme.MutedText,
								BackgroundTransparency = 1,
								Position = UDim2.fromOffset(14, 36),
								Size = UDim2.new(1, -360, 0, 20),
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
							Button({
								Text = "Kick",
								Color = Theme.Warning,
								Size = UDim2.fromOffset(74, 32),
								OnClick = function()
									props.Client:invoke(
										"executeCommand",
										{ commandName = "kick", args = { snapshot.name, "Kicked from admin panel" } }
									)
								end,
							}) :: any,
						},
					})
			end),
		},
	})
end
