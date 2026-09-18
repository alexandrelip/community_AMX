dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local CMFDNumber = get_param_handle("CMFDNumber")
local CMFDNu = CMFDNumber:get()
local BRIGHT = "CMFD"..tostring(CMFDNu).."_BRIGHT"

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.EFB}}

local function label(text, x, y, font)
    return addStrokeText(nil, text, CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {x, y}, page_root.name, nil, nil, font or CMFD_FONT_W)
end

local function value(param, x, y, format, font)
    local item = addStrokeText(nil, "0", CMFD_STRINGDEFS_DEF_X06, "RightCenter", {x, y}, page_root.name, nil, {format}, font or CMFD_FONT_CYAN)
    item.element_params = {BRIGHT, param}
    item.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
    return item
end

local function warning(text, x, param)
    local item = addStrokeText(nil, text, CMFD_STRINGDEFS_DEF_X06, "CenterCenter", {x, -0.67}, page_root.name, nil, nil, CMFD_FONT_R)
    item.element_params = {BRIGHT, param}
    item.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}
end

label("ELECTRONIC FLIGHT BAG", -0.48, 0.66, CMFD_FONT_CYAN)

label("FUEL", -0.78, 0.48, CMFD_FONT_Y)
label("TOTAL", -0.75, 0.38);       value("EFB_FUEL_KG", -0.12, 0.38, "%4.0f KG")
label("REMAIN", -0.75, 0.29);      value("EFB_FUEL_PCT", -0.12, 0.29, "%3.0f %%")
label("RANGE", -0.75, 0.20);       value("EFB_RANGE_NM", -0.12, 0.20, "%4.0f NM")
label("ENDUR", -0.75, 0.11);       value("EFB_ENDURANCE_MIN", -0.12, 0.11, "%3.0f MIN")
label("BINGO", -0.75, 0.02);       value("EFB_BINGO_DYN_KG", -0.12, 0.02, "%4.0f KG")

label("WEIGHT / PERF", 0.08, 0.48, CMFD_FONT_Y)
label("GROSS", 0.10, 0.38);        value("EFB_GW_KG", 0.82, 0.38, "%5.0f KG")
label("V STALL", 0.10, 0.29);      value("EFB_V_STALL_KIAS", 0.82, 0.29, "%3.0f KT")
label("V ROT", 0.10, 0.20);        value("EFB_V_ROT_KIAS", 0.82, 0.20, "%3.0f KT")
label("V APP", 0.10, 0.11);        value("EFB_V_APP_KIAS", 0.82, 0.11, "%3.0f KT")

label("NAVIGATION", -0.78, -0.16, CMFD_FONT_Y)
label("HOME BRG", -0.75, -0.27);   value("EFB_BRG_HOME_DEG", -0.04, -0.27, "%03.0f DEG")
label("HOME RNG", -0.75, -0.36);   value("EFB_DIST_HOME_NM", -0.04, -0.36, "%4.0f NM")
label("NEXT WP", 0.10, -0.27);     value("EFB_DIST_WP_NM", 0.82, -0.27, "%4.0f NM")
label("WP ETE", 0.10, -0.36);      value("EFB_ETE_WP_MIN", 0.82, -0.36, "%3.0f MIN")

warning("BINGO", -0.45, "EFB_BINGO_REACHED")
warning("MTOW", 0, "EFB_OVER_MTOW")
warning("LAND WT", 0.45, "EFB_OVER_LANDING")