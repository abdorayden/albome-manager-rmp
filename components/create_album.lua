local api = require("rmp.rmp")

local TextStyle = api.TextStyle

return function(ctx, vterm, x, y, width, height)
    local colors = ctx.colors
    local state = ctx.plugin_state

    vterm:writeText(x, y, "Create New Album", colors.info, colors.bg, TextStyle.Bold)
    vterm:writeText(x, y + 2, "Please enter the name for the new album.", colors.fg, colors.bg)
    vterm:writeText(x, y + height - 1, "ENTER to create, ESC to cancel", colors.fg, colors.bg)

    local input_y = y + 4
    local input_width = width - 4
    local input_x = x + 2

    vterm:drawBox(nil, input_x - 1, input_y, input_width + 2, 3, api.BoxDrawing.RoundedCorners, colors.highlight,
        colors.bg)

    if not state.input_instance then
        state.input_instance = api.Input.new(
            "Album Name: ", input_x, input_y + 1, input_width - 2, "", api.KEY_ESCAPE, colors.fg, colors.bg
        )
        state.input_instance:start()
    end
end
