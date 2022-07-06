-- Wafflechad's plugin loader --
--[[
	Heavily inspired by TiffanyXXX's loader in the Tag Editor plugin.
	Depending on the constant configuration, this will load a plugin from an instance in the game when studio starts up.
	This allows for rapid testing without having to reload the plugin using the plugin debugger.
	The 'Libraries' folder should be populated by static modulescripts that will not need to be changed in development. 
	This also includes anything the plugin driver (this script) depends on such as Quenty's maid class.
]]

script.Disabled = true

-- Driver Configuration --
local USE_DEV_SOURCE = true
local DEV_SOURCE = "ServerStorage/DevPluginSource"
local DEV_VERBOSE = true


local isStudio = game:GetService("RunService"):IsStudio()
local function verbosePrint(message: string)
	if DEV_VERBOSE and isStudio then
		print(message)
	end
end
verbosePrint("Plugin driver loading.")

local pluginSource: Folder
local unloadCallback: () -> ()

local function retrieveDevSource(): Folder?
	local parent = game
	for childName in string.gmatch(DEV_SOURCE, "[^/]+") do
		local child = parent:FindFirstChild(childName)
		if not child then
			error(string.format("Could not follow path. \"%s\" is not a child of %s", childName, parent:GetFullName()))
		end
		parent = child
	end
	if not parent then
		error(string.format("Could not follow path: \"%s\"", DEV_SOURCE))
	end
	return parent
end

local pluginInterface = {}

local toolbars = {}
local toolbarButtons = {}
local dockWidgetGuis = {}

function pluginInterface.getToolbar(name: string?): PluginToolbar
	local toolbar = plugin:CreateToolbar(name)
	table.insert(toolbars, toolbar)
	return toolbar
end

-- for now, id must be unique to the plugin interface, not the toolbar
function pluginInterface.getToolbarButton(toolbar: PluginToolbar, id: string, toolTip: string, icon: string, text: string): PluginToolbarButton
	--[[local button = toolbar:CreateButton(id, toolTip, icon, text)
	table.insert(toolbarButtons, button)
	return button]]
	local button = toolbarButtons[id]
	if button then
		return button
	end
	button = toolbar:CreateButton(id, toolTip, icon, text)
	toolbarButtons[id] = button
	return button
end

function pluginInterface.getWidget(id: string, widgetInfo: DockWidgetPluginGuiInfo): DockWidgetPluginGui
	local widget = plugin:CreateDockWidgetPluginGui(id, widgetInfo)
	table.insert(dockWidgetGuis, widget)
	return widget
end

function pluginInterface.bindToUnload(callback)
	unloadCallback = callback
end

local function unload()
	if unloadCallback then
		unloadCallback()
	end
	unloadCallback = nil
	-- cleanup objects
	for _, widget in ipairs(dockWidgetGuis) do
		widget:Destroy()
	end
	for _, toolbarButton in ipairs(toolbarButtons) do
		toolbarButton:Destroy()
	end
	for _, toolbar in ipairs(toolbars) do
		toolbar:Destroy()
	end
end

local function load()
	local succ, err = pcall(unload)
	if not succ then
		warn("Plugin failed to unload. Reason: ", err)
	end
	verbosePrint("Reloading plugin.")
	local source = pluginSource:Clone()
	local main = require(source.Modules.Main)
	main.load(pluginInterface)
end

local function watch(instance: Instance)
	instance.Changed:Connect(load)
	for _, child in ipairs(instance:GetChildren()) do
		watch(child)
	end
	instance.ChildAdded:Connect(function(child)
		watch(child)
	end)
end

verbosePrint("Plugin loading source.")
if USE_DEV_SOURCE then
	pluginSource = retrieveDevSource()
	if not pluginSource then
		warn("Can not retrieve dev-source, using plugin source.")
	else
		verbosePrint("Loaded plugin from dev-source.")
	end
	watch(pluginSource.Modules)
end
if not pluginSource then
	pluginSource = script.Parent
end
load()

plugin.Unloading:Connect(unload)