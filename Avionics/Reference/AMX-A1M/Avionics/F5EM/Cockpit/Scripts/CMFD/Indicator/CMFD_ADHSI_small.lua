dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/avionics_api.lua")

local scale = 0.75
SetCustomScale(GetScale()*scale)

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."FULL", "CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,0}, {"parameter_compare_with_number", 1, SUB_PAGE_ID.MENU2, 1}}

local object
local AD_origin = addPlaceholder(nil,
	{-0.5/scale, -((aspect-0.45)/2 + 0.3)/scale}, page_root.name)
AD_origin.element_params = {"CMFD"..CMFDNu.."SelLeft"}
AD_origin.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.ADHSI}}
local panel_background = addFillBox(nil, 0.96/scale, (aspect-0.42)/scale,
	"CenterCenter", {0,0}, AD_origin.name, nil, CMFD_MATERIAL_DARK)
panel_background.additive_alpha = false

default_parent = AD_origin.name

object = addAttitudeIndicator(AD_origin.name)
-- VV scale
local vvScale500ftStep		    = 0.05
local vvScaleLongTickLen		= 0.05
local vvScaleShortTickLen		= 0.025
local UnitsPerOneFeetPerMin		= 3 * vvScale500ftStep / 20000 -- don't know why

local VVScale_origin = addPlaceholder(nil, {0.45, 0})

object = addFillArrowBox(nil, 0.064, 0.064, "CenterCenter", {0.07, 0}, VVScale_origin.name, nil, CMFD_MATERIAL_GRND)
object = encapsulateObject(object)
object.element_params = {"ADHSI_VV_LIM"}
object.controllers = {{"move_up_down_using_parameter", 0, UnitsPerOneFeetPerMin}}

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

AD_origin = addPlaceholder(nil, {0.5/scale, -((aspect-0.45)/2 + 0.3)/scale}, page_root.name)
AD_origin.element_params = {"CMFD"..CMFDNu.."SelRight"}
AD_origin.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.ADHSI}}
panel_background = addFillBox(nil, 0.96/scale, (aspect-0.42)/scale,
	"CenterCenter", {0,0}, AD_origin.name, nil, CMFD_MATERIAL_DARK)
panel_background.additive_alpha = false

default_parent = AD_origin.name

object = addAttitudeIndicator(AD_origin.name)
-- VV scale

VVScale_origin = addPlaceholder(nil, {0.45, 0})

object = addFillArrowBox(nil, 0.064, 0.064, "CenterCenter", {0.07, 0}, VVScale_origin.name, nil, CMFD_MATERIAL_GRND)
object = encapsulateObject(object)
object.element_params = {"ADHSI_VV_LIM"}
object.controllers = {{"move_up_down_using_parameter", 0, UnitsPerOneFeetPerMin}}

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
