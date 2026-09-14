--!strict

local DataContract = require(script.Parent.DataContract)

local DataMigration = {}

local function isValidInteger(value: any, maximum: number): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value % 1 == 0
		and value >= 0
		and value <= maximum
end

function DataMigration:ToCurrentVersion(rawData: any): (any?, boolean, string?)
	if rawData == nil then
		return DataContract.CreateDefaultData(), false, nil
	end

	if type(rawData) ~= "table" then
		return nil, false, "El payload persistente no es una tabla."
	end

	local sourceVersion = rawData.DataVersion

	if sourceVersion == nil then
		sourceVersion = 0
	elseif type(sourceVersion) ~= "number"
		or sourceVersion ~= sourceVersion
		or sourceVersion == math.huge
		or sourceVersion == -math.huge
		or sourceVersion % 1 ~= 0 then
		return nil, false, "DataVersion inválido."
	end

	if sourceVersion > DataContract.CURRENT_DATA_VERSION then
		return nil, false, "DataVersion futura no soportada."
	end

	if sourceVersion < 0 then
		return nil, false, "Versión legacy no reconocible."
	end

	if sourceVersion == DataContract.CURRENT_DATA_VERSION and rawData.Seeds == nil then
		return rawData, false, nil
	end

	local inventory = {}

	if rawData.Inventory ~= nil and type(rawData.Inventory) ~= "table" then
		return nil, false, "Inventory legacy no es una tabla."
	end

	if type(rawData.Inventory) == "table" then
		for itemId, amount in rawData.Inventory do
			inventory[itemId] = amount
		end
	end

	local legacySeeds = rawData.Seeds
	local inventorySeeds = inventory["Seeds"]
	local validLegacySeeds = isValidInteger(legacySeeds, DataContract.MAX_ITEM_COUNT)
	local validInventorySeeds = isValidInteger(inventorySeeds, DataContract.MAX_ITEM_COUNT)

	if validLegacySeeds or validInventorySeeds then
		local canonicalSeeds = 0

		if validLegacySeeds then
			canonicalSeeds = legacySeeds
		end

		if validInventorySeeds and inventorySeeds > canonicalSeeds then
			canonicalSeeds = inventorySeeds
		end

		if canonicalSeeds > 0 then
			inventory["Seeds"] = canonicalSeeds
		else
			inventory["Seeds"] = nil
		end
	else
		inventory["Seeds"] = nil
	end

	return {
		DataVersion = DataContract.CURRENT_DATA_VERSION,
		Coins = rawData.Coins,
		XP = rawData.XP,
		Inventory = inventory,
	}, true, nil
end

return DataMigration
