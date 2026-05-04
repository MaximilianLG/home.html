--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Theme = require(script.Parent.Parent.Theme)
local Panel = require(script.Parent.Parent.Components.Panel)

local New = Fusion.New
local Children = Fusion.Children

return function(props: { State: any })
	return New("Frame")({
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		[Children] = {
			New("UIListLayout")({ Padding = UDim.new(0, 12), FillDirection = Enum.FillDirection.Vertical }),
			Panel({
				Size = UDim2.new(1, 0, 0, 110),
				Children = {
					New("TextLabel")({
						Text = "Forge X Admin Dashboard",
						Font = Theme.BoldFont,
						TextSize = 24,
						TextColor3 = Theme.Text,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -32, 0, 40),
						Position = UDim2.fromOffset(16, 12),
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					New("TextLabel")({
						Text = "Secure server-authoritative moderation, audit logging, rank control, and live ops tooling.",
						Font = Theme.Font,
						TextSize = 15,
						TextColor3 = Theme.MutedText,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -32, 0, 44),
						Position = UDim2.fromOffset(16, 54),
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
				},
			}),
			Panel({
				Size = UDim2.new(1, 0, 1, -122),
				Children = {
					New("TextLabel")({
						Text = "Use the tabs to manage players, execute commands, inspect logs, and adjust server settings.",
						Font = Theme.Font,
						TextSize = 16,
						TextColor3 = Theme.Text,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -32, 0, 60),
						Position = UDim2.fromOffset(16, 16),
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
				},
			}),
		},
	})
end
