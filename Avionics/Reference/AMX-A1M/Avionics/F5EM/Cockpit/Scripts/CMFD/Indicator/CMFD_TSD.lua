dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/avionics_api.lua")

local CMFDNumber=get_param_handle("CMFDNumber")
local CMFDNu = CMFDNumber:get()

DEFAULT_LEVEL = 9
default_material = CMFD_FONT_DEF
stroke_font			= "cmfd_font_def"
stroke_material		= "HUD"
stroke_thickness  = 1 --0.25
stroke_fuzziness  = 0.6
additive_alpha		= true
default_element_params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}
default_controllers={{"opacity_using_parameter", 0}}

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_in_range", 0, SUB_PAGE_ID.TSD - 0.05, SUB_PAGE_ID.TSD + 0.05}}
default_parent      = page_root.name


local aspect = GetAspect()

local object

local CMFD_HSD_origin = addPlaceholder(nil, {0,0}, page_root.name)
local HSD_DIVIDER_Y = -0.34
local HSD_CLIP_BOTTOM = HSD_DIVIDER_Y + 0.01
local HSD_CLIP_TOP = 0.89

local function tactical_clip(name, relation)
    local mask = addFillBox(name, 1.64, HSD_CLIP_TOP - HSD_CLIP_BOTTOM,
        "CenterCenter", {0, (HSD_CLIP_TOP + HSD_CLIP_BOTTOM) / 2}, page_root.name,
        nil, CMFD_MATERIAL_WHITE)
    mask.isvisible = false
    mask.additive_alpha = false
    mask.h_clip_relation = relation
    mask.level = CMFD_DEFAULT_LEVEL
    return mask
end

tactical_clip("TSD_TACTICAL_CLIP", h_clip_relations.INCREASE_IF_LEVEL)
DEFAULT_LEVEL = CMFD_DEFAULT_LEVEL + 1

------------------- HSI
stroke_thickness  = 0.25 --0.25
stroke_fuzziness  = 0.3
local HSI_radius = 0.43
local HSI_tick_lenght = 0.035
local HSI_outer_radius = HSI_radius + 2.3 * HSI_tick_lenght + 0.07

local HSI_Origin = addPlaceholder("TSD_HSI_Origin", {0, HSD_DIVIDER_Y + HSI_outer_radius + 0.02})
local HSI_Origin_Rot = addPlaceholder("TSD_HSI_Origin_Rot", {0,0}, HSI_Origin.name)
HSI_Origin_Rot.element_params = {"AVIONICS_HDG"}
HSI_Origin_Rot.controllers = {{"rotate_using_parameter", 0, math.rad(1)}}

-- Ownship remains fixed while the heading-up tactical picture rotates.
local HSD_OWN_SHIP = addPlaceholder("HSD_OWN_SHIP", {0, 0}, HSI_Origin.name)
addStrokeLine(nil, 0.075, {-0.0375, -0.025}, 27, HSD_OWN_SHIP.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.075, { 0.0375, -0.025}, -27, HSD_OWN_SHIP.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.060, {0, -0.025}, 180, HSD_OWN_SHIP.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.055, {-0.0275, 0.010}, -90, HSD_OWN_SHIP.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)

