-- RMP Framework Plugin: Album Manager
-- Manages albums, favorites, and song collections from Sound playlist
-- configurations => {
--  info_color: color
-- }

-- TODO: more advanced albome management (artist , albome name)
-- TODO: make the plugin extensible

local api = require("rmp.rmp")

local PLUGIN_NAME = "Album Manager"
local info_color_override = nil
local use_shared_theme = false
local theme = nil

local UI = {
    Border = {
        h = "─",
        v = "│",
        topLeft = "┌",
        topRight = "┐",
        bottomLeft = "└",
        bottomRight = "┘",
    },
    SELECTED_PREFIX = "❯ ",
    UNSELECTED_PREFIX = "  ",
    SELECTED_SONG_PREFIX = "* ",
}

local MODE_LABELS = {
    main = "Home",
    view_albums = "Albums",
    view_songs = "Songs",
    create_album = "Create",
    add_songs = "Add",
    select_album = "Select",
    confirm_exit = "Exit"
}

local function clip_text(text, max_width)
    if not text or max_width <= 0 then return "" end
    if #text <= max_width then return text end
    if max_width <= 3 then return string.rep(".", max_width) end
    return text:sub(1, max_width - 3) .. "..."
end

local function get_theme_colors()
    local t = theme
    local bg = t and api.colorFromHex(t.BackGround, api.BG) or nil
    return {
        success = (t and api.colorFromHex(t.PrimaryContent, api.FG)) or api.FGColors.Brights.Green,
        error = (t and api.colorFromHex(t.AccentElements, api.FG)) or api.FGColors.Brights.Red,
        info = (t and api.colorFromHex(t.SecondaryContent, api.FG)) or info_color_override or api.FGColors.Brights.Cyan,
        highlight = (t and api.colorFromHex(t.Highlight, api.FG)) or api.FGColors.Brights.Yellow,
        selected = (t and api.colorFromHex(t.MutedElements, api.FG)) or api.FGColors.Brights.Magenta,
        fg = (t and api.colorFromHex(t.BorderColor, api.FG)) or api.FGColors.NoBrights.White,
        border = (t and api.colorFromHex(t.BorderColor, api.FG)) or api.FGColors.NoBrights.White,
        bg = bg,
        active_bg = nil
    }
end

if api.getOs() == api.PlatformType.Windows then
    SAVED_PATH = api.Path.new():getHomePath() .. "\\.rmp\\plugins\\albome-manager-rmp\\albomes\\init.lua"
else
    SAVED_PATH = api.Path.new():getHomePath() .. "/.rmp/plugins/albome-manager-rmp/albomes/init.lua"
end
-- package.path = package.path .. ";" .. SAVED_PATH .. ";"

local plugin_state = {
    active = false,
    mode = "main", -- "main", "create_album", "add_songs", "view_albums", "select_album", "confirm_exit", "view_songs"
    albums = require("albome-manager-rmp.albomes"),
    current_album_index = 1,
    selected_option = 1,
    input_instance = nil,
    sound_instance = nil,
    show_message = false,
    message_text = "",
    message_color = nil,
    message_timer = 0,
    scroller = nil,
    song_scroller = nil,
    album_selector_scroller = nil,
    album_songs_scroller = nil,
    selected_song_index = nil,
    selected_songs = {},
    multi_select_mode = false,
    has_unsaved_changes = false
}

local function show_message(text, color, duration)
    local colors = get_theme_colors()
    plugin_state.show_message = true
    plugin_state.message_text = text or ""
    plugin_state.message_color = color or colors.fg
    plugin_state.message_timer = (duration or 3) * 30 -- Assuming 30 FPS
end

local Albome = require("albome-manager-rmp.lib.albome")
local Extension = require("albome-manager-rmp.lib.extensions")

-- TODO: apply the extension
local _ = Extension(plugin_state)
local albome = Albome(plugin_state, SAVED_PATH, api.FGColors.Brights.Red)

local function get_sound_playlist()
    if plugin_state.sound_instance and plugin_state.sound_instance:instanceOf(api.Sound) then
        return plugin_state.sound_instance:getPlaylist()
    end
    return {}
end

local function update_message_timer()
    if plugin_state.show_message then
        plugin_state.message_timer = plugin_state.message_timer - 1
        if plugin_state.message_timer <= 0 then
            plugin_state.show_message = false
            plugin_state.message_text = ""
        end
    end
end

local function toggle_song_selection(song_index)
    for i, selected_index in ipairs(plugin_state.selected_songs) do
        if selected_index == song_index then
            table.remove(plugin_state.selected_songs, i)
            return false
        end
    end
    table.insert(plugin_state.selected_songs, song_index)
    return true
