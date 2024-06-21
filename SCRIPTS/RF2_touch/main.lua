chdir("/SCRIPTS/RF2_touch")

local LUA_VERSION = "2.0.0-dev.4"

-- to disable touch app, and use the command line version. set to false
local allow_touch_app = true

local function select_ui()
    if allow_touch_app == false then
        return "ui.lua"
    end

    local ver, radio, maj, minor, rev, osname = getVersion()

    local isTouch = (osname=="EdgeTX") and (LCD_W==480) and (LCD_H==272) and (maj==2) and (minor>=9)
    if isTouch then
        return "touch/ui_touch.lua"
    end

    return "ui.lua"
end

apiVersion = 0
mcuId = nil
runningInSimulator = string.sub(select(2,getVersion()), -4) == "simu"

local run = nil
local scriptsCompiled = assert(loadScript("COMPILE/scripts_compiled.lua"))()

if scriptsCompiled then
    protocol = assert(loadScript("protocols.lua"))()
    radio = assert(loadScript("radios.lua"))().msp
    assert(loadScript(protocol.mspTransport))()
    assert(loadScript("MSP/common.lua"))()
    local ui_file = select_ui()
    run = assert(loadScript(ui_file, "tcd"))(LUA_VERSION)
else
    run = assert(loadScript("COMPILE/compile.lua"))()
end

return { run=run }
