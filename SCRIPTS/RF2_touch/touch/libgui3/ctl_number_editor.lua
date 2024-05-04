-- args: x, y, w, h, f, fieldsInfo, onDone, onCancel

function ctl_number_editor(panel, id, args)
    panel.log("number_as_button ctl_number_editor(): panel=%s, id=%s, [%s]=%s, min:%s, max:%s, steps:%s", panel, args.id, args.text, args.value, args.min, args.max, args.steps)

    local self = {
        -- flags = bit32.bor(flags or panel.flags, CENTER, VCENTER),
        flags = bit32.bor(panel.flags or panel.default_flags),
        disabled = false,
        editable = true,
        hidden = false,

        panel = panel,
        id = id,
        x = args.x,
        y = args.y,
        w = args.w,
        h = args.h,
        value = args.value or -1,
        min = args.min or 0,
        max = args.max or 100,
        text = args.text or "",
        help = args.help or "",
        scale = args.scale or 1, --???
        steps = args.steps, --???
        fieldsInfo = args.fieldsInfo,
        onDone = args.onDone or panel.doNothing,
        onCancel = args.onCancel or panel.doNothing,

        x1 = 20,
        y1 = 45,
        w1 = 430,
        h1 = 210,


        h_header = 30,
        measureTape = nil,
        val_org = args.initiatedValue or args.value,

        editing = true,
        drawingMenu = false,
    }
    function self.onMeasureTapeValueChange(obj) --????
        panel.log("ctl_number_editor onMeasureTapeValueChange: %s", obj.val)
        self.value = obj.val   --???
    end

    self.measureTape = nil


    function self.get_value()
        return self.measureTape.get_value()
    end

    function self.set_value(v)
        return self.measureTape.set_value(v)
    end

    function self.covers(tsx, tsy)
        panel.log("ctl_number_editor::covers() ?")
        if (tsx >= self.x and tsx <= self.x + self.w and tsy >= self.y - self.h and tsy <= self.y + self.h) then
            panel.log("ctl_number_editor::covers() true")
            return true
        end

        panel.log("ctl_number_editor::covers() - false")
        return false
    end

    function self.fullScreenRefresh()
        local x1,y1,w1,h1 = self.x1, self.y1, self.w1,self.h1
        panel.log("ctl_number_editor.fullScreenRefresh() - editing: %d", self.editing)
        -- if not menuPanel.editing then
            --     dismissMenu()
            --     return
            -- end

        if self.editing then
            -- menu background
            panel.log("ctl_number_editor.fullScreenRefresh() EDITING")
            panel.drawFilledRectangle(x1, y1, w1, h1, panel.colors.list.bg)
            panel.drawRectangle(x1-2, y1-2, w1+4, h1+4, panel.colors.list.border)
            self.drawingMenu = true
        else
            dismissMenu()
            return
        end
    end

    function self.draw(focused)
        local x,y,w,h,f = self.x, self.y, self.w,self.h,self.f

        local x1,y1,w1,h1 = self.x1, self.y1, self.w1,self.h1

        local f_val = self.measureTape.val or 77

        panel.drawFilledRectangle(0, 30, LCD_W, LCD_H - self.h_header, LIGHTGREY, 6) -- obfuscate main page
        panel.drawFilledRectangle(x1, y1, w1, h1, GREY, 2) -- edit window bkg
        panel.drawFilledRectangle(x1, y1, w1, self.h_header, BLACK, 2) -- header
        panel.drawRectangle(x1 + 5, y1 + 2, 10, 10, WHITE, 0) -- x
        panel.drawText(x1 + w1 - 20, y1 + 5, "x", panel.FONT_SIZES.FONT_8 + BOLD + WHITE)
        panel.drawRectangle(x1, y1, w1, h1, GREY, 0) -- border
        -- lcd.drawText(x1 + 5, y1 + h_header, field_name, FONT_SIZES.FONT_12 + BOLD + CUSTOM_COLOR)

        -- title
        panel.drawText((x1 + w1) / 2, y1 + 5, self.text, panel.FONT_SIZES.FONT_8 + BOLD + WHITE + CENTER)

        -- additional info
        -- lcd.drawText(x1 + w1 - 5, y1 + h_header + 2, string.format("max: \n%s", f.min), FONT_SIZES.FONT_8 + BLACK + RIGHT)
        -- lcd.drawText(x1 + w1 - 5, y1 + h1 - 45, string.format("max: \n%s", f.max), FONT_SIZES.FONT_8 + BLACK + RIGHT)
        -- lcd.drawText(x1 + 20, y1 + h_header + 20, string.format("%s", f.t2 or f.t), FONT_SIZES.FONT_8 + WHITE)
        panel.drawText(x1 + 20, y1 + self.h_header + 30, string.format("min: %s", self.min), panel.FONT_SIZES.FONT_8 + WHITE)
        panel.drawText(x1 + 20, y1 + self.h_header + 50, string.format("max: %s", self.max), panel.FONT_SIZES.FONT_8 + WHITE)
        if self.help ~= nil and self.help ~= "" then
            panel.drawText(x1 + 20, y1 + self.h_header + 85, "Info: \n" .. self.help, panel.FONT_SIZES.FONT_8 + WHITE)
        end

        -- value
        lcd.drawText((x1 + w1) / 2 + 80, y1 + 30, f_val, panel.FONT_SIZES.FONT_16 + BOLD + BLUE + RIGHT)
        if units ~= nil then
            panel.drawText((x1 + w1) / 2 + 85, y1 + 60, self.units, panel.FONT_SIZES.FONT_12 + BOLD + BLUE)
        end

        if self.val_org ~= f_val then
            lcd.drawText((x1 + w1) / 2 + 80, y1 + 60 + 35, string.format("current: %s %s", self.val_org, units), panel.FONT_SIZES.FONT_8 + WHITE + RIGHT)
        end

        -- progress bar
        f_val = tonumber(f_val)
        local f_min = self.min / self.scale
        local f_max = self.max / self.scale
        local percent = (f_val - f_min) / (f_max - f_min)

        -- local fg_col = lcd.RGB(0x00, 0xB0, 0xDC)
        local w = 250 -- w1-30
        local h = 8
        local x = x1 + 15
        local y = y1 + h1 - 20
        local r = 8
        local px = (w - 2) * percent

        panel.drawFilledRectangle(x, y + 2, w, h, LIGHTGREY)
        panel.drawFilledRectangle(x, y + 2, px, h, lcd.RGB(0x00, 0xB0, 0xDC))
        -- panel.drawFilledCircle(x + px - r/2, y + r/2, r, lcd.RGB(0x00, 0xB0, 0xDC))
        panel.drawFilledCircle(x + px - r/2, y + r/2, r, BLUE)

    end

    function self.onEvent(event, touchState)
        panel.log("[%s] fancy  self.onEvent(%s) (event:%s, touchState:%s)", self.id, self.text, event, touchState)

        if event == EVT_VIRTUAL_NEXT then
            self.scrolling = false
            self.measureTape.inc_value(self.steps)
            log("[%s] fancy EVT_VIRTUAL_NEXT, val=%s", self.id, self.measureTape.get_value())

        elseif event == EVT_VIRTUAL_PREV then
            self.scrolling = false
            self.measureTape.inc_value(0-self.steps)
            log("[%s] fancy EVT_VIRTUAL_PREV, val=%s", self.id, self.measureTape.get_value())

        elseif event == EVT_VIRTUAL_ENTER then
            log("[%s] fancy EVT_VIRTUAL_ENTER, val=%s", self.id, self.measureTape.get_value())
            self.onDone(self.measureTape.get_value())

        elseif event == EVT_VIRTUAL_EXIT then
            log("[%s] fancy EVT_VIRTUAL_EXIT, val=%s", self.id, self.measureTape.get_value())
            -- revert value
            self.measureTape.set_value(self.val_org)
            self.onCancel()

        end

        self.measureTape.onEvent(event, touchState)
    end

    if panel~=nil then
        panel.addCustomElement(self)
    end

    if self.measureTape == nil then
        self.measureTape = panel.newControl.ctl_number_measure_tape(panel, "mt1",
            {x=360, y=self.y + self.h_header + (self.h - self.h_header) / 2,w=70,h=(self.h - self.h_header) / 2 - 5,
            start_val=self.value, min=self.min, max=self.max,
            onChangeCallBack=self.onMeasureTapeValueChange
        })

    end

    return self
end

return ctl_number_editor

