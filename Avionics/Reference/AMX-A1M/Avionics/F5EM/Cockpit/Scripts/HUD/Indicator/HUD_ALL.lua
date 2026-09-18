dofile(LockOn_Options.script_path .. "HUD/Indicator/HUD_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/avionics_api.lua")
dofile(LockOn_Options.script_path .. "Systems/weapon_system_api.lua")


create_page_root()

local grid
grid                      = CreateElement "ceMeshPoly"
grid.primitivetype        = "lines"
grid.init_pos             = {0, 0, 0.0}
grid.material             = HUD_TEX_IND2
grid.vertices             ={{math.rad(-7.6)*1000, math.rad(5.5)*1000}, {math.rad(7.6)*1000,math.rad(5.5)*1000}, {math.rad(7.6)*1000,math.rad(-11.5)*1000}, {math.rad(-7.6)*1000,math.rad(-11.5)*1000},}
grid.indices              = {0,1, 1,2, 2,3, 3,0}
grid.isvisible            = true
-- AddElementObject(grid)
grid = nil

grid                      = CreateElement "ceMeshPoly"
grid.primitivetype        = "lines"
grid.init_pos             = {0, 0, 0.0}
grid.material             = HUD_TEX_IND2
grid.vertices             = {
                                {math.rad(-7.6)*1000, math.rad(1.2)*1000}, {math.rad(7.6)*1000,math.rad(1.2)*1000},
                                {0, math.rad(5.5)*1000}, {0,math.rad(-11.5)*1000},
                                {math.rad(-7.6)*1000, math.rad(-3.7)*1000}, {math.rad(7.6)*1000,math.rad(-3.7)*1000},
                                {math.rad(-7.6)*1000, 0}, {math.rad(7.6)*1000,0},
                            }
grid.indices              = {0,1, 2,3, 4,5, 6,7}
grid.isvisible            = true

-- AddElementObject(grid)
grid = nil

-- HUD boresight cross

local object

local HUD_BoresightRoot = addStrokeSymbol("HUD_Boresight_Cross", {"f5em_stroke_symbols", "boresight-cross"}, "CenterCenter", {0, DegToMil(1.2)})

-- FYT
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "aim9lm-caged"}, "CenterCenter", {0, 0})
object.element_params = {"HUD_BRIGHT", "HUD_FYT_HIDE", "CMFD_NAV_FYT_VALID", "HUD_FYT_AZIMUTH", "HUD_FYT_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, -0.05, 0.05},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"move_left_right_using_parameter", 3, move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
}
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, object.name)
object.element_params = {"HUD_BRIGHT", "HUD_FYT_OS"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}

-- OAP
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "oap"}, "CenterCenter", {0, 0})
object.element_params = {"HUD_BRIGHT", "HUD_OAP_HIDE", "CMFD_NAV_FYT_VALID", "HUD_OAP_AZIMUTH", "HUD_OAP_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_compare_with_number",1,0},
	{"parameter_compare_with_number",2,1},
	{"move_left_right_using_parameter", 3, move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
}

object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, object.name)
object.element_params = {"HUD_BRIGHT", "HUD_OAP_OS"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number",1,1}}

-- TIP
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "target"}, "CenterCenter", {0, 0})
object.element_params = {"HUD_BRIGHT", "HUD_TIP_HIDE", "CMFD_NAV_FYT_VALID", "HUD_TIP_AZIMUTH", "HUD_TIP_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"parameter_compare_with_number",1,0},
	{"parameter_compare_with_number",2,1},
	{"move_left_right_using_parameter", 3, move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
}

object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, object.name)
object.element_params = {"HUD_BRIGHT", "HUD_TIP_OS"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number",1,1}}

-- Flight Path Marker - FPM
local HUD_FPM_origin = addPlaceholder("HUD_FPM_origin", {0, 0})
HUD_FPM_origin.element_params = {"HUD_DCLT", "HUD_BRIGHT"}
HUD_FPM_origin.controllers = {{"parameter_in_range",0,-0.05,1.05}, {"opacity_using_parameter", 1}}


object = addStrokeSymbol("HUD_FPM", {"f5em_stroke_symbols", "flightpath-marker"}, "FromSet", {0, 0}, HUD_FPM_origin.name, {{"HUD_FPM_Flash"}})
object.element_params = {"HUD_FPM_SLIDE", "HUD_FPM_VERT", "UFCP_DRIFT_CO", "HUD_BRIGHT"}
object.controllers = {{"move_left_right_using_parameter", 0, move_scale}, {"move_up_down_using_parameter", 1, move_scale}, {"parameter_compare_with_number",2,0}, {"opacity_using_parameter", 3}}

object = addStrokeSymbol("HUD_FPM_CO", {"f5em_stroke_symbols", "flightpath-marker-co"}, "FromSet", {0, 0}, HUD_FPM_origin.name, {{"HUD_FPM_Flash"}})
object.element_params = {"HUD_FPM_VERT", "UFCP_DRIFT_CO", "HUD_BRIGHT"}
object.controllers = {{"move_up_down_using_parameter", 0, move_scale}, {"parameter_compare_with_number",1,1}, {"opacity_using_parameter", 2}}

-- ILS
object = addStrokeSymbol("HUD_ILS_LOC", {"f5em_stroke_symbols", "ils-loc"}, "FromSet", {0, 0}, "HUD_FPM", {{"HUD_FPM_Flash"}})
object.element_params = {"NAV_ILS_LOC_DEV", "NAV_ILS_LOC_VALID", "HUD_BRIGHT", "AVIONICS_ANS_MODE", "AVIONICS_MASTER_MODE"}
object.controllers = {{"move_left_right_using_parameter", 0, 1}, {"parameter_compare_with_number",1,1}, {"opacity_using_parameter", 2}, {"parameter_compare_with_number",3,AVIONICS_ANS_MODE_IDS.ILS}, {"parameter_in_range", 4, AVIONICS_MASTER_MODE_ID.NAV - 0.05, AVIONICS_MASTER_MODE_ID.LANDING + 0.05}}

object = addStrokeSymbol("HUD_ILS_GS", {"f5em_stroke_symbols", "ils-loc"}, "FromSet", {0, 0}, "HUD_FPM", {{"HUD_FPM_Flash"}})
object.init_rot={-90};
object.element_params = {"NAV_ILS_GS_DEV", "NAV_ILS_GS_VALID", "HUD_BRIGHT", "AVIONICS_ANS_MODE", "AVIONICS_MASTER_MODE"}
object.controllers = {{"move_left_right_using_parameter", 0, 1}, {"parameter_compare_with_number",1,1}, {"opacity_using_parameter", 2}, {"parameter_compare_with_number",3,AVIONICS_ANS_MODE_IDS.ILS}, {"parameter_in_range", 4, AVIONICS_MASTER_MODE_ID.NAV - 0.05, AVIONICS_MASTER_MODE_ID.LANDING + 0.05}}

-- FPM cross
object = addStrokeSymbol("HUD_FPM_Cross", {"f5em_stroke_symbols", "fpm-cross"}, "FromSet", {0, 0}, "HUD_FPM", {{"HUD_FPM_Cross"}})
object.element_params = {"HUD_FPM_CROSS", "HUD_BRIGHT"}
object.controllers = {{"parameter_compare_with_number",0,1}, {"opacity_using_parameter", 1}}

-- AoA bracket
object = addStrokeSymbol("HUD_AoA_bracket", {"f5em_stroke_symbols", "aoa-bracket"}, "FromSet", {0, 0}, "HUD_FPM", {{"HUD_AoA_bracket"}})
object.element_params = {"HUD_BRIGHT", "AVIONICS_MASTER_MODE", "BASE_SENSOR_WOW_LEFT_GEAR", "HUD_AOA_DELTA"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number",1,AVIONICS_MASTER_MODE_ID.LANDING},  {"parameter_compare_with_number",2,0}, {"move_up_down_using_parameter", 3, DegToMil(1)/1000/2}}


-- Great steering circle cue "tadpole"
-- [F-5EM 2026-08-29] Reactivated. The A-29 stroke-symbol form used a named
-- controller set ("HUD_Tadpole_Pos") that DCS never resolved, which is why it
-- shipped commented out. It is now built from primitives with explicit
-- controllers: a circle riding on the FPM whose lateral deflection is
-- HUD_TADPOLE_OFFSET (rad, saturating at 50 mil) published by hud.lua from the
-- bearing to the active flight point versus the current ground track.
local HUD_Tadpole_FPM = addPlaceholder("HUD_Tadpole_FPM", {0, 0})
HUD_Tadpole_FPM.element_params = {"HUD_FPM_SLIDE", "HUD_FPM_VERT"}
HUD_Tadpole_FPM.controllers = {
	{"move_left_right_using_parameter", 0, move_scale},
	{"move_up_down_using_parameter", 1, move_scale},
}

local HUD_Tadpole_origin = addPlaceholder("HUD_Tadpole_origin", {0, 0}, HUD_Tadpole_FPM.name)
HUD_Tadpole_origin.element_params = {"HUD_TADPOLE_OFFSET"}
HUD_Tadpole_origin.controllers = {{"move_left_right_using_parameter", 0, move_scale}}

object = addStrokeCircle("HUD_Tadpole", 8, {0, 0}, HUD_Tadpole_origin.name)
addDcltGate(object, 2, {"HUD_BRIGHT", "HUD_TADPOLE_SHOW"}, {
	{"opacity_using_parameter", 0},
	{"parameter_in_range", 1, 0.95, 1.05},
})

-- Pitch Ladder (PL)
local PL_origin = addPlaceholder("HUD_PL_origin", {0, 0}, HUD_FPM_origin.name, {{"HUD_AA_Gun_HideIfActive"}, {"HUD_PitchLadder_Show"}, {"HUD_PitchLadder_PosRot"}})
PL_origin.element_params            = {"HUD_PITCH", "HUD_ROLL", "HUD_PL_SLIDE"}
PL_origin.controllers 		        = {{"move_left_right_using_parameter", 2, move_scale}, {"rotate_using_parameter",1, 1 }, {"move_up_down_using_parameter",0,-move_scale}, }

local PL_horizon_line_half_gap		= 16
local PL_long_horizon_line_width	= 70

local PL_pitch_line_half_gap		= 16
local PL_pitch_line_width			= 25
local PL_pitch_line_tick			= 4


-- long line - horizon
object = add_PL_line("PL_horizon_long_line", PL_long_horizon_line_width, PL_horizon_line_half_gap, 0, 0, 0, {{"HUD_PL_GhostHorizon", 0}}, PL_origin.name)
-- object.element_params = {"HUD_PITCH"}
-- object.controllers = {{"parameter_in_range",0,math.rad(-5), math.rad(5)}}

-- object = add_PL_GhostHorizon("PL_GhostHorizon_", PL_long_horizon_line_width, PL_horizon_line_half_gap, {{"HUD_PitchLadder_Show"}, {"HUD_PL_GhostHorizon", 1}}, {0, 0})
-- object.parent_element = PL_origin.name
-- object.element_params = {"HUD_PITCH"}
-- object.controllers = {{"parameter_in_range",0,-10, math.rad(-5)}}

object = add_PL_line("PL_horizon_25_line", PL_pitch_line_width*move_scale, PL_pitch_line_half_gap, 0, DegToMil(-2.5), 0, nil, PL_origin.name)
object.element_params = {"AVIONICS_MASTER_MODE"}
object.controllers = {{"parameter_compare_with_number", 0, AVIONICS_MASTER_MODE_ID.LANDING}}

-- -80 to +80 degrees
local counterBegin = -80
local counterEnd   = -counterBegin
for i = counterBegin, counterEnd, 5 do
	local ang=math.abs(i)
	if i ~= 0 and ang ~= 65 and ang~= 75 then
		object = add_PL_line("PL_pitch_line_"..i, PL_pitch_line_width, PL_pitch_line_half_gap, PL_pitch_line_tick, DegToMil(i), i, {{"HUD_PitchLadder_Limit", DegToMil(10)}}, PL_origin.name)
		object.element_params = {"HUD_PL"}
		object.controllers = {{"parameter_compare_with_number", 0, 1}}
	end
end
addStrokeSymbol(nil, {"f5em_stroke_symbols", "pup"}, "CenterCenter", {0, DegToMil(90)}, PL_origin.name)
addStrokeSymbol(nil, {"f5em_stroke_symbols", "pup"}, "CenterCenter", {0, DegToMil(-90)}, PL_origin.name)
addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, DegToMil(-90)}, PL_origin.name,nil, 0.5)


