dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/avionics_api.lua")
dofile(LockOn_Options.script_path.."CMFD/CMFD_NAV_ID_defs.lua")

dofile(LockOn_Options.script_path.."utils.lua")

local CMFDNumber=get_param_handle("CMFDNumber")
local CMFDNu = CMFDNumber:get()

local aspect = GetAspect()

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.NAV}}


local object

object = addOSSText(2, "ROUT")
object = addOSSStrokeBox(2,1)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FORMAT"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, CMFD_NAV_FORMAT_IDS.ROUT}}

object = addOSSText(5, "FYT")
object = addOSSStrokeBox(5,1)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FORMAT"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, CMFD_NAV_FORMAT_IDS.FYT}}

object = addOSSText(6, "MARK")
object = addOSSStrokeBox(6,1)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FORMAT"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, CMFD_NAV_FORMAT_IDS.MARK}}

object = addOSSText(7, "A/C")
object = addOSSStrokeBox(7,1)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FORMAT"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, CMFD_NAV_FORMAT_IDS.AC}}

object = addOSSText(8, "DATA")
object = addOSSStrokeBox(8,1)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FORMAT"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, CMFD_NAV_FORMAT_IDS.DATA}}

object = addOSSText(28, "AFLD")
object = addOSSStrokeBox(28,1)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FORMAT"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, CMFD_NAV_FORMAT_IDS.AFLD}}

object = addOSSArrow(3, 0, nil)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_PG_NEXT"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

object = addOSSArrow(4, 1, nil)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_PG_PREV"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}


local CMFD_NAV_FYT_origin = addPlaceholder(nil, {0,0}, page_root.name)
CMFD_NAV_FYT_origin.element_params = {"CMFD_NAV_FORMAT"}
CMFD_NAV_FYT_origin.controllers = {{"parameter_compare_with_number", 0, CMFD_NAV_FORMAT_IDS.FYT}}

object = addOSSArrow(27, 1, CMFD_NAV_FYT_origin.name)
object = addOSSArrow(26, 0, CMFD_NAV_FYT_origin.name)

