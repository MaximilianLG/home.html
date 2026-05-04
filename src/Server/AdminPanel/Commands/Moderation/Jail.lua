--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
	name = "jail",
	aliases = {},
	description = "Create a simple server-side jail around target players.",
	category = "Moderation",
	minRank = 50,
	cooldownSeconds = 3,
	args = {
		{ name = "targets", kind = "players", required = true, description = "Target players" },
	},
	run = function(context)
		local targets = context.args[1] :: { Player }
		for _, target in targets do
			local character = target.Character
			local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
			if root ~= nil and root:IsA("BasePart") then
				local jail = Instance.new("Model")
				jail.Name = `ForgeXJail_{target.UserId}`
				jail.Parent = workspace
				local center = root.Position
				for index, offset in
					{
						Vector3.new(0, 0, 6),
						Vector3.new(0, 0, -6),
						Vector3.new(6, 0, 0),
						Vector3.new(-6, 0, 0),
						Vector3.new(0, 6, 0),
					}
				do
					local part = Instance.new("Part")
					part.Name = `Wall{index}`
					part.Anchored = true
					part.Size = if index <= 2
						then Vector3.new(12, 12, 1)
						elseif index <= 4 then Vector3.new(1, 12, 12)
						else Vector3.new(12, 1, 12)
					part.CFrame = CFrame.new(center + offset)
					part.Transparency = 0.35
					part.Color = Color3.fromRGB(97, 135, 255)
					part.Parent = jail
				end
			end
		end
		return { success = true, message = `Jailed {#targets} player(s)` }
	end,
}

return command
