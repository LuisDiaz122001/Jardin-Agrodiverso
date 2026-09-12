--!strict

-- CropVisualService sincroniza la apariencia de modelos de cultivo ya creados en Studio.
-- CropState sigue siendo la autoridad de gameplay; VisualGrowthStage solo elige la etapa visible.
-- No crea ni elimina instancias del mapa.

local Workspace = game:GetService("Workspace")

local CropCatalog = require(script.Parent.CropCatalog)

type CropDefinition = CropCatalog.CropDefinition
type VisualAppearance = CropCatalog.VisualAppearance

type PlotVisualBinding = {
	model: Model,
	parts: {BasePart},
	originalTransparency: {[BasePart]: number},
	originalScale: number,
	cropStateConnection: RBXScriptConnection?,
	visualStageConnection: RBXScriptConnection?,
	ancestryConnection: RBXScriptConnection?,
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

local function buildVisibleNameSet(partNames: {string}?): {[string]: boolean}?
	if not partNames then
		return nil
	end

	local visibleNames: {[string]: boolean} = {}

	for _, partName in partNames do
		visibleNames[partName] = true
	end

	return visibleNames
end

local function resolveAppearance(definition: CropDefinition, plot: Instance): VisualAppearance?
	local cropState = plot:GetAttribute("CropState")

	if cropState == nil or cropState == "Empty" then
		return nil
	end

	if cropState == "Ready" then
		return definition.ReadyVisual
	end

	if cropState ~= "Growing" then
		return nil
	end

	local visualStage = plot:GetAttribute("VisualGrowthStage")

	if type(visualStage) == "number" then
		local growingStage = CropCatalog.FindGrowingStage(definition, visualStage)

		if growingStage then
			return {
				Id = growingStage.Id,
				Scale = growingStage.Scale,
				VisiblePartNames = growingStage.VisiblePartNames,
			}
		end

		if visualStage == definition.ReadyVisual.Id then
			return definition.ReadyVisual
		end
	end

	local firstStage = CropCatalog.GetFirstGrowingStage(definition)

	if not firstStage then
		return definition.ReadyVisual
	end

	return {
		Id = firstStage.Id,
		Scale = firstStage.Scale,
		VisiblePartNames = firstStage.VisiblePartNames,
	}
end

local function applyAppearance(binding: PlotVisualBinding, appearance: VisualAppearance?)
	if not binding.model.Parent then
		return
	end

	if not appearance then
		binding.model:ScaleTo(binding.originalScale)

		for _, part in binding.parts do
			if part.Parent then
				part.Transparency = 1
			end
		end

		return
	end

	binding.model:ScaleTo(binding.originalScale * appearance.Scale)

	local visibleNames = buildVisibleNameSet(appearance.VisiblePartNames)

	for _, part in binding.parts do
		if part.Parent then
			local isVisible = visibleNames == nil or visibleNames[part.Name] == true

			if isVisible then
				part.Transparency = binding.originalTransparency[part]
			else
				part.Transparency = 1
			end
		end
	end
end

local function unbindPlot(plot: Instance)
	local binding = bindingsByPlot[plot]

	if not binding then
		return
	end

	if binding.cropStateConnection then
		binding.cropStateConnection:Disconnect()
	end

	if binding.visualStageConnection then
		binding.visualStageConnection:Disconnect()
	end

	if binding.ancestryConnection then
		binding.ancestryConnection:Disconnect()
	end

	bindingsByPlot[plot] = nil
end

local function refreshPlotVisual(plot: Instance, definition: CropDefinition)
	local binding = bindingsByPlot[plot]

	if not binding then
		return
	end

	applyAppearance(binding, resolveAppearance(definition, plot))
end

local function bindPlot(plot: Instance)
	if bindingsByPlot[plot] then
		return
	end

	local cropType = plot:GetAttribute("CropType")

	if type(cropType) ~= "string" then
		return
	end

	local definition = CropCatalog.Get(cropType)

	if not definition then
		return
	end

	local visualModel = plot:FindFirstChild(definition.VisualModelName)

	if not visualModel or not visualModel:IsA("Model") then
		return
	end

	local parts = {}
	local originalTransparency = {}

	for _, descendant in visualModel:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
			originalTransparency[descendant] = descendant.Transparency
		end
	end

	if #parts == 0 then
		return
	end

	local binding: PlotVisualBinding = {
		model = visualModel,
		parts = parts,
		originalTransparency = originalTransparency,
		originalScale = visualModel:GetScale(),
		cropStateConnection = nil,
		visualStageConnection = nil,
		ancestryConnection = nil,
	}

	bindingsByPlot[plot] = binding
	applyAppearance(binding, resolveAppearance(definition, plot))

	binding.cropStateConnection = plot:GetAttributeChangedSignal("CropState"):Connect(function()
		refreshPlotVisual(plot, definition)
	end)

	binding.visualStageConnection = plot:GetAttributeChangedSignal("VisualGrowthStage"):Connect(function()
		refreshPlotVisual(plot, definition)
	end)

	binding.ancestryConnection = plot.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			unbindPlot(plot)
		end
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
		if type(descendant:GetAttribute("CropType")) == "string" then
			bindPlot(descendant)
		end
	end

	initialized = true
end

return CropVisualService