local HSD_RDR_CONE = addPlaceholder("HSD_RDR_CONE", {0, 0}, HSI_Origin.name)
HSD_RDR_CONE.element_params = {"RDR_POWER", "RDR_OPR", "RDR_AA_AG"}
HSD_RDR_CONE.controllers = {
    {"parameter_in_range", 0, 0.95, 1.05},
    {"parameter_in_range", 1, 0.95, 1.05},
    {"parameter_in_range", 2, -0.05, 0.05},
}
local function addRadarConeBoundary(name, parameter)
    local boundary = addPlaceholder(name, {0, 0}, HSD_RDR_CONE.name)
    boundary.element_params = {parameter, "RDR_HSD_RANGE_SCALE"}
    boundary.controllers = {
        {"rotate_using_parameter", 0, math.rad(1)},
        {"scale_using_parameter", 1, 1, 1},
    }
    addStrokeLine(nil, HSI_radius, {0, 0}, 0, boundary.name,
        nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
end
addRadarConeBoundary("HSD_RDR_CONE_LEFT", "RDR_SCAN_LEFT_DEG")
addRadarConeBoundary("HSD_RDR_CONE_RIGHT", "RDR_SCAN_RIGHT_DEG")

for i = 0, 350, 10 do
    if i % 30 ~= 0 then
        object = addStrokeLine("TSD_HSI_tick_"..i, HSI_tick_lenght, {HSI_radius * math.sin(math.rad(i)), HSI_radius * math.cos(math.rad(i))}, -i, HSI_Origin_Rot.name, nil, nil, nil, nil, "CMFD_IND_WHITE")
    else
        local text
        if i == 0 then text = "N"
        elseif i == 90 then text = "E"
        elseif i == 180 then text = "S"
        elseif i == 270 then text = "W"
        else text = string.format("%02.0f", i/10)
        end
        object = addStrokeText("TSD_HSI_text_"..i, text, CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {(HSI_radius+HSI_tick_lenght/2) * math.sin(math.rad(i)), (HSI_radius+HSI_tick_lenght/2) * math.cos(math.rad(i))}, HSI_Origin_Rot.name, nil, {"%s"},CMFD_FONT_W)
        object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVIONICS_HDG"}
        object.controllers = {{"opacity_using_parameter", 0}, {"rotate_using_parameter", 1, -math.rad(1)}}
    end
end

-- GPS Arrow
stroke_thickness  = 1.5 --0.25
stroke_fuzziness  = 0.6
local HSI_GPS_Origin = addPlaceholder("TSD_HSI_GPS_Origin", {0,0}, HSI_Origin_Rot.name)
HSI_GPS_Origin.element_params = {"ADHSI_GPS_HDG", "AVIONICS_ANS_MODE"}
HSI_GPS_Origin.controllers = {{"rotate_using_parameter", 0, -math.rad(1)}, {"parameter_in_range",0 , -0.05, 360.05}, {"parameter_compare_with_number", 1, AVIONICS_ANS_MODE_IDS.GPS}}
object = addStrokeBox("TSD_HSI_GPS_box", 0.02, 0.04, "CenterCenter", {0,-HSI_radius + 2* HSI_tick_lenght}, HSI_GPS_Origin.name, nil, "CMFD_IND_BLUE")
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeBox("TSD_HSI_GPS_box1", 0.03, 0.03, "CenterCenter", {0,HSI_radius - 2* HSI_tick_lenght}, HSI_GPS_Origin.name, nil, "CMFD_IND_BLUE")
object.init_rot = {45}
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}

-- GPS DATA Indicator
object = addStrokeText("TSD_HSI_GPS_DATA_text", "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.6, -0.086}, nil, nil, {"GPS\n", "%03.0f`\n", "%2.1f\n", "%02.0f:", "%02.0f"}, CMFD_FONT_B)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT",  "ADHSI_GPS_HDG", "ADHSI_GPS_DIST", "ADHSI_GPS_MIN", "ADHSI_GPS_SEC", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, -0.05, 360.05}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 1, 1}, {"text_using_parameter", 2, 2}, {"text_using_parameter", 3, 3}, {"text_using_parameter", 4, 4}, {"parameter_compare_with_number", 5, AVIONICS_ANS_MODE_IDS.GPS}}
object = addStrokeText("TSD_HSI_GPS_NOATA_text", "GPS\nXXX`\nX.XX\nXX:XX", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {-0.6, -0.086}, nil, nil, nil, CMFD_FONT_B)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT",  "ADHSI_GPS_HDG", "ADHSI_GPS_DIST", "ADHSI_GPS_MIN", "ADHSI_GPS_SEC", "AVIONICS_ANS_MODE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, -1}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 1, 1}, {"text_using_parameter", 2, 2}, {"text_using_parameter", 3, 3}, {"text_using_parameter", 4, 4}, {"parameter_compare_with_number", 5, AVIONICS_ANS_MODE_IDS.GPS}}

stroke_thickness  = 0.5 --0.25
stroke_fuzziness  = 0.6

-- FYT DTK Arrow
stroke_thickness  = 1.5 --0.25
stroke_fuzziness  = 0.6
local HSI_FYT_Origin = addPlaceholder(nil, {0,0}, HSI_Origin_Rot.name)
HSI_FYT_Origin.element_params = {"CMFD_NAV_FYT_VALID", "CMFD_NAV_FYT_DTK_BRG", "AVIONICS_ANS_MODE"}
HSI_FYT_Origin.controllers = {{"rotate_using_parameter", 1, -math.rad(1)}, {"parameter_compare_with_number", 0, 1}, {"parameter_in_range", 2, AVIONICS_ANS_MODE_IDS.EGI-0.05, AVIONICS_ANS_MODE_IDS.GPS + 0.05}}
object = addStrokeBox(nil, 0.03, 0.05, "CenterCenter", {0,-HSI_radius - 2.3* HSI_tick_lenght}, HSI_FYT_Origin.name, nil, "CMFD_IND_MAGENTA")
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeBox(nil, 0.02, 0.12, "CenterCenter", {0,HSI_radius + 2.3* HSI_tick_lenght}, HSI_FYT_Origin.name, nil, "CMFD_IND_MAGENTA")
object.vertices = {{0,0.07}, {0.035, 0.02}, {0.015, 0.02}, {0.015,0}, {-0.015, 0}, {-0.015, 0.02}, {-0.035, 0.02}}
object.indices = {0,1, 1,2, 2,3, 3,4, 4,5, 5,6, 6,0}
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}