object = addStrokeText(nil, "FYT\n5", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.89, 0.56}, CMFD_NAV_FYT_origin.name, nil, {"FT\n%1.0f"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

CMFD_NAV_FYT_origin = addPlaceholder(nil, GetMainCenter(), CMFD_NAV_FYT_origin.name)

object = addStrokeText(nil, "FT   5", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, 0.66}, CMFD_NAV_FYT_origin.name, nil, {"FT   %1.0f"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "TOFT 00:00:00", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, 0.391}, CMFD_NAV_FYT_origin.name, nil, {"TOFT %02.0f:", "%02.0f:", "%02.0f"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_HOURS", "CMFD_NAV_FYT_MINS", "CMFD_NAV_FYT_SECS"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}, {"text_using_parameter", 3, 2}}

object = addStrokeText(nil, "N   41`52.20'", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, 0.305}, CMFD_NAV_FYT_origin.name, nil, {"%s", "   %02.0f`", "%05.2f'"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_LAT_HEMIS", "CMFD_NAV_FYT_LAT_DEG", "CMFD_NAV_FYT_LAT_MIN"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}, {"text_using_parameter", 3, 2}}

object = addStrokeText(nil, "N  047`39.51'", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, 0.206}, CMFD_NAV_FYT_origin.name, nil, {"%s", "  %03.0f`", "%05.2f'"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_LON_HEMIS", "CMFD_NAV_FYT_LON_DEG", "CMFD_NAV_FYT_LON_MIN"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}, {"text_using_parameter", 3, 2}}

object = addStrokeText(nil, "ELV    120 FT", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, 0.02}, CMFD_NAV_FYT_origin.name, nil, {"ELV %5.0f FT"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_ELV"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "TTG 00:00", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.41, -0.095}, CMFD_NAV_FYT_origin.name, nil, {"TTG %02.0f:", "%02.0f"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_DTK_MINS", "CMFD_NAV_FYT_DTK_SECS"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}}

object = addStrokeText(nil, "ETA 00:00:00", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.41, -0.155}, CMFD_NAV_FYT_origin.name, nil, {"ETA %02.0f:", "%02.0f:", "%02.0f"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_DTK_ETA_HOURS", "CMFD_NAV_FYT_DTK_ETA_MINS", "CMFD_NAV_FYT_DTK_ETA_SECS"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}, {"text_using_parameter", 3, 2}}

object = addStrokeText(nil, "GSR 000 KT", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.41, -0.215}, CMFD_NAV_FYT_origin.name, nil, {"GSR %03.0f KT"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_DTK_STT", "CMFD_NAV_FYT_DTK_STT_VALID"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 2, 1}, {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "GSR XXX KT", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.41, -0.215}, CMFD_NAV_FYT_origin.name)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_DTK_STT_VALID"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 0}}

object = addStrokeText(nil, "DTK 000`", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {0.22, 0.391}, CMFD_NAV_FYT_origin.name, nil, {"DTK %03.0f`"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_DTK_BRG_TEXT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "DIS  0.0 NM", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {0.22, 0.305}, CMFD_NAV_FYT_origin.name, nil, {"DIS %5.1f NM"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_DTK_DIST"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "DELV   0 FT", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {0.22, 0.206}, CMFD_NAV_FYT_origin.name, nil, {"DELV %5.0f FT"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_DTK_ELV"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "OAP", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, -0.349}, CMFD_NAV_FYT_origin.name)

-- OAP disabled: show current DTK leg solution.
object = addStrokeText(nil, "BRG  350`", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, -0.448}, CMFD_NAV_FYT_origin.name, nil, {"BRG  %03.0f`"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_DTK_BRG_TEXT", "UFCP_OAP"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 2, 0}, {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "DIS  1300 NM", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, -0.543}, CMFD_NAV_FYT_origin.name, nil, {"DIS %5.1f NM"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_DTK_DIST", "UFCP_OAP"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 2, 0}, {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "ELV  +733 FT", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, -0.627}, CMFD_NAV_FYT_origin.name, nil, {"ELV %+5.0f FT"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_DTK_ELV", "UFCP_OAP"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 2, 0}, {"text_using_parameter", 1, 0}}

-- OAP enabled: show saved OAP offset point.
object = addStrokeText(nil, "BRG  350`", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, -0.448}, CMFD_NAV_FYT_origin.name, nil, {"BRG  %03.0f`"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_OAP_BRG", "UFCP_OAP"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 2, 1}, {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "DIS  1300 NM", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, -0.543}, CMFD_NAV_FYT_origin.name, nil, {"DIS %5.1f NM"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_OAP_DIST", "UFCP_OAP"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 2, 1}, {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "ELV   733 FT", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.41, -0.627}, CMFD_NAV_FYT_origin.name, nil, {"ELV %5.0f FT"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_OAP_ELV", "UFCP_OAP"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 2, 1}, {"text_using_parameter", 1, 0}}

page_root = addPlaceholder(nil, GetMainCenter(), page_root.name)

local CMFD_NAV_ROUT_origin = addPlaceholder(nil, {0,0}, page_root.name)
CMFD_NAV_ROUT_origin.element_params = {"CMFD_NAV_FORMAT"}
CMFD_NAV_ROUT_origin.controllers = {{"parameter_compare_with_number", 0, CMFD_NAV_FORMAT_IDS.ROUT}}

object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, -0.1}, CMFD_NAV_ROUT_origin.name, nil, {"%s", "%s", "%s"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_ROUT_TEXT", "CMFD_NAV_ROUT_TEXT1", "CMFD_NAV_ROUT_TEXT2"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}, {"text_using_parameter", 3, 2}}

local CMFD_NAV_AC_origin = addPlaceholder(nil, {0,0}, page_root.name)
CMFD_NAV_AC_origin.element_params = {"CMFD_NAV_FORMAT"}
CMFD_NAV_AC_origin.controllers = {{"parameter_compare_with_number", 0, CMFD_NAV_FORMAT_IDS.AC}}

object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, -0.1}, CMFD_NAV_AC_origin.name, nil, {"%s", "%s", "%s"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_AC_TEXT", "CMFD_NAV_AC_TEXT1", "CMFD_NAV_AC_TEXT2"}
object.controllers = {
                        {"opacity_using_parameter", 0},
                        {"text_using_parameter", 1, 0},
                    }

local CMFD_NAV_DATA_origin = addPlaceholder(nil, {0,0}, page_root.name)
CMFD_NAV_DATA_origin.element_params = {"CMFD_NAV_FORMAT"}
CMFD_NAV_DATA_origin.controllers = {{"parameter_compare_with_number", 0, CMFD_NAV_FORMAT_IDS.DATA}}

object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, -0.1}, CMFD_NAV_DATA_origin.name, nil, {"%s"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_DATA_TEXT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

local CMFD_NAV_AFLD_origin = addPlaceholder(nil, {0,0}, page_root.name)
CMFD_NAV_AFLD_origin.element_params = {"CMFD_NAV_FORMAT"}
CMFD_NAV_AFLD_origin.controllers = {{"parameter_compare_with_number", 0, CMFD_NAV_FORMAT_IDS.AFLD}}

object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, -0.1}, CMFD_NAV_AFLD_origin.name, nil, {"%s"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_AFLD_TEXT"}
object.controllers = {
                        {"opacity_using_parameter", 0},
                        {"text_using_parameter", 1, 0},
                    }

local CMFD_NAV_MARK_origin = addPlaceholder(nil, {0,0}, page_root.name)
CMFD_NAV_MARK_origin.element_params = {"CMFD_NAV_FORMAT"}
CMFD_NAV_MARK_origin.controllers = {{"parameter_compare_with_number", 0, CMFD_NAV_FORMAT_IDS.MARK}}

object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, -0.1}, CMFD_NAV_MARK_origin.name, nil, {"%s"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_MARK_TEXT"}
object.controllers = {
                        {"opacity_using_parameter", 0},
                        {"text_using_parameter", 1, 0},
                    }

