local source = script.Parent.Parent
local Config = require(source.Modules.Config)
local Widget = require(source.Modules.Widget)
local ViewExplorer = require(source.Modules.ViewExplorer)
local View = require(source.Modules.View)
local Maid = require(source.Libraries.Maid)

local main = {}

local masterMaid = Maid.new()
local candidateMaid = Maid.new()
masterMaid:GiveTask(candidateMaid)

local toolbar: PluginToolbar
local toggleButton: PluginToolbarButton

local isOpen
local function open()
	isOpen = true
	toggleButton:SetActive(true)
	Widget.open()
end

local function close()
	isOpen = false
	toggleButton:SetActive(false)
	Widget.close()
end

local function isCandidate(instance)
	return instance:IsA("ModuleScript")
end

local function isView(instance)
	return instance:IsA("ModuleScript") and instance.Name:match(string.format("%%.%s$", Config.viewSuffix))
end

local function addView(instance)
	if isView(instance) then
		ViewExplorer.addScript(instance)
	end
	if isCandidate(instance) then
		candidateMaid[instance] = instance:GetPropertyChangedSignal("Name"):Connect(function()
			if isView(instance) then
				print(("Adding %s as script"):format(instance:GetFullName()))
				ViewExplorer.addScript(instance)
			else
				print(("Removing %s as script"):format(instance:GetFullName()))
				ViewExplorer.removeScript(instance)
			end
		end)
	end
	
end

function main.unload()
	-- handle unloading
	print("Muledog: Unloading.")
	Widget.cleanup()
	ViewExplorer.cleanup()
	masterMaid:Destroy()
end

function main.load(pluginInterface)
	-- bind unload
	pluginInterface.bindToUnload(main.unload)

	-- init
	toolbar = pluginInterface.getToolbar(Config.pluginTitle)
	toggleButton = pluginInterface.getToolbarButton(toolbar, "ToggleButton", "", "", "" ,"")
	masterMaid:GiveTask(toggleButton.Click:Connect(function() 
		if isOpen then
			close()
		else
			open()
		end
	end))

	-- init widget
	Widget.init(pluginInterface, close)

	-- initiate views & explorer
	ViewExplorer.setServices(Config.scanServices)
	ViewExplorer.parent(Widget.getObject())
	View.parent(Widget.getObject())
	for _, serviceName in ipairs(Config.scanServices) do
		local service
		local succ, err = pcall(function()
			service = game:GetService(serviceName)
		end)
		if succ and service then
			for _, child in ipairs(service:GetDescendants()) do
				addView(child)
			end
			masterMaid:GiveTask(service.DescendantAdded:Connect(function(child) 
				addView(child)
			end))
		end
	end
end

return main