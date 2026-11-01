local api = require("rmp.rmp")

return function(ctx, vterm, x, y, width, height)
    local colors = ctx.colors
    local state = ctx.plugin_state

    local instructions = "Arrow Keys: Navigate | ENTER: Select | ESC: Exit"
    vterm:writeText(x, y, instructions, colors.fg, colors.bg)
    if state.has_unsaved_changes then
        local unsaved_text = "UNSAVED CHANGES"
        vterm:writeText(x + width - #unsaved_text, y, unsaved_text, colors.error, colors.bg, api.TextStyle.Bold)
    end

    local menu_options = {
        "View Albums (" .. #state.albums .. ")",
        "Create New Album",
        "Add Songs from Playlist",
        "Exit Album Manager"
    }

    local menu_start_y = y + 3
    for i, option in ipairs(menu_options) do
        local option_y = menu_start_y + i
        if option_y < y + height then
            local is_selected = (i == state.selected_option)
            local fg_color = is_selected and colors.highlight or colors.fg
            local bg_color = is_selected and colors.active_bg or colors.bg
            local prefix = is_selected and ctx.UI.SELECTED_PREFIX or ctx.UI.UNSELECTED_PREFIX
            local style = is_selected and api.TextStyle.Bold or api.TextStyle.Normal
            vterm:writeText(x, option_y, prefix .. string.rep(" ", width - #prefix - #option), fg_color, bg_color)
            vterm:writeText(x, option_y, prefix .. option, fg_color, bg_color, style)
        end
    end

    if #state.albums > 0 then
        local current_album = state.albums[state.current_album_index]
        local album_info = "Current Album: " .. current_album.name .. " (" .. #current_album.songs .. " songs)"
        vterm:writeText(x, y + height - 1, album_info, colors.info, colors.bg)
    end
end
