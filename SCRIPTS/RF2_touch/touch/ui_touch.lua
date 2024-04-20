local LUA_VERSION = "2.0 - 240229"

local app_name = "RF2_touch"

local uiStatus =
{
    init     = 1,
    mainMenu = 2,
    pages    = 3,
    confirm  = 4,
}

local pageStatus =
{
    display = 1,
    editing = 2,
    saving  = 3,
}

local uiMsp =
{
    reboot = 68,
    eepromWrite = 250,
}

local uiState = uiStatus.init
local prevUiState
local pageState = pageStatus.display
local requestTimeout = 80
local currentPage = 1
local currentField = 1
local saveTS = 0
local saveTimeout = protocol.saveTimeout
local saveRetries = 0
local saveMaxRetries = protocol.saveMaxRetries
local popupMenuActive = 1
local is_popupmenu_active = false
local is_modal_number_editor_active = false
local killEnterBreak = 0
local pageScrollY = 0
local mainMenuScrollY = 0
local PageFiles, Page, init
-- local popupMenu

local backgroundFill = TEXT_BGCOLOR or ERASE
local foregroundColor = LINE_COLOR or SOLID

local globalTextOptions = TEXT_COLOR or 0
local template = assert(loadScript(radio.template))()
rfglobals = {}


-- better font size names
local FONT_SIZES = {
    FONT_38 = XXLSIZE, -- 38px
    FONT_16 = DBLSIZE, -- 16px
    FONT_12 = MIDSIZE, -- 12px
    FONT_8  = 0,       -- Default 8px
    FONT_6  = SMLSIZE, -- 6px
}

-- ---------------------------------------------------------------------
local function log(fmt, ...)
    print(string.format("ui_touch| " .. fmt, ...))
end

local libgui_dir = "/SCRIPTS/" .. app_name .. "/touch/libgui3"
local libGUI         = assert(loadScript("touch/libgui3/e_libgui.lua", "tcd"))(libgui_dir)
local ctl_fieldsInfo = assert(loadScript("touch/fields_info.lua", "tcd"))()

-- Instantiate main menu GUI panel
local panelTopBar = libGUI.newPanel("panelTopBar")
local panelPopupMenu = libGUI.newPanel("panelPopupMenu", {x=0, y=0})
local panelMainMenu = libGUI.newPanel("mainMenu", {enable_page_scroll=true})
local panelFieldsPage = nil

-- -------------------------------------------------------------------
local function saveSettings()
    if Page.values then
        local payload = Page.values
        if Page.preSave then
            payload = Page.preSave(Page)
        end
        protocol.mspWrite(Page.write, payload)
        saveTS = getTime()
        if pageState == pageStatus.saving then
            saveRetries = saveRetries + 1
        else
            pageState = pageStatus.saving
            saveRetries = 0
        end
    end
end

local function invalidatePages()
    Page = nil
    pageState = pageStatus.display
    saveTS = 0
    collectgarbage()
end

local function rebootFc()
    protocol.mspRead(uiMsp.reboot)
    invalidatePages()
    is_popupmenu_active = false
end

local function eepromWrite()
    protocol.mspRead(uiMsp.eepromWrite)
end

local function confirm(page)
    prevUiState = uiState
    uiState = uiStatus.confirm
    invalidatePages()
    currentField = 1
    Page = assert(loadScript(page))()
    collectgarbage()
end

