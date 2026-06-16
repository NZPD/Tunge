local Maid = require(script.Parent.Maid)
local Signal = require(script.Parent.Signal)

local Loader = {}
Loader.__index = Loader

export type Loader = typeof(Loader)

function Loader.new(): Loader
	return setmetatable({
		_services = {},
		_controllers = {},
		_components = {},
		_loaded = false,
		_started = false,
		_maid = Maid.new(),
	}, Loader)
end

function Loader:_loadModules(folders: { Folder })
	local modules = {}
	for _, folder in folders do
		for _, child in folder:GetChildren() do
			if child:IsA("ModuleScript") then
				modules[child.Name] = require(child)
			end
		end
	end
	return modules
end

function Loader:LoadServices(...: Folder)
	if self._loaded then return end
	local folders = { ... }
	local modules = self:_loadModules(folders)
	for name, module in modules do
		if type(module) == "table" and module._init then
			local service = module
			service.Name = name
			self._services[name] = service
			self._maid:GiveTask(service)
		end
	end
end

function Loader:LoadControllers(...: Folder)
	if self._loaded then return end
	local folders = { ... }
	local modules = self:_loadModules(folders)
	for name, module in modules do
		if type(module) == "table" and module._init then
			local controller = module
			controller.Name = name
			if game:GetService("Players").LocalPlayer then
				controller.Player = game:GetService("Players").LocalPlayer
			end
			self._controllers[name] = controller
			self._maid:GiveTask(controller)
		end
	end
end

function Loader:LoadComponents(...: Folder)
	if self._loaded then return end
	local folders = { ... }
	local modules = self:_loadModules(folders)
	for name, module in modules do
		if type(module) == "table" and module._init then
			local component = module
			component.Name = name
			self._components[name] = component
		end
	end
end

function Loader:GetService(name: string): any?
	return self._services[name]
end

function Loader:GetController(name: string): any?
	return self._controllers[name]
end

function Loader:GetComponent(name: string): any?
	return self._components[name]
end

function Loader:HasService(name: string): boolean
	return self._services[name] ~= nil
end

function Loader:HasController(name: string): boolean
	return self._controllers[name] ~= nil
end

function Loader:HasComponent(name: string): boolean
	return self._components[name] ~= nil
end

function Loader:InjectService(name: string, instance: any)
	instance.Name = name
	self._services[name] = instance
	self._maid:GiveTask(instance)
end

function Loader:InjectController(name: string, instance: any)
	instance.Name = name
	if game:GetService("Players").LocalPlayer then
		instance.Player = game:GetService("Players").LocalPlayer
	end
	self._controllers[name] = instance
	self._maid:GiveTask(instance)
end

function Loader:Start()
	if self._started then return end
	self._loaded = true
	self._started = true

	for _, service in self._services do
		local s, e = pcall(function() service:_init() end)
		if not s and e then warn(("[VyTax] Service %s _init error: %s"):format(service.Name, e)) end
	end
	for _, controller in self._controllers do
		local s, e = pcall(function() controller:_init() end)
		if not s and e then warn(("[VyTax] Controller %s _init error: %s"):format(controller.Name, e)) end
	end
	for name, component in self._components do
		component._maid = Maid.new()
	end

	for _, service in self._services do
		local s, e = pcall(function() service:_start() end)
		if not s and e then warn(("[VyTax] Service %s _start error: %s"):format(service.Name, e)) end
	end
	for _, controller in self._controllers do
		local s, e = pcall(function() controller:_start() end)
		if not s and e then warn(("[VyTax] Controller %s _start error: %s"):format(controller.Name, e)) end
	end
end

function Loader:Destroy()
	self._maid:DoCleaning()
	self._services = {}
	self._controllers = {}
	self._components = {}
	self._loaded = false
	self._started = false
end

return Loader