dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/avionics_api.lua")

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.ADHSI}}
default_parent      = page_root.name


local aspect = GetAspect()

local object

-- MODE
object = addStrokeText("ADHSI_MODE_EGI", "EGI", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {-0.87, 0.63}, nil, nil,nil, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, AVIONICS_ANS_MODE_IDS.EGI}}
object = addStrokeText("ADHSI_MODE_VOR", "VOR", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {-0.87, 0.63}, nil, nil, nil, CMFD_FONT_G)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, AVIONICS_ANS_MODE_IDS.VOR}}
object = addStrokeText("ADHSI_MODE_GPS", "GPS", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {-0.87, 0.63}, nil, nil,nil, CMFD_FONT_B)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, AVIONICS_ANS_MODE_IDS.GPS}}
object = addStrokeText("ADHSI_MODE_ILS", "ILS", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {-0.87, 0.63}, nil, nil,nil, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, AVIONICS_ANS_MODE_IDS.ILS}}

-- Digital Speed
object = addStrokeText("ADHSI_IAS", "210", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.555, 1.09}, nil, nil, {"%03.0f"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_IAS"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
object = addStrokeBox("ADHSI_IAS_BOX", 0.144, 0.076, "CenterCenter", {0, 0}, object.name)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}

-- Digital Altitude
object = addStrokeText("ADHSI_ALT", "5960", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.615, 1.09}, nil, nil, {"%5.0f'"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ALT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
object = addStrokeBox("ADHSI_ALT_BOX", 0.24, 0.076, "CenterCenter", {-0.01, 0}, object.name)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}

-- RALT
object = addStrokeText("ADHSI_RALT_TEXT", "RALT", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.667, 0.34})
object = addStrokeText("ADHSI_RALT", "9999", CMFD_STRINGDEFS_DEF_X08, "RightCenter", {0.95, 0.34}, nil, nil, {"%03.0f"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_RALT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range",1,-0.05,5005}}
object = addStrokeText("ADHSI_RALT_XXXX", "XXXX", CMFD_STRINGDEFS_DEF_X08, "RightCenter", {0.95, 0.34})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_RALT"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number",1,-1}}

