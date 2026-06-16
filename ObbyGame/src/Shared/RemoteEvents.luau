--!strict
-- RemoteEvents.luau
-- Centralized remote event/functions management for the Obby Framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(script.Parent.Types)
local Constants = require(script.Parent.Constants)

local RemoteEvents = {
	RemoteEvents = {} as { [string]: RemoteEvent },
	RemoteFunctions = {} as { [string]: RemoteFunction },
}

-- Internal module table
local module = {}

-- Stores references for cleanup
local createdEvents: { Instance } = {}
local connections: { RBXScriptConnection } = {}

-- Folder to hold all remotes
local remoteFolder: Folder?

--[[
	Initializes the remote folder in ReplicatedStorage.
	Creates all necessary RemoteEvents and RemoteFunctions.
]]
function module.Init(): boolean
	local success, err = pcall(function()
		-- Create or find the remote folder
		remoteFolder = ReplicatedStorage:FindFirstChild("ObbyRemotes") :: Folder
		if not remoteFolder then
			remoteFolder = Instance.new("Folder")
			remoteFolder.Name = "ObbyRemotes"
			remoteFolder.Parent = ReplicatedStorage
		end

		-- Create all RemoteEvents
		for _, eventName in Constants.REMOTE_EVENTS do
			local existing = remoteFolder:FindFirstChild(eventName)
			if existing then
				RemoteEvents.RemoteEvents[eventName] = existing :: RemoteEvent
			else
				local newEvent = Instance.new("RemoteEvent")
				newEvent.Name = eventName
				newEvent.Parent = remoteFolder
				RemoteEvents.RemoteEvents[eventName] = newEvent
				table.insert(createdEvents, newEvent)
			end
		end

		-- Create RemoteFunctions if needed (example for leaderboard fetch)
		local leaderboardFunc = remoteFolder:FindFirstChild("GetLeaderboard")
		if not leaderboardFunc then
			leaderboardFunc = Instance.new("RemoteFunction")
			leaderboardFunc.Name = "GetLeaderboard"
			leaderboardFunc.Parent = remoteFolder
		end
		RemoteEvents.RemoteFunctions["GetLeaderboard"] = leaderboardFunc :: RemoteFunction
		table.insert(createdEvents, leaderboardFunc)
	end)

	if not success then
		warn(`[RemoteEvents] Failed to initialize: {err}`)
		return false
	end

	return true
end

--[[
	Fires a RemoteEvent to all players or a specific player.
]]
function module.Fire(eventName: string, playerOrNil: Player?, ...: any): boolean
	local event = RemoteEvents.RemoteEvents[eventName]
	if not event then
		warn(`[RemoteEvents] Unknown event: {eventName}`)
		return false
	end

	local success, err = pcall(function()
		if playerOrNil then
			event:FireClient(playerOrNil, ...)
		else
			event:FireAllClients(...)
		end
	end)

	if not success then
		warn(`[RemoteEvents] Failed to fire {eventName}: {err}`)
		return false
	end

	return true
end

--[[
	Fires a RemoteEvent to all players.
]]
function module.FireAll(eventName: string, ...: any): boolean
	return module.Fire(eventName, nil, ...)
end

--[[
	Connects a handler function to a RemoteEvent.
]]
function module.OnServerEvent(eventName: string, handler: (player: Player, ...any) -> ()): RBXScriptConnection?
	local event = RemoteEvents.RemoteEvents[eventName]
	if not event then
		warn(`[RemoteEvents] Unknown event for connection: {eventName}`)
		return nil
	end

	local connection = event.OnServerEvent:Connect(handler)
	table.insert(connections, connection)
	return connection
end

--[[
	Connects a handler function to a RemoteEvent on the client side.
]]
function module.OnClientEvent(eventName: string, handler: (...any) -> ()): RBXScriptConnection?
	local event = RemoteEvents.RemoteEvents[eventName]
	if not event then
		warn(`[RemoteEvents] Unknown event for client connection: {eventName}`)
		return nil
	end

	local connection = event.OnClientEvent:Connect(handler)
	table.insert(connections, connection)
	return connection
end

--[[
	Sets up a RemoteFunction for server invocation.
]]
function module.OnServerInvoke(functionName: string, handler: (player: Player, ...any) -> any): boolean
	local func = RemoteEvents.RemoteFunctions[functionName]
	if not func then
		warn(`[RemoteEvents] Unknown function: {functionName}`)
		return false
	end

	func.OnServerInvoke = handler
	return true
end

--[[
	Invokes a RemoteFunction from the client.
]]
function module.InvokeServer(functionName: string, ...: any): any
	local func = RemoteEvents.RemoteFunctions[functionName]
	if not func then
		warn(`[RemoteEvents] Unknown function for invoke: {functionName}`)
		return nil
	end

	local success, result = pcall(function()
		return func:InvokeServer(...)
	end)

	if not success then
		warn(`[RemoteEvents] Failed to invoke {functionName}: {result}`)
		return nil
	end

	return result
end

--[[
	Gets a RemoteEvent by name (useful for direct manipulation).
]]
function module.GetEvent(eventName: string): RemoteEvent?
	return RemoteEvents.RemoteEvents[eventName]
end

--[[
	Gets a RemoteFunction by name.
]]
function module.GetFunction(functionName: string): RemoteFunction?
	return RemoteEvents.RemoteFunctions[functionName]
end

--[[
	Cleans up all remote events and connections.
]]
function module.Destroy()
	for _, conn in connections do
		conn:Disconnect()
	end
	table.clear(connections)

	if remoteFolder then
		remoteFolder:Destroy()
		remoteFolder = nil
	end

	table.clear(RemoteEvents.RemoteEvents)
	table.clear(RemoteEvents.RemoteFunctions)
	table.clear(createdEvents)
end

return module