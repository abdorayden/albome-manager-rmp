local draw_frame = require("albome-manager-rmp.components.frame")
local render_main_menu = require("albome-manager-rmp.components.main_menu")
local render_album_list = require("albome-manager-rmp.components.album_list")
local render_album_songs = require("albome-manager-rmp.components.album_songs")
local render_create_album = require("albome-manager-rmp.components.create_album")
local render_add_songs = require("albome-manager-rmp.components.add_songs")
local render_album_selector = require("albome-manager-rmp.components.album_selector")
local render_confirm_exit = require("albome-manager-rmp.components.confirm_exit")

return function(ctx, vterm, terminal_width, terminal_height)
    local colors = ctx.colors
    local state = ctx.plugin_state

    local popup_width = math.min(80, terminal_width - 4)
    local popup_height = math.min(25, terminal_height - 4)
    local popup_x = math.max(1, math.floor((terminal_width - popup_width) / 2))
    local popup_y = math.max(1, math.floor((terminal_height - popup_height) / 2))

    draw_frame(ctx, vterm, popup_x, popup_y, popup_width, popup_height, ctx.PLUGIN_NAME)

    local content_x = popup_x + 2
    local content_y = popup_y + 3
    local content_width = popup_width - 4
    local content_height = popup_height - 4

    local render_map = {
        main = render_main_menu,
        view_albums = render_album_list,
        view_songs = render_album_songs,
        create_album = render_create_album,
        add_songs = render_add_songs,
        select_album = render_album_selector,
        confirm_exit = render_confirm_exit
    }

    local render_func = render_map[state.mode]
    if render_func then
        render_func(ctx, vterm, content_x, content_y, content_width, content_height)
    end

    if state.show_message then
        local message_y = popup_y + popup_height - 2
        local message_x = popup_x + 2
        local message_color = state.message_color or colors.fg
        vterm:writeText(message_x, message_y, string.rep(" ", popup_width - 4), message_color, colors.bg)
        vterm:writeText(message_x, message_y, state.message_text, message_color, colors.bg)
    end
end
