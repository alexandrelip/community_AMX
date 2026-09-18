dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local CMFDNumber = get_param_handle("CMFDNumber")
local CMFDNu = CMFDNumber:get()
local BRIGHT = "CMFD"..tostring(CMFDNu).."_BRIGHT"

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.DLMSG}}

local function add_gated(text, pos, param, low, high, font)
    local item = addStrokeText(nil, text, CMFD_STRINGDEFS_DEF_X07, "CenterCenter", pos, page_root.name, nil, nil, font or CMFD_FONT_W)
    item.element_params = {BRIGHT, param}
    item.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, low, high}}
end

add_gated("LINK-BR2 MESSAGES", {0, 0.62}, "CMFD_VARIANT_F5EM", 0.95, 1.05, CMFD_FONT_CYAN)
add_gated("LINK-T MESSAGES", {0, 0.62}, "CMFD_VARIANT_F5TH", 0.95, 1.05, CMFD_FONT_CYAN)

addStrokeText(nil, "PREPLANNED TEXT", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {-0.62, 0.46}, page_root.name, nil, nil, CMFD_FONT_W)
local object = addStrokeText(nil, "0", CMFD_STRINGDEFS_DEF_X07, "RightCenter", {0.58, 0.46}, page_root.name, nil, {"%2.0f MSG"}, CMFD_FONT_CYAN)
object.element_params = {BRIGHT, "DL_MSG_COUNT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

for i = 1, 8 do
    local a = string.format("%02d", i)
    local y = 0.34 - (i - 1) * 0.105
    add_gated(string.format("MSG %02d   PTEXT", i), {-0.18, y}, "DL_MSG_"..a.."_VALID", 0.95, 1.05, CMFD_FONT_W)
end

add_gated("NO MESSAGES", {0, -0.18}, "DL_MSG_COUNT", -0.05, 0.05, CMFD_FONT_Y)
addStrokeText(nil, "PTEXT DIRECTORY", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0, -0.58}, page_root.name, nil, nil, CMFD_FONT_W)