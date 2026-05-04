--!strict

local Theme = {
	Background = Color3.fromRGB(12, 14, 19),
	Surface = Color3.fromRGB(22, 25, 33),
	SurfaceAlt = Color3.fromRGB(31, 35, 46),
	Text = Color3.fromRGB(245, 247, 255),
	MutedText = Color3.fromRGB(158, 166, 184),
	Accent = Color3.fromRGB(97, 135, 255),
	Danger = Color3.fromRGB(255, 86, 86),
	Success = Color3.fromRGB(78, 220, 142),
	Warning = Color3.fromRGB(255, 193, 84),
	Radius = UDim.new(0, 12),
	Font = Enum.Font.Gotham,
	BoldFont = Enum.Font.GothamBold,
}

return table.freeze(Theme)
