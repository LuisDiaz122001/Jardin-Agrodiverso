--!strict

local DataContract = require(script.Parent.DataContract)

local DataValidator = {}

local function isFiniteInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value % 1 == 0
end

local function isValidItemId(itemId: any): boolean
	return type(itemId) == "string"
		and itemId ~= ""
		and #itemId <= 100
		and string.match(itemId, "^%S+$") ~= nil
end

function DataValidator:Normalize(rawData: any): (DataContract.PersistentData?, boolean, string?)
	if type(rawData) ~= "table" then
		return nil, false, "El payload normalizado no es una tabla."
	end

	if rawData.DataVersion ~= DataContract.CURRENT_DATA_VERSION then
		return nil, false, "DataVersion no soportada durante la validación."
	end

	local wasRepaired = false
	local coins = rawData.Coins
	local xp = rawData.XP

	if not isFiniteInteger(coins) or coins < 0 or coins > DataContract.MAX_COINS then
		coins = 100
		wasRepaired = true
	end

	if not isFiniteInteger(xp) or xp < 0 or xp > DataContract.MAX_XP then
		xp = 0
		wasRepaired = true
	end

	if rawData.Inventory == nil then
		rawData.Inventory = {}
		wasRepaired = true
	elseif type(rawData.Inventory) ~= "table" then
		return nil, false, "Inventory no es una tabla; el payload no es reconocible."
	end

	local inventory: {[string]: number} = {}

	for itemId, amount in rawData.Inventory do
		if not isValidItemId(itemId) then
			wasRepaired = true
			continue
		end

		if not isFiniteInteger(amount) or amount < 0 or amount > DataContract.MAX_ITEM_COUNT then
			wasRepaired = true
			continue
		end

		if amount > 0 then
			inventory[itemId] = amount
		else
			wasRepaired = true
		end
	end

	return {
		DataVersion = DataContract.CURRENT_DATA_VERSION,
		Coins = coins,
		XP = xp,
		Inventory = inventory,
	}, wasRepaired, nil
end

return DataValidator
