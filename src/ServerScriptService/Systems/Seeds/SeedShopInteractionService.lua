--!strict

-- SeedShopInteractionService conecta los prompts existentes del Banco de Semillas.
-- Las compras y sus validaciones permanecen en SeedShopService.

local Workspace = game:GetService("Workspace")

local SeedShopService = require(script.Parent.SeedShopService)

local SeedShopInteractionService = {}

local DEBUG_SEED_SHOP = true
local initialized = false
local connectedPrompts: {[ProximityPrompt]: RBXScriptConnection} = {}

local function getSeedId(prompt: ProximityPrompt): string?
	local seedId = prompt:GetAttribute("SeedId")

	if type(seedId) ~= "string" or seedId == "" then
		return nil
	end

	return seedId
end

local function getPurchaseAmount(prompt: ProximityPrompt): number?
	local purchaseAmount = prompt:GetAttribute("PurchaseAmount")

	if type(purchaseAmount) ~= "number"
		or purchaseAmount <= 0
		or purchaseAmount % 1 ~= 0
		or purchaseAmount == math.huge
		or purchaseAmount == -math.huge
		or purchaseAmount ~= purchaseAmount then
		return nil
	end

	return purchaseAmount
end

local function connectPrompt(prompt: ProximityPrompt)
	if connectedPrompts[prompt] then
		return
	end

	connectedPrompts[prompt] = prompt.Triggered:Connect(function(player)
		local seedId = getSeedId(prompt)
		local purchaseAmount = getPurchaseAmount(prompt)

		if not seedId or not purchaseAmount or not SeedShopService:GetSeedPrice(seedId) then
			warn("SeedShopInteractionService encontró un prompt con configuración inválida:", prompt:GetFullName())
			return
		end

		local purchaseSuccessful = SeedShopService:BuySeeds(player, seedId, purchaseAmount)

		if DEBUG_SEED_SHOP then
			print(
				string.format(
					"[SeedShopDebug] Prompt: %s | SeedId: %s | PurchaseAmount: %d | BuySeeds: %s",
					prompt:GetFullName(),
					seedId,
					purchaseAmount,
					tostring(purchaseSuccessful)
				)
			)
		end
	end)
end

function SeedShopInteractionService:Initialize()
	if initialized then
		return
	end

	local stations = Workspace:FindFirstChild("Stations")
	local seedShop = stations and stations:FindFirstChild("SeedShop")

	if not seedShop then
		warn("SeedShopInteractionService no encontró Workspace.Stations.SeedShop.")
		return
	end

	for _, descendant in seedShop:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			connectPrompt(descendant)
		end
	end

	initialized = true

	if DEBUG_SEED_SHOP then
		print("SeedShopInteractionService inicializado correctamente.")
	end
end

return SeedShopInteractionService
