-- args: x,y,w,h,items,selected,callback

-- x,y,w,h: position and size of the dropdown
-- items: table of items to be displayed in the dropdown
-- selected: index of the selected item
-- callback: function to be called when an item is selected

function dropDown(panel, id, args, flags)
    local flags = flags or panel.flags

    local x = args.x
    local y = args.y
    local w = args.w
    local h = args.h
    local items0or1 = args.items or {} -- can be 0 based table, or 1 based table
    local items1 = panel._.tableBasedX_convertTableTo1Based(items0or1) -- 1 based table
    local selected0or1 = args.selected or 1
    local callback = args.callback or panel._.doNothing

    local showingMenu
    local drawingMenu
    local lh = 3 + select(2, lcd.sizeText("", flags)) -- should be sync to menu
    local menu_height = math.min(0.75 * LCD_H, #items1 * lh)
    local menu_top = (LCD_H - 10 - menu_height)


    -- menu_top = math.min(menu_top, y)
    menu_top = math.min(menu_top, panel.translateY(y))
    -- menu_top = math.max(menu_top, y + h - menu_height)
    local ctlMenu

    local function dismissMenu()
        showingMenu = false
        panel.dismissPrompt()
    end

    local function onMenu(menu)
        print("dropd/onMenu()")
        dismissMenu()
        callback(ctlMenu)
    end

    local menuPanel = panel.newPanel()
    menuPanel.x = panel.translate(0, 0)
    ctlMenu = panel.newControl.ctl_menu(menuPanel, "m1",
        {x=x, y=menu_top, w=w, h=menu_height, items=items0or1, selected=selected0or1, callback=onMenu}
        , flags)
    --ctlMenu.editable = true

    function menuPanel.fullScreenRefresh()
        if not menuPanel.editing then
            dismissMenu()
            return
        end
        menuPanel.drawFilledRectangle(x, menu_top, w, menu_height, panel.colors.primary2)
        menuPanel.drawRectangle(x - 2, menu_top - 2, w + 4, menu_height + 4, panel.colors.primary1)
        drawingMenu = true
    end

    local orgMenuDraw = ctlMenu.draw

    function ctlMenu.draw(focused)
        if drawingMenu then
            drawingMenu = false
            orgMenuDraw(focused)
        else
            local flags = bit32.bor(VCENTER, panel.colors.primary1, panel.getFlags(ctlMenu))

            if focused then
                panel.drawFocus(x, y, w, h)
            end
            local selectedTxt = ctlMenu.getSelectedText()
            panel.drawFilledRectangle(x, y, w, h, panel.colors.btn.bg)
            panel.drawRectangle(x, y, w, h, panel.colors.btn.border,2)
            panel.drawText(panel._.align_w(x, w, flags) + 5, y + h / 2, selectedTxt, flags)
            local dd = lh / 2
            local yy = y + (h - dd) / 2
            local xx = (x-5) + w - 1.15 * dd
            panel.drawTriangle(x-5 + w, yy, (x-5 + w + xx) / 2, yy + dd, xx, yy, panel.colors.primary1)
        end
    end

    local orgMenuOnEvent = ctlMenu.onEvent

    function ctlMenu.onEvent(event, touchState)
        if showingMenu then
            orgMenuOnEvent(event, touchState)
        elseif event == EVT_VIRTUAL_ENTER then
            -- Show drop down and let it take over while active
            showingMenu = true
            menuPanel.onEvent(event, nil)
            panel.showPrompt(menuPanel)
        else
        end
    end

    local orgMenuCovers = ctlMenu.covers

    function ctlMenu.covers(p, q)
        if showingMenu then
            return orgMenuCovers(p, q)
        else
            return (x <= p and p <= x + w and y <= q and q <= y + h)
        end
    end

    if panel~=nil then
        panel.addCustomElement(ctlMenu)
    end

    return ctlMenu
end

return dropDown