-- Roll Indicator
local HUD_RI_origin	= addPlaceholder("HUD_RI_origin", {0, -48}, nil, {{"HUD_RI_Pos"}})
HUD_RI_origin.element_params = {"HUD_BRIGHT"}
HUD_RI_origin.controllers = {{"opacity_using_parameter", 0}}

local HUD_RI_origin_rot	= addPlaceholder("HUD_RI_origin_rot", {0, 0}, HUD_RI_origin.name)
HUD_RI_origin_rot.element_params = {"HUD_RI_ROLL"}
HUD_RI_origin_rot.controllers = {{"rotate_using_parameter", 0, 1}}
addRollIndicator(54, 8, 2, HUD_RI_origin.name)
addStrokeSymbol("HUD_Roll_Indicator_Caret", {"f5em_stroke_symbols", "roll-caret"}, "FromSet", {0, -58}, HUD_RI_origin_rot.name, {{"HUD_RI_Roll", -55}})

--
local HUD_Indication_bias = addPlaceholder("HUD_Indication_bias", {0, 0}, nil, {{"HUD_Indication_Bias"}})

-- Velocity numerics
local HUD_Vel_num_origin	= addPlaceholder("HUD_Vel_num_origin", {-48, 0}, HUD_Indication_bias.name)
HUD_Vel_num_origin.element_params = {"UFCP_VAH"}
HUD_Vel_num_origin.controllers = {{"parameter_compare_with_number",0,0}}

object = addStrokeText("HUD_Velocity_num", "520", STROKE_FNT_DFLT_100_NARROW, "RightCenter", {0, 0}, HUD_Vel_num_origin.name, {{"HUD_Velocity_Num"}}, {"%3.0f"})
object.element_params = {"HUD_IAS", "HUD_BRIGHT"}
object.controllers = {{"text_using_parameter",0,0}, {"opacity_using_parameter", 1}}

addStrokeSymbol("HUD_Velocity_box", {"f5em_stroke_symbols", "velocity-box"}, "FromSet", {-9, 0}, HUD_Vel_num_origin.name)
addStrokeLine("HUD_VelNumLine", 10, {13, 0}, 90, HUD_Vel_num_origin.name)

-- Velocity scale
local velScale20KnotsStep		= 25
local velScaleLongTickLen		= 4
local velScaleShortTickLen		= 2
local Mil_PerOneKnots			= velScale20KnotsStep / 50

local HUD_VelScale_origin = addPlaceholder("HUD_VelScale_origin", {-90, 0}, HUD_Indication_bias.name, {{"HUD_AA_Gun_HideIfActive"}, {"HUD_VelScaleOrigin"}})
HUD_VelScale_origin.element_params = {"UFCP_VAH", "HUD_BRIGHT"}
HUD_VelScale_origin.controllers = {{"parameter_compare_with_number",0,1}, {"opacity_using_parameter", 1}}


local HUD_VelScale_originLong  = addPlaceholder("HUD_VelScale_originLong", {-velScaleShortTickLen, 0}, HUD_VelScale_origin.name, {{"HUD_VelScaleVerPos", 0, Mil_PerOneKnots}})
HUD_VelScale_originLong.element_params = {"HUD_VEL_SCALE_MOVE"}
HUD_VelScale_originLong.controllers = { {"move_up_down_using_parameter",0, -velScale20KnotsStep/20/1000*move_scale}}

local HUD_VelScale_originShort = {}
for j = 1,4 do
	HUD_VelScale_originShort[j] = addPlaceholder("HUD_VelScale_originShort"..j, {0, 0}, HUD_VelScale_originLong.name, {{"HUD_VelScaleVerPos", 10 * j, Mil_PerOneKnots}})
end

for i = 1, 4 do
	local posY = velScale20KnotsStep * (i - 2.5)
	object = addStrokeLine("HUD_VelScaleTickLong_"..i, velScaleLongTickLen, {0, posY}, 90, HUD_VelScale_originLong.name, {{"HUD_VelScaleHide", i, 0}})
	object.element_params = {"HUD_BRIGHT", "HUD_VEL_SCALE_MOVE", "HUD_IAS"}
	if i == 1 then
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, -0.05 , 0.05}, {"parameter_in_range",2, 19.95 , 999}}
	elseif i==2 then
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",2, 19.95 , 999}}
	end
	for j = 1,3 do
		object = addStrokeLine("HUD_VelScaleTickShort_"..j..i, velScaleShortTickLen, {0, posY + j*velScale20KnotsStep/4}, 90, HUD_VelScale_originShort[j].name, {{"HUD_VelScaleHide", i, j}})
		object.element_params = {"HUD_BRIGHT", "HUD_VEL_SCALE_MOVE", "HUD_IAS"}
		if i == 1 then
			object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, -0.05 , (j)*5+0.05}, {"parameter_in_range",2, 19.95 , 999}}
		elseif i == 2 then
			object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",2, 19.95 , 999}}
		elseif i == 4 then
			object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1,j*5-0.05, 20.05}}
		end
	end
	object = addStrokeText("HUD_VelScaleNumerics_"..i, tostring(i), STROKE_FNT_DFLT_100_NARROW, "RightCenter", {-velScaleLongTickLen - 1, posY}, HUD_VelScale_originLong.name, {{"HUD_VelScaleText", i}}, {"%02.0f"})
	object.element_params = {"HUD_BRIGHT", "HUD_VEL_SCALE_MOVE", "HUD_VEL_SCALE_NUM_"..i, "HUD_IAS"}
	if i == 1 then
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, -0.05 , 0.05}, {"text_using_parameter",2,0}, {"parameter_in_range",3, 19.95 , 999}}
	elseif i == 2 then
		object.controllers = { {"opacity_using_parameter", 0}, {"text_using_parameter",2,0}, {"parameter_in_range",3, 19.95 , 999}}
	else 
		object.controllers = { {"opacity_using_parameter", 0}, {"text_using_parameter",2,0}}
	end
end

local HUD_Velocity_CueOrigin = addPlaceholder("HUD_Velocity_CueOrigin", {0,0}, HUD_VelScale_origin.name)
HUD_Velocity_CueOrigin.element_params = {"HUD_VEL_CUE_MOVE", "HUD_VEL_CUE_VALUE"}
HUD_Velocity_CueOrigin.controllers = {{"move_up_down_using_parameter",0, velScale20KnotsStep/20/1000*move_scale}, {"parameter_in_range", 1, 0, 999}}
object = addStrokeSymbol("HUD_Velocity_Cue", {"f5em_stroke_symbols", "AA-DLZ-range"}, "RightCenter", {0, 0}, HUD_Velocity_CueOrigin.name)
object.init_rot = {180}
object = addStrokeText("HUD_VelCueNumerics", 0, STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {7,0}, HUD_Velocity_CueOrigin.name, nil, {"%02.0f"})
object.element_params = {"HUD_BRIGHT", "HUD_VEL_CUE_MOVE", "HUD_VEL_CUE_VALUE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 27.5, 30.05}, {"text_using_parameter", 2, 0}}


addStrokeLine("HUD_VelScaleLine", 10, {10, 0}, 90, HUD_VelScale_origin.name)

-- Altitude numerics
local HUD_Alt_num_origin	= addPlaceholder("HUD_Alt_num_origin", {72, 0}, HUD_Indication_bias.name)
HUD_Alt_num_origin.element_params = {"UFCP_VAH", "HUD_BRIGHT"}
HUD_Alt_num_origin.controllers = {{"parameter_compare_with_number",0,0}, {"opacity_using_parameter", 1}}

object = addStrokeText("HUD_Altitude_num", "     ", STROKE_FNT_DFLT_100_NARROW, "CenterCenter", {-15, 0}, HUD_Alt_num_origin.name, {{"HUD_Altitude_Num"}}, {"%05.0f"})
object.element_params = {"HUD_ALT_FT", "HUD_BRIGHT"}
object.controllers = {{"text_using_parameter",0,0}, {"opacity_using_parameter", 1}}

addStrokeSymbol("HUD_Altitude_box", {"f5em_stroke_symbols", "altitude-box"}, "FromSet", {-15, 0}, HUD_Alt_num_origin.name)
addStrokeLine("HUD_AltNumLine", 10, {-41, 0}, -90, HUD_Alt_num_origin.name)

-- Altitude scale
local altScale500FeetStep		= 25
local altScaleLongTickLen		= 4
local altScaleShortTickLen		= 2
local Mil_Per100Feet			= altScale500FeetStep / 50

local HUD_AltScale_origin = addPlaceholder("HUD_AltScale_origin", {84, 0}, HUD_Indication_bias.name, {{"HUD_AA_Gun_HideIfActive"}, {"HUD_AltScaleOrigin"}})
HUD_AltScale_origin.element_params = {"UFCP_VAH"}
HUD_AltScale_origin.controllers = {{"parameter_compare_with_number",0,1}}

local HUD_AltScale_originLong  = addPlaceholder("HUD_AltScale_originLong", {altScaleShortTickLen, 0}, HUD_AltScale_origin.name, {{"HUD_AltScaleVerPos", 0, Mil_Per100Feet}})
HUD_AltScale_originLong.element_params = {"HUD_ALT_SCALE_MOVE"}
HUD_AltScale_originLong.controllers = { {"move_up_down_using_parameter",0, -altScale500FeetStep/500/1000*move_scale}}

local HUD_AltScale_originShort = {}
for j = 1,4 do
	HUD_AltScale_originShort[j] = addPlaceholder("HUD_AltScale_originShort"..j, {0, 0}, HUD_AltScale_originLong.name, {{"HUD_AltScaleVerPos", 10 * j, Mil_Per100Feet}})
end

for i = 1, 4 do
	local posY = altScale500FeetStep * (i - 2.5)-- + velScale50KnotsStep / 2
	object = addStrokeLine("HUD_AltScaleTickLong_"..i, altScaleLongTickLen, {0, posY}, -90, HUD_AltScale_originLong.name, {{"HUD_AltScaleHide", i, 0}})
	if i == 1 then
		object.element_params = {"HUD_BRIGHT", "HUD_ALT_SCALE_MOVE"}
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, -0.05 , 0.05}}
	end
