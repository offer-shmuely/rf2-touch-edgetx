


-- Create a toggle button that turns on/off. callBack gets true/false

-- args: x,y,w,h,title, value, callback
function toggleButton(panel, id, args, flags)
    local self = {
        flags = bit32.bor(flags or panel.flags, CENTER, VCENTER),
        disabled = false,
        hidden= false,

        -- args
        x=args.x,
        y=args.y,
        w=args.w,
        h=args.h,
        title=args.title,
        value=args.value,
        callback=args.callback or panel._.doNothing,
    }

    function self.draw(focused)
        local x,y,w,h = self.x, self.y, self.w, self.h

        local fg = panel.colors.primary3
        local bg = panel.colors.primary2
        local border = panel.colors.secondary2

        if self.value then
            fg = panel.colors.secondary3
            bg = panel.colors.secondary1
            border = panel.colors.focus
        end

        if focused then
            panel.drawFocus(x, y, w, h, border)
        end

        panel.drawFilledRectangle(x, y, w, h, bg)
        panel.drawRectangle(x, y, w, h, border)
        panel.drawText(x + w / 2, y + h / 2, self.title, bit32.bor(fg, self.flags))

        if self.disabled then
            panel.drawFilledRectangle(x, y, w, h, GREY, 7)
        end
    end

    function self.onEvent(event, touchState)
        if event == EVT_VIRTUAL_ENTER then
            self.value = not self.value
            return self.callback(self)
        end
    end

    if panel~=nil then
        panel.addCustomElement(self)
    end
    return self
end

return toggleButton
