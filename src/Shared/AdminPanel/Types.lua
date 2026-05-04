--!strict

export type RankId = number

export type RankDefinition = {
	id: RankId,
	name: string,
	priority: number,
	color: Color3,
	inheritsFrom: RankId?,
	commandCooldownMultiplier: number,
	canTargetSameRank: boolean,
	canTargetHigherRank: boolean,
}

export type UserRankRecord = {
	userId: number,
	rankId: RankId,
	assignedBy: number,
	assignedAt: number,
	expiresAt: number?,
	reason: string,
	version: number,
}

export type CommandArgKind = "player" | "players" | "number" | "string" | "boolean" | "enum" | "duration" | "rank" | "json"

export type CommandArgument = {
	name: string,
	kind: CommandArgKind,
	required: boolean,
	description: string,
	default: any?,
	min: number?,
	max: number?,
	values: { string }?,
}

export type CommandCategory = "Moderation" | "Utility" | "Teleport" | "Fun" | "Server" | "Developer" | "Settings"

export type CommandContext = {
	executor: Player,
	executorRank: RankDefinition,
	rawText: string,
	commandName: string,
	args: { any },
	metadata: { [string]: any },
	createdAt: number,
}

export type CommandResult = {
	success: boolean,
	message: string,
	data: any?,
}

export type CommandDefinition = {
	name: string,
	aliases: { string },
	description: string,
	category: CommandCategory,
	minRank: RankId,
	args: { CommandArgument },
	cooldownSeconds: number,
	run: (context: CommandContext) -> CommandResult,
}

export type AuditSeverity = "Info" | "Warning" | "High" | "Critical"

export type AuditLogEntry = {
	id: string,
	timestamp: number,
	serverJobId: string,
	placeId: number,
	executorUserId: number,
	executorName: string,
	executorRankId: RankId,
	command: string,
	arguments: { string },
	targetUserIds: { number },
	result: string,
	severity: AuditSeverity,
	metadata: { [string]: any },
}

export type BanRecord = {
	userId: number,
	reason: string,
	createdAt: number,
	createdBy: number,
	expiresAt: number?,
	active: boolean,
	version: number,
}

export type WarningRecord = {
	id: string,
	userId: number,
	reason: string,
	createdAt: number,
	createdBy: number,
	active: boolean,
}

export type RemoteRequest = {
	action: string,
	requestId: string,
	payload: { [string]: any },
	clientTimestamp: number,
}

export type RemoteResponse = {
	success: boolean,
	requestId: string,
	message: string,
	payload: { [string]: any }?,
}

return table.freeze({})