for j = 1,4 do
		object = addStrokeLine("HUD_AltScaleTickShort_"..j..i, altScaleShortTickLen, {0, posY + j*altScale500FeetStep/5}, -90, HUD_AltScale_originShort[j].name, {{"HUD_AltScaleHide", i, j}})
		object.element_params = {"HUD_BRIGHT", "HUD_ALT_SCALE_MOVE"}
		if i == 1 then
			object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, -0.05 , (j)*100+0.05}}
		elseif i == 4 then
			object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1,j*100-0.05, 500.05}}
		end
	end
	object = addStrokeText("HUD_AltScaleNumericsL_"..i, i, STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {altScaleLongTickLen + altScaleShortTickLen, posY}, HUD_AltScale_originLong.name, {{"HUD_AltScaleText", i, 0}}, {"%04.1f"})
	object.element_params = {"HUD_BRIGHT", "HUD_ALT_SCALE_MOVE", "HUD_ALT_SCALE_NUM_"..i}
	if i == 1 then
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, -0.05 , 0.05}, {"text_using_parameter",2,0}}
	else 
		object.controllers = { {"opacity_using_parameter", 0}, {"text_using_parameter",2,0}}
	end
end
addStrokeLine("HUD_AltScaleLine", 10, {-10, 0}, -90, HUD_AltScale_origin.name)

local HUD_Alt_Cue_origin = addPlaceholder(nil, {0,0}, HUD_AltScale_origin.name)
HUD_Alt_Cue_origin.element_params = {"HUD_ALT_CUE_MOVE", "HUD_ALT_CUE_VALUE"}
HUD_Alt_Cue_origin.controllers = {{"move_up_down_using_parameter",0, altScale500FeetStep/500/1000*move_scale}, {"parameter_in_range", 1, -0.05, 50000}}
object = addStrokeSymbol("HUD_Alt_Cue", {"f5em_stroke_symbols", "AA-DLZ-range"}, "RightCenter", {0, 0}, HUD_Alt_Cue_origin.name)
object = addStrokeText("HUD_AltCueNumerics", 0, STROKE_FNT_DFLT_100_NARROW, "RightCenter", {-7,0}, HUD_Alt_Cue_origin.name, nil, {"%04.1f"})
object.element_params = {"HUD_BRIGHT", "HUD_ALT_CUE_MOVE", "HUD_ALT_CUE_VALUE"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 775, 800.05}, {"text_using_parameter", 2, 0}}


-- Vertical Speed scale
local VSScale1000FeetStep		= 25 * 1.4/2
local VSScaleLongTickLen		= 4
local VSScaleShortTickLen		= 2
local VSMil_Per100Feet			= VSScale1000FeetStep / 50

local HUD_VSScale_origin = addPlaceholder(nil, {66, 0}, HUD_Indication_bias.name, {{"HUD_AA_Gun_HideIfActive"}, {"HUD_AltScaleOrigin"}})
addDcltGate(HUD_VSScale_origin, 1, {"UFCP_VV"}, {{"parameter_compare_with_number",0,1}})

local HUD_VSScale_originLong  = addPlaceholder(nil, {VSScaleShortTickLen, 0}, HUD_VSScale_origin.name, {{"HUD_AltScaleVerPos", 0, VSMil_Per100Feet}})
local HUD_VSScale_originShort = {}
for j = 1,4 do
	HUD_VSScale_originShort[j] = addPlaceholder(nil, {0, 0}, HUD_VSScale_originLong.name, {{"HUD_AltScaleVerPos", 10 * j, VSMil_Per100Feet}})
end

for i = 1, 5 do
	local posY = VSScale1000FeetStep * (i -3)
	object = addStrokeLine(nil, VSScaleLongTickLen, {0, posY}, -90, HUD_VSScale_originLong.name, {{"HUD_AltScaleHide", j, 0}})
	if i ~= 5 then
		object = addStrokeLine(nil, VSScaleShortTickLen, {0, posY + VSScale1000FeetStep/2}, -90, HUD_VSScale_originShort[i].name, {{"HUD_AltScaleHide", i}})
	end
end
local HUD_VS_Cue_origin = addPlaceholder(nil, {0,0}, HUD_VSScale_origin.name)
HUD_VS_Cue_origin.element_params = {"HUD_VS_CUE_MOVE", "HUD_VS_CUE_VALUE"}
HUD_VS_Cue_origin.controllers = {{"move_up_down_using_parameter",0, VSScale1000FeetStep/1000/1000*move_scale}, {"parameter_in_range", 1, -0.05, 50000}}
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "AA-DLZ-range"}, "RightCenter", {0, 0}, HUD_VS_Cue_origin.name)


-- Heading numerics
local HUD_Hdg_origin	= addPlaceholder("HUD_Hdg_origin", {0, 95}, nil, {{"HUD_AA_Gun_HideIfActive"}, {"HUD_Heading_Bias"}})
HUD_Hdg_origin.element_params = {"UFCP_VAH", "HUD_BRIGHT"}
-- The F-5EM reference combines boxed IAS/ALT with a heading tape. Keep the
-- legacy boxed heading available in the file, but outside the selectable
-- UFCP_VAH states (0/1) so it cannot overlap the tape.
HUD_Hdg_origin.controllers = {{"parameter_compare_with_number",0,2}, {"opacity_using_parameter", 1}}
object = addStrokeText("HUD_Heading_num", "360", STROKE_FNT_DFLT_100_NARROW, "CenterCenter", {0, -12.5}, HUD_Hdg_origin.name, {{"HUD_Heading_Num"}}, {"%03.0f"})
object.element_params = {"HUD_HDG", "HUD_BRIGHT"}
object.controllers = {{"text_using_parameter",0,0}, {"opacity_using_parameter", 1}}
addStrokeBox("HUD_Heading_box", 17, 11, "CenterCenter", {0, -12.5}, HUD_Hdg_origin.name)

-- Heading scale
local hdgScaleTenDegreesStep	= 38
local hdgScaleLongTickLen		= 4
local hdgScaleTextShiftY		= 2
local Mil_PerOneDegree			= hdgScaleTenDegreesStep / 10

local HUD_HdgScale_origin = addPlaceholder("HUD_HdgScale_origin", {0, 86}, nil, {{"HUD_HdgScaleOrigin"}})
HUD_HdgScale_origin.element_params = {"HUD_BRIGHT"}
HUD_HdgScale_origin.controllers = {{"opacity_using_parameter", 0}}

local HUD_HdgScale_originLong  = addPlaceholder("HUD_HdgScale_originLong", {0, -hdgScaleTextShiftY}, HUD_HdgScale_origin.name, {{"HUD_HdgScaleHorPos", 0, Mil_PerOneDegree}})
HUD_HdgScale_originLong.element_params = {"HUD_HDG_SCALE_MOVE"}
HUD_HdgScale_originLong.controllers = { {"move_left_right_using_parameter",0, -hdgScaleTenDegreesStep/10/1000*move_scale}}

local HUD_HdgScale_originShort = addPlaceholder("HUD_HdgScale_originShort", {0, 0}, HUD_HdgScale_originLong.name, {{"HUD_HdgScaleHorPos", -5, Mil_PerOneDegree}})

for i = 1, 4 do
	local posX = hdgScaleTenDegreesStep * (i - 2) 
	object = addStrokeLine("HUD_HeadingTickLong_"..i, -hdgScaleLongTickLen, {posX, 0}, 0, HUD_HdgScale_originLong.name, {{"HUD_HdgScaleHide", (i - 2), 0}})
	if i == 1 then
		object.element_params = {"HUD_BRIGHT", "HUD_HDG_SCALE_MOVE"}
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, -0.05 , 2.05}}
	elseif i == 4 then
		object.element_params = {"HUD_BRIGHT", "HUD_HDG_SCALE_MOVE"}
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, 7.95 , 10.05}}
	end
	object = addStrokeLine("HUD_HeadingTickShort_"..i, -hdgScaleLongTickLen * 0.5, {posX + hdgScaleTenDegreesStep/2, 0}, 0, HUD_HdgScale_originShort.name, {{"HUD_HdgScaleHide", (i - 2), 1}})
	object.element_params = {"HUD_BRIGHT", "HUD_HDG_SCALE_MOVE"}
	if i == 1 then
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, -0.05 , 7.05}}
	elseif i == 3 then
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, 2.95 , 10.05}}
	elseif i == 4 then
		object. isvisible = false
	end
	object = addStrokeText("HUD_HeadingNumerics_"..i, tostring(i), STROKE_FNT_DFLT_100_NARROW, "CenterBottom", {posX, hdgScaleLongTickLen + 1}, HUD_HdgScale_originLong.name, {{"HUD_HeadingScaleText", (i - 2)}}, {"%03.0f"})
	object.element_params = {"HUD_BRIGHT", "HUD_HDG_SCALE_MOVE", "HUD_HDG_SCALE_NUM_"..i}
	if i == 1 then
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, -0.05 , 2.05}, {"text_using_parameter",2, 0}}
	elseif i == 4 then
		object.controllers = { {"opacity_using_parameter", 0}, {"parameter_in_range",1, 7.95 , 10.05}, {"text_using_parameter",2, 0}}
	else 
		object.controllers = { {"opacity_using_parameter", 0}, {"text_using_parameter",2, 0}}
	end
