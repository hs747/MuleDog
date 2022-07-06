local StudioService = game:GetService("StudioService")

local source = script.Parent.Parent
local Maid = require(source.Libraries.Maid)
local GuiUtilities = require(source.Libraries.StudioWidgets.GuiUtilities)
local View = require(source.Modules.View)

local LINE_HEIGHT = 16
local TEXT_HEIGHT = 14
local HEIR_INDENT = 10
local TEXT_FONT = Enum.Font.SourceSans

local viewSelected = Instance.new("BindableEvent")

local container = Instance.new("ScrollingFrame") do
	container.Position = UDim2.fromScale(0, 0)
	container.Size = UDim2.new(0, 200, 1, 0)
	container.BorderSizePixel = 1
	container.BorderMode = Enum.BorderMode.Middle
	container.AutomaticCanvasSize = Enum.AutomaticSize.XY
	GuiUtilities.syncGuiElementBackgroundColor(container)
	GuiUtilities.syncGuiElementBorderColor(container)
end

local containerLayout = Instance.new("UIListLayout") do
	containerLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	containerLayout.Parent = container
end

local function updateDirectoryImage(image, isScript)
	local imageInfo = StudioService:GetClassIcon(isScript and "ModuleScript" or "Folder")
	image.Image = imageInfo.Image
	image.ImageRectOffset = imageInfo.ImageRectOffset
	image.ImageRectSize = imageInfo.ImageRectSize
end

local function directoryImage(isScript)
	local image = Instance.new("ImageLabel") do
		local imageInfo = StudioService:GetClassIcon(isScript and "ModuleScript" or "Folder")
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromOffset(imageInfo.ImageRectSize.X, imageInfo.ImageRectSize.Y)
	end
	updateDirectoryImage(image, isScript)
	return image
end

local function directoryArrow(open)
	local image = Instance.new("ImageButton") do
		image.Image = "rbxasset://textures/StudioSharedUI/arrowSpriteSheet.png" -- had to do some digging for this
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromOffset(9, 9)
		image.ImageRectSize = Vector2.new(12, 12)
		image.ImageRectOffset = Vector2.new(open and 24 or 12, 0)
	end
	return image
end

local function directoryArrowSet(image, open)
	image.ImageRectOffset = Vector2.new(open and 24 or 12, 0)
end

-- hash of services that are valid
local services = {}
-- shows the existing directories
local directories = {}

local selectedDir
local function selectScriptDirectory(dir)
	if selectedDir then
		selectedDir:deselect()
		if selectedDir == dir then
			selectedDir = nil
			return
		end
	end
	selectedDir = dir
	selectedDir:select()
	-- report to listeners
	viewSelected:Fire(selectedDir.Instance)
end

local function removeScriptDirectory(dir)
	local parent = dir.parentDirectory and dir.parentDirectory.instance
	dir = directories[parent]
	print(parent, dir)
	while parent and dir do
		print("removing a parent directory")
		if not dir.isScript and dir.children < 1 then
			print("actually removing a parent directory")
			dir:cleanup()
			directories[dir] = nil
		else
			return
		end
		parent = parent.Parent
		dir = directories[parent]
	end
end

