local Promise = {}
Promise.__index = Promise

export type Promise<T> = typeof(Promise)

function Promise.new<T>(executor: (resolve: (T) -> (), reject: (any) -> ()) -> ()): Promise<T>
	local self = setmetatable({
		_state = "Pending",
		_value = nil,
		_error = nil,
		_fulfilled = {},
		_rejected = {},
	}, Promise)

	local function resolve(value: T)
		if self._state ~= "Pending" then return end
		if type(value) == "table" and typeof(value) == "table" and rawget(value, "_state") ~= nil then
			(value :: any):Then(resolve, reject)
			return
		end
		self._state = "Resolved"
		self._value = value
		task.spawn(function()
			for _, cb in self._fulfilled do task.spawn(cb, value) end
			self._fulfilled = {}
			self._rejected = {}
		end)
	end

	local function reject(err: any)
		if self._state ~= "Pending" then return end
		self._state = "Rejected"
		self._error = err
		task.spawn(function()
			for _, cb in self._rejected do task.spawn(cb, err) end
			self._fulfilled = {}
			self._rejected = {}
		end)
	end

	task.spawn(executor, resolve, reject)
	return self
end

function Promise.Resolve<T>(value: T): Promise<T>
	return Promise.new(function(resolve) resolve(value) end)
end

function Promise.Reject(err: any): Promise<any>
	return Promise.new(function(_, reject) reject(err) end)
end

function Promise:Then<U>(onFulfilled: (T) -> U): Promise<U>
	return Promise.new(function(resolve, reject)
		if self._state == "Resolved" then
			task.spawn(function()
				local s, r = pcall(onFulfilled, self._value)
				if s then resolve(r) else reject(r) end
			end)
		elseif self._state == "Rejected" then
			reject(self._error)
		else
			table.insert(self._fulfilled, function(value)
				local s, r = pcall(onFulfilled, value)
				if s then resolve(r) else reject(r) end
			end)
			table.insert(self._rejected, reject)
		end
	end)
end

function Promise:Catch<U>(onRejected: (any) -> U): Promise<U>
	return Promise.new(function(resolve, reject)
		if self._state == "Rejected" then
			task.spawn(function()
				local s, r = pcall(onRejected, self._error)
				if s then resolve(r) else reject(r) end
			end)
		elseif self._state == "Resolved" then
			resolve(self._value)
		else
			table.insert(self._fulfilled, resolve)
			table.insert(self._rejected, function(err)
				local s, r = pcall(onRejected, err)
				if s then resolve(r) else reject(r) end
			end)
		end
	end)
end

function Promise:Finally(onFinally: () -> ()): Promise<T>
	return self:Then(function(value)
		onFinally()
		return value
	end):Catch(function(err)
		onFinally()
		return Promise.Reject(err)
	end)
end

function Promise:Await(): (T?, any?)
	if self._state == "Pending" then
		local thread = coroutine.running()
		self:Then(function(value) task.spawn(thread, value) end):Catch(function(err) task.spawn(thread, nil, err) end)
		return coroutine.yield()
	end
	if self._state == "Resolved" then return self._value, nil end
	return nil, self._error
end

return Promise