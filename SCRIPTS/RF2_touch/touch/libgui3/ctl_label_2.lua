-- Create a text label
function label(panel, id, x, y, w, h, title, flags)
    local self = {
        title = title,
        flags = bit32.bor(flags or panel.flags, VCENTER, panel.colors.primary1),
        disabled = false,
        editable = false,
        hidden= false,

        panel = panel,
        id = id,
        x = x,
        y = y,
        w = w,
        h = h,
    }

    function self.draw(focused)
        local flags = panel.getFlags(self)

        -- if focused then
        --     panel.drawFocus(x, y, w, h)
        -- end
        panel.drawText(panel._.align(x, w, flags), y + h / 2, self.title, flags)
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

return label