local directory = {} do
	directory.__index = directory
	function directory.new(instance, isScript)
		local self = setmetatable({}, directory)
		self.instance = instance
		self.isScript = isScript
		self.children = 0
		self.open = true
		local frame = Instance.new("Frame") do
			frame.Size = UDim2.new(1, 0, 0, LINE_HEIGHT)
			frame.Position = UDim2.new(0, 0, 0, 0)
			frame.BackgroundTransparency = 1
			frame.ZIndex = -10
			frame.ClipsDescendants = true
			frame.LayoutOrder = isScript and 1 or 0
		end
		local header = Instance.new("TextButton") do
			header.Size = UDim2.new(1, 0, 0, LINE_HEIGHT)
			header.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
			header.BackgroundTransparency = 1
			header.AutoButtonColor = false
			header.Text = ""
			header.Parent = frame
		end
		if isScript then
			header.MouseButton1Click:Connect(function() 
				selectScriptDirectory(self)
			end)
		end
		local sub = Instance.new("Frame") do
			sub.Size = UDim2.new(1, 0, 0, LINE_HEIGHT)
			sub.BackgroundTransparency = 1
			sub.Position = UDim2.new(0, 16, 0, LINE_HEIGHT)
			sub.Name = "ChildContainer"
			sub.Parent = frame
		end
		local layout = Instance.new("UIListLayout") do
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			layout.VerticalAlignment = Enum.VerticalAlignment.Top
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = sub
		end
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
			frame.Size = UDim2.new(1, 0, 0, LINE_HEIGHT + layout.AbsoluteContentSize.Y)
		end)
		local arrowImage = directoryArrow(self.open) do
			arrowImage.AnchorPoint = Vector2.new(0, 0.5)
			arrowImage.Position = UDim2.fromScale(0, 0.5)
			arrowImage.Visible = false
			arrowImage.Parent = header
		end
		arrowImage.MouseButton1Click:Connect(function() 
			self:toggleOpen()
		end)
		local classImage = directoryImage(isScript) do
			classImage.Position = UDim2.new(0, 16, 0, 0)
			classImage.Parent = header
		end
		local nameLabel = Instance.new("TextLabel") do
			nameLabel.BackgroundTransparency = 1
			nameLabel.Size = UDim2.fromScale(1, 1)
			nameLabel.Position = UDim2.new(0, 36, 0, 0)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextYAlignment = Enum.TextYAlignment.Center
			nameLabel.Text = instance.Name
			nameLabel.TextSize = TEXT_HEIGHT
			nameLabel.Font = TEXT_FONT
			GuiUtilities.syncGuiElementFontColor(nameLabel)
			nameLabel.Parent = header
		end
		-- handle instance updating
		self.propConns = {}
		table.insert(self.propConns, instance:GetPropertyChangedSignal("Name"):Connect(function()
			nameLabel.Text = instance.Name
		end))
		table.insert(self.propConns, instance:GetPropertyChangedSignal("Parent"):Connect(function() 
			self:reparent()
		end))
		-- define object variables
		self.frame = frame
		self.header = header
		self.classImage = classImage
		self.arrow = arrowImage
		self.container = sub
		self.layout = layout
		directories[instance] = self
		-- handle the parenting
		self.parentDirectory = nil
		if services[instance] then
			frame.Parent = container
		else
			self.parentDirectory = directories[instance.Parent]
			self.parentDirectory:addChild(self)
		end
		return self
	end

	function directory:toggleOpen()
		self.open = not self.open
		directoryArrowSet(self.arrow, self.open)
		self.frame.Size = self.open and UDim2.new(1, 0, 0, LINE_HEIGHT + self.layout.AbsoluteContentSize.Y) or UDim2.new(1, 0, 0, LINE_HEIGHT)
	end

	function directory:addChild(dir)
		self.children += 1
		self.arrow.Visible = true
		dir.frame.Parent = self.container
	end

	function directory:removeChild(dir)
		self.children -= 1
		self.arrow.Visible = self.children > 0
	end

	function directory:setIsScript(isScript)
		self.isScript = isScript
		if not isScript then
			if self.children < 1 then
				self:cleanup()
				directories[self.instance] = nil
				print("committing self remove")
				removeScriptDirectory(self)
			end
			return
		end
		updateDirectoryImage(self.classImage, isScript)
	end

	function directory:reparent()
		if self.parentDirectory then
			self.parentDirectory:removeChild(self)
		end
		local parent = self.instance.Parent
		local parents = {}
		while not directories[parent] and parent do
			table.insert(parents, parent)
			if services[parent] then
				break
			end
			parent = parent.Parent
		end
		if not parent then
			self:cleanup()
			directories[self.instance] = nil
			if self.isScript then
				removeScriptDirectory(self)
			end
			return
		end
		for i = #parents, 1, -1 do
			local parent = parents[i]
			directory.new(parent)
		end
		--self.frame.Parent = directories[self.instance.Parent].container
		self.parentDirectory = directories[self.instance.Parent]
		self.parentDirectory:addChild(self)
	end

	function directory:cleanup()
		for _, c in ipairs(self.propConns) do
			c:Disconnect()
		end
		pcall(self.frame.Destroy, self.frame) --just in case
	end

	function directory:select()
		self.header.BackgroundTransparency = 0
		View.attach(self.instance)
	end

	function directory:deselect()
		self.header.BackgroundTransparency = 1
		View.detach()
	end
end
	
local viewExplorer = {}

function viewExplorer.onSelected(func)
	return viewSelected.Event:Connect(func)
end

function viewExplorer.addScript(child)
	if directories[child] then
		directories[child]:setIsScript(true)
		return
	end
	-- find the nearest ancestor directory
	local parent = child.Parent
	local parents = {}
	while not directories[parent] and parent do
		table.insert(parents, parent)
		if services[parent] then
			break
		end
		parent = parent.Parent
	end
	-- handle if child was not in one of the approved services
	if not parent then
		return
	end
	for i = #parents, 1, -1 do
		local parent = parents[i]
		directory.new(parent, false)
	end
	directory.new(child, true)
end

function viewExplorer.removeScript(child)
	if directories[child] then
		directories[child]:setIsScript(false)
	end
end

function viewExplorer.setServices(s)
	local t = {}
	for _, serviceName in ipairs(s) do
		local service
		local succ, err = pcall(function()
			service = game:GetService(serviceName)
		end)
		if succ and service then
			t[service] = true
		end
	end
	services = t
end

function viewExplorer.parent(parent)
	container.Parent = parent
	return container
end

function viewExplorer.cleanup()
	for _, d in pairs(directories) do
		d:cleanup()
	end
end

return viewExplorer