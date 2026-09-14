--!strict

local Players = game:GetService("Players")

local PlayerDataService = require(script.Parent.Parent.PlayerData.PlayerDataService)

local CurrencyService = {}

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

function CurrencyService:AddCoins(player: Player, amount: number): boolean
	if not isValidAmount(amount) then
		return false
	end

	local playerData = getActivePlayerData(player)

	if not playerData then
		return false
	end

	playerData.Coins += amount
	PlayerDataService:SyncPlayerAttributes(player)

	return true
end

function CurrencyService:RemoveCoins(player: Player, amount: number): boolean
	if not isValidAmount(amount) then
		return false
	end

	local playerData = getActivePlayerData(player)

	if not playerData or playerData.Coins < amount then
		return false
	end

	playerData.Coins -= amount
	PlayerDataService:SyncPlayerAttributes(player)

	return true
end

function CurrencyService:GetCoins(player: Player): number?
	local playerData = getActivePlayerData(player)

	if not playerData then
		return nil
	end

	return playerData.Coins
end

function CurrencyService:CanAfford(player: Player, amount: number): boolean
	if not isValidAmount(amount) then
		return false
	end

	local playerData = getActivePlayerData(player)

	if not playerData then
		return false
	end

	return playerData.Coins >= amount
end

return CurrencyService