-- FYT Point

--[[-- This is the FYT circle
object = addMesh(nil, nil, nil, {0,0}, "triangles", HSI_FYT_Origin.name, nil, "CMFD_IND_MAGENTA")
object = SetMeshCircle(object, 0.02, 10)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_HSD_FYT_DTK_DIST"}
object.controllers = {{"opacity_using_parameter", 0}, {"move_up_down_using_parameter", 1, HSI_radius}}

-- This is the FYT text
object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {0,0}, HSI_FYT_Origin.name, nil, {" %02.0f"}, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_NAV_FYT", "CMFD_NAV_FYT_DTK_BRG", "AVIONICS_HDG", "CMFD_HSD_FYT_DTK_DIST"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"move_up_down_using_parameter", 4, HSI_radius}, {"rotate_using_parameter", 2, math.rad(1)}, {"rotate_using_parameter", 3, -math.rad(1)}, }]]

-- Waypoints
for k=1,100 do
    -- Outer purple circle outline dashed
    object = addStrokeCircle(nil, 0.03, {0,0}, HSI_Origin_Rot.name, nil, nil, 0.5, 0.5, true, "CMFD_IND_MAGENTA")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_HSD_DTK" .. k .. "_DIST", "CMFD_HSD_DTK" .. k .. "_BRG", "CMFD_HSD_DTK" .. k}
    object.controllers = {{"opacity_using_parameter", 0}, {"rotate_using_parameter", 2, -math.rad(1)}, {"move_up_down_using_parameter", 1, HSI_radius}, {"parameter_in_range",1,0.01,1.05}, {"parameter_compare_with_number", 3, 1}}
    object.thickness = 0.05

    -- Outer purple circle outline
    object = addStrokeCircle(nil, 0.03, {0,0}, HSI_Origin_Rot.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_MAGENTA")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_HSD_WP" .. k .. "_DIST", "CMFD_HSD_WP" .. k .. "_BRG"}
    object.controllers = {{"opacity_using_parameter", 0}, {"rotate_using_parameter", 2, -math.rad(1)}, {"move_up_down_using_parameter", 1, HSI_radius}, {"parameter_in_range",1,0.01,1.05}}
    object.thickness = 0.01

    -- Inner purple circle fill
    object = addMesh(nil, nil, nil, {0,0}, "triangles", HSI_Origin_Rot.name, nil, "CMFD_IND_MAGENTA")
    object = SetMeshCircle(object, 0.02, 10)
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_HSD_WP" .. k .. "_DIST", "CMFD_HSD_WP" .. k .. "_BRG", "CMFD_NAV_FYT"}
    object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 3, k-1}, {"rotate_using_parameter", 2, -math.rad(1)}, {"move_up_down_using_parameter", 1, HSI_radius}, {"parameter_in_range",1,0.01,1.05}}

    object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X08, "LeftCenter", {0,0}, HSI_Origin_Rot.name, nil, {" %02.0f"}, CMFD_FONT_MAGENTA)
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_HSD_WP" .. k .. "_DIST", "CMFD_HSD_WP" .. k .. "_BRG", "CMFD_HSD_WP" .. k .. "_ID", "AVIONICS_HDG"}
    object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 3, 0}, {"parameter_in_range",1,0.01,1.05}, {"rotate_using_parameter", 2, -math.rad(1)}, {"move_up_down_using_parameter", 1, HSI_radius}, {"rotate_using_parameter", 2, math.rad(1)}, {"rotate_using_parameter", 4, -math.rad(1)}}
end

