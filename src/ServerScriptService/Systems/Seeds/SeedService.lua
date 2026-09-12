--!strict

-- SeedService conserva la API de semillas usada por agricultura.
-- Las operaciones se delegan en InventoryService.

local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)

local SeedService = {}

function SeedService:GetSeedCountByItem(player: Player, itemId: string): number
	return InventoryService:GetItemCount(player, itemId)
end

function SeedService:AddSeedsByItem(player: Player, itemId: string, amount: number): boolean
	return InventoryService:AddItem(player, itemId, amount)
end

function SeedService:ConsumeSeedByItem(player: Player, itemId: string): boolean
	return InventoryService:RemoveItem(player, itemId, 1)
end

function SeedService:GetSeedCount(player: Player): number
	return self:GetSeedCountByItem(player, "Seeds")
end

function SeedService:AddSeeds(player: Player, amount: number): boolean
	return self:AddSeedsByItem(player, "Seeds", amount)
end

function SeedService:ConsumeSeed(player: Player): boolean
	return self:ConsumeSeedByItem(player, "Seeds")
end

return SeedService
