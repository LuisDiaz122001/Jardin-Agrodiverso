--!strict

-- SeedService administra las operaciones de semillas durante la sesión.
-- Los datos pertenecen exclusivamente a PlayerDataService.

local PlayerDataService = require(script.Parent.Parent.PlayerData.PlayerDataService)

local SeedService = {}

local function isValidSeedAmount(amount: number): boolean
	return amount > 0 and amount % 1 == 0 and amount < math.huge
end

function SeedService:GetSeedCount(player: Player): number
	local playerData = PlayerDataService:GetPlayerData(player)

	if not playerData then
		return 0
	end

	return playerData.Seeds
end

function SeedService:AddSeeds(player: Player, amount: number): boolean
	if not isValidSeedAmount(amount) then
		return false
	end

	local playerData = PlayerDataService:GetPlayerData(player)

	if not playerData then
		return false
	end

	playerData.Seeds += amount
	return true
end

function SeedService:ConsumeSeed(player: Player): boolean
	local playerData = PlayerDataService:GetPlayerData(player)

	if not playerData or playerData.Seeds < 1 then
		return false
	end

	playerData.Seeds -= 1
	return true
end

return SeedService
