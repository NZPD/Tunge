local Maid = {}
Maid.__index = Maid

export type Maid = typeof(Maid)

function Maid.new(): Maid
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:GiveTask(task: any): Maid
	if task then
		self._tasks[#self._tasks + 1] = task
	end
	return self
end

function Maid:DoCleaning()
	local tasks = self._tasks
	self._tasks = {}
	for i = #tasks, 1, -1 do
		self:_clean(tasks[i])
	end
end

function Maid:Destroy()
	self:DoCleaning()
	self._tasks = nil
end

function Maid:_clean(task: any)
	local t = typeof(task)
	if t == "function" then
		task()
	elseif t == "thread" then
		task.cancel(task)
	elseif t == "RBXScriptConnection" then
		task:Disconnect()
	elseif t == "Instance" then
		task:Destroy()
	elseif type(task) == "table" then
		pcall(function()
			if task.Destroy then task:Destroy()
			elseif task.DoCleaning then task:DoCleaning() end
		end)
	end
end

return Maid