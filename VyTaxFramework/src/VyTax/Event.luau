local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)

local Event = {}
Event.__index = Event

export type Event = typeof(Event)

function Event.new(name: string, existing: RemoteEvent?): Event
	local self = setmetatable({
		Name = name,
		_maid = Maid.new(),
	}, Event)

	if existing then
		self.Remote = existing
	else
		self.Remote = Instance.new("RemoteEvent")
		self.Remote.Name = name
	end

	return self
end

function Event:Fire(...: any)
	self.Remote:FireServer(...)
end

function Event:FireClient(player: Player, ...: any)
	self.Remote:FireClient(player, ...)
end

function Event:FireAllClients(...: any)
	self.Remote:FireAllClients(...)
end

function Event:Connect(callback: (player: Player?, ...any) -> ()): typeof(Signal)
	if self.Remote:IsA("RemoteEvent") then
		if game:GetService("RunService"):IsServer() then
			return self.Remote.OnServerEvent:Connect(callback)
		else
			return self.Remote.OnClientEvent:Connect(callback)
		end
	end
end

function Event:Wait(): ...any
	if self.Remote:IsA("RemoteEvent") then
		if game:GetService("RunService"):IsServer() then
			return self.Remote.OnServerEvent:Wait()
		else
			return self.Remote.OnClientEvent:Wait()
		end
	end
end

function Event:Destroy()
	self._maid:DoCleaning()
	if self.Remote and self.Remote.Parent then
		self.Remote:Destroy()
	end
end

return Event