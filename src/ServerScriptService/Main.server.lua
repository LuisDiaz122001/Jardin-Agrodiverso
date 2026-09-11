--!strict

print("========================================")
print(" JARDÍN AGRODIVERSO")
print(" Sistema principal iniciado correctamente")
print("========================================")

local PlayerDataService = require(script.Parent.Systems.PlayerData.PlayerDataService)
local PlotInteractionService = require(script.Parent.Systems.Farming.PlotInteractionService)
local CropVisualService = require(script.Parent.Systems.Farming.CropVisualService)

PlayerDataService:Initialize()
PlotInteractionService:Initialize()
CropVisualService:Initialize()