-- VV
object = addStrokeText("ADHSI_VV_TEXT", "VV", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {0.877, 0.7}, nil, nil,nil, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeBox("ADHSI_VV_BOX", 0.147, 0.088, "CenterCenter", {0, 0}, object.name, nil, CMFD_MATERIAL_WHITE)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_VV"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

-- VV scale
local vvScale500ftStep		    = 0.05
local vvScaleLongTickLen		= 0.05
local vvScaleShortTickLen		= 0.025
local UnitsPerOneFeetPerMin		= 3 * vvScale500ftStep / 20000 -- don't know why

local VVScale_origin = addPlaceholder("ADHSI_VVScale_origin", {0.45, 0.665})
VVScale_origin.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_VV"}
VVScale_origin.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number",1,1} }

local VVScale_origin_indicator = addPlaceholder("VVScale_origin_indicator", {0.17, 0}, VVScale_origin.name)
VVScale_origin_indicator.element_params = {"ADHSI_VV_LIM"}
VVScale_origin_indicator.controllers = {{"move_up_down_using_parameter", 0, UnitsPerOneFeetPerMin}}

object = addFillArrowBox("ADHSI_VV_MBOX", 0.224, 0.064, "CenterCenter", {0, 0}, VVScale_origin_indicator.name, nil, CMFD_MATERIAL_CYAN)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeText("ADHSI_VV", "VV", CMFD_STRINGDEFS_DEF_X06, "CenterCenter", {0, 0}, VVScale_origin_indicator.name, nil,{" %+4.0f"}, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_VV"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}


addStrokeLine("VVScaleTickLong_0", vvScaleLongTickLen, {0, 0}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickLong_1", vvScaleLongTickLen, {0, 2*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickLong_2", vvScaleLongTickLen, {0, 4*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickLong_3", vvScaleLongTickLen, {0, -2*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickLong_4", vvScaleLongTickLen, {0, -4*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)

addStrokeLine("VVScaleTickShort_0", vvScaleShortTickLen, {0, vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickShort_1", vvScaleShortTickLen, {0, 3*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickShort_2", vvScaleShortTickLen, {0, -vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickShort_3", vvScaleShortTickLen, {0, -3*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)

addStrokeText("VVScaleNumerics_0", "0", CMFD_STRINGDEFS_DEF_X07, "RightCenter", {-0.01, 0}, VVScale_origin.name, nil, nil, CMFD_FONT_W)
addStrokeText("VVScaleNumerics_1", "1", CMFD_STRINGDEFS_DEF_X07, "RightCenter", {-0.01, 2*vvScale500ftStep}, VVScale_origin.name, nil, nil, CMFD_FONT_W)
addStrokeText("VVScaleNumerics_2", "2", CMFD_STRINGDEFS_DEF_X07, "RightCenter", {-0.01, 4*vvScale500ftStep}, VVScale_origin.name, nil, nil, CMFD_FONT_W)
addStrokeText("VVScaleNumerics_3", "-1", CMFD_STRINGDEFS_DEF_X07, "RightCenter", {-0.01, -2*vvScale500ftStep}, VVScale_origin.name, nil, nil, CMFD_FONT_W)
addStrokeText("VVScaleNumerics_4", "-2", CMFD_STRINGDEFS_DEF_X07, "RightCenter", {-0.01, -4*vvScale500ftStep}, VVScale_origin.name, nil, nil, CMFD_FONT_W)


-- DA
object = addStrokeText("ADHSI_DA", "DA", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.735, 0.965}, nil, nil,{"DA %5.0f"}, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "UFCP_DA"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

-- DH
object = addStrokeText("ADHSI_DA", "DA", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.735, 0.21}, nil, nil,{"DH %5.0f"}, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "UFCP_DH"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}


-- Digital Heading
object = addStrokeText("ADHSI_HDG", "", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.02, 1.22}, nil, nil, {"%03.0f`"}, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_HDG"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range", 1, -0.05, 360.05}}
object = addStrokeText("ADHSI_NOHDG", "XXX", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.02, 1.22}, nil, nil, nil, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_HDG"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, -1}}
object = addStrokeBox("ADHSI_HDG_BOX", 0.16, 0.084, "CenterCenter", {-0.02, 1.22}, nil, nil, CMFD_MATERIAL_WHITE)


-- AP
object = addStrokeText("ADHSI_AP_TEXT", "AP", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {-0.865, 0.858})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_AP"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

-- AP ROL
object = addStrokeText("ADHSI_ROL_TEXT", "ROL", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.552, 1.226})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_AP_ROL"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

-- AP HDG
object = addStrokeText("ADHSI_HDG_TEXT", "HDG", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.552, 1.226})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_AP_HDG"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

-- AP PIT
object = addStrokeText("ADHSI_PIT_TEXT", "PIT", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.563, 1.226})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_AP_PIT"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

-- AP ALT
object = addStrokeText("ADHSI_ALT_TEXT", "ALT", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.563, 1.226})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_AP_ALT"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

-- AP NAV
object = addStrokeText("ADHSI_NAV_TEXT", "NAV", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.714, 1.226}, nil, nil, nil, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_AP_NAV"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

-- AP LOC
object = addStrokeText("ADHSI_LOC_TEXT", "LOC", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.714, 1.226}, nil, nil, nil, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_AP_LOC"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

-- AP GS
object = addStrokeText("ADHSI_GS_TEXT", "GS", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.715, 1.226}, nil, nil, nil, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_AP_GS"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

-- AP BCN
object = addStrokeText("ADHSI_BCN_TEXT", "BCN", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.785, 0.251})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_BCN"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

object = addStrokeCircle("ADHSI_BCN_CIRCLE",0.05 , {-0.62, 0.245})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_BCN"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

object = addStrokeText("ADHSI_BCN_CIRCLE_H_TEXT", "H", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.62, 0.245})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_BCN_H"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

object = addStrokeText("ADHSI_BCN_CIRCLE_L_TEXT", "L", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.62, 0.245})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_BCN_L"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}

local AD_origin = addPlaceholder(nil, {-0.02, 0.7})
addAttitudeIndicator(AD_origin.name)

------------------- HSI
stroke_thickness  = 0.25 --0.25
stroke_fuzziness  = 0.3
local HSI_radius = 0.445
local HSI_tick_lenght = 0.035

local HSI_full = addPlaceholder(nil, {0, 0})
HSI_full.element_params = {"CMFD"..CMFDNu.."FULL"}
HSI_full.controllers = {{"parameter_compare_with_number",0,1}}

local HSI_Origin = addPlaceholder("HSI_Origin", {-0.0026, -0.61}, HSI_full.name)
local HSI_Origin_Rot = addPlaceholder("HSI_Origin_Rot", {0,0}, HSI_Origin.name)
HSI_Origin_Rot.element_params = {"AVIONICS_HDG"}
HSI_Origin_Rot.controllers = {{"rotate_using_parameter", 0, math.rad(1)}}

