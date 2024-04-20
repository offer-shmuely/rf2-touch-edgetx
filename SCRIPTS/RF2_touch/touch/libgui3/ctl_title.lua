-- Create a text label
-- args: x, y, w, h, [title1_x, title1, title2_x,title2]
function title(panel, id, args, flags)
    assert(args)
        local self = {
        flags = bit32.bor(flags or panel.flags, panel.colors.primary1),
        disabled = false,
        editable = false,
        hidden= false,

        panel = panel,
        id = id,
        -- args
        x = args.x,
        y = args.y,
        w = args.w or 0,
        h = args.h or 0,
        title1 = args.title1 or "",
        title1_x = args.title1_x or 30,
        txt_color = args.txt_color or WHITE,
        bg_color = args.bg_color or GREY,

    }

    function self.draw(focused)
        local x,y,w,h = self.x, self.y, self.w, self.h
        local flags = panel.getFlags(self)

        panel.drawFilledRectangle(x, y, w, h, self.bg_color, 2) -- header
        panel.drawRectangle(x + 5, y + 2, 10, 10, WHITE, 0) -- x
        panel.drawRectangle(x, y, w, h, GREY, 0) -- border

        panel.drawText(
            self.x + self.title1_x,
            self.y + self.h/2,
            self.title1,
            self.txt_color + VCENTER)
    end

    -- We should not ever onEvent, but just in case...
    function self.onEvent(event, touchState)
        -- self.disabled = true
        moveFocus(1)
    end

    function self.covers(p, q)
        return false
    end

    if panel~=nil then
        panel.addCustomElement(self)
    end

    return self
end

return title