end

local HUD_Hdg_Cue_origin = addPlaceholder(nil, {0,0}, HUD_HdgScale_origin.name)
HUD_Hdg_Cue_origin.element_params = {"HUD_HDG_CUE_MOVE", "HUD_HDG_CUE_VALUE"}
HUD_Hdg_Cue_origin.controllers = {{"move_left_right_using_parameter",0, hdgScaleTenDegreesStep/10/1000*move_scale}, {"parameter_in_range", 1, -0.05, 360}}
object = addStrokeSymbol("HUD_Hdg_Cue", {"f5em_stroke_symbols", "AA-DLZ-range"}, "RightCenter", {0, 0}, HUD_Hdg_Cue_origin.name)
object.init_rot = {-90}

-- heading index
object = addStrokeSymbol("HUD_HeadingScaleIndex", {"f5em_stroke_symbols", "AA-DLZ-range"}, "CenterCenter", {0, -9}, HUD_HdgScale_origin.name)
object.init_rot = {90}

-- Normal Acceleration
object = addStrokeText("HUD_NormalAccel", "     ", STROKE_FNT_DFLT_120, "LeftCenter", {-55, -71}, nil, nil, {"G %1.1f"})
object.element_params = {"HUD_NORMAL_ACCEL", "HUD_BRIGHT"}
object.controllers = {{"text_using_parameter",0,0}, {"opacity_using_parameter", 1}}

-- Peak G, right of the live G reading. HUD_MAX_ACCEL was already computed by
-- hud.lua but had no element, so the "+ max" half of the real Elbit G block
-- was missing. hud.lua publishes -1 outside its valid window, which hides it.
object = addStrokeText("HUD_MaxAccel", "     ", STROKE_FNT_DFLT_120, "LeftCenter", {-24, -71}, nil, nil, {"%1.1f"})
addDcltGate(object, 2, {"HUD_MAX_ACCEL", "HUD_BRIGHT"},
	{{"text_using_parameter",0,0}, {"parameter_in_range", 0, 0.05, 9.95}, {"opacity_using_parameter", 1}})


-- Weapon Ready
-- [F-5EM auto-lock 2026-07-08] Texto RDY / RDY-S / RDY-M por tipo de arma
-- (bate com convencao do jet real -- fotos 1o/14 GAV).
--   HUD_RDY = 1: "RDY"
--   HUD_RDY = 2: "RDY" + "S" (Sidewinder-class IR: Python 5 / MAA-1B)
--   HUD_RDY = 3: "RDY" + "M" (Medium radar: Derby)
object = addStrokeText("HUD_Rdy", "RDY", STROKE_FNT_DFLT_120, "CenterCenter", {-85, 75})
object.element_params = {"HUD_RDY", "HUD_BRIGHT"}
object.controllers = {{"parameter_in_range",0,0.95, 3.05}, {"opacity_using_parameter", 1}}

object = addStrokeText("HUD_Rdy_S", "S", STROKE_FNT_DFLT_120, "CenterCenter", {-70, 75})
object.element_params = {"HUD_RDY", "HUD_BRIGHT"}
object.controllers = {{"parameter_compare_with_number",0,2}, {"opacity_using_parameter", 1}}

object = addStrokeText("HUD_Rdy_M", "M", STROKE_FNT_DFLT_120, "CenterCenter", {-70, 75})
object.element_params = {"HUD_RDY", "HUD_BRIGHT"}
object.controllers = {{"parameter_compare_with_number",0,3}, {"opacity_using_parameter", 1}}

-- [F-5EM v0.61.3 2026-07-10] Range NM digital do alvo (STT hard-lock OU L&S bug BVR)
-- ABAIXO do RDY-S / RDY-M, bate com foto real 1o/14 GAV (foto 3: "RDY-S / 2.5").
-- Antes v0.61.3 o range ficava parented ao TD box (movia com alvo) e ao L&S marker
-- (idem). Agora e FIXO no canto sup-esq do HUD, junto do RDY -- mais legivel e nao
-- overlapa o alvo. Dois textos (STT + L&S) mutuamente exclusivos, gateados por
-- HUD_STT_SHOW / HUD_LS_SHOW (hud.lua garante que so um esta ativo por vez).
object = addStrokeText("HUD_Combat_Range_NearRdy", "    ", STROKE_FNT_DFLT_120, "CenterCenter", {-80, 60}, nil, nil, {"%2.1f"})
object.element_params = {"F5EM_COMBAT_TARGET_RANGE_VALID", "F5EM_COMBAT_TARGET_RANGE_NM", "HUD_BRIGHT"}
object.controllers = {
	{"parameter_compare_with_number", 0, 1},
	{"text_using_parameter", 1, 0},
	{"opacity_using_parameter", 2},
}

object = addStrokeText("HUD_Combat_Weapon_IR", "IR MSL", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {-95, -94})
object.element_params = {"F5EM_COMBAT_WEAPON_STATE", "HUD_BRIGHT"}
object.controllers = {{"parameter_compare_with_number", 0, 1}, {"opacity_using_parameter", 1}}
object = addStrokeText("HUD_Combat_Weapon_Radar", "DERBY", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {-95, -94})
object.element_params = {"F5EM_COMBAT_WEAPON_STATE", "HUD_BRIGHT"}
object.controllers = {{"parameter_compare_with_number", 0, 2}, {"opacity_using_parameter", 1}}

local combat_sensor_labels = {
	{1, "IR"}, {2, "RDR"}, {3, "RDR L&S"}, {4, "RDR STT"}, {5, "IR LOCK"},
	{6, "RDR RWS"}, {7, "RDR TWS"}, {8, "RDR VS"},
	{9, "RDR BORE"}, {10, "RDR VACQ"}, {11, "RDR AACQ"},
}
for _, sensor in ipairs(combat_sensor_labels) do
	object = addStrokeText("HUD_Combat_Sensor_"..sensor[1], sensor[2], STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {-95, -106})
	object.element_params = {"F5EM_COMBAT_SENSOR_STATE", "HUD_BRIGHT", "RADAR_ACQ_STATE", "RADAR_ACQ_REASON"}
	object.controllers = {
		{"parameter_in_range", 0, sensor[1] - 0.05, sensor[1] + 0.05},
		{"opacity_using_parameter", 1},
		{"parameter_in_range", 2, -0.05, 0.05},
		{"parameter_in_range", 3, -0.05, 0.05},
	}
end

object = addStrokeText("HUD_Radar_ACQ", "ACQ", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {-95, -106})
object.element_params = {"RADAR_ACQ_STATE", "HUD_BRIGHT"}
object.controllers = {{"parameter_in_range", 0, 0.95, 1.05}, {"opacity_using_parameter", 1}}

object = addStrokeText("HUD_Radar_NoLock", "NO LOCK", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {-95, -106})
object.element_params = {"RADAR_ACQ_STATE", "HUD_BRIGHT", "RADAR_ACQ_REASON"}
object.controllers = {
	{"parameter_in_range", 0, 1.95, 2.05},
	{"opacity_using_parameter", 1},
	{"parameter_in_range", 2, -0.05, 0.05},
}

local radar_reason_labels = {
	{1, "CUE",       -0.05, 0.05},
	{2, "NO TGT",     1.95, 2.05},
	{3, "NO ACK",     1.95, 2.05},
	{4, "LOCK LOST", -0.05, 0.05},
	{5, "FRIEND",    -0.05, 0.05},
}
for _, reason in ipairs(radar_reason_labels) do
	object = addStrokeText("HUD_Radar_Reason_"..reason[1], reason[2],
		STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {-95, -106})
	object.element_params = {"RADAR_ACQ_REASON", "HUD_BRIGHT", "RADAR_ACQ_STATE"}
	object.controllers = {
		{"parameter_in_range", 0, reason[1] - 0.05, reason[1] + 0.05},
		{"opacity_using_parameter", 1},
		{"parameter_in_range", 2, reason[3], reason[4]},
	}
end

-- [F-5EM 2026-07-20] INT M DLZ range readout (RMAX/RNE/RMIN) as a standalone
-- right-column stack above AL, in the SAME page root as AL/TTG so they align
-- and render reliably (the DLZ scale bar itself stays in HUD_AA_INT.lua).
-- Gated to INT M + a valid DLZ (HUD_DLZ_MAX in range) + ready state, matching
-- when the envelope is active. Numeric params + numeric formats only.
object = addStrokeText("HUD_INTM_RMAX", "RMAX 00.0", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {55, -82}, nil, nil, {"RMAX %2.1f"})
object.element_params = {"HUD_BRIGHT", "HUD_DLZ_MAX_NM", "HUD_DLZ_MAX", "F5EM_COMBAT_READY_STATE", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"parameter_in_range", 2, -0.001, 1.001},
	{"parameter_in_range", 3, 0.5, 2.5},
	{"parameter_in_range", 4, AVIONICS_MASTER_MODE_ID.INT_M - 0.5, AVIONICS_MASTER_MODE_ID.INT_M + 0.5},
}
object = addStrokeText("HUD_INTM_RNE", "RNE 00.0", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {55, -94}, nil, nil, {"RNE %2.1f"})
object.element_params = {"HUD_BRIGHT", "HUD_DLZ_BEST_NM", "HUD_DLZ_MAX", "F5EM_COMBAT_READY_STATE", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"parameter_in_range", 2, -0.001, 1.001},
	{"parameter_in_range", 3, 0.5, 2.5},
	{"parameter_in_range", 4, AVIONICS_MASTER_MODE_ID.INT_M - 0.5, AVIONICS_MASTER_MODE_ID.INT_M + 0.5},
}
object = addStrokeText("HUD_INTM_RMIN", "RMIN 00.0", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {55, -106}, nil, nil, {"RMIN %2.1f"})
object.element_params = {"HUD_BRIGHT", "HUD_DLZ_MIN_NM", "HUD_DLZ_MAX", "F5EM_COMBAT_READY_STATE", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"parameter_in_range", 2, -0.001, 1.001},
	{"parameter_in_range", 3, 0.5, 2.5},
	{"parameter_in_range", 4, AVIONICS_MASTER_MODE_ID.INT_M - 0.5, AVIONICS_MASTER_MODE_ID.INT_M + 0.5},
}

object = addStrokeText("HUD_Combat_Altitude", "          ", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {55, -118}, nil, nil, {"AL %05.0f"})
object.element_params = {"HUD_BRIGHT", "F5EM_COMBAT_TARGET_ALT_FT", "F5EM_COMBAT_TARGET_ALT_VALID", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"parameter_in_range", 3, AVIONICS_MASTER_MODE_ID.INT_S - 0.5, AVIONICS_MASTER_MODE_ID.DGFT_M + 0.5},
}

