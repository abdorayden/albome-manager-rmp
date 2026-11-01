local api = require("rmp.rmp")

local TextStyle = api.TextStyle
local Options = api.Options
local Scroller = api.Scroller

return function(ctx, vterm, x, y, width, height)
    local colors = ctx.colors
    local state = ctx.plugin_state

    local title = #state.selected_songs > 1 and "Select Album for " .. #state.selected_songs .. " Songs" or
        "Select Album for Song"

    vterm:writeText(x, y, title, colors.info, colors.bg, TextStyle.Bold)
    vterm:writeText(x, y + height - 1, "ENTER: Select | ESC: Back", colors.fg, colors.bg)

    if not state.album_selector_scroller then
        local album_names = {}
        for _, album in ipairs(state.albums) do
            table.insert(album_names, album.name .. " (" .. #album.songs .. " songs)")
        end

        local options = Options(album_names)
        options:setColorFocus(colors.highlight)
        state.album_selector_scroller = Scroller(height - 3, options)
    end

    local visible_items, start_index, focus_index = state.album_selector_scroller:getVisible()

    local list_y = y + 2
    for i, item in ipairs(visible_items) do
        local item_y = list_y + i - 1
        local is_focused = (i == focus_index)
        local fg_color = is_focused and colors.highlight or colors.fg
        local bg_color = is_focused and colors.active_bg or colors.bg
        local prefix = is_focused and ctx.UI.SELECTED_PREFIX or ctx.UI.UNSELECTED_PREFIX
        local style = is_focused and TextStyle.Bold or TextStyle.Normal

        local display_text = ctx.clip_text(item.text, width - #prefix - 1)
        vterm:writeText(x, item_y, prefix .. string.rep(" ", width - #prefix - #display_text), fg_color, bg_color)
        vterm:writeText(x, item_y, prefix .. display_text, fg_color, bg_color, style)
    end
end