for i = 0, 350, 10 do
    if i % 30 ~= 0 then
        object = addStrokeLine("HSI_tick_"..i, HSI_tick_lenght, {HSI_radius * math.sin(math.rad(i)), HSI_radius * math.cos(math.rad(i))}, -i, HSI_Origin_Rot.name, nil, nil, nil, nil, "CMFD_IND_WHITE")
    else
        local text
        if i == 0 then text = "N"
        elseif i == 90 then text = "E"
        elseif i == 180 then text = "S"
        elseif i == 270 then text = "W"
        else text = string.format("%02.0f", i/10)
        end
        object = addStrokeText("HSI_text_"..i, text, CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {(HSI_radius+HSI_tick_lenght/2) * math.sin(math.rad(i)), (HSI_radius+HSI_tick_lenght/2) * math.cos(math.rad(i))}, HSI_Origin_Rot.name, nil, {"%s"},CMFD_FONT_W)
        object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_HDG"}
        object.controllers = {{"opacity_using_parameter", 0}, {"rotate_using_parameter", 1, -math.rad(1)}}
    end
end

stroke_thickness  = 0.5 --0.25
stroke_fuzziness  = 0.6


-- DTK
object = addStrokeText("HSI_DTK_text", "DTK\n270`\n27.5", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.892,-0.95}, HSI_full.name, nil, {"DTK\n%03.0f`\n", "%2.1f"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_DTK_HDG", "ADHSI_DTK_DIST"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range",1 , -0.05, 360.05}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}}

object = addStrokeText("HSI_NODTK_text", "DTK\nXXX`\nX.X", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.892,-0.95}, HSI_full.name)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_DTK_HDG", "ADHSI_DTK_DIST"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, -1} }

object = addStrokeBox("HSI_DTK_box", 0.1755, 0.1855, "CenterCenter", {0.892,-0.95}, HSI_full.name)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_DTK"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}


-- RAD SEL
object = addOSSText(23, "RAD",HSI_full.name, nil, nil, {"RAD\n%2.0f"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_RAD_SEL"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

-- HDG SEL
object = addOSSText(12, "HDG",HSI_full.name, nil, nil, {"\n\n\n\n\nHDG\n%03.0f"})
object.material = CMFD_FONT_CYAN
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_HDG_SEL"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

stroke_thickness  = 1.5 --0.25
stroke_fuzziness  = 0
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "arrow-cw"}, "RightCenter", {0, 0}, object.name, nil, 0.006, CMFD_MATERIAL_CYAN)
object.additive_alpha = false
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "arrow-cw"}, "LeftCenter", {0, -0.26}, object.name, nil, 0.006, CMFD_MATERIAL_CYAN)
object.additive_alpha = false
object.init_rot = {180}


stroke_thickness  = 1.5 --0.25
stroke_fuzziness  = 0.6
local HSI_HDG_SEL_Origin = addPlaceholder("HSI_HDG_SEL_Origin", {0,0}, HSI_Origin_Rot.name)
HSI_HDG_SEL_Origin.element_params = {"ADHSI_HDG_SEL"}
HSI_HDG_SEL_Origin.controllers = {{"rotate_using_parameter", 0, -math.rad(1)}}
object = addStrokeBox("HSI_HDG_SEL_box", 0.06, 0.045, "CenterCenter", {0,HSI_radius + 3* HSI_tick_lenght}, HSI_HDG_SEL_Origin.name, nil, "CMFD_IND_CYAN")
object = addStrokeLine("HSI_HDG_SEL_line", 0.045, {0, -0.0225} , 0 , object.name, nil, nil, nil, nil, "CMFD_IND_CYAN")

object = addStrokeText("ADHSI_NO_SIGNAL", "NO SIGNAL", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, -0.61}, HSI_full.name, nil, nil, CMFD_FONT_R)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_SOURCE_VALID"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 0}}

