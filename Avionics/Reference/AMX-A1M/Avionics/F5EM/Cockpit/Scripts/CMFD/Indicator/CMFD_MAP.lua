dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local CMFDNumber = get_param_handle("CMFDNumber")
local CMFDNu = CMFDNumber:get()
local BRIGHT = "CMFD"..tostring(CMFDNu).."_BRIGHT"

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.MAP}}

addOSSArrow(28, 1, page_root.name)
addOSSArrow(27, 0, page_root.name)

local object = addStrokeText(nil, "VECTOR MAP", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, 0.67}, page_root.name, nil, nil, CMFD_FONT_W)
object.element_params = {BRIGHT}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeText(nil, "20", CMFD_STRINGDEFS_DEF_X08, "RightCenter", {0.72, 0.67}, page_root.name, nil, {"%4.0f NM"}, CMFD_FONT_W)
object.element_params = {BRIGHT, "HSD_RAD_SEL"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

local MAP_RADIUS = 0.58
local map_origin = addPlaceholder(nil, {0, -0.04}, page_root.name)
local map_rot = addPlaceholder(nil, {0, 0}, map_origin.name)
map_rot.element_params = {"AVIONICS_HDG"}
map_rot.controllers = {{"rotate_using_parameter", 0, math.rad(1)}}

for _, radius in ipairs({MAP_RADIUS / 3, 2 * MAP_RADIUS / 3, MAP_RADIUS}) do
    object = addStrokeCircle(nil, radius, {0,0}, map_origin.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_WHITE")
    object.element_params = {BRIGHT}
    object.controllers = {{"opacity_using_parameter", 0}}
    object.thickness = 0.008
end
object = addStrokeLine(nil, 2 * MAP_RADIUS, {-MAP_RADIUS, 0}, 90, map_origin.name, nil, nil, nil, nil, "CMFD_IND_WHITE")
object.element_params = {BRIGHT}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeLine(nil, 2 * MAP_RADIUS, {0, -MAP_RADIUS}, 0, map_origin.name, nil, nil, nil, nil, "CMFD_IND_WHITE")
object.element_params = {BRIGHT}
object.controllers = {{"opacity_using_parameter", 0}}

-- Ownship at map center.
addStrokeLine(nil, 0.09, {-0.045, -0.035}, 27, map_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.09, {0.045, -0.035}, -27, map_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.07, {0, -0.035}, 180, map_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)

-- Route points; labels appear only on the active destination to avoid clutter.
for k = 1, 100 do
    local wp = addPlaceholder(nil, {0,0}, map_rot.name)
    wp.element_params = {"CMFD_HSD_WP"..k.."_DIST", "CMFD_HSD_WP"..k.."_BRG"}
    wp.controllers = {
        {"rotate_using_parameter", 1, -math.rad(1)},
        {"move_up_down_using_parameter", 0, MAP_RADIUS},
        {"parameter_in_range", 0, 0.005, 1.05},
    }
    addStrokeCircle(nil, 0.012, {0,0}, wp.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_MAGENTA")

    local active = addPlaceholder(nil, {0,0}, wp.name)
    active.element_params = {"CMFD_NAV_FYT"}
    active.controllers = {{"parameter_in_range", 0, k - 1.05, k - 0.95}}
    addStrokeCircle(nil, 0.024, {0,0}, active.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_MAGENTA")
    addStrokeText(nil, tostring(k - 1), CMFD_STRINGDEFS_DEF_X04, "LeftCenter", {0.025, 0}, active.name, nil, nil, CMFD_FONT_MAGENTA)
end

-- Datalink tracks use NATO-like identity shapes.
for i = 1, 8 do
    local a = string.format("%02d", i)
    local track = addPlaceholder(nil, {0,0}, map_rot.name)
    track.element_params = {"DL_TRACK_"..a.."_DIST", "DL_TRACK_"..a.."_BRG", "DL_TRACK_"..a.."_VALID"}
    track.controllers = {
        {"rotate_using_parameter", 1, -math.rad(1)},
        {"move_up_down_using_parameter", 0, MAP_RADIUS},
        {"parameter_in_range", 0, 0.005, 1.05},
        {"parameter_in_range", 2, 0.95, 1.05},
    }

    local unknown = addPlaceholder(nil, {0,0}, track.name)
    unknown.element_params = {"DL_TRACK_"..a.."_CLASS"}
    unknown.controllers = {{"parameter_in_range", 0, -0.05, 0.05}}
    addStrokeBox(nil, 0.026, 0.026, "CenterCenter", {0,0}, unknown.name, nil, "CMFD_IND_YELLOW")

    local hostile = addPlaceholder(nil, {0,0}, track.name)
    hostile.element_params = {"DL_TRACK_"..a.."_CLASS"}
    hostile.controllers = {{"parameter_in_range", 0, 0.95, 1.05}}
    object = addStrokeBox(nil, 0.028, 0.028, "CenterCenter", {0,0}, hostile.name, nil, "CMFD_IND_RED")
    object.init_rot = {45}

    local friendly = addPlaceholder(nil, {0,0}, track.name)
    friendly.element_params = {"DL_TRACK_"..a.."_CLASS"}
    friendly.controllers = {{"parameter_in_range", 0, 1.95, 2.05}}
    addStrokeCircle(nil, 0.020, {0,0}, friendly.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_BLUE")
end

-- Bullseye and estimated threat envelopes.
local bull = addPlaceholder(nil, {0,0}, map_rot.name)
bull.element_params = {"CMFD_RAP_BULL_DIST", "CMFD_RAP_BULL_BRG", "CMFD_RAP_BULL_VALID"}
bull.controllers = {
    {"rotate_using_parameter", 1, -math.rad(1)},
    {"move_up_down_using_parameter", 0, MAP_RADIUS},
    {"parameter_in_range", 0, 0.005, 1.05},
    {"parameter_in_range", 2, 0.95, 1.05},
}
addStrokeCircle(nil, 0.027, {0,0}, bull.name, nil, nil, 0.5, 0.5, false, "CMFD_IND_MAGENTA")
addStrokeLine(nil, 0.065, {-0.0325, 0}, 90, bull.name, nil, nil, nil, nil, "CMFD_IND_MAGENTA")
addStrokeLine(nil, 0.065, {0, -0.0325}, 0, bull.name, nil, nil, nil, nil, "CMFD_IND_MAGENTA")

for i = 1, 8 do
    local threat = addPlaceholder(nil, {0,0}, map_rot.name)
    threat.element_params = {
        "CMFD_RAP_THREAT_"..i.."_DIST",
        "CMFD_RAP_THREAT_"..i.."_BRG",
        "CMFD_RAP_THREAT_"..i.."_VALID",
    }
    threat.controllers = {
        {"rotate_using_parameter", 1, -math.rad(1)},
        {"move_up_down_using_parameter", 0, MAP_RADIUS},
        {"parameter_in_range", 0, 0.005, 1.05},
        {"parameter_in_range", 2, 0.95, 1.05},
    }
    local wez = addPlaceholder(nil, {0,0}, threat.name)
    wez.element_params = {"CMFD_RAP_THREAT_"..i.."_RADIUS"}
    wez.controllers = {{"scale_using_parameter", 0, MAP_RADIUS / 0.03, 1}}
    addStrokeCircle(nil, 0.030, {0,0}, wez.name, nil, nil, 0.5, 0.5, true, "CMFD_IND_RED")
    addStrokeBox(nil, 0.014, 0.014, "CenterCenter", {0,0}, threat.name, nil, "CMFD_IND_RED")
end

object = addStrokeText(nil, "BINGO", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, -0.69}, page_root.name, nil, nil, CMFD_FONT_R)
object.element_params = {BRIGHT, "BINGO_ACTIVE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}