-- [F-5EM INT/DGFT stack 2026-07-20] Per the updated reference (image 2), the
-- intercept data forms one clean right-side stack: RMAX/RNE/RMIN (INT M DLZ, in
-- HUD_AA_INT.lua) above AL (target altitude) above TTG (waypoint time-to-go).
-- At the user's request the old lower-left NAV box (NAV/HDG/CRS/DMG) and the VC
-- closure line were removed. TTG keeps its real source (CMFD_NAV_FYT_DTK_MINS/
-- SECS -- same as the CMFD NAV/FYT page) and its combat-mode + valid-flight-
-- point gate, now positioned below AL on the right column.
object = addStrokeText("HUD_Combat_NAV_TTG", "         ", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {55, -130}, nil, nil, {"TTG %02.0f:", "%02.0f"})
object.element_params = {"HUD_BRIGHT", "CMFD_NAV_FYT_DTK_MINS", "CMFD_NAV_FYT_DTK_SECS", "CMFD_NAV_FYT_VALID", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"text_using_parameter", 2, 1},
	{"parameter_in_range", 3, 0.95, 1.05},
	{"parameter_in_range", 4, AVIONICS_MASTER_MODE_ID.INT_S - 0.5, AVIONICS_MASTER_MODE_ID.DGFT_M + 0.5},
}

-- [F-5EM 2026-08-29] Intercept time-to-go. Derived in combat_display.lua from
-- the validated target range and closure (the same range/closure arithmetic
-- the CMFD RDR page uses for HPT TTT), so it is real intercept telemetry and
-- not the waypoint TTG above it. Hidden whenever the target is not closing.
object = addStrokeText("HUD_Combat_TTI", "        ", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {55, -142}, nil, nil, {"TTI %03.0f"})
object.element_params = {"HUD_BRIGHT", "F5EM_COMBAT_TARGET_TTI_SEC", "F5EM_COMBAT_TARGET_TTI_VALID", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"parameter_in_range", 3, AVIONICS_MASTER_MODE_ID.INT_S - 0.5, AVIONICS_MASTER_MODE_ID.DGFT_M + 0.5},
}

object = addStrokeText("HUD_FLIR_Range", "    ", STROKE_FNT_DFLT_120, "CenterCenter", {80, 60}, nil, nil, {"%2.1f"})
object.element_params = {"HUD_FLIR_SHOW", "HUD_FLIR_RANGE_NM", "HUD_BRIGHT"}
object.controllers = {
	{"parameter_in_range", 0, 0.5, 2.5},
	{"text_using_parameter", 1, 0},
	{"opacity_using_parameter", 2},
}

object = addStrokeText("HUD_FLIR_Laser_Armed", "L ARM", STROKE_FNT_DFLT_120, "CenterCenter", {78, 75})
object.element_params = {"HUD_FLIR_LASER_STATE", "HUD_BRIGHT"}
object.controllers = { {"parameter_in_range", 0, 0.5, 1.5}, {"opacity_using_parameter", 1} }

object = addStrokeText("HUD_FLIR_Laser_Firing", "LASE", STROKE_FNT_DFLT_120, "CenterCenter", {78, 75})
object.element_params = {"HUD_FLIR_LASER_STATE", "HUD_BRIGHT"}
object.controllers = { {"parameter_in_range", 0, 1.5, 2.5}, {"opacity_using_parameter", 1} }

-- [F-5EM 2026-08-29] Laser code readback ("LSR 1688"). Same source and gate as
-- the CMFD SMS page (WPN_LASER_CODE + WPN_LASER_SELECTED), so the pilot can
-- confirm the PRF against the JTAC call without leaving the HUD.
object = addStrokeText("HUD_Laser_Code", "        ", STROKE_FNT_DFLT_100_NARROW, "CenterCenter", {78, 88}, nil, nil, {"LSR %04.0f"})
addDcltGate(object, 2, {"HUD_BRIGHT", "HUD_LASER_CODE", "HUD_LASER_CODE_SHOW"}, {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"parameter_in_range", 2, 0.95, 1.05},
})

object = addStrokeText("HUD_FLIR_Laser_Inhibit", "L INH", STROKE_FNT_DFLT_120, "CenterCenter", {78, 75})
object.element_params = {"HUD_FLIR_LASER_STATE", "HUD_BRIGHT"}
object.controllers = { {"parameter_in_range", 0, 2.5, 3.5}, {"opacity_using_parameter", 1} }


-- DOI
object = addStrokeSymbol("HUD_Doi", {"f5em_stroke_symbols", "hud-doi"}, "FromSet", {94, 45})
addDcltGate(object, 1, {"HUD_DOI", "HUD_BRIGHT"},
	{{"parameter_compare_with_number",0,1}, {"opacity_using_parameter", 1}})

-- Radar altitude and configured minimum. State 0/2/3 deliberately renders
-- source status instead of leaving a valid-looking empty box.
local HUD_RALT_valid = addPlaceholder("HUD_RALT_valid", {0, 0})
HUD_RALT_valid.element_params = {"HUD_RALT_STATE"}
HUD_RALT_valid.controllers = {{"parameter_in_range", 0, 0.5, 1.5}}
addStrokeText("HUD_Radar_Alt_R", "R", STROKE_FNT_DFLT_120, "CenterCenter", {60, -60}, HUD_RALT_valid.name)
addStrokeBox("HUD_Radar_Alt_Box", 30, 11, "CenterCenter", {85, -60}, HUD_RALT_valid.name)
object = addStrokeText("HUD_Radar_Alt", "    ", STROKE_FNT_DFLT_120, "CenterCenter", {85, -60}, HUD_RALT_valid.name, nil, {"%04.0f"})
object.element_params = {"HUD_RADAR_ALT", "HUD_BRIGHT"}
object.controllers = {{"text_using_parameter", 0, 0}, {"opacity_using_parameter", 1}}

object = addStrokeText("HUD_Radar_Alt_Off", "R OFF", STROKE_FNT_DFLT_120, "CenterCenter", {82, -60})
object.element_params = {"HUD_RALT_STATE", "HUD_BRIGHT"}
object.controllers = {{"parameter_in_range", 0, -0.05, 0.05}, {"opacity_using_parameter", 1}}
object = addStrokeText("HUD_Radar_Alt_High", "R HI", STROKE_FNT_DFLT_120, "CenterCenter", {82, -60})
object.element_params = {"HUD_RALT_STATE", "HUD_BRIGHT"}
object.controllers = {{"parameter_in_range", 0, 1.95, 2.05}, {"opacity_using_parameter", 1}}
object = addStrokeText("HUD_Radar_Alt_Invalid", "R --", STROKE_FNT_DFLT_120, "CenterCenter", {82, -60})
object.element_params = {"HUD_RALT_STATE", "HUD_BRIGHT"}
object.controllers = {{"parameter_in_range", 0, 2.95, 3.05}, {"opacity_using_parameter", 1}}

object = addStrokeText("HUD_Radar_Alt_Min", "AL 500", STROKE_FNT_DFLT_120, "CenterCenter", {82, -73}, nil, nil, {"AL %03.0f"})
object.element_params = {"HUD_RALT_MIN", "HUD_RALT_STATE", "HUD_BRIGHT"}
object.controllers = {{"text_using_parameter", 0, 0}, {"parameter_in_range", 1, 0.5, 2.5}, {"opacity_using_parameter", 2}}
object = addStrokeBox("HUD_Radar_Alt_Min_Alert", 30, 11, "CenterCenter", {82, -73})
object.element_params = {"HUD_RALT_ALERT", "HUD_BRIGHT"}
object.controllers = {{"parameter_compare_with_number", 0, 1}, {"opacity_using_parameter", 1}}