end

local function clear_selected_songs()
    plugin_state.selected_songs = {}
end

local function is_song_selected(song_index)
    for _, selected_index in ipairs(plugin_state.selected_songs) do
        if selected_index == song_index then
            return true
        end
    end
    return false
end

local render_popup = require("albome-manager-rmp.components.popup")

local function build_render_context()
    return {
        api = api,
        PLUGIN_NAME = PLUGIN_NAME,
        UI = UI,
        MODE_LABELS = MODE_LABELS,
        plugin_state = plugin_state,
        clip_text = clip_text,
        get_sound_playlist = get_sound_playlist,
        is_song_selected = is_song_selected,
        colors = get_theme_colors()
    }
end

local function handle_main_menu_key(key)
    if key == api.KEY_UP or key == api.KEY_K then
        plugin_state.selected_option = plugin_state.selected_option - 1
        if plugin_state.selected_option < 1 then
            plugin_state.selected_option = 4
        end
    elseif key == api.KEY_DOWN or key == api.KEY_J then
        plugin_state.selected_option = plugin_state.selected_option + 1
        if plugin_state.selected_option > 4 then
            plugin_state.selected_option = 1
        end
    elseif key == api.KEY_ENTER then
        if plugin_state.selected_option == 1 then
            plugin_state.mode = "view_albums"
            plugin_state.scroller = nil
        elseif plugin_state.selected_option == 2 then
            plugin_state.mode = "create_album"
            plugin_state.input_instance = nil
        elseif plugin_state.selected_option == 3 then
            plugin_state.mode = "add_songs"
            plugin_state.song_scroller = nil
            plugin_state.selected_song_index = nil
            clear_selected_songs()
        elseif plugin_state.selected_option == 4 then
            if plugin_state.has_unsaved_changes then
                plugin_state.mode = "confirm_exit"
                plugin_state.selected_option = 1
            else
                plugin_state.active = false
            end
        end
    elseif key == api.KEY_ESCAPE then
        if plugin_state.has_unsaved_changes then
            plugin_state.mode = "confirm_exit"
            plugin_state.selected_option = 1
        else
            plugin_state.active = false
        end
    end
end

