dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
dofile(LockOn_Options.script_path.."CMFD/CMFD_UFCP_ID_defs.lua")

dofile(LockOn_Options.script_path.."utils.lua")


local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.UFC}}

local object

local CMFD_UFCP_DED_origin = addPlaceholder(nil, {0,0}, page_root.name)

object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, 0.5}, CMFD_UFCP_DED_origin.name, nil, {"%s"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "UFCP_TEXT"}
object.controllers = {
                        {"opacity_using_parameter", 0},
                        {"text_using_parameter", 1, 0},
                    }

-- OSS Menus
object = addOSSText(2,  "MAIN")
object = addOSSText(3,  "MENU")
object = addOSSText(4,  "UP")
object = addOSSArrow(4, 1)
object = addOSSText(5,  "DOWN")
object = addOSSArrow(5, 0)
object = addOSSText(6,  "ENT")

object = addPlaceholder(nil, nil, page_root.name)
object.element_params = {"CMFD"..tostring(CMFDNu).."FULL"}
object.controllers = {{"parameter_compare_with_number",0,1}}
default_parent = object.name

object = addOSSText(12, "A/A")
object = addOSSText(13, "A/G")
object = addOSSText(14, "NAV")
object = addOSSText(21, "CLR")
object = addOSSArrow(23, 1)
object = addOSSArrow(22, 0)

-- UFC1
object = addPlaceholder(nil, nil, page_root.name)
object.element_params = {"CMFD_UFCP_FORMAT"}
object.controllers = {{"parameter_compare_with_number",0,CMFD_UFCP_FORMAT_IDS.UFC1}}
default_parent = object.name

--object = addOSSText(1, "UFC1")
object = addOSSText(7,  "TIME\n6 E ")
object = addOSSText(8,  "MARK\n7   ")
object = addOSSText(9,  "FIX\n8 S")
object = addOSSText(10, "TIP\n9  ")
object = addOSSText(11, "M SEL\n0-   ")


object = addOSSText(24, "XPDR\n5   ")
object = addOSSText(25, "WPT\n4 W")
object = addOSSText(26, "FACK\n3   ")
object = addOSSText(27, "DA/H\n2 N")
object = addOSSText(28, "VV\n1 ")

-- UFC2
object = addPlaceholder(nil, nil, page_root.name)
object.element_params = {"CMFD_UFCP_FORMAT"}
object.controllers = {{"parameter_compare_with_number",0,CMFD_UFCP_FORMAT_IDS.UFC2}}
default_parent = object.name

--object = addOSSText(1 ,"UFC2")
object = addOSSText(7,  "COM 1")
object = addOSSText(8,  "COM 2")
object = addOSSText(9,  "NAV \nAIDS")
object = addOSSText(10, "IDNT")
object = addOSSText(11, "BARO\nRALT")
object = addOSSText(24, "CFG \nCOM2")
object = addOSSText(25, "CFG \nCOM1")
object = addOSSText(26, "WARN\nRST ")
object = addOSSText(27, "AIR\nSPD")
object = addOSSText(28, "CZ")

-- UFC3
object = addPlaceholder(nil, nil, page_root.name)
object.element_params = {"CMFD_UFCP_FORMAT"}
object.controllers = {{"parameter_compare_with_number",0,CMFD_UFCP_FORMAT_IDS.UFC3}}
default_parent = object.name
--object = addOSSText(1,  "UFC3")             --          init_pos={CMFD_FONT_UD1_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0},{"parameter_compare_with_number", 1, CMFD_UFCP_FORMAT_IDS.UFC3}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_UFCP_FORMAT"}},
object = addOSSText(7,  "INS\nOFF")             --         init_pos={CMFD_FONT_R_HORI_X, ( 5.8*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0},{"parameter_compare_with_number", 1, CMFD_UFCP_FORMAT_IDS.UFC3}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_UFCP_FORMAT"}},
object = addOSSText(8,  "INS\nSH ")             --         init_pos={CMFD_FONT_R_HORI_X, ( 4.1*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0},{"parameter_compare_with_number", 1, CMFD_UFCP_FORMAT_IDS.UFC3}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_UFCP_FORMAT"}},
object = addOSSText(9,  "INS\nGC")              --    init_pos={CMFD_FONT_R_HORI_X, ( 2.5*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0},{"parameter_compare_with_number", 1, CMFD_UFCP_FORMAT_IDS.UFC3}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_UFCP_FORMAT"}},
object = addOSSText(10,  "INS\nNAV")             --          init_pos={CMFD_FONT_R_HORI_X, ( 0.9*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0},{"parameter_compare_with_number", 1, CMFD_UFCP_FORMAT_IDS.UFC3}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_UFCP_FORMAT"}},
object = addOSSText(11,  "INS\nTST")             --    init_pos={CMFD_FONT_R_HORI_X, (-1.2*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0},{"parameter_compare_with_number", 1, CMFD_UFCP_FORMAT_IDS.UFC3}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_UFCP_FORMAT"}},
object = addOSSText(12,  "RAL\nXMT")             --      init_pos={CMFD_FONT_L_HORI_X, ( 4.1*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0},{"parameter_compare_with_number", 1, CMFD_UFCP_FORMAT_IDS.UFC3}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_UFCP_FORMAT"}},
object = addOSSText(13,  "RAL\nOFF")             --            init_pos={CMFD_FONT_L_HORI_X, ( 5.8*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0},{"parameter_compare_with_number", 1, CMFD_UFCP_FORMAT_IDS.UFC3}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_UFCP_FORMAT"}},


page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."FULL", "CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,0}, {"parameter_compare_with_number", 1, SUB_PAGE_ID.MENU2, 1}}

local origin = addPlaceholder(nil,
    {-0.5, -((aspect-0.45)/2 + 0.3)}, page_root.name)
origin.element_params = {"CMFD"..CMFDNu.."SelLeft"}
origin.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.UFC}}
local panel_background = addFillBox(nil, 0.96, aspect-0.42,
    "CenterCenter", {0,0}, origin.name, nil, CMFD_MATERIAL_DARK)
panel_background.additive_alpha = false

object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, 0.1}, origin.name, nil, {"%s"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "UFCP_TEXT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

object = addStrokeBox(nil, 0.85, 0.35, "CenterCenter", {0,0}, object.name)

origin = addPlaceholder(nil,
    {0.5, -((aspect-0.45)/2 + 0.3)}, page_root.name)
origin.element_params = {"CMFD"..CMFDNu.."SelRight"}
origin.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.UFC}}
panel_background = addFillBox(nil, 0.96, aspect-0.42,
    "CenterCenter", {0,0}, origin.name, nil, CMFD_MATERIAL_DARK)
panel_background.additive_alpha = false

object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, 0.1}, origin.name, nil, {"%s"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "UFCP_TEXT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

object = addStrokeBox(nil, 0.85, 0.35, "CenterCenter", {0,0}, object.name)
