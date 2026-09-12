--!strict

-- FarmingService coordina el ciclo de cultivo de parcelas en el servidor.
-- El estado lógico de la parcela permanece en CropState: Empty, Growing o Ready.
-- VisualGrowthStage es una señal de presentación derivada del mismo ciclo; no autoriza plantar ni cosechar.

local Players = game:GetService("Players")

local CropCatalog = require(script.Parent.CropCatalog)
local PlayerDataService = require(script.Parent.Parent.PlayerData.PlayerDataService)
local SeedService = require(script.Parent.Parent.Seeds.SeedService)

export type CropState = "Empty" | "Growing" | "Ready"

type CropDefinition = CropCatalog.CropDefinition

local FarmingService = {}
local random = Random.new()

local function getActivePlayerData(player: Player)
	if not player:IsDescendantOf(Players) then
		return nil
	end

	return PlayerDataService:GetPlayerData(player)
end

local function getCropDefinition(plot: Instance): CropDefinition?
	local cropType = plot:GetAttribute("CropType")

	if type(cropType) ~= "string" then
		return nil
	end

	return CropCatalog.Get(cropType)
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

local function setVisualGrowthStage(plot: Instance, stageId: number)
	plot:SetAttribute("VisualGrowthStage", stageId)
end

local function isActiveGrowingCycle(plot: Instance, farmingCycle: number): boolean
	if plot.Parent == nil then
		return false
	end

	if plot:GetAttribute("FarmingCycle") ~= farmingCycle then
		return false
	end

	return getCropState(plot) == "Growing"
end

local function scheduleGrowth(plot: Instance, farmingCycle: number, cropDefinition: CropDefinition)
	local immediateStage = CropCatalog.GetFirstGrowingStage(cropDefinition)

	for _, stage in cropDefinition.GrowingVisualStages do
		if stage.AtProgress <= 0 then
			immediateStage = stage
		else
			local delayTime = cropDefinition.GrowthDuration * stage.AtProgress

			task.delay(delayTime, function()
				if not isActiveGrowingCycle(plot, farmingCycle) then
					return
				end

				setVisualGrowthStage(plot, stage.Id)
			end)
		end
	end

	if immediateStage then
		setVisualGrowthStage(plot, immediateStage.Id)
	else
		setVisualGrowthStage(plot, cropDefinition.ReadyVisual.Id)
	end

	task.delay(cropDefinition.GrowthDuration, function()
		if not isActiveGrowingCycle(plot, farmingCycle) then
			return
		end

		setVisualGrowthStage(plot, cropDefinition.ReadyVisual.Id)
		plot:SetAttribute("CropState", "Ready")
	end)
end

function FarmingService:GetCropState(plot: Instance): CropState?
	return getCropState(plot)
end

function FarmingService:GetVisualGrowthStage(plot: Instance): number
	local visualStage = plot:GetAttribute("VisualGrowthStage")

	if type(visualStage) == "number" then
		return visualStage
	end

	local cropState = getCropState(plot)
	local cropDefinition = getCropDefinition(plot)

	if cropState == "Ready" and cropDefinition then
		return cropDefinition.ReadyVisual.Id
	end

	if cropState == "Growing" and cropDefinition then
		local firstStage = CropCatalog.GetFirstGrowingStage(cropDefinition)

		if firstStage then
			return firstStage.Id
		end

		return cropDefinition.ReadyVisual.Id
	end

	return CropCatalog.GetEmptyVisualStageId()
end

function FarmingService:Plant(player: Player, plot: Instance): boolean
	local playerData = getActivePlayerData(player)
	local cropDefinition = getCropDefinition(plot)

	if not playerData or not cropDefinition or getCropState(plot) ~= "Empty" then
		return false
	end

	if not SeedService:ConsumeSeed(player) then
		return false
	end

	local farmingCycle = getNextFarmingCycle(plot)

	plot:SetAttribute("FarmingCycle", farmingCycle)
	scheduleGrowth(plot, farmingCycle, cropDefinition)
	plot:SetAttribute("CropState", "Growing")

	return true
end

function FarmingService:Harvest(player: Player, plot: Instance): boolean
	local playerData = getActivePlayerData(player)
	local cropDefinition = getCropDefinition(plot)

	if not playerData or not cropDefinition or getCropState(plot) ~= "Ready" then
		return false
	end

	playerData.Coins += cropDefinition.CoinsReward
	playerData.XP += cropDefinition.XPReward

	if random:NextNumber() < cropDefinition.SeedDropChance then
		SeedService:AddSeeds(player, 1)
	end

	plot:SetAttribute("CropState", "Empty")
	setVisualGrowthStage(plot, CropCatalog.GetEmptyVisualStageId())

	return true
end

return FarmingService