-- Range indicator
object = addStrokeText("HUD_Range", "    ", STROKE_FNT_DFLT_120, "CenterCenter", {75, -77}, nil, nil, {"%.0f"})
addDcltGate(object, 2, {"HUD_RANGE", "AVIONICS_MASTER_MODE", "HUD_BRIGHT"},
	{{"text_using_parameter", 0, 0}, {"parameter_in_range",0,-0.05, 9999}, {"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.GUN - 0.5, AVIONICS_MASTER_MODE_ID.GUN_M + 0.5}, {"opacity_using_parameter", 2}})

local HUD_NAV_Data = addPlaceholder("HUD_NAV_Data", {0, 0})
HUD_NAV_Data.element_params = {"AVIONICS_MASTER_MODE"}
HUD_NAV_Data.controllers = {{"parameter_in_range", 0, AVIONICS_MASTER_MODE_ID.NAV - 0.05, AVIONICS_MASTER_MODE_ID.LANDING + 0.05}}

-- Time indicator: also carries the CCRP/CCIP-DELAYED release countdown and
-- the post-release TTI, so it must remain outside HUD_NAV_Data (which only
-- draws in NAV..LANDING). Placed at the same screen position.
-- [F-5EM 2026-08-29] Rebuilt on numeric params. The single element that read
-- HUD_TIME through a `%s` format never rendered in DCS 2.9.27 (the dynamic
-- string path already proven dead for the CCRP TTG). hud.lua now publishes
-- HUD_TIME_MODE/H/M/S and the five mutually exclusive forms below consume it.
local HUD_TIME_FORMS = {
	{ name = "HUD_Time_MMSS", mode = 1, blank = "        ",
	  formats = {"%02.0f:", "%02.0f"}, fields = {"HUD_TIME_M", "HUD_TIME_S"} },
	{ name = "HUD_Time_CCIP", mode = 2, blank = "      ",
	  formats = {"T %02.0f"}, fields = {"HUD_TIME_S"} },
	{ name = "HUD_Time_Ahead", mode = 3, blank = "          ",
	  formats = {"A %02.0f:", "%02.0f"}, fields = {"HUD_TIME_M", "HUD_TIME_S"} },
	{ name = "HUD_Time_Late", mode = 4, blank = "          ",
	  formats = {"D %02.0f:", "%02.0f"}, fields = {"HUD_TIME_M", "HUD_TIME_S"} },
	{ name = "HUD_Time_ETA", mode = 5, blank = "           ",
	  formats = {"%02.0f:", "%02.0f:", "%02.0f"}, fields = {"HUD_TIME_H", "HUD_TIME_M", "HUD_TIME_S"} },
}
for _, form in ipairs(HUD_TIME_FORMS) do
	object = addStrokeText(form.name, form.blank, STROKE_FNT_DFLT_120, "LeftCenter", {-55, -100}, nil, nil, form.formats)
	local params = {"HUD_BRIGHT", "HUD_TIME_MODE"}
	local ctrls = {
		{"opacity_using_parameter", 0},
	}
	for i, field in ipairs(form.fields) do
		params[#params + 1] = field
		ctrls[#ctrls + 1] = {"text_using_parameter", #params - 1, i - 1}
	end
	ctrls[#ctrls + 1] = {"parameter_in_range", 1, form.mode - 0.05, form.mode + 0.05}
	addDcltGate(object, 1, params, ctrls)
end

-- Live aircraft-to-waypoint distance in NM (DME). Gated directly on
-- AVIONICS_MASTER_MODE (NAV..LANDING) with parent=nil: the HUD_NAV_Data
-- placeholder parent did not render its children in-game, whereas the
-- proven parent=nil + direct mode-gate pattern (see HUD_Gun_Ammo) works.
-- The validity gate prevents a plausible-looking zero when no flight point
-- is selected.
object = addStrokeText("HUD_Waypoint_Distance", "        ", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {-55, -84}, nil, nil, {"WP %1.1f"})
object.element_params = {"HUD_BRIGHT", "CMFD_NAV_FYT_DTK_DIST", "CMFD_NAV_FYT_VALID", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"parameter_in_range", 3, AVIONICS_MASTER_MODE_ID.NAV - 0.05, AVIONICS_MASTER_MODE_ID.LANDING + 0.05},
}

-- [F-5EM NAV data block 2026-07-20] CRS / GS / TTG on the lower-right, matching
-- the F-5EM (Grifo-F) NAV HUD reference. Numeric params + numeric formats only
-- (no %s dynamic-string crash path). Each element is gated directly on
-- AVIONICS_MASTER_MODE (NAV..LANDING) using the proven parent=nil pattern;
-- CRS/TTG also require a valid flight point. GS is own-ship ground speed
-- (always shown in NAV/LANDING). Placeholders are spaces so nothing false
-- renders before real data arrives. Placed below the radar-altimeter R/AL
-- block to avoid overlap.
object = addStrokeText("HUD_NAV_CRS", "       ", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {52, -84}, nil, nil, {"CRS %03.0f"})
object.element_params = {"HUD_BRIGHT", "CMFD_NAV_FYT_DTK_BRG_TEXT", "CMFD_NAV_FYT_VALID", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"parameter_in_range", 3, AVIONICS_MASTER_MODE_ID.NAV - 0.05, AVIONICS_MASTER_MODE_ID.LANDING + 0.05},
}

object = addStrokeText("HUD_NAV_GS", "      ", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {52, -96}, nil, nil, {"GS %03.0f"})
object.element_params = {"HUD_BRIGHT", "HUD_GS", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"parameter_in_range", 1, -0.05, 2000.05},
	{"parameter_in_range", 2, AVIONICS_MASTER_MODE_ID.NAV - 0.05, AVIONICS_MASTER_MODE_ID.LANDING + 0.05},
}

object = addStrokeText("HUD_NAV_TTG", "         ", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {52, -108}, nil, nil, {"TTG %02.0f:", "%02.0f"})
object.element_params = {"HUD_BRIGHT", "CMFD_NAV_FYT_DTK_MINS", "CMFD_NAV_FYT_DTK_SECS", "CMFD_NAV_FYT_VALID", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"text_using_parameter", 2, 1},
	{"parameter_in_range", 3, 0.95, 1.05},
	{"parameter_in_range", 4, AVIONICS_MASTER_MODE_ID.NAV - 0.05, AVIONICS_MASTER_MODE_ID.LANDING + 0.05},
}

-- VOR/DME
-- [F-5EM 2026-08-29] Moved off the HUD_NAV_Data placeholder parent, which does
-- not render its children (same failure as the 2026-07-20 NAV block), onto the
-- proven parent=nil + direct AVIONICS_MASTER_MODE gate. hud.lua now feeds
-- HUD_VOR_DIST/HUD_VOR_MAG from the ADHSI receiver instead of a hardcoded -1,
-- so this is the aircraft's real DME readout.
object = addStrokeText("HUD_VOR", "       ", STROKE_FNT_DFLT_120, "CenterCenter", {80, -120}, nil, nil, {"%2.1fV","%03.0f"})
addDcltGate(object, 1, {"HUD_VOR_DIST", "HUD_VOR_MAG", "HUD_BRIGHT", "AVIONICS_MASTER_MODE"}, {
	{"text_using_parameter", 0, 0},
	{"text_using_parameter", 1, 1},
	{"parameter_in_range", 0, -0.05, 99.94},
	{"opacity_using_parameter", 2},
	{"parameter_in_range", 3, AVIONICS_MASTER_MODE_ID.NAV - 0.05, AVIONICS_MASTER_MODE_ID.LANDING + 0.05},
})

object = addStrokeText("HUD_VOR_100", "       ", STROKE_FNT_DFLT_120, "CenterCenter", {80, -120}, nil, nil, {"%3.0fV","%03.0f"})
addDcltGate(object, 1, {"HUD_VOR_DIST", "HUD_VOR_MAG", "HUD_BRIGHT", "AVIONICS_MASTER_MODE"}, {
	{"text_using_parameter", 0, 0},
	{"text_using_parameter", 1, 1},
	{"parameter_in_range", 0, 99.95, 999.5},
	{"opacity_using_parameter", 2},
	{"parameter_in_range", 3, AVIONICS_MASTER_MODE_ID.NAV - 0.05, AVIONICS_MASTER_MODE_ID.LANDING + 0.05},
})

-- Bullseye BRA ("BE 090/25.3"): bearing and range from the mission bullseye
-- (DTC waypoint 99) to the own-ship, published by tactical_overlay.lua and
-- converted in hud.lua. Available in every master mode -- it is the reference
-- used for GCI/AWACS calls -- and hidden until a bullseye is actually defined.
object = addStrokeText("HUD_Bullseye", "            ", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {-95, -130}, nil, nil, {"BE %03.0f/", "%2.1f"})
addDcltGate(object, 2, {"HUD_BRIGHT", "HUD_BE_BRG", "HUD_BE_RNG_NM", "HUD_BE_SHOW"}, {
	{"opacity_using_parameter", 0},
	{"text_using_parameter", 1, 0},
	{"text_using_parameter", 2, 1},
	{"parameter_in_range", 3, 0.95, 1.05},
})

-- MACH
object = addStrokeText("HUD_Mach", "      ", STROKE_FNT_DFLT_120, "LeftCenter", {-55, -58}, nil, nil, {"M %1.2f"})
object.element_params = {"HUD_MACH", "HUD_BRIGHT"}
object.controllers = {{"text_using_parameter",0,0}, {"parameter_in_range",0,-0.05,2}, {"opacity_using_parameter", 1}}

-- Mode remains fixed like the reference layout; it must not move with FPM.
object = addStrokeText("HUD_Mode_Fixed", "", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {-95, -82}, nil, nil, {"%s"})
object.element_params = {"AVIONICS_MASTER_MODE_TXT", "HUD_BRIGHT"}
object.controllers = {{"text_using_parameter",0,0}, {"opacity_using_parameter", 1}}

-- AoA
object = addStrokeText("HUD_AoA", "     ", STROKE_FNT_DFLT_120, "LeftCenter", {-55, -45}, nil, nil, {"A %3.1f"})
addDcltGate(object, 2, {"HUD_AOA", "HUD_BRIGHT"},
	{{"text_using_parameter",0,0}, {"parameter_in_range", 0, -9.1, 40.1}, {"opacity_using_parameter", 1}})

-- WARNING
object = addStrokeText("HUD_WARN", "WARN", STROKE_FNT_DFLT_120, "CenterCenter", {0, 0})
object.element_params = {"HUD_WARNING", "HUD_BRIGHT"}
object.controllers = {{"parameter_compare_with_number", 0, 1}, {"opacity_using_parameter", 1}}

-- ★ 2026-07-06 Elbit F-5EM annunciators (STALL / BRK-X / BINGO / SHOOT).
-- Driven by hud.lua _HUD_WARN block (blink cadence baked into published value).
-- STALL: below WARN, indicates AoA past LMT limit
object = addStrokeText("HUD_STALL_WARN", "STALL", STROKE_FNT_DFLT_120, "CenterCenter", {0, -35})
object.element_params = {"HUD_STALL_WARN", "HUD_BRIGHT"}
object.controllers = {{"parameter_compare_with_number", 0, 1}, {"opacity_using_parameter", 1}}

-- [F-5EM 2026-08-29] OVSPD: below STALL. AVIONICS_OVERSPEED (IAS past max_vel
-- or Mach past max_mach, Systems/limit_check.lua) already drove the PFL page
-- but had no HUD annunciator, leaving the third limit-exceedance flag missing.
object = addStrokeText("HUD_OVSPD_WARN", "OVSPD", STROKE_FNT_DFLT_120, "CenterCenter", {0, -50})
object.element_params = {"HUD_OVSPD_WARN", "HUD_BRIGHT"}
object.controllers = {{"parameter_in_range", 0, 0.95, 1.05}, {"opacity_using_parameter", 1}}

-- OVER-G / BRK-X: above WARN, indicates normal accel past LMT limit
object = addStrokeText("HUD_OVERG_WARN", "BRK-X", STROKE_FNT_DFLT_120, "CenterCenter", {0, 35})
object.element_params = {"HUD_OVERG_WARN", "HUD_BRIGHT"}
object.controllers = {{"parameter_compare_with_number", 0, 1}, {"opacity_using_parameter", 1}}

-- [F-5EM 2026-08-29] Dedicated missile-launch flag, above BRK-X. Driven by the
-- RWR launch detection (RWR_LAUNCH_AZ_VALID) that already feeds the EW page;
-- hud.lua bakes the 2 Hz cadence into the published value. parameter_in_range
-- is used because parameter_compare_with_number does not reliably hide.
object = addStrokeText("HUD_LAUNCH_WARN", "LAUNCH", STROKE_FNT_DFLT_120, "CenterCenter", {0, 50})
object.element_params = {"HUD_LAUNCH_WARN", "HUD_BRIGHT"}
object.controllers = {{"parameter_in_range", 0, 0.95, 1.05}, {"opacity_using_parameter", 1}}

-- BINGO fuel advisory: center-below FPM (bate com fotos reais 1o/14 GAV,
-- em vez do canto superior-esquerdo onde piloto nao ve em combate).
-- Trigger: fuel < BINGO_FUEL_KG (default 800 kg, config em tactical_overlay.lua).
local HUD_BINGO_origin = addPlaceholder("HUD_BINGO_origin", {0, 0})
HUD_BINGO_origin.element_params = {"HUD_FPM_SLIDE", "HUD_FPM_VERT"}
HUD_BINGO_origin.controllers = {
	{"move_left_right_using_parameter", 0, move_scale},
	{"move_up_down_using_parameter", 1, move_scale},
}
object = addStrokeText("HUD_BINGO_WARN", "BINGO", STROKE_FNT_DFLT_120, "CenterCenter", {0, -50}, HUD_BINGO_origin.name)
object.element_params = {"HUD_BINGO_WARN", "HUD_BRIGHT"}
object.controllers = {{"parameter_compare_with_number", 0, 1}, {"opacity_using_parameter", 1}}

-- SHOOT cue: upper-right of FPM, solid (rdr.lua only sets it in TWS+L&S+NEZ)
object = addStrokeText("HUD_SHOOT_WARN", "SHOOT", STROKE_FNT_DFLT_120, "CenterCenter", {100, 70})
object.element_params = {"HUD_SHOOT_WARN", "HUD_BRIGHT", "F5EM_IR_NO_LOCK", "F5EM_IR_AWAY"}
object.controllers = {{"parameter_compare_with_number", 0, 1}, {"opacity_using_parameter", 1},
	{"parameter_in_range", 2, -0.05, 0.05}, {"parameter_in_range", 3, -0.05, 0.05}}

-- [F-5EM auto-lock 2026-07-08] IN RNG cue: aparece embaixo do SHOOT quando
-- alvo esta em range (Rmax > alvo > NEZ) mas ainda pode escapar. Real F-5EM
-- distingue "em alcance" de "tiro garantido" -- Rmax = alcance maximo do
-- Derby, NEZ = zona sem escape (garantido).
object = addStrokeText("HUD_IN_RNG_WARN", "IN RNG", STROKE_FNT_DFLT_120, "CenterCenter", {100, 55})
object.element_params = {"HUD_IN_RNG_WARN", "HUD_BRIGHT", "F5EM_IR_NO_LOCK", "F5EM_IR_AWAY"}
object.controllers = {{"parameter_compare_with_number", 0, 1}, {"opacity_using_parameter", 1},
	{"parameter_in_range", 2, -0.05, 0.05}, {"parameter_in_range", 3, -0.05, 0.05}}

object = addStrokeText("HUD_IR_NoLock", "NO LOCK", STROKE_FNT_DFLT_100_NARROW, "CenterCenter", {100, 55})
object.element_params = {"F5EM_IR_NO_LOCK", "HUD_BRIGHT"}
object.controllers = {{"parameter_in_range", 0, 0.95, 1.05}, {"opacity_using_parameter", 1}}
object = addStrokeText("HUD_IR_Away", "IR AWAY", STROKE_FNT_DFLT_100_NARROW, "CenterCenter", {100, 55})
object.element_params = {"F5EM_IR_AWAY", "HUD_BRIGHT"}
object.controllers = {{"parameter_in_range", 0, 0.95, 1.05}, {"opacity_using_parameter", 1}}

-- MG (contador de municao do canhao). Aparece em TODAS as paginas/master
-- modes (NAV..GUN_M), canto esquerdo. Fonte WPN_AA_INTRG_QTY agora e publicada
-- todo frame pelo weapon_system.update_storages(), entao o valor e valido fora
-- de combate tambem (nao mais 0/stale em NAV/LANDING/INT).
object = addStrokeText("HUD_Gun_Ammo", "MG 500", STROKE_FNT_DFLT_100_NARROW, "LeftCenter", {-95, -118}, nil, nil, {"MG %03.0f"})
object.element_params = {"HUD_BRIGHT", "WPN_AA_INTRG_QTY", "AVIONICS_MASTER_MODE"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"text_using_parameter", 1, 0}, 
	{"parameter_in_range",2,AVIONICS_MASTER_MODE_ID.NAV-0.5, AVIONICS_MASTER_MODE_ID.GUN_M + 0.5},
}

-- A/A target-locator lines. STT has priority in every A/A mode; seeker
-- lock lines are limited to the two IR modes and disappear on hard lock.
object = addSimpleLine("HUD_AA_STT_TLL", 10, {0, 0}, 0, nil, nil, 0.5, HUD_MAT_DEF)
object.element_params = {
	"HUD_BRIGHT", "AVIONICS_MASTER_MODE", "HUD_STT_SHOW",
	"HUD_FPM_SLIDE", "HUD_FPM_VERT", "HUD_STT_AZ", "HUD_STT_EL",
}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.INT_S - 0.5, AVIONICS_MASTER_MODE_ID.DGFT_M + 0.5},
	{"parameter_in_range", 2, 0.5, 2.5},
	{"line_object_set_point_using_parameters", 0, 3, 4, move_scale, move_scale},
	{"line_object_set_point_using_parameters", 1, 5, 6, move_scale, move_scale},
}

