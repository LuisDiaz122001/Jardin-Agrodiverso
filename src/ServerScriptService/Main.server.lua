--!strict

print("========================================")
print(" JARDÍN AGRODIVERSO")
print(" Sistema principal iniciado correctamente")
print("========================================")

local PlayerDataService = require(script.Parent.Systems.PlayerData.PlayerDataService)
local SeedShopInteractionService = require(script.Parent.Systems.Seeds.SeedShopInteractionService)
local PlotInteractionService = require(script.Parent.Systems.Farming.PlotInteractionService)
local CropVisualService = require(script.Parent.Systems.Farming.CropVisualService)

PlayerDataService:Initialize()
SeedShopInteractionService:Initialize()
PlotInteractionService:Initialize()
CropVisualService:Initialize()
