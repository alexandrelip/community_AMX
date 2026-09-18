dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")

local CMFDNumber = get_param_handle("CMFDNumber")
local CMFDNu = CMFDNumber:get()
local FORMAT = "CMFD"..tostring(CMFDNu).."Format"
local BRIGHT = "CMFD"..tostring(CMFDNu).."_BRIGHT"
-- Y spans -H2W_SCALE..+H2W_SCALE while X spans -1..1, so frame anchors are
-- expressed as a fraction of the usable height.
local VS = H2W_SCALE
local HEADER_Y = 0.90 * VS
local RANGE_Y = 0.78 * VS
local SCOPE_RADIUS = 0.72
local SCOPE_CENTER_X = 0
local SCOPE_CENTER_Y = -0.03 * VS

-- Same stroke/material contract CMFD_TSD establishes for the other tactical page.
DEFAULT_LEVEL = 9
default_material = CMFD_FONT_DEF
stroke_font = "cmfd_font_def"
stroke_material = "HUD"
stroke_thickness = 1
stroke_fuzziness = 0.6
additive_alpha = true
default_element_params = {BRIGHT}
default_controllers = {{"opacity_using_parameter", 0}}

local function surv_name(suffix)
    return "SURV_CMFD"..tostring(CMFDNu).."_"..suffix
end

-- Root controllers are not reliably inherited by children in this cockpit, so
-- every layout group repeats the format gate directly, like CMFD_TSD does.
local function format_gate(index)
    return {
        "parameter_in_range", index or 0,
        SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05,
    }
end

local function page_group(suffix, position, parent)
    local group = addPlaceholder(surv_name(suffix), position or {0,0}, parent)
    group.element_params = {FORMAT}
    group.controllers = {format_gate()}
    return group
end

local function bright(element)
    element.element_params = {BRIGHT, FORMAT}
    element.controllers = {{"opacity_using_parameter", 0}, format_gate(1)}
    return element
end

local page_root = create_page_root()
page_root.element_params = {FORMAT}
page_root.controllers = {format_gate()}
default_parent = page_root.name

-- Header and filter columns sit at the page origin, so they hang straight off
-- the root instead of an extra placeholder.
local header = page_root
bright(addStrokeText(surv_name("TITLE"), "SURV", CMFD_STRINGDEFS_DEF_X08,
    "LeftCenter", {-0.91, HEADER_Y}, header.name, nil, nil, CMFD_FONT_G))
local object = addStrokeText(surv_name("WP"), "WP 00", CMFD_STRINGDEFS_DEF_X06,
    "CenterCenter", {-0.34, HEADER_Y}, header.name, nil, {"WP %02.0f"}, CMFD_FONT_MAGENTA)
object.element_params = {BRIGHT, "CMFD_NAV_FYT", FORMAT}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range", 2, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
object = addStrokeText(surv_name("BRG"), "000", CMFD_STRINGDEFS_DEF_X06,
    "CenterCenter", {-0.05, HEADER_Y}, header.name, nil, {"%03.0f BRG"}, CMFD_FONT_W)
object.element_params = {BRIGHT, "CMFD_NAV_FYT_DTK_BRG", FORMAT}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range", 2, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
object = addStrokeText(surv_name("RNG"), "00.0", CMFD_STRINGDEFS_DEF_X06,
    "CenterCenter", {0.27, HEADER_Y}, header.name, nil, {"%04.1f NM"}, CMFD_FONT_W)
object.element_params = {BRIGHT, "CMFD_NAV_FYT_DTK_DIST", FORMAT}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range", 2, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
object = addStrokeText(surv_name("IAS"), "000", CMFD_STRINGDEFS_DEF_X06,
    "RightCenter", {0.91, HEADER_Y}, header.name, nil, {"%03.0f KT"}, CMFD_FONT_Y)
object.element_params = {BRIGHT, "AVIONICS_IAS", FORMAT}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range", 2, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
object = addStrokeText(surv_name("RANGE"), "20", CMFD_STRINGDEFS_DEF_X06,
    "RightCenter", {0.91, RANGE_Y}, header.name, nil, {"%3.0f NM"}, CMFD_FONT_W)
object.element_params = {BRIGHT, "HSD_RAD_SEL", FORMAT}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range", 2, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}

local function add_header_count(suffix, value, x, param, format, font)
    local count = addStrokeText(surv_name(suffix), value, CMFD_STRINGDEFS_DEF_X04,
        "CenterCenter", {x, RANGE_Y}, header.name, nil, {format}, font)
    count.element_params = {BRIGHT, param, FORMAT}
    count.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range", 2, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
