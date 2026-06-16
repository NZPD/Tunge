local Logger = {}
Logger.__index = Logger

export type Logger = typeof(Logger)

local LogLevels = {
	Debug = 0,
	Info = 1,
	Warn = 2,
	Error = 3,
	Off = 4,
}

function Logger.new(name: string, level: string?): Logger
	return setmetatable({
		_name = name,
		_level = LogLevels[level or "Debug"] or LogLevels.Debug,
	}, Logger)
end

function Logger:SetLevel(level: string)
	self._level = LogLevels[level] or LogLevels.Debug
end

function Logger:Debug(...: any)
	if self._level > LogLevels.Debug then return end
	print(("[VyTax][%s][DEBUG]"):format(self._name), ...)
end

function Logger:Info(...: any)
	if self._level > LogLevels.Info then return end
	print(("[VyTax][%s][INFO]"):format(self._name), ...)
end

function Logger:Warn(...: any)
	if self._level > LogLevels.Warn then return end
	warn(("[VyTax][%s][WARN]"):format(self._name), ...)
end

function Logger:Error(...: any)
	if self._level > LogLevels.Error then return end
	warn(("[VyTax][%s][ERROR]"):format(self._name), ...)
end

function Logger:Tag(tag: string, ...: any)
	print(("[VyTax][%s][%s]"):format(self._name, tag), ...)
end

return Logger