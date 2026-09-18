dofile(LockOn_Options.script_path .. "HUD/Indicator/HUD_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/avionics_api.lua")
dofile(LockOn_Options.script_path .. "Systems/weapon_system_api.lua")

-- CCRP
local HUD_CCRP_origin = addPlaceholder(nil, {0,0})
HUD_CCRP_origin.element_params = {"HUD_CCRP"}
HUD_CCRP_origin.controllers = {{"parameter_compare_with_number", 0, 1}}

-- [A-29 parity 2026-07-21] HUD_SHOW_TD wrapper: publica-se em CCRP + CCIP-DELAYED +
-- MAN(AG_GUIDED_MISSILE). Permite mostrar o target designator (TD) e o TLL sem
-- que os elementos puramente CCRP (SL steering line, SI solution indicator, Max
-- Range Circle) tambem aparecam em MAN. A/A e NAV nao publicam HUD_SHOW_TD.
local HUD_TD_origin = addPlaceholder(nil, {0,0})
HUD_TD_origin.element_params = {"HUD_SHOW_TD"}
HUD_TD_origin.controllers = {{"parameter_in_range", 0, 0.95, 1.05}}

-- TD Target Designator
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "target"}, "CenterCenter", {0, 0}, HUD_TD_origin.name)
object.element_params = {"HUD_BRIGHT", "HUD_TD_HIDE", "HUD_TD_AZIMUTH", "HUD_TD_ELEVATION", "HUD_CCIP_DELAYED"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, -0.05, 0.05},
	{"move_left_right_using_parameter", 2, move_scale},
	{"move_up_down_using_parameter", 3, move_scale},
	{"parameter_in_range", 4, -0.05, 0.05},
}
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, object.name)
object.element_params = {"HUD_BRIGHT", "HUD_TD_OS"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}

-- TLL Target Locator Line
object = addStrokeLine(nil, 30, {0,DegToMil(1.2)}, 0, HUD_TD_origin.name)
object.vertices = {{8, 0}, {40,0}}
object.element_params = {"HUD_BRIGHT", "HUD_TD_HIDE", "HUD_TD_ANGLE"}
object.controllers = {{"opacity_using_parameter", 0}, 
						{"parameter_in_range", 1, 0.95, 1.05},
						{"rotate_using_parameter", 2, 1}}

-- SL Steering Line
object = addStrokeLine(nil, 30, {0,0}, 0, HUD_CCRP_origin.name)
object.vertices = {{0, 200}, {0,-200}}
object.element_params = {"HUD_BRIGHT", "HUD_TD_HIDE", "HUD_SL_AZIMUTH", "HUD_ROLL"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, -0.05, 0.05},
	{"move_left_right_using_parameter", 2, move_scale},
	{"rotate_using_parameter", 3,1},
}
-- SI Solution Indicator
object = addStrokeLine(nil, 10, {0,0}, 0, object.name)
object.vertices = {{-5,0}, {5,0}}
object.element_params = {"HUD_BRIGHT", "HUD_SI_HIDE", "HUD_SI_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_compare_with_number", 1, 0},
	{"move_up_down_using_parameter", 2, move_scale},
}

-- Max Range Circle
object = addStrokeCircle(nil, 50, {0, 0}, HUD_CCRP_origin.name)
object.element_params = {"HUD_BRIGHT", "HUD_MAX_RANGE"}
object.controllers = { {"opacity_using_parameter", 0},  {"parameter_compare_with_number", 1, 1},}


-- CCIP Gun
local HUD_CCIP_GUN_origin = addPlaceholder(nil, {0,0})
HUD_CCIP_GUN_origin.element_params = {"AVIONICS_MASTER_MODE", "WPN_MASS"}
HUD_CCIP_GUN_origin.controllers = {
	{"parameter_in_range",0,AVIONICS_MASTER_MODE_ID.GUN-0.5, AVIONICS_MASTER_MODE_ID.GUN_R + 0.5},
	{"parameter_compare_with_number", 1, WPN_MASS_IDS.LIVE},
}
-- CCIP Gun cue
object = addStrokeCircle(nil, 16, {0,0}, HUD_CCIP_GUN_origin.name)
object.element_params = {"HUD_BRIGHT", "HUD_CCIP_PIPER_AZIMUTH", "HUD_CCIP_PIPER_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"move_left_right_using_parameter", 1, move_scale},
	{"move_up_down_using_parameter", 2, move_scale},
}
object = addStrokeCircle(nil, 1, {0,0}, object.name)