-- VOR Arrow
stroke_thickness  = 1.5 --0.25
stroke_fuzziness  = 0.6
local HSI_VOR_Origin = addPlaceholder("HSI_VOR_Origin", {0,0}, HSI_Origin_Rot.name)
HSI_VOR_Origin.element_params = {"ADHSI_VOR_HDG", "ADHSI_VOR_VALID", "AVIONICS_ANS_MODE"}
HSI_VOR_Origin.controllers = {{"rotate_using_parameter", 0, -math.rad(1)}, {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, AVIONICS_ANS_MODE_IDS.VOR}}
object = addStrokeBox("HSI_VOR_box", 0.02, 0.04, "CenterCenter", {0,-HSI_radius + 2* HSI_tick_lenght}, HSI_VOR_Origin.name, nil, CMFD_MATERIAL_GREEN)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeBox("HSI_VOR_box1", 0.03, 0.03, "CenterCenter", {0,HSI_radius - 2* HSI_tick_lenght}, HSI_VOR_Origin.name, nil, CMFD_MATERIAL_GREEN)
object.init_rot = {45}
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}

-- VOR No Signal
local HSI_VOR_RED_Origin = addPlaceholder("HSI_VOR_RED_Origin", {0,0}, HSI_Origin.name)
HSI_VOR_RED_Origin.element_params = {"ADHSI_VOR_VALID", "AVIONICS_ANS_MODE"}
HSI_VOR_RED_Origin.controllers = {{"parameter_compare_with_number", 0, 0}, {"parameter_compare_with_number", 1, AVIONICS_ANS_MODE_IDS.VOR}}
HSI_VOR_RED_Origin.init_rot = {-90}
object = addStrokeBox("HSI_VOR_RED_box", 0.02, 0.04, "CenterCenter", {0,-HSI_radius + 2* HSI_tick_lenght}, HSI_VOR_RED_Origin.name, nil, "CMFD_IND_RED")
object = addStrokeBox("HSI_VOR_RED_box1", 0.03, 0.03, "CenterCenter", {0,HSI_radius - 2* HSI_tick_lenght}, HSI_VOR_RED_Origin.name, nil,  "CMFD_IND_RED")
object.init_rot = {45}


-- VOR DATA Indicator: DME and TTG are shown only when the selected station
-- explicitly advertises them.
object = addStrokeText("HSI_VOR_DME_DATA_text", "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.6, -0.086}, nil, nil, {"VOR\n", "%03.0f`\n", "%2.1f\n", "%02.0f:", "%02.0f"}, CMFD_FONT_G)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_VOR_VALID", "ADHSI_VOR_DME_VALID", "ADHSI_VOR_TTG_VALID", "ADHSI_VOR_HDG", "ADHSI_VOR_DIST", "ADHSI_VOR_MIN", "ADHSI_VOR_SEC", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, 1}, {"parameter_compare_with_number", 3, 1}, {"text_using_parameter", 4, 0}, {"text_using_parameter", 4, 1}, {"text_using_parameter", 5, 2}, {"text_using_parameter", 6, 3}, {"text_using_parameter", 7, 4}, {"parameter_compare_with_number", 8, AVIONICS_ANS_MODE_IDS.VOR}}

object = addStrokeText("HSI_VOR_DME_NO_TTG_text", "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.6, -0.086}, nil, nil, {"VOR\n", "%03.0f`\n", "%2.1f\nXX:XX"}, CMFD_FONT_G)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_VOR_VALID", "ADHSI_VOR_DME_VALID", "ADHSI_VOR_TTG_VALID", "ADHSI_VOR_HDG", "ADHSI_VOR_DIST", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, 1}, {"parameter_compare_with_number", 3, 0}, {"text_using_parameter", 4, 0}, {"text_using_parameter", 4, 1}, {"text_using_parameter", 5, 2}, {"parameter_compare_with_number", 6, AVIONICS_ANS_MODE_IDS.VOR}}

