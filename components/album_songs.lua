local api = require("rmp.rmp")

local TextStyle = api.TextStyle
local Options = api.Options
local Scroller = api.Scroller

return function(ctx, vterm, x, y, width, height)
    local colors = ctx.colors
    local state = ctx.plugin_state

    local album = state.albums[state.current_album_index]
    vterm:writeText(x, y, "Songs in: " .. album.name .. " (" .. #album.songs .. ")", colors.info, colors.bg,
        TextStyle.Bold)
    vterm:writeText(x, y + 1, string.rep(ctx.UI.Border.h, width), colors.border, colors.bg)
    vterm:writeText(x, y + height - 2, string.rep(ctx.UI.Border.h, width), colors.border, colors.bg)
    vterm:writeText(x, y + height - 1, "ENTER: Play | D: Delete | ESC: Back", colors.fg, colors.bg)

    local list_y = y + 2
    local list_height = height - 4

    if not state.album_songs_scroller then
        local song_names = {}
        for _, song_path in ipairs(album.songs) do
            local song_name = song_path:match("([^/\\]+)$") or song_path
            table.insert(song_names, song_name)
        end
        local options = Options(song_names)
        options:setColorFocus(colors.highlight)
        state.album_songs_scroller = Scroller(list_height, options)
    end

    if #album.songs == 0 then
        vterm:writeText(x, y + 3, "This album is empty. Add some songs.", colors.fg, colors.bg)

        return
    end

    local visible_items, start_index, focus_index = state.album_songs_scroller:getVisible()
    local content_width = width
    local has_scrollbar = #album.songs > list_height

    if has_scrollbar then
        content_width = width - 1
        local scrollbar_x = x + width - 1
        for i = 0, list_height - 1 do
            vterm:setChar(scrollbar_x, list_y + i, "║", colors.border, colors.bg)
        end
        local thumb_size = math.max(1, math.floor(list_height * list_height / #album.songs))

        if #album.songs > list_height then
            local thumb_pos_ratio = (start_index - 1) / (#album.songs - list_height)
            local thumb_y_offset = math.floor((list_height - thumb_size) * thumb_pos_ratio)
            for i = 0, thumb_size - 1 do
                if list_y + thumb_y_offset + i < y + height - 2 then
                    vterm:setChar(scrollbar_x, list_y + thumb_y_offset + i, "█", colors.highlight, colors.bg)
                end
            end
        end
    end

    for i, item in ipairs(visible_items) do
        local item_y = list_y + i - 1
        local is_focused = (i == focus_index)
        local fg_color = is_focused and colors.highlight or colors.fg
        local bg_color = is_focused and colors.active_bg or colors.bg
        local prefix = is_focused and ctx.UI.SELECTED_PREFIX or ctx.UI.UNSELECTED_PREFIX
        local style = is_focused and TextStyle.Bold or TextStyle.Normal

        vterm:writeText(x, item_y, string.rep(" ", content_width), colors.fg, bg_color)

        local max_text_width = content_width - #prefix - 1
        local display_text = ctx.clip_text(item.text, max_text_width)

        vterm:writeText(x, item_y, prefix .. display_text, fg_color, bg_color, style)
    end
end
