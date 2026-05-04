--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Theme = require(script.Parent.Parent.Theme)

local New = Fusion.New
local Children = Fusion.Children

return function(props: { Size: UDim2?, Position: UDim2?, Children: any? })
	return New("Frame")({
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.fromScale(0, 0),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		[Children] = {
			New("UICorner")({ CornerRadius = Theme.Radius }),
			New("UIStroke")({ Color = Theme.SurfaceAlt, Thickness = 1, Transparency = 0.2 }),
			props.Children,
		},
	})
end
