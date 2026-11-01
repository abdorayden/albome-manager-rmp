local api = require("rmp.rmp")

local TextStyle = api.TextStyle
local Options = api.Options
local Scroller = api.Scroller

return function(ctx, vterm, x, y, width, height)
    local colors = ctx.colors
    local state = ctx.plugin_state
    local playlist = ctx.get_sound_playlist()

    vterm:writeText(x, y, "Add Songs from Current Playlist (" .. #playlist .. ")", colors.info, colors.bg,
        TextStyle.Bold)

    local help_text
    if state.multi_select_mode then
        help_text = "SPACE: Toggle | ENTER: Add " ..
            #state.selected_songs .. " songs | M: Single-Select Mode | ESC: Back"
    else
        help_text = "ENTER: Add Song | M: Multi-Select Mode | ESC: Back"
    end
    vterm:writeText(x, y + height - 1, help_text, colors.fg, colors.bg)

    if #playlist == 0 then
        vterm:writeText(x, y + 3, "The current playlist is empty.", colors.error, colors.bg)
        vterm:writeText(x, y + 4, "Load songs into the player to add them to an album.", colors.fg, colors.bg)
        return
    end

    if not state.song_scroller then
        local options = Options(playlist)
        options:setColorFocus(colors.highlight)
        state.song_scroller = Scroller(height - 3, options)
    end

    local visible_items, start_index, focus_index = state.song_scroller:getVisible()

    local list_y = y + 2
    for i, item in ipairs(visible_items) do
        local item_y = list_y + i - 1
        local absolute_index = start_index + i - 1
        local is_selected = ctx.is_song_selected(absolute_index)
        local is_focused = (i == focus_index)

        local fg_color = is_selected and colors.selected or (is_focused and colors.highlight or colors.fg)
        local bg_color = is_focused and colors.active_bg or colors.bg
        local style = is_focused and TextStyle.Bold or TextStyle.Normal

        local prefix
        if is_selected then
            prefix = ctx.UI.SELECTED_SONG_PREFIX
        elseif is_focused then
            prefix = ctx.UI.SELECTED_PREFIX
        else
            prefix = ctx.UI.UNSELECTED_PREFIX
        end

        local display_name = item.text:match("([^/\\]+)$") or item.text
        display_name = ctx.clip_text(display_name, width - #prefix - 1)

        vterm:writeText(x, item_y, prefix .. string.rep(" ", width - #prefix - #display_name), fg_color, bg_color)
        vterm:writeText(x, item_y, prefix .. display_name, fg_color, bg_color, style)
    end
end
