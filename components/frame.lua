local api = require("rmp.rmp")

return function(ctx, vterm, x, y, width, height, title)
    local colors = ctx.colors
    local state = ctx.plugin_state

    vterm:drawBox(nil, x, y, width, height, api.BoxDrawing.RoundedCorners, colors.border, colors.bg)

    for i = y + 1, y + height - 2 do
        vterm:writeText(x + 1, i, string.rep(" ", width - 2), colors.fg, colors.bg)
    end

    local header_y = y + 1
    local title_text = title and (" " .. title .. " ") or " "
    vterm:writeText(x + 2, header_y, title_text, colors.info, colors.bg, api.TextStyle.Bold)

    local mode_label = ctx.MODE_LABELS[state.mode] or state.mode
    local mode_text = "Mode: " .. mode_label
    mode_text = ctx.clip_text(mode_text, width - #title_text - 6)
    vterm:writeText(x + width - #mode_text - 2, header_y, mode_text, colors.fg, colors.bg)

    vterm:writeText(x + 1, header_y + 1, string.rep("─", width - 2), colors.border, colors.bg)
end
