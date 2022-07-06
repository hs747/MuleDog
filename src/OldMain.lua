-- wafflechad's hoarsekat clone, for pablo :) (imperative beauty)
local source = script.Parent
local Config = require(source.Config)
local Widget = require(source.Widget)
local ViewExplorer = require(source.ViewExplorer)
local View = require(source.View)
local Maid = require(source.Lib.Maid)

local masterMaid = Maid.new()

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

local candidateMaid = Maid.new()
masterMaid:GiveTask(candidateMaid)
-- handle getting view explorer children
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

-- return initializer function
return function(plgn, getToolbar, getToolbarButton, getWidget)
	plugin = plgn 

	-- initiate plugin toolbar & button
	toolbar = getToolbar(Config.pluginTitle)
	toggleButton = getToolbarButton(toolbar, "Toggle", "", "")
	toggleButton.ClickableWhenViewportHidden = true
	masterMaid:GiveTask(toggleButton.Click:Connect(function() 
		if isOpen then
			close()
		else
			open()
		end
	end))

	-- init widget
	Widget.init(getWidget, close)

	-- initiate views & view explorer
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

	-- return cleanup handler
	return function()
		print("cleaning up main")
		Widget.cleanup()
		ViewExplorer.cleanup()
		masterMaid:Destroy()
	end
end