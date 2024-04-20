local template = assert(loadScript(radio.template))()
local margin = template.margin
local indent = template.indent
local lineSpacing = template.lineSpacing
local tableSpacing = template.tableSpacing
local sp = template.listSpacing.field
local yMinLim = radio.yMinLimit
local x = margin
local y = yMinLim - lineSpacing
local inc = { x = function(val) x = x + val return x end, y = function(val) y = y + val return y end }
local labels = {}
local fields = {}

fields[#fields + 1] = { t = "field 1", x = x, y = inc.y(lineSpacing), sp = x + sp, min = 0, max = 100,   vals = { 6 }, scale = 10, id="profilesRescueClimbTime" }
fields[#fields + 1] = { t = "field 2", x = x, y = inc.y(lineSpacing), sp = x + sp, min = 0, max = 20,   vals = { 80 }, scale = 10, id="profilesRescueClimbTime" }


return {
    read        = 146, -- MSP_RESCUE_PROFILE
    write       = 147, -- MSP_SET_RESCUE_PROFILE
    title       = "Profile - Rescue",
    reboot      = false,
    eepromWrite = true,
    minBytes    = 28,
    labels      = labels,
    fields      = fields,
}
