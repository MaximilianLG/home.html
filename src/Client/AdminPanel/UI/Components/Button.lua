--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Theme = require(script.Parent.Parent.Theme)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

return function(props: { Text: string, Color: Color3?, Size: UDim2?, OnClick: (() -> ())? })
	return New("TextButton")({
		Text = props.Text,
		Font = Theme.BoldFont,
		TextSize = 14,
		TextColor3 = Theme.Text,
		BackgroundColor3 = props.Color or Theme.Accent,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(120, 36),
		AutoButtonColor = true,
		[OnEvent("Activated")] = props.OnClick,
		[Children] = {
			New("UICorner")({ CornerRadius = Theme.Radius }),
			New("UIPadding")({ PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
		},
	})
end
