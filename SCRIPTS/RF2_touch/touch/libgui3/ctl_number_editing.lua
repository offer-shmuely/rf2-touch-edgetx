
-----------------------------------------------------------------------------------------------

function ctl_number_editing(panel, id, x, y, w, h, f, gui_fieldsInfo)
    panel.log("ctl_number_editing(): panel=%s, id=%s, [%s]=%s", panel, f.id, f.t, f.value)

    local self = {
        -- callBack = callBack or doNothing,
        -- flags = bit32.bor(flags or panel.flags, CENTER, VCENTER),
        flags = bit32.bor(panel.flags or panel.default_flags),
        disabled = false,
        editable = true,
        hidden = false,

        panel = panel,
        id = id,
        x = x,
        y = y,
        w = w,
        h = h,

        f = f,
        gui_fieldsInfo = gui_fieldsInfo,

        h_header = 30,
        measureTape = nil,
        val_org = f.value,
    }
    function self.onMeasureTapeValueChange(obj) --????
        panel.log("onMeasureTapeValueChange: %s", obj.val)
        f.value = obj.val   --???
    end

    -- self.measureTape = gui_measureTape(nil, "mt1", 360, y + self.h_header + (h - self.h_header) / 2, 70,
    --     (h - self.h_header) / 2 - 5, f.value, f.min, f.max, onMeasureTapeValueChange) -- , callBack, flags)
    self.measureTape = panel.newControl.ctl_measure_tape(panel, "mt1", 360, y + self.h_header + (h - self.h_header) / 2, 70,
        (h - self.h_header) / 2 - 5, f.value, f.min, f.max, self.onMeasureTapeValueChange) -- , callBack, flags)


    function self.get_value()
        return self.measureTape.get_value()
    end

    function self.set_value(v)
        return self.measureTape.set_value(v)
    end

    function self.covers(tsx, tsy)
        panel.log("::covers() ?")
        if (tsx >= self.x and tsx <= self.x + self.w and tsy >= self.y - self.h and tsy <= self.y + self.h) then
            panel.log("::covers() true")
            return true
        end

        panel.log("::covers() - false")
        return false
    end

    function self.onEvent(event, touchState)
        self.measureTape.onEvent(event, touchState)
    end

    function self.draw(focused)
        local x1 = 20
        local y1 = 45
        local w1 = 430
        local h1 = 210

        local f_val = self.measureTape.val or 77
        local field_name = f.t2 or f.t

        panel.drawFilledRectangle(0, 30, LCD_W, LCD_H - self.h_header, LIGHTGREY, 6) -- obfuscate main page
        panel.drawFilledRectangle(x1, y1, w1, h1, GREY, 2) -- edit window bkg
        panel.drawFilledRectangle(x1, y1, w1, self.h_header, BLACK, 2) -- header
        panel.drawRectangle(x1 + 5, y1 + 2, 10, 10, WHITE, 0) -- x
        panel.drawText(x1 + w1 - 20, y1 + 5, "x", panel.FONT_SIZES.FONT_8 + BOLD + WHITE)
        panel.drawRectangle(x1, y1, w1, h1, GREY, 0) -- border
        -- lcd.drawText(x1 + 5, y1 + h_header, field_name, FONT_SIZES.FONT_12 + BOLD + CUSTOM_COLOR)

        -- title
        panel.drawText((x1 + w1) / 2, y1 + 5, field_name, panel.FONT_SIZES.FONT_8 + BOLD + WHITE + CENTER)

        local fHelp = "Info: $$"
        local units = ""
        if f.id ~= nil then
            fHelp = gui_fieldsInfo[f.id].help
            units = gui_fieldsInfo[f.id].units
            -- units = string.gsub(units, "&deg;", "°")
        end

        -- additional info
        -- lcd.drawText(x1 + w1 - 5, y1 + h_header + 2, string.format("max: \n%s", f.min), FONT_SIZES.FONT_8 + BLACK + RIGHT)
        -- lcd.drawText(x1 + w1 - 5, y1 + h1 - 45, string.format("max: \n%s", f.max), FONT_SIZES.FONT_8 + BLACK + RIGHT)
        -- lcd.drawText(x1 + 20, y1 + h_header + 20, string.format("%s", f.t2 or f.t), FONT_SIZES.FONT_8 + WHITE)
        panel.drawText(x1 + 20, y1 + self.h_header + 30, string.format("max: %s", f.min), panel.FONT_SIZES.FONT_8 + WHITE)
        panel.drawText(x1 + 20, y1 + self.h_header + 50, string.format("max: %s", f.max), panel.FONT_SIZES.FONT_8 + WHITE)
        if fHelp ~= nil then
            panel.drawText(x1 + 20, y1 + self.h_header + 85, "Info: \n" .. fHelp, panel.FONT_SIZES.FONT_8 + WHITE)
        end

        -- value
        lcd.drawText((x1 + w1) / 2 + 80, y1 + 30, f_val, panel.FONT_SIZES.FONT_16 + BOLD + BLUE + RIGHT)
        if units ~= nil then
            panel.drawText((x1 + w1) / 2 + 85, y1 + 60, units, panel.FONT_SIZES.FONT_12 + BOLD + BLUE)
        end

        if self.val_org ~= f_val then
            lcd.drawText((x1 + w1) / 2 + 80, y1 + 60 + 35, string.format("current: %s %s", self.val_org, units), panel.FONT_SIZES.FONT_8 + WHITE + RIGHT)
        end

        -- progress bar
        f_val = tonumber(f_val)
        local f_min = f.min / (f.scale or 1)
        local f_max = f.max / (f.scale or 1)
        local percent = (f_val - f_min) / (f_max - f_min)

        -- local fg_col = lcd.RGB(0x00, 0xB0, 0xDC)
        local w = 250 -- w1-30
        local h = 8
        local x = x1 + 15
        local y = y1 + h1 - 20
        local r = 8
        local px = (w - 2) * percent

        panel.drawFilledRectangle(x, y + 2, w, h, LIGHTGREY)
        panel.drawFilledCircle(x + px - r / 2, y + r / 2, r, lcd.RGB(0x00, 0xB0, 0xDC))
        panel.drawFilledCircle(x + px - r / 2, y + r / 2, r, BLUE)

        self.measureTape.draw()
    end

    return self
end

return ctl_number_editing

