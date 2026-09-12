--!strict

-- SeedService conserva la API de semillas usada por agricultura.
-- Las operaciones se delegan en InventoryService.

local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)

local SeedService = {}

function SeedService:GetSeedCount(player: Player): number
	return InventoryService:GetItemCount(player, "Seeds")
end

function SeedService:AddSeeds(player: Player, amount: number): boolean
	return InventoryService:AddItem(player, "Seeds", amount)
end

function SeedService:ConsumeSeed(player: Player): boolean
	return InventoryService:RemoveItem(player, "Seeds", 1)
end

return SeedService
