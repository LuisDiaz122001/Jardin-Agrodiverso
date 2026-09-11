--!strict

-- CropVisualService sincroniza la visibilidad de cultivos ya creados en Studio.
-- Solo modifica Transparency de BasePart existentes dentro de CornCrop.

local Workspace = game:GetService("Workspace")

type PlotVisualBinding = {
	parts: {BasePart},
	originalTransparency: {[BasePart]: number},
	connection: RBXScriptConnection?,
}

local CropVisualService = {}

local initialized = false
local bindingsByPlot: {[Instance]: PlotVisualBinding} = {}

local function findFarmRoot(): Instance?
	local stations = Workspace:FindFirstChild("Stations")

	if not stations then
		return nil
	end

	return stations:FindFirstChild("Farm")
end

local function applyCropVisibility(binding: PlotVisualBinding, cropState: unknown)
	local isVisible = cropState == "Growing" or cropState == "Ready"

	for _, part in binding.parts do
		if part.Parent then
			if isVisible then
				part.Transparency = binding.originalTransparency[part]
			else
				part.Transparency = 1
			end
		end
	end
end

local function bindCornPlot(plot: Instance)
	if bindingsByPlot[plot] or plot:GetAttribute("CropType") ~= "Corn" then
		return
	end

	local cornCrop = plot:FindFirstChild("CornCrop")

	if not cornCrop or not cornCrop:IsA("Model") then
		return
	end

	local parts = {}
	local originalTransparency = {}

	for _, descendant in cornCrop:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
			originalTransparency[descendant] = descendant.Transparency
		end
	end

	if #parts == 0 then
		return
	end

	local binding: PlotVisualBinding = {
		parts = parts,
		originalTransparency = originalTransparency,
		connection = nil,
	}

	bindingsByPlot[plot] = binding
	applyCropVisibility(binding, plot:GetAttribute("CropState"))

	binding.connection = plot:GetAttributeChangedSignal("CropState"):Connect(function()
		applyCropVisibility(binding, plot:GetAttribute("CropState"))
	end)
end

function CropVisualService:Initialize()
	if initialized then
		return
	end

	local farmRoot = findFarmRoot()

	if not farmRoot then
		warn("CropVisualService no encontró Workspace.Stations.Farm.")
		return
	end

	for _, descendant in farmRoot:GetDescendants() do
		if descendant:GetAttribute("CropType") == "Corn" then
			bindCornPlot(descendant)
		end
	end

	initialized = true
end

return CropVisualService
