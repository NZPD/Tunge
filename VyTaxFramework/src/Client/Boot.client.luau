local Loader = require(game:GetService("ReplicatedStorage").VyTax.Loader)

local framework = Loader.new()

framework:LoadControllers(
	script.Parent.Controllers
)

framework:Start()