local function handle_album_list_key(key)
    if not plugin_state.scroller then return end
    local colors = get_theme_colors()

    if key == api.KEY_UP or key == api.KEY_K then
        plugin_state.scroller:prevLine()
    elseif key == api.KEY_DOWN or key == api.KEY_J then
        plugin_state.scroller:nextLine()
    elseif key == api.KEY_ENTER then
        local current_pos = plugin_state.scroller:getCursorPosition()
        plugin_state.current_album_index = current_pos
        local selected_album = plugin_state.albums[current_pos]

        if plugin_state.sound_instance and plugin_state.sound_instance:instanceOf(api.Sound) then
            if #selected_album.songs > 0 then
                plugin_state.sound_instance:setPlaylist(selected_album.songs)
                show_message("Loaded " .. #selected_album.songs .. " songs from " .. selected_album.name, colors.success)
            else
                show_message("Album " .. selected_album.name .. " is empty", colors.error)
            end
        else
            show_message("No Sound instance available", colors.error)
        end
    elseif key == api.KEY_S then
        local current_pos = plugin_state.scroller:getCursorPosition()
        plugin_state.current_album_index = current_pos
        plugin_state.mode = "view_songs"
        plugin_state.album_songs_scroller = nil
    elseif key == api.KEY_D then
        local current_pos = plugin_state.scroller:getCursorPosition()
        local album_name = plugin_state.albums[current_pos].name
        if not plugin_state.albums[current_pos].is_default then
            -- local success, msg = delete_album(current_pos)
            local success, msg = albome:delete(current_pos)
            show_message(msg, success and colors.success or colors.error)
            if success then
                plugin_state.scroller = nil
            end
        else
            show_message("Cannot delete default album", colors.error)
        end
    elseif key == api.KEY_ESCAPE then
        plugin_state.mode = "main"
        plugin_state.scroller = nil
    end
end

local function handle_album_songs_key(key)
    if not plugin_state.album_songs_scroller then return end
    local colors = get_theme_colors()

    local album = plugin_state.albums[plugin_state.current_album_index]

    if key == api.KEY_UP or key == api.KEY_K then
        plugin_state.album_songs_scroller:prevLine()
    elseif key == api.KEY_DOWN or key == api.KEY_J then
        plugin_state.album_songs_scroller:nextLine()
    elseif key == api.KEY_ENTER then
        local current_pos = plugin_state.album_songs_scroller:getCursorPosition()
        if current_pos <= #album.songs then
            local song_path = album.songs[current_pos]

            if plugin_state.sound_instance and plugin_state.sound_instance:instanceOf(api.Sound) then
                plugin_state.sound_instance:setPlaylist({ song_path })
                plugin_state.sound_instance:play()
                local song_name = song_path:match("([^/\\]+)$") or song_path
                show_message("Now playing: " .. song_name, colors.success)
            else
                show_message("No Sound instance available", colors.error)
            end
        end
    elseif key == api.KEY_D then
        local current_pos = plugin_state.album_songs_scroller:getCursorPosition()
        if current_pos <= #album.songs then
            -- local success, msg = remove_song_from_album(plugin_state.current_album_index, current_pos)
            local success, msg = albome:remove_song(plugin_state.current_album_index, current_pos)
            show_message(msg, success and colors.success or colors.error)
            if success then
                plugin_state.album_songs_scroller = nil
            end
        end
    elseif key == api.KEY_ESCAPE then
        plugin_state.mode = "view_albums"
        plugin_state.album_songs_scroller = nil
    end
end

local function handle_create_album_key(key)
    if plugin_state.input_instance then
        local handled = plugin_state.input_instance:processKey(key)

        if plugin_state.input_instance:wasSubmitted() then
            local colors = get_theme_colors()
            local album_name = plugin_state.input_instance:getText()
            -- local success, msg = create_album(album_name)
            local success, msg = albome:create(album_name)
            show_message(msg, success and colors.success or colors.error)

            plugin_state.input_instance = nil
            plugin_state.mode = "main"
        elseif not plugin_state.input_instance:isActive() then
            plugin_state.input_instance = nil
            plugin_state.mode = "main"
        end
    end
end

local function handle_add_songs_key(key)
    if key == api.KEY_ESCAPE then
        plugin_state.mode = "main"
        plugin_state.song_scroller = nil
        plugin_state.selected_song_index = nil
        clear_selected_songs()
        plugin_state.multi_select_mode = false
        return
    end

    if not plugin_state.song_scroller then return end

    if key == api.KEY_M then
        plugin_state.multi_select_mode = not plugin_state.multi_select_mode
        if not plugin_state.multi_select_mode then
            clear_selected_songs()
        end
        return
    end

    if key == api.KEY_UP or key == api.KEY_K then
        plugin_state.song_scroller:prevLine()
    elseif key == api.KEY_DOWN or key == api.KEY_J then
        plugin_state.song_scroller:nextLine()
    elseif key == api.KEY_SPACE and plugin_state.multi_select_mode then
        local current_pos = plugin_state.song_scroller:getCursorPosition()
        toggle_song_selection(current_pos)
    elseif key == api.KEY_ENTER then
        local playlist = get_sound_playlist()

        if plugin_state.multi_select_mode and #plugin_state.selected_songs > 0 then
            plugin_state.mode = "select_album"
            plugin_state.album_selector_scroller = nil
        else
            local current_pos = plugin_state.song_scroller:getCursorPosition()
            if current_pos <= #playlist then
                plugin_state.selected_song_index = current_pos
                plugin_state.mode = "select_album"
                plugin_state.album_selector_scroller = nil
            end
        end
    elseif key == api.KEY_A then
        local playlist = get_sound_playlist()
        if plugin_state.multi_select_mode and #plugin_state.selected_songs > 0 then
            plugin_state.mode = "select_album"
            plugin_state.album_selector_scroller = nil
        else
            local current_pos = plugin_state.song_scroller:getCursorPosition()
            if current_pos <= #playlist then
                plugin_state.selected_song_index = current_pos
                plugin_state.mode = "select_album"
                plugin_state.album_selector_scroller = nil
            end
        end
    end
end

local function handle_album_selector_key(key)
    if not plugin_state.album_selector_scroller then return end
    local colors = get_theme_colors()

    if key == api.KEY_UP or key == api.KEY_K then
        plugin_state.album_selector_scroller:prevLine()
    elseif key == api.KEY_DOWN or key == api.KEY_J then
        plugin_state.album_selector_scroller:nextLine()
    elseif key == api.KEY_ENTER then
        local playlist = get_sound_playlist()
        local selected_album_index = plugin_state.album_selector_scroller:getCursorPosition()

        if plugin_state.multi_select_mode and #plugin_state.selected_songs > 0 then
            local song_paths = {}
            for _, song_index in ipairs(plugin_state.selected_songs) do
                if song_index <= #playlist then
                    table.insert(song_paths, playlist[song_index])
                end
            end

            -- local success, msg = add_multiple_songs_to_album(selected_album_index, song_paths)
            local success, msg = albome:add_multiple_songs(selected_album_index, song_paths)
            show_message(msg, success and colors.success or colors.error)

            plugin_state.mode = "add_songs"
            clear_selected_songs()
            plugin_state.multi_select_mode = false
        else
            if plugin_state.selected_song_index and plugin_state.selected_song_index <= #playlist then
                local song_path = playlist[plugin_state.selected_song_index]
                -- local success, msg = add_song_to_album(selected_album_index, song_path)
                local success, msg = albome:add_song(selected_album_index, song_path)
                show_message(msg, success and colors.success or colors.error)

                plugin_state.mode = "add_songs"
                plugin_state.selected_song_index = nil
            end
        end
    elseif key == api.KEY_ESCAPE then
        plugin_state.mode = "add_songs"
        plugin_state.selected_song_index = nil
        if plugin_state.multi_select_mode then
            clear_selected_songs()
        end
    end
end

local function handle_confirm_exit_key(key)
    if key == api.KEY_UP or key == api.KEY_K then
        plugin_state.selected_option = plugin_state.selected_option - 1
        if plugin_state.selected_option < 1 then
            plugin_state.selected_option = 3
        end
    elseif key == api.KEY_DOWN or key == api.KEY_J then
        plugin_state.selected_option = plugin_state.selected_option + 1
        if plugin_state.selected_option > 3 then
            plugin_state.selected_option = 1
        end
    elseif key == api.KEY_ENTER then
        if plugin_state.selected_option == 1 then
            -- save_albums()
            local err = albome:save()
            if err ~= nil then
                show_message(err)
            end
            plugin_state.active = false
        elseif plugin_state.selected_option == 2 then
            plugin_state.active = false
        elseif plugin_state.selected_option == 3 then
            plugin_state.mode = "main"
        end
    elseif key == api.KEY_ESCAPE then
        plugin_state.mode = "main"
    end
end

local last_mes = nil

if raymp.albome_manager_plugin == nil then
    raymp.albome_manager_plugin = {}
end

if raymp.albome_manager_plugin.key == nil then
    raymp.albome_manager_plugin.key = api.KEY_SHIFT_A
end

return function()
    local terminal_width, terminal_height = raymp:getSize()

    local colors = get_theme_colors()
    albome:setSavedPath(SAVED_PATH)
    albome:setErrorColor(colors.error)


    theme = raymp:getTheme()

    raymp:addEventListener(api.EventType.Keyboard, function(key)
        if key == raymp.albome_manager_plugin.key then
            plugin_state.active = not plugin_state.active
            if plugin_state.active then
                plugin_state.mode = "main"
                plugin_state.selected_option = 1
                plugin_state.scroller = nil
                plugin_state.song_scroller = nil
                plugin_state.album_selector_scroller = nil
                plugin_state.album_songs_scroller = nil
                plugin_state.input_instance = nil
                plugin_state.selected_song_index = nil
                clear_selected_songs()
                plugin_state.multi_select_mode = false
            end
        end
    end)

    raymp:addEventListener(api.EventType.TransformDataPut, function()
        return {
            albome_instance = albome
        }
    end)

    update_message_timer()

    if plugin_state.message_text ~= "" and plugin_state.message_text ~= last_mes then
        last_mes = plugin_state.message_text
        raymp:addEventListener(api.EventType.TransformDataPut, function()
            return {
                notification = {
                    message = plugin_state.message_text,
                    duration = math.floor(plugin_state.message_timer / 30),
                    status = "info"
                },
            }
        end)
    end

    if plugin_state.active then
        raymp:addEventListener(api.EventType.Focuse, function(key)
            if plugin_state.mode == "main" then
                handle_main_menu_key(key)
            elseif plugin_state.mode == "view_albums" then
                handle_album_list_key(key)
            elseif plugin_state.mode == "view_songs" then
                handle_album_songs_key(key)
            elseif plugin_state.mode == "create_album" then
                handle_create_album_key(key)
            elseif plugin_state.mode == "add_songs" then
                handle_add_songs_key(key)
            elseif plugin_state.mode == "select_album" then
                handle_album_selector_key(key)
            elseif plugin_state.mode == "confirm_exit" then
                handle_confirm_exit_key(key)
            end
        end)

        raymp:addEventListener(api.EventType.Sound, function(sound)
            if sound and sound:instanceOf(api.Sound) then
                plugin_state.sound_instance = sound
            end
        end)

        local ctx = build_render_context()
        render_popup(ctx, raymp, terminal_width, terminal_height)

        if plugin_state.mode == "create_album" and plugin_state.input_instance then
            local input_vterm = plugin_state.input_instance:getVterm()
            if input_vterm then
                raymp:merge(input_vterm)
            end
        end
    end
end
