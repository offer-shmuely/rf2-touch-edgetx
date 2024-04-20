local toolName = "TNS|_Rotorflight 2 touch disabled|TNE"
chdir("/SCRIPTS/RF2_touch")

--local app_ver = "0.1.0"

-- local function isHighResolutionColor_on_EdgeTx_2_9_x()
--     local ver, radio, maj, minor, rev, osname = getVersion()
--     if osname ~= "EdgeTX"   then return false end
--     if LCD_W ~= 480         then return false end
--     if maj ~= 2             then return false end
--     if minor < 9            then return false end
--     return true
-- end

local function select_ui()
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
    run = assert(loadScript(ui_file, "tcd"))()
    -- run = assert(loadScript("ui.lua"))()
else
    run = assert(loadScript("COMPILE/compile.lua"))()
end

return { run=run }
