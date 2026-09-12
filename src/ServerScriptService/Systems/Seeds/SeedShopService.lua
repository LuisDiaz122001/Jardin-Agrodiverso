--!strict

-- SeedShopService administra las compras de semillas con Coins durante la sesión.
-- No mantiene datos de jugadores: PlayerDataService sigue siendo la autoridad.

local PlayerDataService = require(script.Parent.Parent.PlayerData.PlayerDataService)
local SeedService = require(script.Parent.SeedService)

export type SeedDefinition = {
	ItemId: string,
	Price: number,
}

local SEED_CATALOG: {[string]: SeedDefinition} = {
	CornSeed = {
		ItemId = "Seeds",
		Price = 5,
	},
}

local SeedShopService = {}

local function isValidAmount(amount: number): boolean
	return type(amount) == "number"
		and amount > 0
		and amount % 1 == 0
		and amount < math.huge
end

local function getSeedDefinition(seedId: string): SeedDefinition?
	if type(seedId) ~= "string" then
		return nil
	end

	return SEED_CATALOG[seedId]
end

local function getPurchaseCost(seedDefinition: SeedDefinition, amount: number): number?
	local totalCost = seedDefinition.Price * amount

	if totalCost == math.huge then
		return nil
	end

	return totalCost
end

function SeedShopService:GetSeedPrice(seedId: string): number?
	local seedDefinition = getSeedDefinition(seedId)

	if not seedDefinition then
		return nil
	end

	return seedDefinition.Price
end

function SeedShopService:CanAffordSeeds(player: Player, seedId: string, amount: number): boolean
	local seedDefinition = getSeedDefinition(seedId)

	if not seedDefinition or not isValidAmount(amount) then
		return false
	end

	local playerData = PlayerDataService:GetPlayerData(player)
	local totalCost = getPurchaseCost(seedDefinition, amount)

	if not playerData or not totalCost then
		return false
	end

	return playerData.Coins >= totalCost
end

function SeedShopService:BuySeeds(player: Player, seedId: string, amount: number): boolean
	local seedDefinition = getSeedDefinition(seedId)

	if not seedDefinition or not isValidAmount(amount) then
		return false
	end

	local playerData = PlayerDataService:GetPlayerData(player)
	local totalCost = getPurchaseCost(seedDefinition, amount)

	if not playerData or not totalCost or playerData.Coins < totalCost then
		return false
	end

	-- SeedService debe completar la adición antes de modificar Coins.
	if not SeedService:AddSeeds(player, amount) then
		return false
	end

	playerData.Coins -= totalCost
	return true
end

return SeedShopService
