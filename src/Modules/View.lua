-- handles the rendering and tracking updating of a view
local source = script.Parent.Parent
local Maid = require(source.Libraries.Maid)

local view = {}

-- view state
local state: {
	script: ModuleScript?,
	changeMaid: any?,
	cleanup: () -> ()?,
	container: Frame?,
} = {}


local container = Instance.new("Frame") do
	container.Position = UDim2.new(0, 200, 0, 0)
	container.Size = UDim2.new(1, -200, 1, 0)
	container.BackgroundTransparency = 1
end

local function tempContainer()
	local temp = Instance.new("Frame") do
		temp.Position = UDim2.new(0, 0, 0, 0)
		temp.Size = UDim2.new(1, 0, 1, 0)
		temp.BackgroundTransparency = 1
		temp.Parent = container
	end
	return temp
end

local function cleanup()
	if state.cleanup then
		task.spawn(state.cleanup)
	end
	if state.container then
		state.container:Destroy()
	end
	if state.changeMaid then
		state.changeMaid:DoCleaning()
	end
	state.cleanup = nil
	state.container = nil
	state.changeMaid = nil
end

-- the following is borrowed heavily from hoarsekat (thanks kampfkarren)
function view.load(script)
	local loadState = {
		script = script,
		cache = {},
		shared = {},
	}
	state.changeMaid = Maid.new()
	local function requireOverride(m: ModuleScript)
		if loadState.cache[m] then
			return loadState.cache[m]
		end
		state.changeMaid:GiveTask(m.Changed:Connect(function()
			if state.script and state.script == script then
				cleanup()
				view.load(script)
			end
		end))
		local func, err = loadstring(m.Source, m:GetFullName())
		if not func then
			error(("[Muledog]: Modulescript [%s] had an error while loading.\nError: %s"):format(m:GetFullName(), err))
		end
		-- may want to override env funcs in the future to prevent required from gaining access to the plugin environment
		local fenv = {
			require = requireOverride,
			script = m,
			_G = loadState.shared,
			shared = loadState.shared,

		}
		setfenv(func, setmetatable(fenv, {__index = getfenv()}))
		local ret = func()
		loadState.cache[m] = ret
		return ret
	end
	
	-- run view
	local createFunc = requireOverride(script)
	state.container = tempContainer()
	task.spawn(function()
		state.cleanup = createFunc(state.container)
	end)
end

function view.detach()
	cleanup()
	state = {}
end

function view.attach(module: ModuleScript)
	view.detach()
	state = {
		script = module,
	}
	view.load(state.script)
end

function view.cleanup()
	cleanup()
	state = {}
end

function view.parent(parent)
	container.Parent = parent
end

return view