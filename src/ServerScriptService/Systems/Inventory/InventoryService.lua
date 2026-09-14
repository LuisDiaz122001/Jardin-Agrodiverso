--!strict

-- InventoryService centraliza las operaciones sobre los objetos del jugador.
-- Seeds permanece en PlayerData.Seeds por compatibilidad con el sistema actual.

local PlayerDataService = require(script.Parent.Parent.PlayerData.PlayerDataService)

local InventoryService = {}

local LEGACY_SEEDS_ITEM_ID = "Seeds"

local function isValidItemId(itemId: string): boolean
	return type(itemId) == "string" and itemId ~= "" and string.match(itemId, "^%S+$") ~= nil
end

local function isValidAmount(amount: number): boolean
	return type(amount) == "number"
		and amount > 0
		and amount % 1 == 0
		and amount < math.huge
end

local function getPlayerData(player: Player)
	return PlayerDataService:GetPlayerData(player)
end

function InventoryService:GetItemCount(player: Player, itemId: string): number
	if not isValidItemId(itemId) then
		return 0
	end

	local playerData = getPlayerData(player)

	if not playerData then
		return 0
	end

	if itemId == LEGACY_SEEDS_ITEM_ID then
		return playerData.Seeds
	end

	return playerData.Inventory[itemId] or 0
end

function InventoryService:AddItem(player: Player, itemId: string, amount: number): boolean
	if not isValidItemId(itemId) or not isValidAmount(amount) then
		return false
	end

	local playerData = getPlayerData(player)

	if not playerData then
		return false
	end

	if itemId == LEGACY_SEEDS_ITEM_ID then
		playerData.Seeds += amount
	else
		playerData.Inventory[itemId] = (playerData.Inventory[itemId] or 0) + amount
	end

	PlayerDataService:SyncPlayerAttributes(player)
	return true
end

function InventoryService:RemoveItem(player: Player, itemId: string, amount: number): boolean
	if not isValidItemId(itemId) or not isValidAmount(amount) then
		return false
	end

	local playerData = getPlayerData(player)

	if not playerData or self:GetItemCount(player, itemId) < amount then
		return false
	end

	if itemId == LEGACY_SEEDS_ITEM_ID then
		playerData.Seeds -= amount
	else
		local remainingAmount = playerData.Inventory[itemId] - amount

		if remainingAmount == 0 then
			playerData.Inventory[itemId] = nil
		else
			playerData.Inventory[itemId] = remainingAmount
		end
	end

	PlayerDataService:SyncPlayerAttributes(player)
	return true
end

function InventoryService:HasItem(player: Player, itemId: string, amount: number): boolean
	if not isValidItemId(itemId) or not isValidAmount(amount) then
		return false
	end

	return self:GetItemCount(player, itemId) >= amount
end

return InventoryService
