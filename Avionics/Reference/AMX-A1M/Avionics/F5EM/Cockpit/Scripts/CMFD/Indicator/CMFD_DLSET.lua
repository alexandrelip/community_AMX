dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local CMFDNumber = get_param_handle("CMFDNumber")
local CMFDNu = CMFDNumber:get()
local BRIGHT = "CMFD"..tostring(CMFDNu).."_BRIGHT"

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.DLSET}}

addOSSText(3, "MODE")

local function add_gated(text, pos, param, low, high, font)
    local item = addStrokeText(nil, text, CMFD_STRINGDEFS_DEF_X08, "CenterCenter", pos, page_root.name, nil, nil, font or CMFD_FONT_W)
    item.element_params = {BRIGHT, param}
    item.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, low, high}}
    return item
end

add_gated("LINK-BR2 SETUP", {0, 0.62}, "CMFD_VARIANT_F5EM", 0.95, 1.05, CMFD_FONT_CYAN)
add_gated("LINK-T SETUP", {0, 0.62}, "CMFD_VARIANT_F5TH", 0.95, 1.05, CMFD_FONT_CYAN)

addStrokeText(nil, "OPERATING MODE", CMFD_STRINGDEFS_DEF_X07, "LeftCenter", {-0.62, 0.42}, page_root.name, nil, nil, CMFD_FONT_W)
add_gated("OFF", {0.36, 0.42}, "DL_MODE", -0.05, 0.05, CMFD_FONT_Y)
add_gated("STBY", {0.36, 0.42}, "DL_MODE", 0.95, 1.05, CMFD_FONT_Y)
add_gated("OPER", {0.36, 0.42}, "DL_MODE", 1.95, 2.05, CMFD_FONT_G)

addStrokeText(nil, "TRACK FILES", CMFD_STRINGDEFS_DEF_X07, "LeftCenter", {-0.62, 0.28}, page_root.name, nil, nil, CMFD_FONT_W)
local object = addStrokeText(nil, "0", CMFD_STRINGDEFS_DEF_X08, "RightCenter", {0.48, 0.28}, page_root.name, nil, {"%2.0f"}, CMFD_FONT_CYAN)
object.element_params = {BRIGHT, "DL_TRACK_COUNT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

addStrokeText(nil, "TDMA ID", CMFD_STRINGDEFS_DEF_X07, "LeftCenter", {-0.62, 0.10}, page_root.name, nil, nil, CMFD_FONT_W)
object = addStrokeText(nil, "0", CMFD_STRINGDEFS_DEF_X08, "RightCenter", {0.48, 0.10}, page_root.name, nil, {"%3.0f"}, CMFD_FONT_CYAN)
object.element_params = {BRIGHT, "DL_SETUP_TDMA_ID"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

addStrokeText(nil, "FORMATION", CMFD_STRINGDEFS_DEF_X07, "LeftCenter", {-0.62, -0.06}, page_root.name, nil, nil, CMFD_FONT_W)
add_gated("UNKNOWN", {0.32, -0.06}, "DL_SETUP_FORMATION", -0.05, 0.05, CMFD_FONT_Y)
add_gated("TRAIL", {0.32, -0.06}, "DL_SETUP_FORMATION", 0.95, 1.05, CMFD_FONT_CYAN)
add_gated("WEDGE", {0.32, -0.06}, "DL_SETUP_FORMATION", 1.95, 2.05, CMFD_FONT_CYAN)
add_gated("LINE", {0.32, -0.06}, "DL_SETUP_FORMATION", 2.95, 3.05, CMFD_FONT_CYAN)
add_gated("SPREAD", {0.32, -0.06}, "DL_SETUP_FORMATION", 3.95, 4.05, CMFD_FONT_CYAN)

add_gated("DTC SETUP NOT LOADED", {0, -0.35}, "DL_SETUP_LOADED", -0.05, 0.05, CMFD_FONT_Y)
add_gated("DTC SETUP LOADED", {0, -0.35}, "DL_SETUP_LOADED", 0.95, 1.05, CMFD_FONT_G)

addStrokeText(nil, "SECURE TACTICAL NETWORK", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0, -0.56}, page_root.name, nil, nil, CMFD_FONT_W)