-- [Fase 14b] Marcadores das areas taticas do DTC, posicionados em polar
-- (BRG/DIST) como os waypoints. Sem linhas de conexao (so os pontos):
-- avoid zones = vermelho, contact line (FLOT) = amarelo, flight area = verde.
for k = 1, 10 do
    object = addStrokeCircle(nil, 0.035, {0,0}, HSI_Origin_Rot.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_RED")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_HSD_AVD" .. k .. "_DIST", "CMFD_HSD_AVD" .. k .. "_BRG"}
    object.controllers = {{"opacity_using_parameter", 0}, {"rotate_using_parameter", 2, -math.rad(1)}, {"move_up_down_using_parameter", 1, HSI_radius}, {"parameter_in_range",1,0.01,1.05}}
    object.thickness = 0.02
end
for k = 1, 10 do
    object = addStrokeCircle(nil, 0.02, {0,0}, HSI_Origin_Rot.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_YELLOW")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_HSD_CNT" .. k .. "_DIST", "CMFD_HSD_CNT" .. k .. "_BRG"}
    object.controllers = {{"opacity_using_parameter", 0}, {"rotate_using_parameter", 2, -math.rad(1)}, {"move_up_down_using_parameter", 1, HSI_radius}, {"parameter_in_range",1,0.01,1.05}}
    object.thickness = 0.01
end
for k = 1, 12 do
    object = addStrokeCircle(nil, 0.02, {0,0}, HSI_Origin_Rot.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_GREEN")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_HSD_FLT" .. k .. "_DIST", "CMFD_HSD_FLT" .. k .. "_BRG"}
    object.controllers = {{"opacity_using_parameter", 0}, {"rotate_using_parameter", 2, -math.rad(1)}, {"move_up_down_using_parameter", 1, HSI_radius}, {"parameter_in_range",1,0.01,1.05}}
    object.thickness = 0.01
end

