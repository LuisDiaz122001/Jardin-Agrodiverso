--!strict

local Players = game:GetService("Players")

local PlayerDataService = require(script.Parent.Parent.PlayerData.PlayerDataService)
local ProgressionCatalog = require(script.Parent.ProgressionCatalog)

local ProgressionService = {}

local function isValidAmount(amount: number): boolean
	return type(amount) == "number"
		and amount > 0
		and amount % 1 == 0
		and amount < math.huge
end

local function getActivePlayerData(player: Player)
	if not player:IsDescendantOf(Players) then
		return nil
	end

	return PlayerDataService:GetPlayerData(player)
end

local function getLevelForXP(xp: number): number
	local level = 1

	while ProgressionCatalog[level + 1] ~= nil
		and xp >= ProgressionCatalog[level + 1] do
		level += 1
	end

	return level
end

function ProgressionService:AddXP(player: Player, amount: number): boolean
	if not isValidAmount(amount) then
		return false
	end

	local playerData = getActivePlayerData(player)

	if not playerData then
		return false
	end

	playerData.XP += amount
	playerData.Level = getLevelForXP(playerData.XP)
	PlayerDataService:SyncPlayerAttributes(player)

	return true
end

function ProgressionService:GetLevel(player: Player): number?
	local playerData = getActivePlayerData(player)

	if not playerData then
		return nil
	end

	return playerData.Level
end

function ProgressionService:GetXP(player: Player): number?
	local playerData = getActivePlayerData(player)

	if not playerData then
		return nil
	end

	return playerData.XP
end

function ProgressionService:GetXPRequirement(level: number): number?
	if type(level) ~= "number" or level % 1 ~= 0 or level < 1 then
		return nil
	end

	return ProgressionCatalog[level]
end

return ProgressionService
