--!strict

local XP_REQUIREMENTS: {[number]: number} = {
	[2] = 10,
	[3] = 25,
	[4] = 50,
}

local ProgressionCatalog = {}

function ProgressionCatalog.GetLevelForXP(xp: number): number
	local level = 1

	while XP_REQUIREMENTS[level + 1] ~= nil
		and xp >= XP_REQUIREMENTS[level + 1] do
		level += 1
	end

	return level
end

function ProgressionCatalog.GetXPRequirement(level: number): number?
	return XP_REQUIREMENTS[level]
end

return ProgressionCatalog