-- [Fase 3] Datalink Link-BR2 tracks (ate 8): triangulo cyan na HSI,
-- visivel se DL_TRACK_NN_VALID = 1. Posicao polar (BRG/DIST) ja em
-- "fracao da escala" (igual aos waypoints).
for k = 1, 8 do
    local a = string.format("%02d", k)
    local track = addPlaceholder(nil, {0,0}, HSI_Origin_Rot.name)
    track.element_params = {
        "CMFD"..tostring(CMFDNu).."_BRIGHT",
        "DL_TRACK_"..a.."_DIST",
        "DL_TRACK_"..a.."_BRG",
        "DL_TRACK_"..a.."_VALID",
    }
    track.controllers = {
        {"opacity_using_parameter", 0},
        {"rotate_using_parameter", 2, -math.rad(1)},
        {"move_up_down_using_parameter", 1, HSI_radius},
        {"parameter_in_range", 1, 0.01, 1.05},
        {"parameter_in_range", 3, 0.95, 1.05},
    }

    -- Unknown: yellow square.
    local unknown = addPlaceholder(nil, {0,0}, track.name)
    unknown.element_params = {"DL_TRACK_"..a.."_CLASS"}
    unknown.controllers = {{"parameter_in_range", 0, -0.05, 0.05}}
    addStrokeBox(nil, 0.035, 0.035, "CenterCenter", {0,0}, unknown.name, nil, "CMFD_IND_YELLOW")

    -- Hostile: red diamond.
    local hostile = addPlaceholder(nil, {0,0}, track.name)
    hostile.element_params = {"DL_TRACK_"..a.."_CLASS"}
    hostile.controllers = {{"parameter_in_range", 0, 0.95, 1.05}}
    object = addStrokeBox(nil, 0.036, 0.036, "CenterCenter", {0,0}, hostile.name, nil, "CMFD_IND_RED")
    object.init_rot = {45}

    -- Friendly: cyan circle crossed by a horizontal identity bar.
    local friendly = addPlaceholder(nil, {0,0}, track.name)
    friendly.element_params = {"DL_TRACK_"..a.."_CLASS"}
    friendly.controllers = {{"parameter_in_range", 0, 1.95, 2.05}}
    addStrokeCircle(nil, 0.024, {0,0}, friendly.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_BLUE")
    addStrokeLine(nil, 0.055, {-0.0275, 0}, 90, friendly.name, nil, nil, nil, nil, "CMFD_IND_BLUE")

    -- Keep numeric metadata upright while the track moves around the HSI.
    local data = addPlaceholder(nil, {0,0}, track.name)
    data.element_params = {"DL_TRACK_"..a.."_BRG", "AVIONICS_HDG"}
    data.controllers = {
        {"rotate_using_parameter", 0, math.rad(1)},
        {"rotate_using_parameter", 1, -math.rad(1)},
    }
    object = addStrokeText(nil, "00", CMFD_STRINGDEFS_DEF_X04,
        "LeftCenter", {0.032, 0.015}, data.name, nil, {"#%02.0f"}, CMFD_FONT_W)
    object.element_params = {"DL_TRACK_"..a.."_ID"}
    object.controllers = {{"text_using_parameter", 0, 0}}
    object = addStrokeText(nil, "00", CMFD_STRINGDEFS_DEF_X04,
        "LeftCenter", {0.032, -0.010}, data.name, nil, {"%02.0fK"}, CMFD_FONT_W)
    object.element_params = {"DL_TRACK_"..a.."_ALT_KFT"}
    object.controllers = {{"text_using_parameter", 0, 0}}
    object = addStrokeText(nil, "DL", CMFD_STRINGDEFS_DEF_X04,
        "RightCenter", {-0.032, -0.010}, data.name, nil, nil, CMFD_FONT_CYAN)
    object.element_params = {"DL_TRACK_"..a.."_SOURCE_KIND"}
    object.controllers = {{"parameter_in_range", 0, 0.95, 1.05}}
    object = addStrokeText(nil, "E", CMFD_STRINGDEFS_DEF_X04,
        "RightCenter", {-0.032, -0.010}, data.name, nil, nil, CMFD_FONT_CYAN)
    object.element_params = {"DL_TRACK_"..a.."_SOURCE_KIND"}
    object.controllers = {{"parameter_in_range", 0, 1.95, 2.05}}
end

-- RAP bullseye marker and numeric BRA block.
local bull = addPlaceholder(nil, {0,0}, HSI_Origin_Rot.name)
bull.element_params = {"CMFD_RAP_BULL_DIST", "CMFD_RAP_BULL_BRG", "CMFD_RAP_BULL_VALID"}
bull.controllers = {
    {"rotate_using_parameter", 1, -math.rad(1)},
    {"move_up_down_using_parameter", 0, HSI_radius},
    {"parameter_in_range", 0, 0.01, 1.05},
    {"parameter_in_range", 2, 0.95, 1.05},
}
addStrokeCircle(nil, 0.030, {0,0}, bull.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_MAGENTA")
addStrokeCircle(nil, 0.015, {0,0}, bull.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_MAGENTA")
addStrokeLine(nil, 0.075, {-0.0375, 0}, 90, bull.name, nil, nil, nil, nil, "CMFD_IND_MAGENTA")
addStrokeLine(nil, 0.075, {0, -0.0375}, 0, bull.name, nil, nil, nil, nil, "CMFD_IND_MAGENTA")

object = addStrokeText(nil, "BULL", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {-0.62, 0.55}, page_root.name, nil, nil, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_RAP_BULL_VALID"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}
object = addStrokeText(nil, "000", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {-0.47, 0.55}, page_root.name, nil, {"%03.0f/"}, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_RAP_BULL_VALID", "CMFD_RAP_BULL_BRG_DEG"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}, {"text_using_parameter", 2, 0}}
object = addStrokeText(nil, "00", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {-0.34, 0.55}, page_root.name, nil, {"%02.0f"}, CMFD_FONT_MAGENTA)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "CMFD_RAP_BULL_VALID", "CMFD_RAP_BULL_RNG_NM"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}, {"text_using_parameter", 2, 0}}

-- Threat centers and estimated WEZ rings. Radius is normalized by the
-- selected TSD range in the backend, so the circle scales with zoom.
for i = 1, 8 do
    local threat = addPlaceholder(nil, {0,0}, HSI_Origin_Rot.name)
    threat.element_params = {
        "CMFD_RAP_THREAT_"..i.."_DIST",
        "CMFD_RAP_THREAT_"..i.."_BRG",
        "CMFD_RAP_THREAT_"..i.."_VALID",
    }
    threat.controllers = {
        {"rotate_using_parameter", 1, -math.rad(1)},
        {"move_up_down_using_parameter", 0, HSI_radius},
        {"parameter_in_range", 0, 0.01, 1.05},
        {"parameter_in_range", 2, 0.95, 1.05},
    }
    local wez = addPlaceholder(nil, {0,0}, threat.name)
    wez.element_params = {"CMFD_RAP_THREAT_"..i.."_RADIUS"}
    wez.controllers = {{"scale_using_parameter", 0, HSI_radius / 0.03, 1}}
    addStrokeCircle(nil, 0.030, {0,0}, wez.name, nil, nil, 0.5, 0.5, true, "CMFD_IND_RED")
    addStrokeBox(nil, 0.018, 0.018, "CenterCenter", {0,0}, threat.name, nil, "CMFD_IND_RED")
end

-- Tactical advisories calculated by tactical_overlay.lua.
object = addStrokeText(nil, "BINGO", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.22, 0.63}, page_root.name, nil, nil, CMFD_FONT_R)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "BINGO_ACTIVE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}
object = addStrokeText(nil, "AVOID", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, 0.63}, page_root.name, nil, nil, CMFD_FONT_R)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "AVD_NEAREST_INSIDE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}
object = addStrokeText(nil, "AREA", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.22, 0.63}, page_root.name, nil, nil, CMFD_FONT_Y)
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "FLT_AREA_OUTSIDE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}