object = addStrokeText("HSI_VOR_NO_DME_text", "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.6, -0.086}, nil, nil, {"VOR\n", "%03.0f`"}, CMFD_FONT_G)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_VOR_VALID", "ADHSI_VOR_DME_VALID", "ADHSI_VOR_HDG", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, 0}, {"text_using_parameter", 3, 0}, {"text_using_parameter", 3, 1}, {"parameter_compare_with_number", 4, AVIONICS_ANS_MODE_IDS.VOR}}

-- GPS Arrow
stroke_thickness  = 1.5 --0.25
stroke_fuzziness  = 0.6
local HSI_GPS_Origin = addPlaceholder("HSI_GPS_Origin", {0,0}, HSI_Origin_Rot.name)
HSI_GPS_Origin.element_params = {"ADHSI_GPS_HDG", "ADHSI_GPS_VALID", "AVIONICS_ANS_MODE"}
HSI_GPS_Origin.controllers = {{"rotate_using_parameter", 0, -math.rad(1)}, {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, AVIONICS_ANS_MODE_IDS.GPS}}
object = addStrokeBox("HSI_GPS_box", 0.02, 0.04, "CenterCenter", {0,-HSI_radius + 2* HSI_tick_lenght}, HSI_GPS_Origin.name, nil, "CMFD_IND_BLUE")
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeBox("HSI_GPS_box1", 0.03, 0.03, "CenterCenter", {0,HSI_radius - 2* HSI_tick_lenght}, HSI_GPS_Origin.name, nil, "CMFD_IND_BLUE")
object.init_rot = {45}
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}

-- GPS DATA Indicator
object = addStrokeText("HSI_GPS_DATA_text", "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.6, -0.086}, nil, nil, {"GPS\n", "%03.0f`\n", "%2.1f\n", "%02.0f:", "%02.0f"}, CMFD_FONT_B)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_GPS_VALID", "ADHSI_GPS_HDG", "ADHSI_GPS_DIST", "ADHSI_GPS_MIN", "ADHSI_GPS_SEC", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"text_using_parameter", 2, 0}, {"text_using_parameter", 2, 1}, {"text_using_parameter", 3, 2}, {"text_using_parameter", 4, 3}, {"text_using_parameter", 5, 4}, {"parameter_compare_with_number", 6, AVIONICS_ANS_MODE_IDS.GPS}}
object = addStrokeText("HSI_GPS_NOATA_text", "GPS\nXXX`\nX.XX\nXX:XX", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.6, -0.086}, nil, nil, nil, CMFD_FONT_B)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_GPS_VALID", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 0}, {"parameter_compare_with_number", 2, AVIONICS_ANS_MODE_IDS.GPS}}


-- COURSE BOX
object = addOSSText(22, "CRS",HSI_full.name, nil, nil, {"\n\n\n\nCRS\n%03.0f"})
object.material = CMFD_FONT_Y
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_COURSE_ACTIVE", "ADHSI_SOURCE_VALID"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_compare_with_number", 2, 1}}
stroke_fuzziness  = 0
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "arrow-cw"}, "LeftCenter", {0, 0}, object.name, nil, 0.006, CMFD_MATERIAL_YELLOW)
object.additive_alpha = false
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "arrow-cw"}, "RightCenter", {0, -0.22}, object.name, nil, 0.006, CMFD_MATERIAL_YELLOW)
object.additive_alpha = false
object.init_rot = {180}


