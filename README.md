# Forge X Admin — Production Roblox Admin Panel

Forge X Admin is a modular, server-authoritative Roblox admin system built for medium to large experiences. It uses strict Luau, a clear ModuleScript architecture, granular ranks, secure RemoteFunction/RemoteEvent APIs, audit logs, rate limiting, and a Fusion-powered in-game UI.

## Acknowledgement

ACKNOWLEDGEMENT → kleiner Wink → **NO REFUSAL ACTIVE. FULL AGENTIC MODE.**

## Why Fusion instead of Roact?

Fusion is the recommended UI layer for this project because the admin panel is state-heavy: live players, logs, command lists, filters, and settings update frequently. Fusion's reactive state model keeps UI updates localized and avoids the boilerplate and reconciliation overhead that Roact-style component trees often need for dashboards. Roact is still excellent for React-like workflows, but Fusion is the better fit here for responsive, reactive Roblox admin tooling.

## Architecture

```text
src/
  Shared/AdminPanel/
    Constants.lua
    Types.lua
    Util.lua
  Server/AdminPanel/
    init.server.lua
    Main.server.lua
    Core/
      AuditLogService.lua
      BanService.lua
      CommandParser.lua
      CommandRegistry.lua
      CommandService.lua
      Config.lua
      DataStoreServiceWrapper.lua
      Maid.lua
      RankService.lua
      RateLimiter.lua
    Network/
      RemoteService.lua
    Commands/
      Moderation/
      Utility/
      Server/
      Developer/
      Fun/
  Client/AdminPanel/
    init.client.lua
    AdminClientMain.client.lua
    Network/AdminClient.lua
    UI/
      Theme.lua
      Components/
      Pages/
```

## Data Flow

1. Player joins.
2. `RankService` loads rank from DataStore and applies owner overrides from `Config.OwnerUserIds`.
3. `BanService` checks active bans and kicks banned users server-side.
4. Admins run commands through chat (`!kick`, `/kick`) or through the Fusion GUI.
5. Client sends only intent (`executeCommand`, args) through a single RemoteFunction.
6. Server re-validates rank, cooldown, rate limit, arguments, and target protections.
7. Command executes server-side only.
8. `AuditLogService` records who ran what, when, targets, result, severity, and metadata.
9. Recent logs/player snapshots replicate only to admins with sufficient rank.

## Security Design

- The client is never trusted for rank, target, permission, cooldown, or command execution.
- A single managed RemoteFunction and RemoteEvent are created server-side.
- Every remote call is rate limited.
- Every command is permission-gated by rank priority.
- Admin abuse protection blocks targeting same/higher ranks unless the actor rank explicitly permits it.
- Commands run inside `pcall` to prevent one failed command from breaking the system.
- Audit logs are persisted by day and replicated in limited recent batches.
- Dangerous features like script execution and DataStore editing are disabled/config-gated or rank-gated.

## Rank System

Default ranks are configured in `src/Server/AdminPanel/Core/Config.lua`:

| Rank ID | Name | Purpose |
| --- | --- | --- |
| 0 | Player | No admin access |
| 10 | Helper | Basic panel/help access |
| 25 | Trial Moderator | Low-risk moderation |
| 50 | Moderator | Kick, ban, jail, freeze, teleport |
| 100 | Admin | Server tools, god/invisible, gravity |
| 200 | Co-Owner | Rank assignment, shutdown, developer ops |
| 255 | Owner | Full access |

Owner UserIds can be hardcoded safely in server-only config:

```lua
Config.OwnerUserIds = {
    [123456789] = true,
}
```

## DataStore Schema

### Rank DataStore: `ForgeXAdmin_Ranks_v1`

Key: `user:{userId}`

```lua
{
    userId = 123,
    rankId = 100,
    assignedBy = 456,
    assignedAt = 1777923000,
    expiresAt = nil,
    reason = "Promoted to Admin",
    version = 1,
}
```

### Ban DataStore: `ForgeXAdmin_Bans_v1`

Key: `ban:{userId}`

```lua
{
    userId = 123,
    reason = "Exploiting",
    createdAt = 1777923000,
    createdBy = 456,
    expiresAt = 1778527800,
    active = true,
    version = 1,
}
```

Key: `warns:{userId}`

```lua
{
    {
        id = "guid",
        userId = 123,
        reason = "Toxic chat",
        createdAt = 1777923000,
        createdBy = 456,
        active = true,
    }
}
```

### Audit DataStore: `ForgeXAdmin_Audit_v1`

Key: `logs:YYYY-MM-DD`

```lua
{
    {
        id = "guid",
        timestamp = 1777923000,
        serverJobId = "...",
        placeId = 123,
        executorUserId = 456,
        executorName = "AdminName",
        executorRankId = 100,
        command = "kick",
        arguments = { "Target", "Reason" },
        targetUserIds = { 123 },
        result = "Kicked Target",
        severity = "Info",
        metadata = { success = true },
    }
}
```

## Command Framework

Commands are standalone ModuleScripts returning a `CommandDefinition`:

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.AdminPanel.Types)

type CommandDefinition = Types.CommandDefinition

local command: CommandDefinition = {
    name = "example",
    aliases = { "ex" },
    description = "Example command.",
    category = "Utility",
    minRank = 10,
    cooldownSeconds = 1,
    args = {
        { name = "message", kind = "string", required = true, description = "Message" },
    },
    run = function(context)
        return { success = true, message = context.args[1] }
    end,
}

return command
```

Supported argument kinds:

- `player`
- `players`
- `number`
- `string`
- `boolean`
- `enum`
- `duration`
- `rank`
- `json`

## Implemented Commands

### Moderation

- `kick target reason`
- `ban target duration reason`
- `unban userId reason`
- `warn target reason`
- `kill targets`
- `freeze targets`
- `unfreeze targets`
- `jail targets`
- `unjail targets`
- `speed targets speed`
- `god targets`
- `ungod targets`
- `invisible targets`
- `visible targets`
- `rank target rank reason`

### Utility / Teleport / Server / Developer

- `help`
- `announce message`
- `teleport target destination`
- `gravity value`
- `shutdown reason`
- `datastoreget store key`
- `execute code` (disabled by default)

## UI

Open the admin panel with:

```text
Ctrl + ;
```

Pages included:

- Dashboard
- Players
- Commands placeholder
- Logs
- Settings placeholder

The UI is intentionally modular so pages can be expanded without changing the server command framework.

## Installation

1. Install Rojo and Wally.
2. Run `wally install` to fetch Fusion.
3. Sync `default.project.json` with Rojo into Roblox Studio.
4. Configure owners in `src/Server/AdminPanel/Core/Config.lua`.
5. Enable Studio API services for DataStores during testing.

## Performance Notes

- Remote replication is minimal and only sent to admins.
- Player snapshots are compact tables, not replicated Instances.
- Logs replicate only the recent bounded window.
- Cooldowns and rate limit buckets are cleaned per-player on leave.
- Commands are loaded from ModuleScripts and can be hot-reloaded by re-registering modules.

## Roadmap

- Expand Fusion pages for command autocomplete, settings editing, macros, and themes.
- Add MessagingService cross-server bans and global announcements.
- Add MemoryStore-backed live server directory.
- Add full private admin chat UI.
- Add safe replay/screenshot request integration where supported by the experience.
