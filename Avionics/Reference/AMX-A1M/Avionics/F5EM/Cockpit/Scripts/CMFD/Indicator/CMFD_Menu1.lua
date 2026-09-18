dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_in_range", 0, SUB_PAGE_ID.MENU1 - 0.05, SUB_PAGE_ID.MENU1 + 0.05}}

local MENU_BRIGHT_PARAM = "CMFD"..tostring(CMFDNu).."_BRIGHT"
local MENU_FORMAT_PARAM = "CMFD"..CMFDNu.."Format"
local MENU_PARAMS = {MENU_BRIGHT_PARAM, MENU_FORMAT_PARAM}
local MENU_CONTROLLERS = {
    {"opacity_using_parameter", 0},
    {"parameter_in_range", 1, SUB_PAGE_ID.MENU1 - 0.05, SUB_PAGE_ID.MENU1 + 0.05},
}

local HW = 0.15
local HH = 0.04 * H2W_SCALE

local function addOSSMenu(pos, text, code, size, lines)
    size = size or #text
    lines = lines or (1 + select(2, text:gsub('\n', '\n')))
    local base = addOSSText(pos, text, page_root.name, MENU_PARAMS, MENU_CONTROLLERS)
    local object = addOSSStrokeBox(pos, lines, page_root.name, nil, nil, nil, size)
    object.element_params = {MENU_BRIGHT_PARAM, "CMFD"..CMFDNu.."Sel", MENU_FORMAT_PARAM}
    object.controllers = {
        {"opacity_using_parameter", 0},
        {"parameter_in_range", 1, code - 0.05, code + 0.05},
        {"parameter_in_range", 2, SUB_PAGE_ID.MENU1 - 0.05, SUB_PAGE_ID.MENU1 + 0.05},
    }
    return base
end

local function addOSSMenuVariant(pos, text, code, variant_param, variant_value, size, lines)
    size = size or #text
    lines = lines or (1 + select(2, text:gsub('\n', '\n')))

    local base = addOSSText(
        pos,
        text,
        page_root.name,
        {MENU_BRIGHT_PARAM, variant_param, MENU_FORMAT_PARAM},
        {
            {"opacity_using_parameter", 0},
            {"parameter_in_range", 1, variant_value - 0.05, variant_value + 0.05},
            {"parameter_in_range", 2, SUB_PAGE_ID.MENU1 - 0.05, SUB_PAGE_ID.MENU1 + 0.05},
        }
    )

    local object = addOSSStrokeBox(pos, lines, page_root.name, nil, nil, nil, size)
    object.element_params = {MENU_BRIGHT_PARAM, "CMFD"..CMFDNu.."Sel", variant_param, MENU_FORMAT_PARAM}
    object.controllers = {
        {"opacity_using_parameter", 0},
        {"parameter_in_range", 1, code - 0.05, code + 0.05},
        {"parameter_in_range", 2, variant_value - 0.05, variant_value + 0.05},
        {"parameter_in_range", 3, SUB_PAGE_ID.MENU1 - 0.05, SUB_PAGE_ID.MENU1 + 0.05},
    }
    return base
end

local object
object = addOSSText(1, "MENU\n2", page_root.name, MENU_PARAMS, MENU_CONTROLLERS)
object = addOSSText(3, "MSMD\nRST", page_root.name, MENU_PARAMS, MENU_CONTROLLERS)
object = addOSSText(4, "SG\nRST", page_root.name, MENU_PARAMS, MENU_CONTROLLERS)

object = addOSSMenu(6, "FLIR", SUB_PAGE_ID.LDP)
object = addOSSMenu(7, "RDR", SUB_PAGE_ID.RDR)

object = addOSSMenu(8, "BIT", SUB_PAGE_ID.BIT)
object = addOSSMenu(9, "DVR", SUB_PAGE_ID.DVR)
object = addOSSMenu(10, "NAV", SUB_PAGE_ID.NAV)
object = addOSSMenu(11, "PFL", SUB_PAGE_ID.PFL)
object = addOSSMenu(12, "EMER", SUB_PAGE_ID.EMER)
object = addOSSMenu(13, "DTU", SUB_PAGE_ID.DTU)
object = addOSSMenu(14, "UFC", SUB_PAGE_ID.UFC)
object = addOSSMenu(21, "HUD", SUB_PAGE_ID.HUD)
object = addOSSMenu(22, "HMD", SUB_PAGE_ID.HMD)
object = addOSSMenu(23, "EICAS", SUB_PAGE_ID.EICAS)
object = addOSSMenu(24, "ADHSI", SUB_PAGE_ID.ADHSI)
object = addOSSMenu(25, "EW", SUB_PAGE_ID.EW)
object = addOSSMenu(26, "SMS", SUB_PAGE_ID.SMS)
-- Paridade F-5TH = F-5EM: rotulo IFR segue CMFD_HAS_IFR, ligado nas duas variantes.
object = addOSSMenuVariant(27, "IFR", SUB_PAGE_ID.IFR, "CMFD_HAS_IFR", 1)
object = addOSSMenu(28, "HSD", SUB_PAGE_ID.TSD)

object = addStrokeText("CMFD_MENU1_VERSION", "F-5EM\nV0.86",
    CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, 0.05}, page_root.name,
    nil, nil, CMFD_FONT_CYAN)
object.element_params = MENU_PARAMS
object.controllers = MENU_CONTROLLERS