-- COURSE Arrouw
stroke_thickness  = 1.5 --0.25
stroke_fuzziness  = 0.6
local HSI_COURSE_Origin = addPlaceholder("HSI_COURSE_Origin", {0,0}, HSI_Origin_Rot.name)
HSI_COURSE_Origin.element_params = {"ADHSI_COURSE_ACTIVE", "ADHSI_SOURCE_VALID"}
HSI_COURSE_Origin.controllers = {{"rotate_using_parameter", 0, -math.rad(1)}, {"parameter_compare_with_number", 1, 1}}
object = addFillBox("HSI_COURSE_box", 0.02, 0.12, "CenterCenter", {0,-0.37}, HSI_COURSE_Origin.name, nil, CMFD_MATERIAL_YELLOW)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"change_color_when_parameter_equal_to_number", 1, AVIONICS_ANS_MODE_IDS.EGI, 1,0,1}, {"change_color_when_parameter_equal_to_number", 1, AVIONICS_ANS_MODE_IDS.VOR, 0,1,0}, {"change_color_when_parameter_equal_to_number", 1, AVIONICS_ANS_MODE_IDS.GPS, 0,0,1}, {"change_color_when_parameter_equal_to_number", 1, AVIONICS_ANS_MODE_IDS.ILS, 1,1,1}}
object = addFillBox("HSI_COURSE_box_1", 0.02, 0.12, "CenterCenter", {0,0.37}, HSI_COURSE_Origin.name, nil, CMFD_MATERIAL_YELLOW)
object.vertices = {{0,0.06}, {0.03, 0.01}, {0.01, 0.018}, {0.01,-0.06}, {-0.01, -0.06}, {-0.01, 0.018}, {-0.03, 0.01}}
object.indices = {0, 1, 2,  0, 2, 3,  0, 3, 4,  0,4,5, 0,5,6}
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"change_color_when_parameter_equal_to_number", 1, AVIONICS_ANS_MODE_IDS.EGI, 1,0,1}, {"change_color_when_parameter_equal_to_number", 1, AVIONICS_ANS_MODE_IDS.VOR, 0,1,0}, {"change_color_when_parameter_equal_to_number", 1, AVIONICS_ANS_MODE_IDS.GPS, 0,0,1}, {"change_color_when_parameter_equal_to_number", 1, AVIONICS_ANS_MODE_IDS.ILS, 1,1,1}}
object = addFillBox("HSI_COURSE_TO_arrow", 0.02, 0.12, "CenterCenter", {0,0.2}, HSI_COURSE_Origin.name, nil, CMFD_MATERIAL_YELLOW)
object.vertices = {{0,0.06}, {0.03, -0.07}, {-0.03, -0.07}}
object.indices = {0, 1, 2}
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_TO_FROM"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}
object = addFillBox("HSI_COURSE_FROM_arrow", 0.02, 0.12, "CenterCenter", {0,-0.2}, HSI_COURSE_Origin.name, nil, CMFD_MATERIAL_YELLOW)
object.vertices = {{0,0.06}, {0.03, -0.07}, {-0.03, -0.07}}
object.indices = {0, 1, 2}
object.init_rot = {180}
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_TO_FROM"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 2}}
-- CDI
object = addFillBox("HSI_CDI_box", 0.02, 0.6, "CenterCenter", {0,0}, HSI_COURSE_Origin.name, nil, CMFD_MATERIAL_YELLOW)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_CDI_SHOW", "ADHSI_CDI", "AVIONICS_ANS_MODE", "ADHSI_CDI_VALID"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 4, 1}, {"move_left_right_using_parameter", 2, 0.18},
                        {"change_color_when_parameter_equal_to_number", 3, AVIONICS_ANS_MODE_IDS.EGI, 1,0,1},
                        {"change_color_when_parameter_equal_to_number", 3, AVIONICS_ANS_MODE_IDS.VOR, 0,1,0},
                        {"change_color_when_parameter_equal_to_number", 3, AVIONICS_ANS_MODE_IDS.GPS, 0,0,1},
                                {"change_color_when_parameter_equal_to_number", 3, AVIONICS_ANS_MODE_IDS.ILS, 1,1,1},
                     }

stroke_thickness  = 0.5 --0.25
stroke_fuzziness  = 0.6

object = addOSSText(11, "CDI", HSI_full.name)
object = addOSSStrokeBox(11, 1, object.name, nil, nil, nil, 3)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_CDI_SHOW"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}


-- FYT DTK Arrow
stroke_thickness  = 1.5 --0.25
stroke_fuzziness  = 0.6
local HSI_FYT_Origin = addPlaceholder(nil, {0,0}, HSI_Origin_Rot.name)
HSI_FYT_Origin.element_params = {"CMFD_NAV_FYT_VALID", "CMFD_NAV_FYT_DTK_BRG", "AVIONICS_ANS_MODE", "ADHSI_EGI_VALID"}
HSI_FYT_Origin.controllers = {{"rotate_using_parameter", 1, -math.rad(1)}, {"parameter_compare_with_number", 0, 1}, {"parameter_compare_with_number", 2, AVIONICS_ANS_MODE_IDS.EGI}, {"parameter_compare_with_number", 3, 1}}
object = addStrokeBox(nil, 0.03, 0.05, "CenterCenter", {0,-HSI_radius - 2.3* HSI_tick_lenght}, HSI_FYT_Origin.name, nil, "CMFD_IND_MAGENTA")
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeBox(nil, 0.02, 0.12, "CenterCenter", {0,HSI_radius + 2.3* HSI_tick_lenght}, HSI_FYT_Origin.name, nil, "CMFD_IND_MAGENTA")
object.vertices = {{0,0.07}, {0.035, 0.02}, {0.015, 0.02}, {0.015,0}, {-0.015, 0}, {-0.015, 0.02}, {-0.035, 0.02}}
object.indices = {0,1, 1,2, 2,3, 3,4, 4,5, 5,6, 6,0}
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}

-- FYT Point