-- CCIP Gun out of screen
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, object.name)
object.element_params = {"HUD_BRIGHT", "HUD_CCIP_PIPER_HIDDEN"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number",1,1}}

-- CCIP
local HUD_CCIP_origin = addPlaceholder(nil, {0,0})
HUD_CCIP_origin.element_params = {"AVIONICS_MASTER_MODE", "WPN_MASS", "WPN_SELECTED_WEAPON_TYPE"}
HUD_CCIP_origin.controllers = {
	{"parameter_in_range",0,AVIONICS_MASTER_MODE_ID.CCIP-0.5, AVIONICS_MASTER_MODE_ID.CCIP_R + 0.5},
	{"parameter_compare_with_number", 1, WPN_MASS_IDS.LIVE},
	{"parameter_in_range",2, WPN_WEAPON_TYPE_IDS.AG_WEAPON_BEG, WPN_WEAPON_TYPE_IDS.AG_WEAPON_END},
}

-- CCIP Rocket
local HUD_CCIP_ROCKET_origin = addPlaceholder(nil, {0,0}, HUD_CCIP_origin.name)
HUD_CCIP_ROCKET_origin.element_params = {"WPN_SELECTED_WEAPON_TYPE"}
HUD_CCIP_ROCKET_origin.controllers = {
	{"parameter_compare_with_number",0,WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_ROCKET},
}

-- CCIP Rocket cue
object = addStrokeCircle(nil, 16, {0,0}, HUD_CCIP_ROCKET_origin.name)
object.element_params = {"HUD_BRIGHT", "HUD_CCIP_PIPER_AZIMUTH", "HUD_CCIP_PIPER_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"move_left_right_using_parameter", 1, move_scale},
	{"move_up_down_using_parameter", 2, move_scale},
}
object = addStrokeCircle(nil, 1, {0,0}, object.name)

-- CCIP out of screen
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, object.name)
object.element_params = {"HUD_BRIGHT", "HUD_CCIP_PIPER_HIDDEN"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number",1,1}}

-- CCIP Bomb
local HUD_CCIP_BOMB_origin = addPlaceholder(nil, {0,0}, HUD_CCIP_origin.name)
HUD_CCIP_BOMB_origin.element_params = {"WPN_SELECTED_WEAPON_TYPE", "HUD_CCIP_DELAYED"}
HUD_CCIP_BOMB_origin.controllers = {
	{"parameter_compare_with_number",0,WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB},
	{"parameter_compare_with_number",1,0},
}

-- CCIP Bomb cue
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "impact-point"}, "CenterCenter", {0, 0}, HUD_CCIP_BOMB_origin.name)
object.element_params = {"HUD_BRIGHT", "HUD_CCIP_PIPER_AZIMUTH", "HUD_CCIP_PIPER_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"move_left_right_using_parameter", 1, move_scale},
	{"move_up_down_using_parameter", 2, move_scale},
}

-- CCIP out of screen
-- object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, object.name)
-- object.element_params = {"HUD_BRIGHT", "HUD_CCIP_PIPER_HIDDEN"}
-- object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number",1,1}}


-- CCIP Bomb Line
object = addSimpleLine(nil, 10, {0,0}, 0, HUD_CCIP_BOMB_origin.name, nil, 0.5, HUD_MAT_DEF)
object.element_params = {"HUD_BRIGHT", "HUD_PIPER_LINE_A_X", "HUD_PIPER_LINE_A_Y", "HUD_PIPER_LINE_B_X", "HUD_PIPER_LINE_B_Y"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"line_object_set_point_using_parameters", 0, 1, 2, move_scale, move_scale},
	{"line_object_set_point_using_parameters", 1, 3, 4, move_scale, move_scale},
}

-- CCIP Delayed Indicator
object = addStrokeLine(nil, 10, {0,0}, 0, HUD_CCIP_BOMB_origin.name)
object.vertices = {{-5,0}, {5,0}}
object.element_params = {"HUD_BRIGHT", "HUD_CCIP_DELAYED_AZIMUTH", "HUD_CCIP_DELAYED_ELEVATION", "HUD_CCIP_PIPER_HIDDEN", "HUD_ROLL"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"move_left_right_using_parameter", 1, move_scale},
	{"move_up_down_using_parameter", 2, move_scale},
	{"parameter_compare_with_number", 3, 1},
	{"rotate_using_parameter", 4},
}


-- CCIP Delayed Target Designator
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "impact-point"}, "CenterCenter", {0, 0}, HUD_CCRP_origin.name)
object.element_params = {"HUD_BRIGHT", "HUD_TD_HIDE", "HUD_TD_AZIMUTH", "HUD_TD_ELEVATION", "HUD_CCIP_DELAYED"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, -0.05, 0.05},
	{"move_left_right_using_parameter", 2, move_scale},
	{"move_up_down_using_parameter", 3, move_scale},
	{"parameter_in_range", 4, 0.95, 1.05},
}
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, object.name)
object.element_params = {"HUD_BRIGHT", "HUD_TD_OS"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}
