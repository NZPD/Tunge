local Module = {}

Module.Maid = require(script.Maid)
Module.Signal = require(script.Signal)
Module.Event = require(script.Event)
Module.Promise = require(script.Promise)
Module.Loader = require(script.Loader)

Module.Util = {}
Module.Util.Logger = require(script.Util.Logger)
Module.Util.Time = require(script.Util.Time)
Module.Util.Table = require(script.Util.Table)

return Module