local function addIrTargetLocatorLine(name, mode)
	local line = addSimpleLine(name, 10, {0, 0}, 0, nil, nil, 0.5, HUD_MAT_DEF)
	line.element_params = {
		"HUD_BRIGHT", "AVIONICS_MASTER_MODE", "HUD_STT_SHOW", "HUD_IR_LOCK_BLINK",
		"HUD_FPM_SLIDE", "HUD_FPM_VERT",
		"HUD_IR_MISSILE_TARGET_AZIMUTH", "HUD_IR_MISSILE_TARGET_ELEVATION",
	}
	line.controllers = {
		{"opacity_using_parameter", 0},
		{"parameter_compare_with_number", 1, mode},
		{"parameter_compare_with_number", 2, 0},
		{"parameter_compare_with_number", 3, 1},
		{"line_object_set_point_using_parameters", 0, 4, 5, move_scale, move_scale},
		{"line_object_set_point_using_parameters", 1, 6, 7, move_scale, move_scale},
	}
end

addIrTargetLocatorLine("HUD_AA_INT_S_TLL", AVIONICS_MASTER_MODE_ID.INT_S)
addIrTargetLocatorLine("HUD_AA_DGFT_S_TLL", AVIONICS_MASTER_MODE_ID.DGFT_S)

local function addRadarMissileReference(name, mode)
	local reference = addStrokeSymbol(name, {"f5em_stroke_symbols", "aim9lm-caged"}, "CenterCenter", {0, 0})
	reference.element_params = {"HUD_BRIGHT", "AVIONICS_MASTER_MODE", "WPN_SELECTED_WEAPON_TYPE", "WPN_READY", "HUD_STT_SHOW"}
	reference.controllers = {
		{"opacity_using_parameter", 0},
		{"parameter_in_range", 1, mode - 0.05, mode + 0.05},
		{"parameter_in_range", 2, WPN_WEAPON_TYPE_IDS.AA_MISSILE - 0.05, WPN_WEAPON_TYPE_IDS.AA_MISSILE + 0.05},
		{"parameter_in_range", 3, 0.95, 1.05},
		{"parameter_in_range", 4, -0.05, 0.05},
	}
	return reference
end

addRadarMissileReference("HUD_INT_Radar_Search_Diamond", AVIONICS_MASTER_MODE_ID.INT_M)
addRadarMissileReference("HUD_DGFT_Radar_Search_Diamond", AVIONICS_MASTER_MODE_ID.DGFT_M)

-- Radar STT
-- [F-5EM fix 2026-07-09] Controller gate corrigido: era 4-arg
-- {parameter_compare_with_number, 3, 0, 1} -- unico uso no arquivo, forma
-- invalida (funcao aceita so 2 args), TD box FALHAVA em silencio e nunca
-- aparecia mesmo com STT ativo. Alinhado com o triangulo de aspecto (mesmo
-- bloco) que usa parameter_in_range com STT_SHOW em [0.5, 2.5] = 1 (lock)
-- ou 2 (lock offset borda do HUD).
-- [F-5EM v0.61.3 2026-07-10] TD box redesenhado p/ bater com fotos reais do
-- 1o/14 GAV (jet real Elbit Grifo-F). Mudancas vs v0.61.1:
--   * Tamanho: 25x25 mils (era ~14x14 do SVG td-box). Foto 3 do jet real mostra
--     alvo (silhueta de aviao) VISIVEL DENTRO da box em 2.5 NM.
--   * Triangulo aspecto: ABAIXO da box (Y=-18 mils) -- era acima {0,0} v0.61.1.
--     Convencao Elbit real (Kfir/Cheetah/F-5M FAB) triangulo pequeno abaixo
--     da borda inferior, sem cobrir o alvo dentro da box.
--   * Range NM digital: REMOVIDO daqui, movido p/ area do RDY (foto real mostra
--     range junto do RDY-S / RDY-M, nao junto da TD box).
-- addStrokeBox inline substitui SVG td-box p/ facilitar ajuste futuro sem editar
-- a29b_stroke_symbols_HUD.svg. Object com nome explicito (HUD_STT_TDBox) p/ os
-- children (triangulo, fpm-cross) serem reparented sem depender do encadeamento
-- object.name -> object.name (que quebrava ao remover elementos intermediarios).
object = addStrokeBox("HUD_STT_TDBox", 25, 25, "CenterCenter", {0, 0})
object.element_params = {"HUD_BRIGHT", "HUD_STT_AZ", "HUD_STT_EL", "HUD_STT_SHOW"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"move_left_right_using_parameter", 1, move_scale},
	{"move_up_down_using_parameter", 2, move_scale},
	{"parameter_in_range", 3, 0.5, 2.5}
}

object = addStrokeSymbol("HUD_Radar_Missile_Diamond", {"f5em_stroke_symbols", "aim120-diamond"}, "CenterCenter", {0, 0}, "HUD_STT_TDBox")
object.element_params = {"HUD_BRIGHT", "WPN_SELECTED_WEAPON_TYPE", "HUD_STT_SHOW"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"parameter_in_range", 1, WPN_WEAPON_TYPE_IDS.AA_MISSILE - 0.05, WPN_WEAPON_TYPE_IDS.AA_MISSILE + 0.05},
	{"parameter_in_range", 2, 0.5, 2.5},
}

