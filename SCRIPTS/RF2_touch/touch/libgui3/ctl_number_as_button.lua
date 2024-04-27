
-- args: x, y, w, h, text, f, units, fieldsInfo

function ctl_number_as_button(panel, id, args, flags)
    panel.log("button.new(%s)", id)

    local self = {
        --value, onChangeValue, flags, min, max,
        -- flags = bit32.bor(flags or panel.flags, CENTER, VCENTER),
        disabled = false,
        editable = true,
        hidden= false,

        panel = panel,
        id = id,
        x = args.x,
        y = args.y,
        w = args.w,
        h = args.h,
        text = args.text,
        f = args.f,
        units = args.units,
        fieldsInfo = args.fieldsInfo,
        callbackOnModalActive = args.callbackOnModalActive or panel._.doNothing,
        callbackOnModalInactive = args.callbackOnModalInactive or panel._.doNothing,

        modalPanel = panel.newPanel("modal for fancy editor"),
        ctlNumberEditing = nil,
        showingEditor = false,
    }
    --???
    if self.f.value == nil then
        self.f.value = 0
    end

    local function drawButton()
        local x,y,w,h = self.x, self.y, self.w,self.h
        panel.drawFilledRectangle(x, y, w, h, panel.colors.btn.bg)
        panel.drawRectangle(x, y, w, h, panel.colors.secondary2)
        local y1 = y+6
        if self.text then
            panel.drawText(x + w / 2, y1, self.text, panel.colors.btn.txt + CENTER)
            y1 = y1 + 20
        end
        local val_txt = string.format("%s%s", self.f.value, self.units)
        panel.drawText(x + w / 2, y1, val_txt, panel.colors.secondary1 + CENTER)

        -- draw progress bar
        local f_min = self.f.min / (self.f.scale or 1)
        local f_max = self.f.max / (self.f.scale or 1)
        local percent = (self.f.value - f_min) / (f_max - f_min)
        local bkg_col = LIGHTGREY
        local fg_col = lcd.RGB(0x00, 0xB0, 0xDC)
        local prg_w = w - 20
        local prg_h = 5
        local px = (prg_w - 2) * percent
        local r = 5

        -- level slider
        -- panel.drawFilledRectangle(x+10, y+h-11, prg_w, prg_h, bkg_col)
        panel.drawFilledRectangle(x+10, y+h-11, px-r-2, prg_h, fg_col)
        panel.drawFilledRectangle(x+10+px+r/2, y+h-11, prg_w-px, prg_h, bkg_col)
        panel.drawCircle(x+10 + px - r/2, y+h-12 + r/2, r, fg_col, 1)
    end

    function self.draw(focused)
        local x,y,w,h = self.x, self.y, self.w,self.h
        -- panel.log("ctl_number_editing.draw(%s) - isEditorOpen:%s", self.text, self.isEditorOpen)

        drawButton()
        if self.showingEditor then
            -- panel.log("ctl_number_editing.draw(%s) - panelNumberEditing is ok", self.text)
            panel.drawRectangle(x, y, w, h, RED, 4)
            -- self.modalPanel.draw()
            -- self.ctlNumberEditing.draw()
        else
            if focused then
                -- panel.log("drawFocus: %s", self.text)
                panel.drawFocus(x, y, w, h)
            end

            if self.disabled then
                panel.drawFilledRectangle(x, y, w, h, GREY, 7)
            end
        end
    end

    function self.onEvent(event, touchState)
        panel.log("ctl_number_editing.onEvent(%s)", self.text)
        if self.showingEditor == false then
            if event == EVT_VIRTUAL_ENTER then
                self.ctlNumberEditing = self.modalPanel.newControl.ctl_number_editing(self.modalPanel, "valEtd1", 20, 45, 430, 210, self.f, self.fieldsInfo)
                self.showingEditor = true
                panel.showPrompt(self.modalPanel) --???
                self.modalPanel.onEvent(event, touchState)
                self.callbackOnModalActive(self)
            end
        else
            if event == EVT_VIRTUAL_ENTER then
                --??? need to implement
                self.value = value --???
                self.showingEditor = false
                self.ctlNumberEditing = nil
                self.callbackOnModalInactive(self)

            elseif event == EVT_VIRTUAL_EXIT then
                self.value = value --???
                self.showingEditor = false
                self.ctlNumberEditing = nil
                self.callbackOnModalInactive(self)
            end
        end

        if self.showingEditor then
            -- panel.log("ctl_number_editing.onEvent(%s) - panelNumberEditing", event)
            -- self.modalPanel.onEvent(event, touchState)
            -- self.ctlNumberEditing.onEvent(event, touchState)
        end
    end

    if panel~=nil then
        panel.addCustomElement(self)
    end
    return self
end

return ctl_number_as_button




