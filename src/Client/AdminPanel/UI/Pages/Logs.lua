--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Theme = require(script.Parent.Parent.Theme)

local New = Fusion.New
local Children = Fusion.Children
local ForPairs = Fusion.ForPairs

return function(props: { State: any })
	return New("ScrollingFrame")({
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		[Children] = {
			New("UIListLayout")({ Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical }),
			ForPairs(props.State.logs, function(id, entry)
				return id,
					New("Frame")({
						Size = UDim2.new(1, -8, 0, 68),
						BackgroundColor3 = Theme.Surface,
						BorderSizePixel = 0,
						[Children] = {
							New("UICorner")({ CornerRadius = Theme.Radius }),
							New("TextLabel")({
								Text = `{entry.executorName} ran {entry.command}`,
								Font = Theme.BoldFont,
								TextSize = 14,
								TextColor3 = Theme.Text,
								BackgroundTransparency = 1,
								Position = UDim2.fromOffset(12, 8),
								Size = UDim2.new(1, -24, 0, 22),
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
							New("TextLabel")({
								Text = `{entry.severity}: {entry.result}`,
								Font = Theme.Font,
								TextSize = 13,
								TextColor3 = Theme.MutedText,
								BackgroundTransparency = 1,
								Position = UDim2.fromOffset(12, 34),
								Size = UDim2.new(1, -24, 0, 22),
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
						},
					})
			end),
		},
	})
end