-- local function createPopupMenu()
--     popupMenuActive = 1
--     popupMenu = {}
--     if uiState == uiStatus.pages then
--         popupMenu[#popupMenu + 1] = { t = "save page", f = saveSettings }
--         popupMenu[#popupMenu + 1] = { t = "reload", f = invalidatePages }
--     end
--     popupMenu[#popupMenu + 1] = { t = "reboot", f = rebootFc }
--     popupMenu[#popupMenu + 1] = { t = "acc cal", f = function() confirm("CONFIRM/acc_cal.lua") end }
--     --[[if apiVersion >= 1.42 then
--         popupMenu[#popupMenu + 1] = { t = "vtx tables", f = function() confirm("CONFIRM/vtx_tables.lua") end }
--     end
--     --]]
-- end

function dataBindFields()
    for i=1,#Page.fields do
        if #Page.values >= Page.minBytes then
            local f = Page.fields[i]
            if f.vals then
                f.value = 0
                for idx=1, #f.vals do
                    local raw_val = Page.values[f.vals[idx]] or 0
                    raw_val = bit32.lshift(raw_val, (idx-1)*8)
                    f.value = bit32.bor(f.value, raw_val)
                end
                local bits = #f.vals * 8
                if f.min and f.min < 0 and bit32.btest(f.value, bit32.lshift(1, bits - 1)) then
                    f.value = f.value - (2 ^ bits)
                end
                f.value = f.value/(f.scale or 1)
            end
        end
    end
end

local function processMspReply(cmd,rx_buf,err)
    if not Page or not rx_buf then
    elseif cmd == Page.write then
        if Page.eepromWrite then
            eepromWrite()
        else
            invalidatePages()
        end
    elseif cmd == uiMsp.eepromWrite then
        if Page.reboot then
            rebootFc()
        end
        invalidatePages()
    elseif cmd == Page.read and err then
        Page.fields = { { x = 6, y = radio.yMinLimit, value = "", ro = true } }
        Page.labels = { { x = 6, y = radio.yMinLimit, t = "N/A" } }
    elseif cmd == Page.read and #rx_buf > 0 then
        Page.values = rx_buf
        if Page.postRead then
            Page.postRead(Page)
        end
        dataBindFields()
        if Page.postLoad then
            Page.postLoad(Page)
        end
    end
end

local function incMax(val, inc, base)
    return ((val + inc + base - 1) % base) + 1
end

-- ---------------------------------------------------------------------

-- local function selectFieldByTouch(x,y)
--     log("search: ------------")
--     log("search: %s,%s", x,y)
--     for i=1,#Page.fields do
--         local f = Page.fields[i]

--         if (f.on_screen) then
--             log("search: %s - %s,%s,%s,%s", f.t, f.on_screen.x1, f.on_screen.y1, f.on_screen.x2, f.on_screen.y2 )
--             if (x > f.on_screen.x1 and x < f.on_screen.x2) and (y > f.on_screen.y1 and y < f.on_screen.y2) then
--                 log("search: found!!! %s", f.t)
--                 currentField = i
--                 return
--             end
--         else
--             log("search: %s", f.t)
--         end

--     end
-- end

function clipValue(val,min,max)
    if val < min then
        val = min
    elseif val > max then
        val = max
    end
    return val
end

local function incPage(inc)
    currentPage = incMax(currentPage, inc, #PageFiles)
    currentField = 1
    invalidatePages()
end

-- local function incPopupMenu(inc)
--     popupMenuActive = clipValue(popupMenuActive + inc, 1, #popupMenu)
-- end

local function requestPage()
    if Page.read and ((not Page.reqTS) or (Page.reqTS + requestTimeout <= getTime())) then
        Page.reqTS = getTime()
        protocol.mspRead(Page.read)
    end
end

local function drawScreenTitle(screenTitle, uiState, panel)
    lcd.clear()

    if panel ~= nil then
        panel.drawFilledRectangle(0, 0, LCD_W, LCD_H, lcd.RGB(0xE0, 0xEC, 0xF0))
        panel.drawFilledRectangle(0, 0, LCD_W, 30, lcd.RGB(0x10, 0x5C, 0x98)) --TITLE_BGCOLOR)
        panel.drawText(5,5,screenTitle, MENU_TITLE_COLOR)
    end

end

local function drawTextMultiline(x, y, text, options)
    local lineSpacing = 23
    local lines = {}
    for str in string.gmatch(text, "([^\n]+)") do
        lcd.drawText(x, y, str, options)
        y = y + lineSpacing
    end
end

local function change_state_to_menu()
    invalidatePages()
    currentField = 1
    uiState = uiStatus.mainMenu
end

local function change_state_to_pages()
    currentField = 1
    invalidatePages()
    uiState = uiStatus.pages
end


local function buildPopupMenu()
    local x1=20
    local y1=40
    local w1=LCD_W - 2*x1
    local h1=LCD_H - y1 - 10
    local btn_h =60
    local btn_w =140
    -- local h1=btn_h+20
    local h_header=30

    local panel = panelPopupMenu

    libGUI.newControl.ctl_title(panel, nil, {x=x1, y=y1, w=w1, h=h1, bg_color=GERY})
    libGUI.newControl.ctl_title(panel, nil, {x=x1, y=y1, w=w1, h=h_header, title1="Menu1", title1_x=10, bg_color=BLACK})

    libGUI.newControl.ctl_button(panel, nil, {x=300, y=80, w=btn_w, h=btn_h, title = "Reboot", callback = rebootFc})
    libGUI.newControl.ctl_button(panel, nil, {x=300, y=160, w=btn_w, h=btn_h, title = "Acc cal",
        callback = function()
            confirm("CONFIRM/acc_cal.lua")
        end
    })

    if uiState == uiStatus.pages then
        libGUI.newControl.ctl_button(panel, nil, {x=100, y=80, w = btn_w, h=btn_h, title = "Save page", callback = saveSettings})
        libGUI.newControl.ctl_button(panel, nil, {x=100, y=160, w = btn_w, h=btn_h, title = "Reload", callback = invalidatePages})
    end

end

-- draw menu (pages)
local function buildMainMenu()
    local yMinLim = radio.yMinLimit

    -- buildPopupMenu(panelMainMenu)

    local h = 50
    local w = 147
    local lineSpacing_w = 9
    local lineSpacing_h = 9
    local maxLines = 4
    local maxCol = 3
    local col = 0

    for i=1, #PageFiles do
        local line = math.floor((i-1)/maxCol)
        local y = 40 + line * (h + lineSpacing_h)
        local x = 10 + (i - (line*maxCol) -1)*(w+lineSpacing_w)

        local bg = nil -- i.e. default
        if false then
            bg = panelMainMenu.colors.active
        end

        libGUI.newControl.ctl_button(panelMainMenu, nil,
            {x = x, y = y, w = w, h = h, title = PageFiles[i].title,
            bgColor=bg,
            callback=function()
                currentPage = i
                change_state_to_pages()
            end
        })
        log("mainMenuBuild: i=%s, col=%s, y=%s", i, col, y)
    end

end

local function getLableIfNeed(lastFieldY, field)
    log("getLableIfNeed: lastFieldY=%s, y=%s   (%s)", lastFieldY, field.y, field.t)

    for i=1,#Page.labels do
        local f = Page.labels[i]
        local y = f.y
        if y >= lastFieldY and y <= field.y then
            log("getLableIfNeed: found label: y=%s (%s)", y, f.t)
            return f
        end
    end
    return nil
end

local function buildFieldsPage()
    local yMinLim = radio.yMinLimit

    local h = 30 --24
    local h_btn = 55
    local w = 400
    local lineSpacing = 10
    local maxLines = 6
    local col = 0

    panelFieldsPage = libGUI.newPanel("fieldsPage", {enable_page_scroll=true})

    log("fieldsPageBuild: fields num=%s", #Page.labels)

    local y = yMinLim + 2
    local last_y = y
    local col_id = 0
    local lastFieldY = 0

    for i=1,#Page.fields do
        local f = Page.fields[i]
        local txt = f.t
        if f.t2 ~= nil then
            txt = f.t2
        end
        log("fieldsPageBuild: i=%s, title: %s", i, txt)

        if runningInSimulator and f.value == nil and f.label == nil then
            local val = math.floor((f.max + f.min) / (f.scale or 1) * 0.2)
            if f.table ~= nil then
                val = #f.table-1
            end
            f.value = val
        end

        -- local col = math.floor((i-1)/maxLines)
        -- local x = 10 + col * (w + lineSpacing)
        -- local y = (i - (col*maxLines) -1)*(h+lineSpacing) + yMinLim + 2
        local col = 0
        -- local x = 10 + col * (w + lineSpacing)
        local x = 10

        local units = "$$"
        if f.id ~= nil then
            if ctl_fieldsInfo[f.id] then
                units = ctl_fieldsInfo[f.id].units
                log("fieldsPageBuild: i=%s, units: %s", i, units)
                if not units then
                    units = ""
                end
            end
        end

        local val_x = 250
        local val_w = 150

        -- merging labels into fields, since they are implemented in two different arrays
        local nextLable = getLableIfNeed(lastFieldY, f)
        lastFieldY = f.y
        if nextLable ~= nil then
            col_id = 0
            y = last_y
            libGUI.newControl.ctl_label(panelFieldsPage, nil, {x=x, y=y, w=0, h=h, title=nextLable.t})
            y = y + h + lineSpacing
            last_y = y
            col_id = 0
        end

        local txt2 = string.format("%s \n%s%s", txt, f.value, units)

        if f.table ~= nil then
            col_id = 0
            y = last_y
            libGUI.newControl.ctl_label(panelFieldsPage, nil, {x=x, y=y, w=0, h=h, title=txt})
            log("fieldsPageBuild: i=%s, table0: %s, table1: %s (total: %s)", i, f.table[0], f.table[1], #f.table)
            libGUI.newControl.ctl_dropdown(panelFieldsPage, nil, {x=val_x, y=y, w=val_w, h=h, items=f.table, selected=f.value, callback=nil} )
            y = y + h + lineSpacing
            last_y = y
            col_id = 0
        elseif f.label == true then
            col_id = 0
            y = last_y
            libGUI.newControl.ctl_label(panelFieldsPage, nil, {x=x, y=y, w=val_w, h=h, title=txt})
            y = y + h + lineSpacing
            last_y = y
            col_id = 0
        else
            local x_Temp =10 + (col_id*(150+6))
            libGUI.newControl.ctl_number_as_button(panelFieldsPage, nil, {
                x=x_Temp, y=y, w=150, h=h_btn,
                title=txt,
                f=f,
                units=units,
                fieldsInfo=ctl_fieldsInfo,
                callbackOnModalActive=function(ctl) is_modal_number_editor_active = true end,
                callbackOnModalInactive=function(ctl) is_modal_number_editor_active = false end
            }
            )

            col_id = col_id + 1
            if col_id > 2 then
                y = y + h_btn + lineSpacing
                col_id = 0
            else
                last_y = y + h_btn + lineSpacing
            end

        end

        log("fieldsPageBuild: i=%s, col=%s, y=%s, title: %s", i, col, y, txt)
    end
end

-- local function drawPopupMenu()
--     local x = radio.MenuBox.x
--     local y = radio.MenuBox.y
--     local w = radio.MenuBox.w
--     local h_line = radio.MenuBox.h_line
--     local h_offset = radio.MenuBox.h_offset
--     local h = #popupMenu * h_line + h_offset*2

--     lcd.drawFilledRectangle(x,y,w,h,backgroundFill)
--     lcd.drawRectangle(x,y,w-1,h-1,foregroundColor)
--     lcd.drawText(x+h_line/2,y+h_offset,"Menu:",globalTextOptions)

--     for i,e in ipairs(popupMenu) do
--         local textOptions = globalTextOptions
--         if popupMenuActive == i then
--             textOptions = textOptions + INVERS
--         end
--         lcd.drawText(x+radio.MenuBox.x_offset,y+(i-1)*h_line+h_offset,e.t,textOptions)
--     end
-- end



-- ---------------------------------------------------------------------
-- init
-- ---------------------------------------------------------------------

local function run_ui(event, touchState)
    log("run_ui: [%s] [%s]", event, touchState)

    local is_modal_active = is_modal_number_editor_active or is_popupmenu_active
    log('is_modal_active: %s', is_modal_active)


    if is_popupmenu_active then
        if event == EVT_VIRTUAL_ENTER and killEnterBreak == 1 then
            killEnterBreak = 0
            killEvents(event)   -- X10/T16 issue: pageUp is a long press
        end
    end
    if popupMenu then
        -- drawPopupMenu()
        -- if event == EVT_VIRTUAL_EXIT then
        --     popupMenu = nil
        -- elseif event == EVT_VIRTUAL_PREV then
        --     incPopupMenu(-1)
        -- elseif event == EVT_VIRTUAL_NEXT then
        --     incPopupMenu(1)
        -- elseif event == EVT_VIRTUAL_ENTER then
        --     if killEnterBreak == 1 then
        --         killEnterBreak = 0
        --     else
        --         popupMenu[popupMenuActive].f()
        --         popupMenu = nil
        --     end
        -- end
    elseif uiState == uiStatus.init then
        drawScreenTitle("Rotorflight "..LUA_VERSION, uiState)
        init = init or assert(loadScript("ui_init.lua"))()
        drawTextMultiline(4, radio.yMinLimit, init.t)
        if not init.f() then
            return 0
        end
        init = nil
        PageFiles = assert(loadScript("pages.lua"))()
        invalidatePages()
        buildPopupMenu()
        buildMainMenu()
        uiState = prevUiState or uiStatus.mainMenu
        prevUiState = nil


    elseif uiState == uiStatus.mainMenu then
        drawScreenTitle("Rotorflight " .. LUA_VERSION, uiState, panelMainMenu)
        log("is_modal_active: %s", is_modal_active)
        if is_popupmenu_active == true then
            log("is_modal_active: onevent()")
            panelPopupMenu.onEvent(event, touchState)
            panelPopupMenu.draw()
        end

        if is_modal_active == false then
            log("is_modal_active: OFF")
            panelMainMenu.draw()
            panelMainMenu.onEvent(event, touchState)
        end

        if event == EVT_VIRTUAL_EXIT then
            return 2
        elseif event == EVT_VIRTUAL_ENTER_LONG then
            killEnterBreak = 1
            -- createPopupMenu()
            is_popupmenu_active = true
            -- killEvents(event) -- X10/T16 issue: pageUp is a long press
        end


    elseif uiState == uiStatus.pages then
        local title = (Page and Page.title or " ---")
        drawScreenTitle(" > "..title, uiState, panelFieldsPage)

        if pageState == pageStatus.saving then
            if saveTS + saveTimeout < getTime() then
                if saveRetries < saveMaxRetries then
                    saveSettings()
                else
                    pageState = pageStatus.display
                    invalidatePages()
                end
            end
        elseif pageState == pageStatus.display then
            if event == EVT_VIRTUAL_PREV_PAGE then
                incPage(-1)
                killEvents(event) -- X10/T16 issue: pageUp is a long press
            elseif event == EVT_VIRTUAL_NEXT_PAGE then
                incPage(1)
            elseif event == EVT_VIRTUAL_ENTER_LONG then
                killEnterBreak = 1
                -- createPopupMenu()
                is_popupmenu_active = true
            elseif event == EVT_VIRTUAL_EXIT then
                change_state_to_menu()
                return 0
            end
        end

        if not Page then
            Page = assert(loadScript("PAGES/"..PageFiles[currentPage].script))()
            collectgarbage()
            buildFieldsPage()
        end
        if not Page.values and pageState == pageStatus.display then
            requestPage()
        end

        if pageState == pageStatus.saving then
            local saveMsg = "Saving..."
            if saveRetries > 0 then
                saveMsg = "Retrying"
            end
            lcd.drawFilledRectangle(radio.SaveBox.x,radio.SaveBox.y,radio.SaveBox.w,radio.SaveBox.h,backgroundFill)
            lcd.drawRectangle(radio.SaveBox.x,radio.SaveBox.y,radio.SaveBox.w,radio.SaveBox.h,SOLID)
            lcd.drawText(radio.SaveBox.x+radio.SaveBox.x_offset,radio.SaveBox.y+radio.SaveBox.h_offset,saveMsg,DBLSIZE + globalTextOptions)
        end

        log("is_modal_active: %s", is_modal_active)
        if is_popupmenu_active == true then
            log("is_modal_active: onevent()")
            panelPopupMenu.onEvent(event, touchState)
            panelPopupMenu.draw()
        end

        if is_modal_active == false then
            log("is_modal_active: OFF")
        end
        panelFieldsPage.draw()
        panelFieldsPage.onEvent(event, touchState)




    elseif uiState == uiStatus.confirm then
        drawScreenFields()
        if event == EVT_VIRTUAL_ENTER then
            uiState = uiStatus.init
            init = Page.init
            invalidatePages()
        elseif event == EVT_VIRTUAL_EXIT then
            invalidatePages()
            uiState = prevUiState
            prevUiState = nil
        end
    end


    -- ???
    -- if getRSSI() == 0 then
    --     lcd.drawText(radio.NoTelem[1],radio.NoTelem[2],radio.NoTelem[3],radio.NoTelem[4])
    -- end
    mspProcessTxQ()
    processMspReply(mspPollReply())
    return 0
end

return run_ui
