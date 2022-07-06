local source = script.Parent.Parent
local GuiUtil = require(source.Libraries.StudioWidgets.GuiUtilities)
local Config = require(source.Modules.Config)
local ViewExplorer = require(source.Modules.ViewExplorer)

local backgroundFrame = Instance.new("Frame") do
	backgroundFrame.Name = "Background"
	backgroundFrame.BorderSizePixel = 0
	backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
	GuiUtil.syncGuiElementBackgroundColor(backgroundFrame)
end

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	true,
	200,
	200,
	200,
	200)

local widgetObj 
local widget = {}

function widget.getObject()
	return widgetObj
end

function widget.open()
	widgetObj.Enabled = true
end

function widget.close()
	widgetObj.Enabled = false
end

function widget.init(pluginInterface, closeCallback)
	widgetObj = pluginInterface.getWidget(Config.pluginTitle, widgetInfo)
	widgetObj.Title = "Waffleview"
	widgetObj:BindToClose(closeCallback)
	-- populate
	backgroundFrame.Parent = widgetObj
end

function widget.cleanup()
	widgetObj:Destroy()
end

return widget