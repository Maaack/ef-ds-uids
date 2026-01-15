# Ef Ds UIDs
For Godot 4.4+

Replaces UIDs from scenes, scripts, imports, and Godot's cache.  

## Why?  

The errors are obnoxious, and the caching is awful.  

The editor doesn't even support fixing any of the warnings and errors it complains about.

So f\*\*\* these UIDs.  

## What?

Supports the following extensions:
- `gd`
- `tres`
- `tscn`
- `wav`
- `mp3`
- `ogg`
- `svg`
- `png`
- `gif`
- `gltf`
- `glb`
- `dae`
- `obj`
- `fbx`


Any format that generates a `.import` file should be supported, but may be missing from the list. The user is encouraged to try adding it to the `UID_IN_IMPORT_FILE_EXTENSIONS` constant in `context_menu_plugin.gd`.

> [!NOTE]  
> Not all of these extensions have been tested, but most generate `.import` files which is what is actually getting content replaced.


## How?  

Right-click on files in the File System Dock, and select `Replace UIDs`. Then restart the editor.

> [!IMPORTANT]  
> The script deletes `.godot/editor/filesystem*` in order to force Godot to rebuild its cache of UIDs.  
> Sometimes though, I've had to nuke the project's entire `.godot/` folder.  
> Issue has been opened: https://github.com/godotengine/godot/issues/115011  

> [!WARNING]  
> Make sure the project is backed-up before using this feature. Users are enouraged to use version control (ie. git).


