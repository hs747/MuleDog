# Muledog
## Building:
Refer to .vscode/tasks.json for building to your local plugin folder and making a test place w/ rojo.

When deploying to publish, make the USE_DEV_SOURCE flag in src/Driver.server.lua false.
## Use:
Same usage as hoarsekat.
```lua
-- example story:
return function(parent: Frame)
	-- perform actions here
	return function()
		-- perform clean actions here
	end
end
```