-- [Phase R3.7] Stormscope overlay (LCMS): cells projected in BRG/RANGE.
for k = 1, 16 do
    local a = string.format("%02d", k)
    local p_range = "STORMSCOPE_CELL_"..a.."_RANGE"
    local p_brg = "STORMSCOPE_CELL_"..a.."_BEARING"
    local p_int = "STORMSCOPE_CELL_"..a.."_INTENSITY"

    -- Low intensity (white)
    object = addStrokeCircle(nil, 0.015, {0,0}, HSI_Origin_Rot.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_WHITE")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "STORMSCOPE_ENABLED", p_range, p_brg, p_int}
    object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"rotate_using_parameter", 3, -math.rad(1)}, {"move_up_down_using_parameter", 2, HSI_radius}, {"parameter_in_range", 2, 0.01, 1.05}, {"parameter_compare_with_number", 4, 0}}
    object.thickness = 0.01

    -- Medium intensity (yellow)
    object = addStrokeCircle(nil, 0.020, {0,0}, HSI_Origin_Rot.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_YELLOW")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "STORMSCOPE_ENABLED", p_range, p_brg, p_int}
    object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"rotate_using_parameter", 3, -math.rad(1)}, {"move_up_down_using_parameter", 2, HSI_radius}, {"parameter_in_range", 2, 0.01, 1.05}, {"parameter_compare_with_number", 4, 1}}
    object.thickness = 0.012

    -- High intensity (red)
    object = addStrokeCircle(nil, 0.025, {0,0}, HSI_Origin_Rot.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_RED")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "STORMSCOPE_ENABLED", p_range, p_brg, p_int}
    object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"rotate_using_parameter", 3, -math.rad(1)}, {"move_up_down_using_parameter", 2, HSI_radius}, {"parameter_in_range", 2, 0.01, 1.05}, {"parameter_compare_with_number", 4, 2}}
    object.thickness = 0.015

    -- Severe intensity (red ring + cross)
    object = addStrokeCircle(nil, 0.030, {0,0}, HSI_Origin_Rot.name, nil, nil, 0.5, 0.5, true, "CMFD_IND_RED")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "STORMSCOPE_ENABLED", p_range, p_brg, p_int}
    object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"rotate_using_parameter", 3, -math.rad(1)}, {"move_up_down_using_parameter", 2, HSI_radius}, {"parameter_in_range", 2, 0.01, 1.05}, {"parameter_compare_with_number", 4, 3}}
    object.thickness = 0.02

    object = addStrokeLine(nil, 0.040, {0,0}, 0, HSI_Origin_Rot.name, nil, nil, nil, nil, "CMFD_IND_RED")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "STORMSCOPE_ENABLED", p_range, p_brg, p_int}
    object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"rotate_using_parameter", 3, -math.rad(1)}, {"move_up_down_using_parameter", 2, HSI_radius}, {"parameter_in_range", 2, 0.01, 1.05}, {"parameter_compare_with_number", 4, 3}}

    object = addStrokeLine(nil, 0.040, {0,0}, 90, HSI_Origin_Rot.name, nil, nil, nil, nil, "CMFD_IND_RED")
    object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "STORMSCOPE_ENABLED", p_range, p_brg, p_int}
    object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}, {"rotate_using_parameter", 3, -math.rad(1)}, {"move_up_down_using_parameter", 2, HSI_radius}, {"parameter_in_range", 2, 0.01, 1.05}, {"parameter_compare_with_number", 4, 3}}
end

DEFAULT_LEVEL = CMFD_DEFAULT_LEVEL
tactical_clip("TSD_TACTICAL_CLIP_END", h_clip_relations.REWRITE_LEVEL)

