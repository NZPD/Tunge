local Signal = {}
Signal.__index = Signal

export type Signal<T...> = typeof(Signal)

local Connection = {}
Connection.__index = Connection

function Connection.new(callback: (...any) -> (), once: boolean?): typeof(Connection)
	return setmetatable({
		Connected = true,
		_callback = callback,
		_once = once or false,
	}, Connection)
end

function Connection:Disconnect()
	self.Connected = false
	self._callback = nil
end

Connection.Destroy = Connection.Disconnect

function Signal.new<T...>(): Signal<T...>
	return setmetatable({
		_connections = {},
		_yielding = false,
		_destroyed = false,
	}, Signal) as Signal<T...>
end

function Signal:Connect(callback: (...any) -> ()): typeof(Connection)
	local connection = Connection.new(callback, false)
	self._connections[#self._connections + 1] = connection
	return connection
end

function Signal:Once(callback: (...any) -> ()): typeof(Connection)
	local connection = Connection.new(callback, true)
	self._connections[#self._connections + 1] = connection
	return connection
end

function Signal:Wait(): ...any
	if self._yielding or self._destroyed then return end
	self._yielding = true
	local thread = coroutine.running()
	local connection: typeof(Connection)
	connection = self:Once(function(...)
		self._yielding = false
		if thread then task.spawn(thread, ...) end
		connection = nil
	end)
	return coroutine.yield()
end

function Signal:Fire(...: any)
	if self._destroyed then return end
	for i = #self._connections, 1, -1 do
		local connection = self._connections[i]
		if connection.Connected then
			task.spawn(connection._callback, ...)
			if connection._once then
				connection:Disconnect()
				table.remove(self._connections, i)
			end
		else
			table.remove(self._connections, i)
		end
	end
end

function Signal:Destroy()
	self._destroyed = true
	for _, connection in self._connections do connection:Disconnect() end
	self._connections = {}
	self._yielding = false
end

return Signal