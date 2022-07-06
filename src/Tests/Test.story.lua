-- test dependencies
local component = require(script.Parent.TestDependency)

return function(parent: Instance)
	print("Story running.")
	component(parent)
	return function() 
		print("Story cleaning.")
	end
end