object = addStrokeText("TSD_HSI_RAD_SEL_text", "20", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.9, 0.850}, nil, nil, {"%3.0f"})
object.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "HSD_RAD_SEL"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
object = addOSSArrow(28, 1, CMFD_HSD_origin.name)
object = addOSSArrow(27, 0, CMFD_HSD_origin.name)

-- COMBINED STRIP START: fixed HSD + engine/systems/stores format from the
-- operational F-5M glass-cockpit reference.
object = addStrokeLine(nil, 2, {-1, HSD_DIVIDER_Y}, -90, page_root.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
object = addStrokeLine(nil, 0.64, {0.02, -0.98}, 0, page_root.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)

local combined_strip = addPlaceholder("HSD_COMBINED_STRIP", {0, 0}, page_root.name)

local function add_combined_dial(name, label, pos, value_param, angle_param, format, radius)
    radius = radius or 0.105
    local base = addPlaceholder(name, pos, combined_strip.name)
    local ring = addStrokeCircle(nil, radius, {0,0}, base.name, nil, nil, 0.5, 0.5, false, CMFD_MATERIAL_WHITE)
    ring.thickness = 0.012
    for angle = 0, 315, 45 do
        local angle_rad = math.rad(angle)
        local tick_pos = {radius * math.sin(angle_rad), radius * math.cos(angle_rad)}
        addStrokeLine(nil, 0.015, tick_pos, -angle, base.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    end

    local needle = addPlaceholder(nil, {0,0}, base.name)
    needle.init_rot = {-60}
    needle.element_params = {angle_param}
    needle.controllers = {{"rotate_using_parameter", 0, math.rad(-1)}}
    addStrokeLine(nil, radius * 0.72, {0,0}, 0, needle.name, nil, nil, nil, nil, CMFD_MATERIAL_GREEN)
    addStrokeCircle(nil, 0.010, {0,0}, base.name, nil, nil, 0.5, 0.5, false, CMFD_MATERIAL_GREEN)

    local value = addStrokeText(nil, "000", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, -0.035}, base.name, nil, {format}, CMFD_FONT_CYAN)
    value.element_params = {value_param}
    value.controllers = {{"text_using_parameter", 0, 0}}
    addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, radius + 0.025}, base.name, nil, nil, CMFD_FONT_W)
end

add_combined_dial("HSD_RPM_L", "RPM L", {-0.76, -0.53}, "EICAS_E1_ROT", "EICAS_E1_ROT_POS", "%3.0f", 0.105)
add_combined_dial("HSD_RPM_R", "RPM R", {-0.40, -0.53}, "EICAS_E2_ROT", "EICAS_E2_ROT_POS", "%3.0f", 0.105)
add_combined_dial("HSD_EGT_L", "EGT L", {-0.76, -0.84}, "EICAS_E1_TEMP", "EICAS_E1_TEMP_POS", "%4.0f", 0.105)
add_combined_dial("HSD_EGT_R", "EGT R", {-0.40, -0.84}, "EICAS_E2_TEMP", "EICAS_E2_TEMP_POS", "%4.0f", 0.105)

add_combined_dial("HSD_OIL_L", "OIL L", {0.22, -0.53}, "EICAS_E1_OIL_PRES", "EICAS_E1_OIL_PRES_POS", "%3.0f", 0.075)
add_combined_dial("HSD_OIL_R", "OIL R", {0.48, -0.53}, "EICAS_E2_OIL_PRES", "EICAS_E2_OIL_PRES_POS", "%3.0f", 0.075)

local function add_combined_value(label, param, pos, format, font)
    addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X04, "LeftCenter", pos, combined_strip.name, nil, nil, CMFD_FONT_W)
    local value = addStrokeText(nil, "0000", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {pos[1] + 0.36, pos[2]}, combined_strip.name, nil, {format}, font or CMFD_FONT_CYAN)
    value.element_params = {param}
    value.controllers = {{"text_using_parameter", 0, 0}}
end

add_combined_value("FUEL", "EICAS_FUEL", {0.12, -0.68}, "%4.0f", CMFD_FONT_CYAN)
add_combined_value("HYD U", "EICAS_HYD_UTIL", {0.12, -0.74}, "%4.0f", CMFD_FONT_G)
add_combined_value("HYD F", "EICAS_HYD_FLT", {0.12, -0.80}, "%4.0f", CMFD_FONT_G)
add_combined_value("GUN", "WPN_GUNS_L", {0.55, -0.68}, "%3.0f", CMFD_FONT_CYAN)

