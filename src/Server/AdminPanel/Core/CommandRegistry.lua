--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.AdminPanel.Types)
local Config = require(script.Parent.Config)

type CommandDefinition = Types.CommandDefinition

local CommandRegistry = {}
CommandRegistry.__index = CommandRegistry

export type CommandRegistry = typeof(setmetatable({
	_commands = {} :: { [string]: CommandDefinition },
	_aliases = {} :: { [string]: string },
	_modules = {} :: { [ModuleScript]: CommandDefinition },
	_changed = Instance.new("BindableEvent"),
}, CommandRegistry))

local function validateCommand(command: CommandDefinition): (boolean, string)
	if command.name == "" then
		return false, "Command name is required"
	end
	if Config.Ranks[command.minRank] == nil then
		return false, `Command {command.name} references unknown minRank {command.minRank}`
	end
	if typeof(command.run) ~= "function" then
		return false, `Command {command.name} has no run function`
	end
	return true, "OK"
end

function CommandRegistry.new(): CommandRegistry
	return setmetatable({
		_commands = {},
		_aliases = {},
		_modules = {},
		_changed = Instance.new("BindableEvent"),
	}, CommandRegistry)
end

function CommandRegistry.getChangedSignal(self: CommandRegistry): RBXScriptSignal
	return self._changed.Event
end

function CommandRegistry.register(
	self: CommandRegistry,
	command: CommandDefinition,
	module: ModuleScript?
): (boolean, string)
	local ok, message = validateCommand(command)
	if not ok then
		return false, message
	end

	local name = string.lower(command.name)
	if Config.DisabledCommands[name] == true then
		return false, `Command {name} is disabled`
	end

	self._commands[name] = command
	if module ~= nil then
		self._modules[module] = command
	end

	for _, alias in command.aliases do
		self._aliases[string.lower(alias)] = name
	end
	local overrideAliases = Config.CommandAliases[name]
	if typeof(overrideAliases) == "table" then
		for _, alias in overrideAliases do
			self._aliases[string.lower(alias)] = name
		end
	end

	self._changed:Fire(command)
	return true, "Registered"
end

function CommandRegistry.unregister(self: CommandRegistry, name: string)
	local lower = string.lower(name)
	local command = self._commands[lower]
	if command == nil then
		return
	end
	self._commands[lower] = nil
	for alias, commandName in self._aliases do
		if commandName == lower then
			self._aliases[alias] = nil
		end
	end
	self._changed:Fire(nil)
end

function CommandRegistry.get(self: CommandRegistry, nameOrAlias: string): CommandDefinition?
	local lower = string.lower(nameOrAlias)
	local canonical = self._aliases[lower] or lower
	return self._commands[canonical]
end

function CommandRegistry.getAll(self: CommandRegistry): { CommandDefinition }
	local commands = {}
	for _, command in self._commands do
		table.insert(commands, command)
	end
	table.sort(commands, function(a, b)
		if a.category == b.category then
			return a.name < b.name
		end
		return a.category < b.category
	end)
	return commands
end

function CommandRegistry.loadFromFolder(self: CommandRegistry, folder: Instance)
	for _, descendant in folder:GetDescendants() do
		if descendant:IsA("ModuleScript") then
			local ok, result = pcall(require, descendant)
			if ok and typeof(result) == "table" then
				if result.name ~= nil then
					self:register(result :: CommandDefinition, descendant)
				elseif result.Commands ~= nil and typeof(result.Commands) == "table" then
					for _, command in result.Commands do
						self:register(command :: CommandDefinition, descendant)
					end
				end
			else
				warn(`Failed to load command module {descendant:GetFullName()}: {result}`)
			end
		end
	end
end

function CommandRegistry.hotReloadModule(self: CommandRegistry, module: ModuleScript)
	local previous = self._modules[module]
	if previous ~= nil then
		self:unregister(previous.name)
		self._modules[module] = nil
	end
	local ok, result = pcall(require, module)
	if ok and typeof(result) == "table" and result.name ~= nil then
		self:register(result :: CommandDefinition, module)
	end
end

function CommandRegistry.loadDefaultCommands(self: CommandRegistry)
	local adminPanel = ServerScriptService:WaitForChild("AdminPanel")
	local commands = adminPanel:WaitForChild("Commands")
	self:loadFromFolder(commands)
end

return CommandRegistry
