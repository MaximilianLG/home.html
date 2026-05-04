--!strict

local Constants = {}

Constants.VERSION = "1.0.0"
Constants.REMOTE_FOLDER_NAME = "ForgeXAdminRemotes"
Constants.NETWORK_EVENT_NAME = "AdminEvent"
Constants.NETWORK_FUNCTION_NAME = "AdminFunction"
Constants.MAX_COMMAND_LENGTH = 512
Constants.MAX_ARGUMENT_LENGTH = 256
Constants.MAX_AUDIT_ARGUMENTS = 24
Constants.MAX_RECENT_LOGS_REPLICATED = 100
Constants.UI_UPDATE_INTERVAL = 1
Constants.SERVER_METRICS_INTERVAL = 5
Constants.DEFAULT_PREFIX = "!"
Constants.SLASH_PREFIX = "/"
Constants.DATASTORE_VERSION = 1
Constants.RANK_DATASTORE = "ForgeXAdmin_Ranks_v1"
Constants.BAN_DATASTORE = "ForgeXAdmin_Bans_v1"
Constants.AUDIT_DATASTORE = "ForgeXAdmin_Audit_v1"
Constants.SETTINGS_DATASTORE = "ForgeXAdmin_Settings_v1"
Constants.MAX_DATASTORE_RETRIES = 5
Constants.DATASTORE_RETRY_BASE_DELAY = 0.75
Constants.RATE_LIMIT_WINDOW = 10
Constants.DEFAULT_RATE_LIMIT_REQUESTS = 12
Constants.HIGH_TRUST_RATE_LIMIT_REQUESTS = 30
Constants.WEBHOOK_TIMEOUT_SECONDS = 10

return table.freeze(Constants)