local station_params = {
    "WPN_POS_1_SEL", "WPN_POS_2_SEL", "WPN_POS_3_SEL", "WPN_POS_4_SEL",
    "WPN_POS_5_SEL", "WPN_POS_6_SEL", "WPN_POS_7_SEL",
}
for i = 1, 7 do
    local x = 0.12 + (i - 1) * 0.125
    local station = addPlaceholder(nil, {x, -0.92}, combined_strip.name)
    addStrokeBox(nil, 0.045, 0.070, "CenterCenter", {0,0}, station.name, nil, CMFD_MATERIAL_WHITE)
    addStrokeText(nil, tostring(i), CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0,0}, station.name, nil, nil, CMFD_FONT_W)

    local selected = addPlaceholder(nil, {0,0}, station.name)
    selected.element_params = {station_params[i]}
    selected.controllers = {{"parameter_in_range", 0, 0.95, 2.05}}
    addStrokeBox(nil, 0.058, 0.083, "CenterCenter", {0,0}, selected.name, nil, CMFD_MATERIAL_CYAN)
end
-- COMBINED STRIP END

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
-- mesh_poly.tex_coords 		= {{600/2048,800/2048}, {1200/2048,800/2048},{1200/2048,1600/2048},{600/2048,1600/2048}}
-- mesh_poly.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT"}
-- mesh_poly.controllers = {{"opacity_using_parameter", 0}}
-- AddElementObject2(mesh_poly)
-- mesh_poly = nil

-- OSS Menus

local HW = 0.15
local HH = 0.04 * H2W_SCALE

local osb_txt = {
    -- {value="MAN",           init_pos={CMFD_FONT_UD1_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0},{"text_using_parameter", 1, 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT","CMFD_DTE_DVR_STATE"}},
    {value=" ",             init_pos={CMFD_FONT_UD2_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="DL\nOFF",        init_pos={CMFD_FONT_UD3_X, H2W_SCALE},                      align="CenterTop",      formats={"DL\n%s"}, controller={{"opacity_using_parameter", 0},{"text_using_parameter", 1, 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT","DL_MODE_STR"}},
    {value=" ",          init_pos={CMFD_FONT_UD4_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="ROUTE\n00-00",           init_pos={CMFD_FONT_UD5_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_UD6_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},

    {value="D\nE\nP",      init_pos={CMFD_FONT_R_HORI_X, ( 5.8*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_R_HORI_X, ( 4.4*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="S\nY\nM",             init_pos={CMFD_FONT_R_HORI_X, ( 2.5*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="A\nN\nM",             init_pos={CMFD_FONT_R_HORI_X, ( 0.9*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="R\nO\nU\nT",          init_pos={CMFD_FONT_R_HORI_X, (-1.2*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="CLR\nSTRM",             init_pos={CMFD_FONT_R_HORI_X, (-2.8*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_R_HORI_X, (-4.5*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="BFI",             init_pos={CMFD_FONT_R_HORI_X, (-6.1*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    
    {value=" ",             init_pos={CMFD_FONT_L_HORI_X, (-6.1*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_L_HORI_X, (-4.5*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_L_HORI_X, (-2.8*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="ALL",           init_pos={CMFD_FONT_L_HORI_X, (-1.2*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="D\nE\nL",           init_pos={CMFD_FONT_L_HORI_X, ( 0.9*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="ADHSI",          init_pos={CMFD_FONT_L_HORI_X, ( 2.5*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",            init_pos={CMFD_FONT_L_HORI_X, ( 4.4*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",           init_pos={CMFD_FONT_L_HORI_X, ( 5.8*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
}

local text_strpoly
local mesh_poly

for i=1, #(osb_txt) do
    text_strpoly                = CreateElement "ceStringPoly"
    text_strpoly.material       = CMFD_FONT_DEF
    text_strpoly.stringdefs     = CMFD_STRINGDEFS_DEF_X08
    text_strpoly.init_pos       = osb_txt[i].init_pos
    text_strpoly.alignment      = osb_txt[i].align
    text_strpoly.formats        = osb_txt[i].formats
    if osb_txt[i].params then
        text_strpoly.element_params = osb_txt[i].params
    end
    if osb_txt[i].controller then
        text_strpoly.controllers    = osb_txt[i].controller
    end
    text_strpoly.name = "osb_txt_" .. i
    if osb_txt[i].value ~= nil then
        text_strpoly.value = osb_txt[i].value
    else
        text_strpoly.value = "OSB" .. i
    end
    text_strpoly.parent_element    = page_root.name
    AddElementObject(text_strpoly)
    text_strpoly = nil
end