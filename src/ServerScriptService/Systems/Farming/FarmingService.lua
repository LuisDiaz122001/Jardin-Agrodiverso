--!strict

-- FarmingService coordina el ciclo de cultivo de parcelas en el servidor.
-- El estado de la parcela se guarda en atributos de la propia parcela.
-- Los recursos del jugador permanecen en PlayerDataService.

local Players = game:GetService("Players")

local PlayerDataService = require(script.Parent.Parent.PlayerData.PlayerDataService)
local SeedService = require(script.Parent.Parent.Seeds.SeedService)

export type CropState = "Empty" | "Growing" | "Ready"

type CropConfig = {
	GrowthDuration: number,
	CoinsReward: number,
	XPReward: number,
}

local CROP_CONFIGS: {[string]: CropConfig} = {
	Corn = {
		GrowthDuration = 30,
		CoinsReward = 10,
		XPReward = 5,
	},
}

local FarmingService = {}

local function getActivePlayerData(player: Player)
	if not player:IsDescendantOf(Players) then
		return nil
	end

	return PlayerDataService:GetPlayerData(player)
end

local function getCropConfig(plot: Instance): CropConfig?
	local cropType = plot:GetAttribute("CropType")

	if type(cropType) ~= "string" then
		return nil
	end

	return CROP_CONFIGS[cropType]
end

local function getCropState(plot: Instance): CropState?
	local cropState = plot:GetAttribute("CropState")

	if cropState == nil then
		return "Empty"
	end

	if cropState == "Empty" or cropState == "Growing" or cropState == "Ready" then
		return cropState
	end

	return nil
end

local function getNextFarmingCycle(plot: Instance): number
	local currentCycle = plot:GetAttribute("FarmingCycle")

	if type(currentCycle) ~= "number" then
		currentCycle = 0
	end

	return currentCycle + 1
end

function FarmingService:GetCropState(plot: Instance): CropState?
	return getCropState(plot)
end

function FarmingService:Plant(player: Player, plot: Instance): boolean
	local playerData = getActivePlayerData(player)
	local cropConfig = getCropConfig(plot)

	if not playerData or not cropConfig or getCropState(plot) ~= "Empty" then
		return false
	end

	if not SeedService:ConsumeSeed(player) then
		return false
	end

	local farmingCycle = getNextFarmingCycle(plot)

	plot:SetAttribute("CropState", "Growing")
	plot:SetAttribute("FarmingCycle", farmingCycle)

	task.delay(cropConfig.GrowthDuration, function()
		if plot.Parent == nil then
			return
		end

		if plot:GetAttribute("FarmingCycle") ~= farmingCycle then
			return
		end

		if getCropState(plot) ~= "Growing" then
			return
		end

		plot:SetAttribute("CropState", "Ready")
	end)

	return true
end

function FarmingService:Harvest(player: Player, plot: Instance): boolean
	local playerData = getActivePlayerData(player)
	local cropConfig = getCropConfig(plot)

	if not playerData or not cropConfig or getCropState(plot) ~= "Ready" then
		return false
	end

	playerData.Coins += cropConfig.CoinsReward
	playerData.XP += cropConfig.XPReward
	plot:SetAttribute("CropState", "Empty")

	return true
end

return FarmingService