end
add_header_count("RADAR_COUNT", "R00", 0.21, "SURV_RADAR_COUNT", "R%02.0f", CMFD_FONT_G)
add_header_count("LINK_COUNT", "D00", 0.39, "SURV_LINK_COUNT", "D%02.0f", CMFD_FONT_MAGENTA)
add_header_count("ROUTE_COUNT", "W00", 0.57, "SURV_ROUTE_COUNT", "W%02.0f", CMFD_FONT_MAGENTA)

local bull_brg = addStrokeText(surv_name("BULL_BRG"), "BE 000",
    CMFD_STRINGDEFS_DEF_X04, "LeftCenter", {-0.91, RANGE_Y},
    header.name, nil, {"BE %03.0f"}, CMFD_FONT_CYAN)
bull_brg.element_params = {BRIGHT, "CMFD_RAP_BULL_VALID", "CMFD_RAP_BULL_BRG_DEG", FORMAT}
bull_brg.controllers = {{"opacity_using_parameter", 0},
    {"parameter_in_range", 1, 0.95, 1.05}, {"text_using_parameter", 2, 0},
    {"parameter_in_range", 3, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
local bull_rng = addStrokeText(surv_name("BULL_RNG"), "/000",
    CMFD_STRINGDEFS_DEF_X04, "LeftCenter", {-0.74, RANGE_Y},
    header.name, nil, {"/%03.0f"}, CMFD_FONT_CYAN)
bull_rng.element_params = {BRIGHT, "CMFD_RAP_BULL_VALID", "CMFD_RAP_BULL_RNG_NM", FORMAT}
bull_rng.controllers = {{"opacity_using_parameter", 0},
    {"parameter_in_range", 1, 0.95, 1.05}, {"text_using_parameter", 2, 0},
    {"parameter_in_range", 3, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
add_header_count("TRACK_COUNT", "T00", 0.03, "SURV_TRACK_COUNT", "T%02.0f", CMFD_FONT_CYAN)

local tactical = page_group("TACTICAL", {SCOPE_CENTER_X, SCOPE_CENTER_Y}, page_root.name)
local card = addPlaceholder(surv_name("CARD"), {0,0}, tactical.name)
card.element_params = {"AVIONICS_HDG", FORMAT}
card.controllers = {
    {"rotate_using_parameter", 0, math.rad(1)},
    {"parameter_in_range", 1,
        SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05},
}

for _, ring in ipairs({{SCOPE_RADIUS * 0.5, 0.005}, {SCOPE_RADIUS, 0.008}}) do
    object = bright(addStrokeCircle(nil, ring[1], {0,0}, tactical.name,
        nil, nil, 0.5, 0.5, false, "CMFD_IND_WHITE"))
    object.thickness = ring[2]
end

for heading = 0, 350, 10 do
    local angle = math.rad(heading)
    local major = heading % 30 == 0
    bright(addStrokeLine(surv_name("CARD_TICK_"..heading), major and 0.035 or 0.025, {
        SCOPE_RADIUS * math.sin(angle), SCOPE_RADIUS * math.cos(angle),
    }, -heading, card.name, nil, nil, nil, nil, "CMFD_IND_WHITE"))
    if major then
        local label
        if heading == 0 then label = "N"
        elseif heading == 90 then label = "E"
        elseif heading == 180 then label = "S"
        elseif heading == 270 then label = "W"
        else label = string.format("%02d", heading / 10) end
        object = addStrokeText(surv_name("CARD_TEXT_"..heading), label,
            CMFD_STRINGDEFS_DEF_X06, "CenterCenter", {
                (SCOPE_RADIUS + 0.045) * math.sin(angle),
                (SCOPE_RADIUS + 0.045) * math.cos(angle),
            }, card.name, nil, nil, CMFD_FONT_W)
        object.element_params = {BRIGHT, "AVIONICS_HDG"}
        object.controllers = {
            {"opacity_using_parameter", 0},
            {"rotate_using_parameter", 1, -math.rad(1)},
        }
    end
end

local ownship = addPlaceholder(surv_name("OWNSHIP"), {0,0}, tactical.name)
ownship.init_rot = {180}
bright(addStrokeLine(nil, 0.075, {-0.0375, -0.025}, 27,
    ownship.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN))
bright(addStrokeLine(nil, 0.075, {0.0375, -0.025}, -27,
    ownship.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN))
bright(addStrokeLine(nil, 0.060, {0, -0.025}, 180,
    ownship.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN))
bright(addStrokeLine(nil, 0.055, {-0.0275, 0.010}, -90,
    ownship.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN))

local function add_scan_limit(suffix, rotation)
    local line = addStrokeLine(surv_name("SCAN_LIMIT_"..suffix),
        SCOPE_RADIUS * 0.5, {0,0}, rotation, tactical.name,
        nil, nil, nil, nil, CMFD_MATERIAL_GREEN)
    line.element_params = {BRIGHT, "RDR_POWER", "RADAR_STT_VALID",
        "SURV_FILTER_AIR", FORMAT}
    line.controllers = {{"opacity_using_parameter", 0},
        {"parameter_in_range", 1, 0.5, 1.5},
        {"parameter_in_range", 2, -0.05, 0.05},
        {"parameter_in_range", 3, 0.95, 1.05},
        {"parameter_in_range", 4, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
end
add_scan_limit("LEFT", 35)
add_scan_limit("RIGHT", -35)

do
    local slot = "01"
    local point = addPlaceholder(surv_name("ROUTE_POINT_"..slot), {0,0}, tactical.name)
    point.element_params = {
        "SURV_ROUTE_POINT_"..slot.."_VALID",
        "SURV_ROUTE_POINT_"..slot.."_X",
        "SURV_ROUTE_POINT_"..slot.."_Y",
    }
    point.controllers = {
        {"parameter_in_range", 0, 0.95, 1.05},
        {"move_left_right_using_parameter", 1, SCOPE_RADIUS},
        {"move_up_down_using_parameter", 2, SCOPE_RADIUS},
    }
    bright(addStrokeLine(nil, 0.031, {-0.015, -0.012}, 29,
        point.name, nil, nil, nil, nil, CMFD_MATERIAL_PINK))
    bright(addStrokeLine(nil, 0.031, {0.015, -0.012}, -29,
        point.name, nil, nil, nil, nil, CMFD_MATERIAL_PINK))
    bright(addStrokeLine(nil, 0.030, {-0.015, -0.012}, -90,
        point.name, nil, nil, nil, nil, CMFD_MATERIAL_PINK))
    object = addStrokeText(nil, "00", CMFD_STRINGDEFS_DEF_X04, "LeftCenter",
        {0.022, 0}, point.name, nil, {"%02.0f"}, CMFD_FONT_MAGENTA)
    object.element_params = {BRIGHT, "SURV_ROUTE_POINT_"..slot.."_ID", FORMAT}
    object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range", 2, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
end

for index = 1, 16 do
    local slot = string.format("%02d", index)
    local link_line = addStrokeLine(surv_name("LINK_LINE_"..slot),
        SCOPE_RADIUS, {0,0}, 0, tactical.name, nil, nil, nil, nil,
        "CMFD_IND_MAGENTA")
    link_line.element_params = {
        BRIGHT,
        "SURV_TRACK_"..slot.."_VALID",
        "SURV_TRACK_"..slot.."_SOURCE_KIND",
        "SURV_TRACK_"..slot.."_DIST_NORM",
        "SURV_TRACK_"..slot.."_BRG_DEG",
        "AVIONICS_HDG",
        "SURV_FILTER_DTL",
        FORMAT,
    }
    link_line.controllers = {
        {"opacity_using_parameter", 0},
        {"parameter_in_range", 1, 0.95, 1.05},
        {"parameter_in_range", 2, 0.95, 2.05},
        {"scale_using_parameter", 3, 1, 1},
        {"rotate_using_parameter", 4, -math.rad(1)},
        {"rotate_using_parameter", 5, math.rad(1)},
        {"parameter_in_range", 6, 0.95, 1.05},
        {"parameter_in_range", 7,
            SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05},
    }
    link_line.thickness = 0.004

    local track = addPlaceholder(surv_name("TRACK_"..slot), {0,0}, tactical.name)
    track.element_params = {
        "SURV_TRACK_"..slot.."_VALID",
        "SURV_TRACK_"..slot.."_X",
        "SURV_TRACK_"..slot.."_Y",
    }
    track.controllers = {
        {"parameter_in_range", 0, 0.95, 1.05},
        {"move_left_right_using_parameter", 1, SCOPE_RADIUS},
        {"move_up_down_using_parameter", 2, SCOPE_RADIUS},
    }

    local unknown = addPlaceholder(nil, {0,0}, track.name)
    unknown.element_params = {"SURV_TRACK_"..slot.."_CLASS"}
    unknown.controllers = {{"parameter_in_range", 0, -0.05, 0.05}}
    bright(addStrokeBox(nil, 0.030, 0.030, "CenterCenter", {0,0},
        unknown.name, nil, "CMFD_IND_YELLOW"))

    local hostile = addPlaceholder(nil, {0,0}, track.name)
    hostile.element_params = {"SURV_TRACK_"..slot.."_CLASS"}
    hostile.controllers = {{"parameter_in_range", 0, 0.95, 1.05}}
    bright(addStrokeLine(nil, 0.034, {-0.017, -0.014}, 30,
        hostile.name, nil, nil, nil, nil, CMFD_MATERIAL_RED))
    bright(addStrokeLine(nil, 0.034, {0.017, -0.014}, -30,
        hostile.name, nil, nil, nil, nil, CMFD_MATERIAL_RED))
    bright(addStrokeLine(nil, 0.034, {-0.017, -0.014}, -90,
        hostile.name, nil, nil, nil, nil, CMFD_MATERIAL_RED))

    local friendly = addPlaceholder(nil, {0,0}, track.name)
    friendly.element_params = {"SURV_TRACK_"..slot.."_CLASS"}
    friendly.controllers = {{"parameter_in_range", 0, 1.95, 2.05}}
    bright(addStrokeCircle(nil, 0.021, {0,0}, friendly.name,
        nil, nil, 0.5, 0.5, false, "CMFD_IND_GREEN"))

    local vector = addPlaceholder(nil, {0,0}, track.name)
    vector.element_params = {"SURV_TRACK_"..slot.."_HDG_DEG", "AVIONICS_HDG"}
    vector.controllers = {
        {"rotate_using_parameter", 0, -math.rad(1)},
        {"rotate_using_parameter", 1, math.rad(1)},
    }
    bright(addStrokeLine(nil, 0.055, {0,0.018}, 0, vector.name,
        nil, nil, nil, nil, CMFD_MATERIAL_CYAN))

    object = addStrokeText(nil, "00", CMFD_STRINGDEFS_DEF_X04, "CenterBottom",
        {0, 0.035}, track.name, nil, {"%02.0f"}, CMFD_FONT_W)
    object.element_params = {BRIGHT, "SURV_TRACK_"..slot.."_ALT_KFT", FORMAT}
    object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range", 2, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
    local donor = addPlaceholder(nil, {0,-0.035}, track.name)
    donor.element_params = {"SURV_TRACK_"..slot.."_SOURCE_KIND"}
    donor.controllers = {{"parameter_in_range", 0, 0.95, 2.05}}
    bright(addStrokeCircle(nil, 0.006, {0,0}, donor.name,
        nil, nil, 0.5, 0.5, true, "CMFD_IND_CYAN"))
end

local bull = addPlaceholder(surv_name("BULL"), {0,0}, card.name)
bull.element_params = {"CMFD_RAP_BULL_DIST", "CMFD_RAP_BULL_BRG", "CMFD_RAP_BULL_VALID"}
bull.controllers = {
    {"rotate_using_parameter", 1, -math.rad(1)},
    {"move_up_down_using_parameter", 0, SCOPE_RADIUS},
    {"parameter_in_range", 0, 0.01, 1.00},
    {"parameter_in_range", 2, 0.95, 1.05},
}
bright(addStrokeCircle(nil, 0.026, {0,0}, bull.name,
    nil, nil, 0.5, 0.5, false, "CMFD_IND_MAGENTA"))
bright(addStrokeLine(nil, 0.060, {-0.030,0}, 90, bull.name,
    nil, nil, nil, nil, "CMFD_IND_MAGENTA"))
bright(addStrokeLine(nil, 0.060, {0,-0.030}, 0, bull.name,
    nil, nil, nil, nil, "CMFD_IND_MAGENTA"))

for index = 1, 8 do
    local threat = addPlaceholder(surv_name("THREAT_"..index), {0,0}, card.name)
    threat.element_params = {
        "CMFD_RAP_THREAT_"..index.."_DIST",
        "CMFD_RAP_THREAT_"..index.."_BRG",
        "CMFD_RAP_THREAT_"..index.."_VALID",
        "SURV_FILTER_GND",
    }
    threat.controllers = {
        {"rotate_using_parameter", 1, -math.rad(1)},
        {"move_up_down_using_parameter", 0, SCOPE_RADIUS},
        {"parameter_in_range", 0, 0.01, 1.00},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, 0.95, 1.05},
    }
    local wez = addPlaceholder(nil, {0,0}, threat.name)
    wez.element_params = {"CMFD_RAP_THREAT_"..index.."_RADIUS",
        "SURV_THREAT_"..index.."_RING"}
    wez.controllers = {
        {"scale_using_parameter", 0, SCOPE_RADIUS / 0.03, 1},
        {"parameter_in_range", 1, 0.95, 1.05},
    }
    bright(addStrokeCircle(nil, 0.030, {0,0}, wez.name,
        nil, nil, 0.5, 0.5, true, "CMFD_IND_YELLOW"))
    bright(addStrokeBox(nil, 0.015, 0.015, "CenterCenter", {0,0},
        threat.name, nil, "CMFD_IND_YELLOW"))
end

local filters = page_root
local function filter_entry(position, label, param)
    bright(addOSSText(position, label, filters.name))
    local selected = addOSSStrokeBox(position, 1, filters.name,
        nil, nil, nil, #label)
    selected.element_params = {BRIGHT, param, FORMAT}
    selected.controllers = {{"opacity_using_parameter", 0},
        {"parameter_in_range", 1, 0.95, 1.05},
        {"parameter_in_range", 2, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05}}
end
filter_entry(6, "DTL", "SURV_FILTER_DTL")
filter_entry(7, "AIR", "SURV_FILTER_AIR")
bright(addOSSText(8, "SEA\nN/A", filters.name))
filter_entry(9, "GND", "SURV_FILTER_GND")
filter_entry(10, "FPL", "SURV_FILTER_FPL")
bright(addOSSText(11, "TF\nN/A", filters.name))
bright(addOSSArrow(27, 0, filters.name))
bright(addOSSArrow(28, 1, filters.name))

local cursor = addPlaceholder(surv_name("TDC"), {0,0}, tactical.name)
cursor.element_params = {
    "SURV_TDC_VALID", "SURV_TDC_X", "SURV_TDC_Y", FORMAT,
}
cursor.controllers = {
    {"parameter_in_range", 0, 0.95, 1.05},
    {"move_left_right_using_parameter", 1, SCOPE_RADIUS},
    {"move_up_down_using_parameter", 2, SCOPE_RADIUS},
    {"parameter_in_range", 3, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05},
}
bright(addStrokeLine(nil, 0.060, {-0.030,0}, -90,
    cursor.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN))
bright(addStrokeLine(nil, 0.060, {0,-0.030}, 0,
    cursor.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN))

local ew_primary = addPlaceholder(surv_name("EW_PRIMARY"), {0,0}, tactical.name)
ew_primary.element_params = {
    "SURV_EW_VALID", "SURV_EW_X", "SURV_EW_Y", FORMAT,
}
ew_primary.controllers = {
    {"parameter_in_range", 0, 0.95, 1.05},
    {"move_left_right_using_parameter", 1, SCOPE_RADIUS},
    {"move_up_down_using_parameter", 2, SCOPE_RADIUS},
    {"parameter_in_range", 3, SUB_PAGE_ID.SURV - 0.05, SUB_PAGE_ID.SURV + 0.05},
}

local function ew_class_marker(name, low, high, material, label, text_font)
    local marker = addPlaceholder(surv_name("EW_"..name), {0,0}, ew_primary.name)
    marker.element_params = {"SURV_EW_CLASS"}
    marker.controllers = {{"parameter_in_range", 0, low, high}}
    bright(addStrokeCircle(nil, 0.026, {0,0}, marker.name,
        nil, nil, 0.5, 0.5, false, material))
    local label_object = addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X04,
        "LeftCenter", {0.035, 0}, marker.name, nil, nil, text_font)
    label_object.element_params = {BRIGHT, FORMAT}
    label_object.controllers = {{"opacity_using_parameter", 0}, format_gate(1)}
end

ew_class_marker("SAM", 0.95, 1.05, CMFD_MATERIAL_YELLOW, "SAM", CMFD_FONT_Y)
ew_class_marker("AIR", 1.95, 3.05, CMFD_MATERIAL_CYAN, "AIR", CMFD_FONT_CYAN)
ew_class_marker("NAVAL", 3.95, 4.05, CMFD_MATERIAL_YELLOW, "SHIP", CMFD_FONT_Y)
ew_class_marker("AAM", 4.95, 5.05, CMFD_MATERIAL_RED, "AAM", CMFD_FONT_R)

-- Breadcrumb proving the indicator page really executed; `log` is not
-- guaranteed to exist in the indicator environment. Built by concatenation so
-- the page keeps adding no dynamic string-format path.
if log and log.info then
    log.info("F5EM_SURV_PAGE cmfd=" .. tostring(CMFDNu)
        .. " page_id=" .. tostring(SUB_PAGE_ID.SURV)
        .. " root=" .. tostring(page_root.name)
        .. " tactical=" .. tostring(tactical.name))
end