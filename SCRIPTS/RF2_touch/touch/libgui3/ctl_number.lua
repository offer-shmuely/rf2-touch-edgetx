-- Create a number that can be edited
-- args: x, y, w, h, value, onChangeValue, flags, min, max
function number(panel, id, args, flags)
-- function number(panel, id, x, y, w, h, value, onChangeValue, flags, min, max)
    local self = {
        onChangeValue = args.onChangeValue or panel._.onChangeDefault,
        flags = bit32.bor(flags or panel.flags, VCENTER),
        disabled = false,
        editable = true,
        hidden= false,
        min_val = args.min or 0,
        max_val = args.max or 100,

        panel = panel,
        id = id,
        x = args.x,
        y = args.y,
        w = args.w,
        h = args.h,
        value = args.value or -1,
        bg_color = args.bg_color,
    }

    local d0

    function self.draw(focused)
        local x,y,w,h = self.x, self.y, self.w, self.h
        local flags = panel.getFlags(self)
        local fg = panel.colors.primary1

        if focused then
            panel.drawFocus(x, y, w, h)

            if panel.editing then
                fg = panel.colors.primary2
                panel.drawFilledRectangle(x, y, w, h, panel.colors.edit)
            end
        end
        if self.bg_color then
            panel.drawFilledRectangle(x, y, w, h, self.bg_color)
        end
        if type(self.value) == "string" then
            panel.drawText(panel._.align_w(x, w, flags), y + h / 2, self.value, bit32.bor(fg, flags))
        else
            panel.drawNumber(panel._.align_w(x, w, flags), y + h / 2, self.value, bit32.bor(fg, flags))
        end
        if self.min_val and self.max_val then
            local percent = (self.value - self.min_val) / (self.max_val - self.min_val)
            local px = (w - 2) * percent
            panel.drawFilledRectangle(x + 5, y+h-2-5, px, 5, BLUE)
        end


    end

    function self.onEvent(event, touchState)
        if panel.editing then
            if event == EVT_VIRTUAL_ENTER then
                panel.editing = false
            elseif event == EVT_VIRTUAL_EXIT then
                self.value = value
                panel.editing = false
            elseif event == EVT_VIRTUAL_INC then
                if self.value < self.max_val then
                    self.value = self.onChangeValue(1, self)
                end
            elseif event == EVT_VIRTUAL_DEC then
                if self.value > self.min_val then
                    self.value = self.onChangeValue(-1, self)
                end
            elseif event == EVT_TOUCH_FIRST then
                d0 = 0
            elseif event == EVT_TOUCH_SLIDE then
                local d = math.floor((touchState.startY - touchState.y) / 20 + 0.5)
                if d ~= d0 then
                    self.value = self.onChangeValue(d - d0, self)
                    d0 = d
                end
            end
        elseif event == EVT_VIRTUAL_ENTER then
            value = self.value
            panel.editing = true
        end
    end

    if panel~=nil then
        panel.addCustomElement(self)
    end

    return self
end


return number
