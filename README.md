# Wafflechad's Plugin Template for Vscode
## Initial Configuration:
1. In .vscode/tasks.json configure the build path for your plugin to match your intended plugin name.
```json
{

"label": "Build to plugin folder",
"type": "shell",
"command": "rojo build --output $env:LOCALAPPDATA/Roblox/Plugins/YOUR_PLUGIN_NAME_HERE.rbxmx plugin.project.json",
"problemMatcher": [],
"group": {
	"kind": "build",
	"isDefault": true
	}
}
```
2. (Optional but suggested) In plugin.project.json configure the name aswell.
```json
{

"name": "PluginTemplate",
"tree": {
	"$className": "Folder",
	"$path": "src"
	}
}
```
3. (Optional) Configure the location and names of the in studio path of the source files that you will be developing with.
In default.project.json configure the location and name of the development source folder.
The default as an example:
```json
"ServerStorage": {
"$className": "ServerStorage",
"DevPluginSource": {
	"$path": "src"
	}
},
```
Then in src/Driver.server.lua configure the DEV_SOURCE constant to match the location in the project json (the path should start with the ancestor service, not game). Example:
```lua
local  DEV_SOURCE  =  "ServerStorage/DevPluginSource"
``` 
4. Build the plugin. Ideally using cntrl+shift+b or opening up the quick pallete and choosing the 'build to plugin folder' task.
5. Build the place. You can either use the quick pallete to execute the 'build testing place' task or run in the terminal
```
rojo build --output testing.rbxlx
```