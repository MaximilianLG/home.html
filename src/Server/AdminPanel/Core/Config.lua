--!strict

local Config = {}

Config.Prefix = "!"
Config.AllowSlashCommands = true
Config.BrandName = "Forge X Admin"
Config.Theme = "Obsidian"
Config.OwnerUserIds = {
	[1563775035] = true,
}
Config.DiscordWebhookUrl = ""
Config.EnableDiscordWebhook = false
Config.EnableHotReload = true
Config.EnablePrivateAdminChat = true
Config.EnableMacroSystem = true
Config.EnableDataStoreEditor = true
Config.EnableScriptExecutor = false
Config.RequireExecutorConfirmation = true
Config.MaxMacroCommands = 20
Config.CommandLogRetentionDays = 30
Config.AllowTargetingOfflineUsers = true
Config.AdminProtectionEnabled = true
Config.Ranks = {
	[0] = {
		id = 0,
		name = "Player",
		priority = 0,
		color = Color3.fromRGB(180, 180, 180),
		commandCooldownMultiplier = 1,
		canTargetSameRank = false,
		canTargetHigherRank = false,
	},
	[10] = {
		id = 10,
		name = "Helper",
		priority = 10,
		color = Color3.fromRGB(95, 200, 255),
		commandCooldownMultiplier = 1,
		canTargetSameRank = false,
		canTargetHigherRank = false,
	},
	[25] = {
		id = 25,
		name = "Trial Moderator",
		priority = 25,
		color = Color3.fromRGB(90, 255, 160),
		commandCooldownMultiplier = 0.9,
		canTargetSameRank = false,
		canTargetHigherRank = false,
	},
	[50] = {
		id = 50,
		name = "Moderator",
		priority = 50,
		color = Color3.fromRGB(80, 220, 120),
		commandCooldownMultiplier = 0.8,
		canTargetSameRank = false,
		canTargetHigherRank = false,
	},
	[100] = {
		id = 100,
		name = "Admin",
		priority = 100,
		color = Color3.fromRGB(255, 190, 75),
		commandCooldownMultiplier = 0.65,
		canTargetSameRank = false,
		canTargetHigherRank = false,
	},
	[200] = {
		id = 200,
		name = "Co-Owner",
		priority = 200,
		color = Color3.fromRGB(255, 120, 120),
		commandCooldownMultiplier = 0.35,
		canTargetSameRank = false,
		canTargetHigherRank = false,
	},
	[255] = {
		id = 255,
		name = "Owner",
		priority = 255,
		color = Color3.fromRGB(255, 80, 220),
		commandCooldownMultiplier = 0.2,
		canTargetSameRank = true,
		canTargetHigherRank = false,
	},
}

Config.CommandRankOverrides = {}
Config.DisabledCommands = {}
Config.CommandAliases = {}
Config.CommandCooldownOverrides = {}
Config.RateLimitsByRank = {
	[0] = 0,
	[10] = 10,
	[25] = 12,
	[50] = 16,
	[100] = 22,
	[200] = 28,
	[255] = 40,
}
Config.ThemePalette = {
	Background = Color3.fromRGB(12, 14, 19),
	Surface = Color3.fromRGB(22, 25, 33),
	SurfaceAlt = Color3.fromRGB(31, 35, 46),
	Text = Color3.fromRGB(245, 247, 255),
	MutedText = Color3.fromRGB(158, 166, 184),
	Accent = Color3.fromRGB(97, 135, 255),
	Danger = Color3.fromRGB(255, 86, 86),
	Success = Color3.fromRGB(78, 220, 142),
	Warning = Color3.fromRGB(255, 193, 84),
}

return Config
