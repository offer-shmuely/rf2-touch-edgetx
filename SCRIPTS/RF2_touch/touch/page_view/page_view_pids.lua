local app_name, script_dir = ...

local M = {}

function M.buildSpecialFields(libGUI, panel,Page,  y, runningInSimulator)
    local num_col = 4
    local row_h = 35
    local col1_w = 120
    local col_w = (LCD_W-col1_w)/num_col-1
    local col_w2 = (LCD_W-col1_w)/num_col

    -- col headers
    local txt
    libGUI.newControl.ctl_title(panel, nil, {x=0,y=y, w=col1_w, h=30, text1_x=10, bg_color=GREY, text1="Axis"})
    libGUI.newControl.ctl_title(panel, nil, {x=col1_w+1+0*(col_w2), y=y, w=col_w, h=30, text1_x="CENTER", bg_color=GREY, text1=Page.labels[6].t})
    libGUI.newControl.ctl_title(panel, nil, {x=col1_w+1+1*(col_w2), y=y, w=col_w, h=30, text1_x="CENTER", bg_color=GREY, text1=Page.labels[8].t})
    libGUI.newControl.ctl_title(panel, nil, {x=col1_w+1+2*(col_w2), y=y, w=col_w, h=30, text1_x="CENTER", bg_color=GREY, text1=Page.labels[10].t .." ".. Page.labels[11].t})
    libGUI.newControl.ctl_title(panel, nil, {x=col1_w+1+3*(col_w2), y=y, w=col_w, h=30, text1_x="CENTER", bg_color=GREY, text1=Page.labels[12].t2 .." ".. Page.labels[13].t2})

    y = y + 30
    -- line names
    libGUI.newControl.ctl_title(panel, nil, {x=0, y=y+0*row_h, w=col1_w, h=row_h, bg_color=RED,    text1_x=10, text1="ROLL"})
    libGUI.newControl.ctl_title(panel, nil, {x=0, y=y+1*row_h, w=col1_w, h=row_h, bg_color=GREEN,  text1_x=10, text1="PITCH"})
    libGUI.newControl.ctl_title(panel, nil, {x=0, y=y+2*row_h, w=col1_w, h=row_h, bg_color=BLUE,   text1_x=10, text1="YAW"})
    local last_y = y

    -- values
    local defaults = { 120,100,90, 150,150,150, 80,120,10, 60,70,0,     1,2,3,   4, 5, 6}
    for col=1, 4 do
        for row=1, 3 do
            local x1 = col1_w+1+(col-1)*(col_w2)
            local y1 = y + (row-1)*row_h
            local i = (col-1)*3 + row
            local f = Page.fields[i]
            -- if runningInSimulator and f.value == nil and f.label == nil then
            if runningInSimulator and f.label == nil then
                f.max = 1000
                f.min = 1
                f.value = defaults[i]
            end

            libGUI.newControl.ctl_number(panel, nil,
                {x=x1+1, y=y1+1, w=col_w-2, h=row_h-2, value=f.value, min=f.min, max=f.max,
                bg_color=panel.colors.btn.bg,
                    onChangeValue=function(delta_val, ctl)
                        panel.log("onChangeValue: %s - %s", delta_val, ctl)
                        panel.log("onChangeValue1: f.value: %s", f.value)
                        f.value = f.value + delta_val
                        panel.log("onChangeValue2: f.value: %s", f.value)
                        return f.value
                    end
                },
                CENTER
            )
            last_y = y1
        end
    end

    y = last_y + 80
    -- libGUI.newControl.ctl_label(panel, nil, {x=5, y=y, h=30, text="Advance"})
    libGUI.newControl.ctl_title(panel, nil,
    {x=0, y=y, w=LCD_W, h=25, text1="Advance", bg_color=panel.colors.topbar.bg, txt_color=panel.colors.topbar.txt})

    y = y + row_h

    -- col headers
    local txt
    libGUI.newControl.ctl_title(panel, nil, {x=0, y=y, w=col1_w, h=30, text1_x=10, bg_color=GREY, text1="Axis"})

    libGUI.newControl.ctl_title(panel, nil,
        {x=col1_w+1+0*(col_w2), y=y, w=col_w, h=30, text1_x=="CENTER", bg_color=GREY, text1=Page.labels[19].t2}
    )
    libGUI.newControl.ctl_title(panel, nil,
        {x=col1_w+1+1*(col_w2), y=y, w=col_w, h=30, text1_x=="CENTER", bg_color=GREY, text1=Page.labels[20].t2})

    y = y + 30
    -- line names
    libGUI.newControl.ctl_title(panel, nil, {x=0, y=y+0*row_h, w=col1_w, h=row_h, bg_color=RED,    text1_x=10, text1="ROLL"})
    libGUI.newControl.ctl_title(panel, nil, {x=0, y=y+1*row_h, w=col1_w, h=row_h, bg_color=GREEN,  text1_x=10, text1="PITCH"})
    libGUI.newControl.ctl_title(panel, nil, {x=0, y=y+2*row_h, w=col1_w, h=row_h, bg_color=BLUE,   text1_x=10, text1="YAW"})

    for i=1, #Page.labels do
        log("buildSpecialFields: i.%s t:%s", i, Page.labels[i].t or "NO")
    end

    -- values
    for col=1, 2 do
        for row=1, 3 do
            local x1 = col1_w+1+(col-1)*(col_w2)
            local y1 = y + (row-1)*row_h
            local i = 12 +(col-1)*3 + row
            local f = Page.fields[i]
            if f then
                if runningInSimulator and f.value == nil and f.label == nil then
                    f.max = 100
                    f.min = 10
                    f.value = defaults[i]
                end

                libGUI.newControl.ctl_number(panel, nil,
                    {x=x1, y=y1, w=col_w, h=row_h, value=f.value, min=f.min, max=f.max,
                        onChangeValue=function(delta_val, ctl)
                            log("onChangeValue: %s - %s", delta_val, ctl)
                            log("onChangeValue1: f.value: %s", f.value)
                            f.value = f.value + delta_val
                            log("onChangeValue2: f.value: %s", f.value)
                            return f.value
                        end
                    },
                    CENTER
                )
            end
        end
    end

    return 18,0 -- firstRegularField, last_y
end

return M
