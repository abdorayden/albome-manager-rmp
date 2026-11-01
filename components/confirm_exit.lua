local api = require("rmp.rmp")

local TextStyle = api.TextStyle

return function(ctx, vterm, x, y, width, height)
    local colors = ctx.colors
    local state = ctx.plugin_state

    vterm:writeText(x, y, "Unsaved Changes", colors.info, colors.bg, TextStyle.Bold)
    vterm:writeText(x, y + 2, "You have unsaved changes. Save before exiting?", colors.fg, colors.bg)

    local options = { "Save and Exit", "Exit Without Saving", "Cancel" }
    local start_y = y + 4
    for i, option in ipairs(options) do
        local option_y = start_y + i
        local is_selected = (i == state.selected_option)
        local fg_color = is_selected and colors.highlight or colors.fg
        local bg_color = is_selected and colors.active_bg or colors.bg
        local prefix = is_selected and ctx.UI.SELECTED_PREFIX or ctx.UI.UNSELECTED_PREFIX
        local style = is_selected and TextStyle.Bold or TextStyle.Normal

        vterm:writeText(x, option_y, prefix .. string.rep(" ", width - #prefix - #option), fg_color, bg_color)
        vterm:writeText(x, option_y, prefix .. option, fg_color, bg_color, style)
    end
end