-- [F-5EM v0.61.3 2026-07-10] Triangulo aspecto ABAIXO da box (Y=-18 mils).
-- Antes v0.61.3 ficava sobre o centro da box {0,0}, cobrindo o alvo dentro dela.
-- Foto 3 real 1o/14 GAV: triangulo pequeno logo abaixo da borda inferior. Rotaciona
-- conforme HUD_STT_ASPECT = RADAR_STT_ANGLE = (plane_hdg - stt_hdg), publicado em
-- rdr.lua. Logo: 0 rad = alvo no MESMO rumo que o nosso = tail-on (simbolo na
-- orientacao base do SVG, apex p/ cima); +/-pi = nose-on (apex p/ baixo);
-- +/-pi/2 = beam. [2026-07-26] Comentario anterior dizia o inverso (0 = nose-on),
-- o que nao batia com a formula de rdr.lua:1435.
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "td-aspect-triangle"}, "CenterCenter", {0, -18}, "HUD_STT_TDBox")
object.element_params = {default_element_params, "HUD_STT_SHOW", "HUD_STT_ASPECT"}
object.controllers = {
	default_controllers[1],
	{"parameter_in_range", 1, 0.5, 2.5},
	{"rotate_using_parameter", 2, 1},
}

-- [F-5EM v0.61.3 2026-07-10] fpm-cross reparenteado direto para HUD_STT_TDBox
-- (era encadeado via triangulo -> range text no v0.61.1). Mostra X sobre a TD box
-- quando STT_SHOW==2 (alvo limitado a borda do HUD -- "off-screen indicator").
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, "HUD_STT_TDBox")
object.element_params = {default_element_params, "HUD_STT_SHOW"}
object.controllers = {
	default_controllers[1],
	{"parameter_compare_with_number", 1, 2}
}

-- [F-5EM v0.61.1 2026-07-10] L&S marker (BVR bug) -- distinto do TD box de STT.
-- Quadrado HOLLOW MENOR (10x10 mils vs ~14x14 do td-box de STT), SEM piscar,
-- SEM triangulo aspecto. Bate com convencao Elbit real (F-5M FAB / Kfir /
-- Cheetah / F-16 T-DIA): STT hard-lock = quadrado grande piscando; L&S bug
-- = marker menor solido. Aparece sobre a posicao do alvo TWS L&S quando ha
-- Derby armado (INT_M/DGFT_M) e NAO ha STT hard-lock (mutuamente exclusivo
-- com o TD box). Publicado por hud.lua bloco pos-STT (HUD_LS_AZ/EL/SHOW).
-- [F-5EM 2026-07-22 v2] Aumentado 10x10 -> 20x20 mils. Pedido do usuario:
-- quadrado deve ser bem visivel envolvendo o alvo (estilo F-15 TDD Bug),
-- nao ficar sumindo entre outras simbologias no centro do HUD.
-- Continua HOLLOW (sem preenchimento) via addStrokeBox.
object = addStrokeBox(nil, 20, 20, "CenterCenter", {0, 0})
object.element_params = {"HUD_BRIGHT", "HUD_LS_AZ", "HUD_LS_EL", "HUD_LS_SHOW"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"move_left_right_using_parameter", 1, move_scale},
	{"move_up_down_using_parameter", 2, move_scale},
	{"parameter_in_range", 3, 0.5, 2.5}
}
-- [F-5EM v0.61.3 2026-07-10] Range NM do L&S removido daqui; agora e desenhado
-- na area do RDY (HUD_LS_Range_NearRdy proximo ao HUD_Rdy_M), bate com foto
-- real 4 do jet Elbit (range digital abaixo do RDY, nao junto do marker BVR).

-- FLIR line of sight. The diamond is distinct from the CCIP piper and radar
-- track boxes; an X marks a target limited to the HUD border.
object = addStrokeSymbol("HUD_FLIR_LOS", {"f5em_stroke_symbols", "aim120-diamond"}, "CenterCenter", {0, 0})
object.element_params = {"HUD_BRIGHT", "HUD_FLIR_AZ", "HUD_FLIR_EL", "HUD_FLIR_SHOW"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"move_left_right_using_parameter", 1, move_scale},
	{"move_up_down_using_parameter", 2, move_scale},
	{"parameter_in_range", 3, 0.5, 2.5}
}
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, "HUD_FLIR_LOS")
object.element_params = {"HUD_BRIGHT", "HUD_FLIR_SHOW"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"parameter_in_range", 1, 1.5, 2.5}
}

-- [F-5EM Elbit 2026-07-09] SUITE do CIRCULO ASE do Elbit Grifo-F -- REDESENHADO
local derby_cues = dofile(LockOn_Options.script_path.."Systems/radar_engagement_sequence.lua").CUE_TEXT
for index, label in ipairs(derby_cues) do
	object = addStrokeText("HUD_Derby_Cue_"..index, label, STROKE_FNT_DFLT_100_NARROW,
		"CenterCenter", {100, 55})
	object.element_params = {"HUD_BRIGHT", "F5EM_DERBY_CUE", "F5EM_IR_AWAY"}
	object.controllers = {{"opacity_using_parameter", 0},
		{"parameter_in_range", 1, index - 0.05, index + 0.05},
		{"parameter_in_range", 2, -0.05, 0.05}}
end

-- [F-5EM Elbit 2026-07-09] SUITE do CIRCULO ASE do Elbit Grifo-F -- REDESENHADO
-- p/ bater com fotos reais do 1o/14 GAV (video @fab_piloto_de_f5m TikTok):
--
-- Componentes no real jet (visiveis SEMPRE que em modo A/A):
--   1) Circulo ASE ~5 deg diametro (raio 2.5 deg) no FPM
--   2) 4 tick marks nos cardinais (12/3/6/9 h) sobre a borda
--   3) Chevron ">" apontando p/ centro (indicador de aspecto/ASE azim)
--   4) Triangulo ▽ pequeno logo ABAIXO do circulo (aspect indicator)
--   5) Steering dot dentro do circulo (segue erro azim do alvo lockado)
--   6) Circulo PISCA em cadencia lenta quando lock ativo (HUD_ASE_BLINK)
--
-- Removido: BORE circle pequeno (0.75 deg) -- nao existe no real jet,
-- era invencao minha. Real F-5EM tem SO 1 circulo ASE.
-- [F-5EM 2026-07-22 v2] MOVIDO DO FPM PARA O BORESIGHT (nariz, 0,0). Motivo:
-- o auto-lock (rdr.lua) agora e boresight-centrado. Para "alvo dentro do
-- circulo = alvo no cone de lock" (pedido MANDATORIO do usuario), o circulo
-- tem que estar ONDE o lock acontece = boresight. Antes o circulo seguia o
-- FPM (vetor de velocidade), que em manobra/look-down nao aponta pro alvo ->
-- alvo nunca no circulo -> nunca travava. Agora o piloto aponta o NARIZ
-- (gun cross) no alvo, o alvo entra no circulo e trava. Removidos os
-- controllers move_left_right/up_down (que ancoravam no FPM); o placeholder
-- fica fixo em (0,0) = boresight.
local HUD_ASE_origin = addPlaceholder("HUD_AutoLock_origin", {0, 0})
HUD_ASE_origin.element_params = {"HUD_ASE_BLINK", "AVIONICS_MASTER_MODE"}
HUD_ASE_origin.controllers = {
	-- HUD_ASE_BLINK vem do hud.lua ja gateado por A/A + brilho:
	--   0 = fora de A/A (some), 1 = solido, blink 1Hz = lock ativo
	{"opacity_using_parameter", 0},
	{"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.INT_S - 0.5, AVIONICS_MASTER_MODE_ID.DGFT_M + 0.5},
}

-- (1) Circulo ASE principal.
-- [F-5EM 2026-07-22] Raio 2.5 -> 5.0 deg (diametro 10 deg). O circulo de 2.5
-- era APERTADO DEMAIS na pratica: log F5EM_TDBOX mostrou o alvo mais proximo
-- do nariz a ~5.9 deg -- nunca caia dentro do cone de 2.5 -> STT auto-lock
-- NUNCA fechava. 5 deg = circulo utilizavel, o piloto voa o alvo pra dentro
-- e o lock fecha. O cone de auto-lock em rdr.lua (ASE_CIRCLE_RADIUS) casa
-- com este valor. Se ficar grande demais, reduzir ambos juntos.
local ASE_RAD_MIL = math.rad(5.0)*1000
addStrokeCircle("HUD_ASE_Circle", ASE_RAD_MIL, {0, 0}, HUD_ASE_origin.name)

-- (2) 4 tick marks nos cardinais 12/3/6/9 -- pequenas linhas radiais de
-- ~6 mils de comprimento, centradas na borda do circulo. Bate com fotos
-- reais onde ha 4 "chanfros" nos pontos cardinais.
local TICK_LEN = 6
-- 12h (topo): linha vertical acima da borda
addStrokeLine(nil, TICK_LEN, {0, ASE_RAD_MIL - TICK_LEN/2}, math.rad(90), HUD_ASE_origin.name)
-- 6h (baixo): linha vertical na borda inferior
addStrokeLine(nil, TICK_LEN, {0, -ASE_RAD_MIL - TICK_LEN/2}, math.rad(90), HUD_ASE_origin.name)
-- 3h (direita): linha horizontal na borda direita
addStrokeLine(nil, TICK_LEN, {ASE_RAD_MIL - TICK_LEN/2, 0}, 0, HUD_ASE_origin.name)
-- 9h (esquerda): linha horizontal na borda esquerda
addStrokeLine(nil, TICK_LEN, {-ASE_RAD_MIL - TICK_LEN/2, 0}, 0, HUD_ASE_origin.name)

-- (3) Chevron ">" no centro (indicador de aspecto azim do ASE).
-- Usa o symbol AA-DLZ-range que ja e um chevron da SVG lib.
addStrokeSymbol(nil, {"f5em_stroke_symbols", "AA-DLZ-range"}, "CenterCenter", {-8, 0}, HUD_ASE_origin.name)

-- (4) Triangulo ▽ pequeno logo ABAIXO do circulo (aspect indicator externo).
-- Usa o mesmo symbol td-aspect-triangle usado no TD box.
addStrokeSymbol(nil, {"f5em_stroke_symbols", "td-aspect-triangle"}, "CenterCenter", {0, -ASE_RAD_MIL - 4}, HUD_ASE_origin.name)

-- (5) Steering dot dentro do ASE (F-16 style). Ponto guiado por
-- RADAR_ASE_AZ_NORM (-0.5..0.5, erro azimutal do alvo lockado). Piloto
-- centra o ponto -> aponta no alvo. Publicado por rdr.lua so quando
-- alvo lockado (ASE_ACTIVE == 1). So aparece com lock ativo.
object = addStrokeSymbol("HUD_ASE_SteeringDot", {"f5em_stroke_symbols", "impact-point"}, "CenterCenter", {0, 0}, HUD_ASE_origin.name)
object.element_params = {"HUD_BRIGHT", "RADAR_ASE_ACTIVE", "RADAR_ASE_AZ_NORM"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"parameter_compare_with_number", 1, 1},
	{"move_left_right_using_parameter", 2, math.rad(5) * move_scale},
}