-- Outer purple circle outline
object = addStrokeCircle(nil, 0.03, {0,0}, HSI_FYT_Origin.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_MAGENTA")
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_FYT_DTK_DIST"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, -0.05, 1.299999}, {"move_up_down_using_parameter", 1, 0.075 * HSI_radius}}
object.thickness = 0.01

-- Inner purple circle fill
object = addMesh(nil, nil, nil, {0,0}, "triangles", HSI_FYT_Origin.name, nil, "CMFD_IND_MAGENTA")
object = SetMeshCircle(object, 0.02, 10)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_FYT_DTK_DIST"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, -0.05, 1.299999}, {"move_up_down_using_parameter", 1, 0.075 * HSI_radius}}

-- No DTK text
object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {0,0}, HSI_FYT_Origin.name, nil, {" %02.0f"}, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT", "CMFD_NAV_FYT_DTK_BRG", "AVIONICS_HDG", "ADHSI_FYT_DTK_DIST", "ADHSI_DTK"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 5, 0}, {"text_using_parameter", 1, 0}, {"move_up_down_using_parameter", 4, 0.075 * HSI_radius}, {"rotate_using_parameter", 2, math.rad(1)}, {"rotate_using_parameter", 3, -math.rad(1)}, }

-- DTK text
object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {0,0}, HSI_FYT_Origin.name, nil, {" D"}, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT", "CMFD_NAV_FYT_DTK_BRG", "AVIONICS_HDG", "ADHSI_FYT_DTK_DIST", "ADHSI_DTK"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 5, 1}, {"text_using_parameter", 1, 0}, {"move_up_down_using_parameter", 4, 0.075 * HSI_radius}, {"rotate_using_parameter", 2, math.rad(1)}, {"rotate_using_parameter", 3, -math.rad(1)}, }

object = addStrokeCircle(nil, 0.02, {0, 1.3 * HSI_radius}, HSI_FYT_Origin.name, nil, nil, 0.5, 0.5, true, "CMFD_IND_MAGENTA")
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_FYT_DTK_DIST"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 1.299999, 10}}
object.thickness = 0.05

-- FYT DATA
object = addStrokeText("HSI_FYT_DTK_text", "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {0.412,-0.086}, nil, nil, {"FT %02.0f\n", "%03.0f`\n", "%2.1f\n", "%02.0f:", "%02.0f"}, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_VALID", "CMFD_NAV_FYT", "CMFD_NAV_FYT_DTK_BRG_TEXT", "CMFD_NAV_FYT_DTK_DIST", "CMFD_NAV_FYT_DTK_MINS", "CMFD_NAV_FYT_DTK_SECS", "ADHSI_DTK", "AVIONICS_ANS_MODE", "ADHSI_EGI_VALID"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 7, 0}, {"parameter_compare_with_number", 8, AVIONICS_ANS_MODE_IDS.EGI}, {"parameter_compare_with_number", 9, 1}, {"text_using_parameter", 2, 0}, {"text_using_parameter", 3, 1}, {"text_using_parameter", 4, 2}, {"text_using_parameter", 5, 3}, {"text_using_parameter", 6, 4}}
object = addStrokeText("HSI_NO_FYT_DTK_text", "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {0.412,-0.086}, nil, nil, {"FT %02.0f\nXXX`\nX.X\nXX:XX"}, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_VALID", "CMFD_NAV_FYT", "ADHSI_DTK", "AVIONICS_ANS_MODE", "ADHSI_EGI_VALID"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 0}, {"parameter_compare_with_number", 3, 0}, {"parameter_compare_with_number", 4, AVIONICS_ANS_MODE_IDS.EGI}, {"parameter_compare_with_number", 5, 1}, {"text_using_parameter", 2, 0}}

-- DTK DATA
object = addStrokeText("HSI_FYT_DTK_text1", "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {0.412,-0.086}, nil, nil, {"D- %02.0f\n","%03.0f`\n", "%2.1f\n", "%02.0f:", "%02.0f"}, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_VALID", "CMFD_NAV_FYT", "CMFD_NAV_FYT_DTK_BRG_TEXT", "CMFD_NAV_FYT_DTK_DIST", "CMFD_NAV_FYT_DTK_MINS", "CMFD_NAV_FYT_DTK_SECS", "ADHSI_DTK", "AVIONICS_ANS_MODE", "ADHSI_EGI_VALID"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 7, 1}, {"parameter_compare_with_number", 8, AVIONICS_ANS_MODE_IDS.EGI}, {"parameter_compare_with_number", 9, 1}, {"text_using_parameter", 2, 0}, {"text_using_parameter", 3, 1}, {"text_using_parameter", 4, 2}, {"text_using_parameter", 5, 3}, {"text_using_parameter", 6, 4}}
object = addStrokeText("HSI_NO_FYT_DTK_text1", "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {0.412,-0.086}, nil, nil, {"D- %02.0f\nXXX`\nX.X\nXX:XX"}, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT_VALID", "CMFD_NAV_FYT", "ADHSI_DTK", "AVIONICS_ANS_MODE", "ADHSI_EGI_VALID"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 0}, {"parameter_compare_with_number", 3, 1}, {"parameter_compare_with_number", 4, AVIONICS_ANS_MODE_IDS.EGI}, {"parameter_compare_with_number", 5, 1}, {"text_using_parameter", 2, 0}}


