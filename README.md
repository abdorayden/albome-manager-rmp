# Albome Manager for RMP

Albome Manager is an RMP plugin for organizing songs from the current player playlist into named albums. You can create albums, add one or several playlist tracks, play an album or a track, remove tracks, and delete albums.

## Requirements

- RMP installed and configured.
- The plugin installed in RMP's plugin directory as `albome-manager-rmp`.
- A playlist loaded in RMP to add songs. Album browsing and creation work without a loaded playlist.

## Install and enable

Install or clone this repository into `~/.rmp/plugins/albome-manager-rmp` (use the equivalent RMP plugin directory on your system). Add the plugin to `~/.rmp/init.lua`:

```lua
raymp:plug {
    name = "albome-manager-rmp"
}

raymp.albome_manager_plugin = {}
raymp.albome_manager_plugin.key = api.KEY_SHIFT_A
```

The key setting is optional; the plugin defaults to `api.KEY_SHIFT_A` (Shift+A) when it is not set. Change the value to another key constant provided by your RMP version to use a different shortcut. The plugin is opened and closed with the configured key.

## Use

The main menu provides **View Albums**, **Create New Album**, **Add Songs from Playlist**, and **Exit Album Manager**. Use Up/Down or `k`/`j` to move through lists and Enter to choose an item. Press Escape to go back or exit the manager.

| Screen | Keys | Action |
| --- | --- | --- |
| Albums | Enter | Load the selected album as the player's playlist |
| Albums | `s` | View tracks in the selected album |
| Albums | `d` | Delete the selected album (the default album is protected) |
| Album tracks | Enter | Play the selected track |
| Album tracks | `d` | Remove the selected track from the album |
| Add songs | Enter | Select a track to add |
| Add songs | `m`, then Space | Toggle multi-select and mark tracks |
| Add songs | Enter | Choose an album for the selected track(s) |
| Album selection | Enter | Add the selected track(s) to the album |

Albums can be created from the main menu. Names must be non-empty and unique, ignoring letter case. Changes are held in memory until you exit with unsaved changes and choose **Save and Exit**. **Exit Without Saving** discards pending edits; **Cancel** returns to the manager.

## Configuration

The plugin's user-facing setting is `raymp.albome_manager_plugin.key`, configured in `~/.rmp/init.lua` as shown above. It uses RMP's current theme for its colors, with terminal color fallbacks when theme colors are unavailable. The `info_color` item mentioned in a comment in `init.lua` is not currently wired to a setting.

## Album data

Saved albums are stored as Lua data in:

```text
~/.rmp/plugins/albome-manager-rmp/albomes/init.lua
```

The plugin loads this module on startup and writes it when you choose **Save and Exit**. Track entries are file paths from the current playlist, so moving or deleting a music file can make a saved entry unavailable.

## shared api

plugin share instans of albome lib to other plugins, so they can use the same album data. The shared instance is available as `raymp.albome_manager_plugin.shared_albome` after the plugin is loaded. Other plugins can use it

you can get it through raymp:onDataGet(function(data) end) tunnel