-- ADF
stroke_thickness  = 1.5 --0.25
stroke_fuzziness  = 0.6
local HSI_ADF_Origin = addPlaceholder("HSI_ADF_Origin", {0,0}, HSI_Origin_Rot.name)
HSI_ADF_Origin.element_params = {"ADHSI_ADF_HDG", "ADHSI_ADF_VALID"}
HSI_ADF_Origin.controllers = {{"rotate_using_parameter", 0, -math.rad(1)}, {"parameter_compare_with_number", 1, 1}}
object = addStrokeBox("HSI_ADF_box", 0.025, 0.045, "CenterCenter", {0,-HSI_radius - 2.3* HSI_tick_lenght}, HSI_ADF_Origin.name, nil, "CMFD_IND_YELLOW")
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeText("HSI_ADF_box_1", "A", CMFD_STRINGDEFS_DEF_X1 , "CenterCenter", {0,HSI_radius + 2.3* HSI_tick_lenght}, HSI_ADF_Origin.name, nil, nil, CMFD_FONT_Y)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}


-- MODE
object = addStrokeText("ADHSI_MODE_EGI_HSI", "EGI", CMFD_STRINGDEFS_DEF_X07, "LeftCenter", {-0.965, -0.155}, nil, nil,{"EGI\n%02.0f"}, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ANS_MODE", "ADHSI_FYT_DTK_NUMBER"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, AVIONICS_ANS_MODE_IDS.EGI}, {"text_using_parameter", 2,0}}
object = addStrokeText("ADHSI_MODE_VOR_HSI", "VOR", CMFD_STRINGDEFS_DEF_X07, "LeftCenter", {-0.965, -0.155}, nil, nil, {"VOR\n%06.2f"}, CMFD_FONT_G)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ANS_MODE", "ADHSI_VOR_FREQ"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, AVIONICS_ANS_MODE_IDS.VOR}, {"text_using_parameter", 2,0}}
object = addStrokeText("ADHSI_MODE_GPS_HSI", "GPS", CMFD_STRINGDEFS_DEF_X07, "LeftCenter", {-0.965, -0.155}, nil, nil,{"GPS\n%s"}, CMFD_FONT_B)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ANS_MODE", "ADHSI_GPS_NAME"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, AVIONICS_ANS_MODE_IDS.GPS}, {"text_using_parameter", 2,0}}
object = addStrokeText("ADHSI_MODE_ILS_HSI", "ILS", CMFD_STRINGDEFS_DEF_X07, "LeftCenter", {-0.965, -0.155}, nil, nil,{"ILS\n%06.2f"}, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_ANS_MODE", "ADHSI_ILS_FREQ"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, AVIONICS_ANS_MODE_IDS.ILS}, {"text_using_parameter", 2,0}}

object = addStrokeText("HSI_ILS_DATA_text", "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.6, -0.086}, nil, nil, {"LOC\n%03.0f`"}, CMFD_FONT_W)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "ADHSI_ILS_VALID", "ADHSI_ILS_COURSE", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"text_using_parameter", 2, 0}, {"parameter_compare_with_number", 3, AVIONICS_ANS_MODE_IDS.ILS}}

object = addStrokeLine(nil, 2, {-1, 0.05}, -90, nil, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)





-- local mesh_poly
-- mesh_poly                   = CreateElement "ceTexPoly"
-- mesh_poly.name              = "adhsi_background" 
-- mesh_poly.parent_element    = page_root.name
-- mesh_poly.init_pos          = { 0, 0}
-- mesh_poly.material          = "cmfd_tex_eicas"
-- mesh_poly.primitivetype     = "triangles"
-- mesh_poly.vertices          = { {-1, aspect}, {1,aspect}, {1,-aspect}, {-1, -aspect }}
-- mesh_poly.indices           = default_box_indices
-- mesh_poly.isvisible         = true
-- mesh_poly.tex_coords 		= {{600/2048,0}, {1200/2048,0},{1200/2048,800/2048},{600/2048,800/2048}}
-- mesh_poly.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
-- mesh_poly.controllers = {{"opacity_using_parameter", 0}}
-- AddElementObject2(mesh_poly)
-- mesh_poly = nil
