dofile(LockOn_Options.script_path .. "HUD/Indicator/HUD_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/avionics_api.lua")
dofile(LockOn_Options.script_path .. "Systems/weapon_system_api.lua")

local object

local HUD_INT_ScaleRoot = create_hud_scaled_root("HUD_INT_ScaleRoot")
default_parent = HUD_INT_ScaleRoot.name

-- INT S
local HUD_INT_origin = addPlaceholder(nil, {0,0})
HUD_INT_origin.element_params = {"AVIONICS_MASTER_MODE", "WPN_MSL_CAGED"}
HUD_INT_origin.controllers = {
	{"parameter_in_range", 0, AVIONICS_MASTER_MODE_ID.INT_S - 0.05, AVIONICS_MASTER_MODE_ID.INT_S + 0.05},
	-- [F-5EM v0.61.8 2026-07-11] Range CAGED expandido de [-0.05, 1.05]
	-- para [-0.05, 2.05] p/ aceitar CAGED=2 (HOBS com HMD). Antes o
	-- parent origin escondia TUDO dentro (inclusive losango caged/uncaged)
	-- quando piloto ligava HMD -- bug silencioso desde que HMD foi
	-- introduzido no mod. Agora HOBS renderiza normalmente.
	{"parameter_in_range", 1, -0.05, 2.05},
}

-- IR Caged
object = addStrokeSymbol("HUD_INT_IR_Search_Diamond", {"f5em_stroke_symbols", "aim9lm-caged"}, "CenterCenter", {0, 0}, HUD_INT_origin.name)
object.element_params = {"HUD_BRIGHT", "WPN_MSL_CAGED", "HUD_IR_LOCK_BLINK",
    "WS_IR_MISSILE_SEEKER_DESIRED_AZIMUTH", "WS_IR_MISSILE_SEEKER_DESIRED_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, -0.05, 2.05},
	{"parameter_in_range", 2, -0.05, 0.05},
	{"move_left_right_using_parameter", 3, -move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
}

-- IR Uncaged
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "aim9lm-uncaged"}, "CenterCenter", {0, 0}, HUD_INT_origin.name)
object.element_params = {"HUD_BRIGHT", "WPN_MSL_CAGED", "HUD_IR_LOCK_BLINK", "HUD_IR_MISSILE_TARGET_AZIMUTH", "HUD_IR_MISSILE_TARGET_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, -0.05, 0.05},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"move_left_right_using_parameter", 3, move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
}
-- [F-5EM v0.61.10 desk-check 2026-07-11] Salvar ref do uncaged como parent
-- do "IR out of screen" abaixo (mesma correcao em HUD_AA_DGFT.lua).
local _uncaged_obj = object

-- [F-5EM v0.61.8 2026-07-11] IR HOBS (CAGED==2, HMD ativo). Antes NAO
-- existia -- HMD ligado -> nenhum losango no HUD. Mesma correcao
-- aplicada em HUD_AA_DGFT.lua. Ver comentario la para detalhes.
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "aim9lm-uncaged"}, "CenterCenter", {0, 0}, HUD_INT_origin.name)
object.element_params = {"HUD_BRIGHT", "WPN_MSL_CAGED", "HUD_IR_LOCK_BLINK", "HUD_IR_MISSILE_TARGET_AZIMUTH", "HUD_IR_MISSILE_TARGET_ELEVATION", "HUD_MSL_HIDDEN"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"parameter_in_range", 1, 1.95, 2.05},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"move_left_right_using_parameter", 3, move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
	-- [F-5EM 2026-07-28] Ver HUD_AA_DGFT.lua: limit_xy projeta na borda em vez
	-- de esconder, entao o losango HOBS so pode aparecer com LOS dentro do HUD.
	{"parameter_in_range", 5, -0.05, 0.05},
}

-- IR out of screen (HOBS)
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, HUD_INT_origin.name)
object.element_params = {"HUD_BRIGHT", "WPN_MSL_CAGED", "HUD_MSL_HIDDEN", "HUD_IR_MISSILE_TARGET_AZIMUTH", "HUD_IR_MISSILE_TARGET_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"parameter_in_range", 1, 1.95, 2.05},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"move_left_right_using_parameter", 3, move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
}

-- IR out of screen
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, _uncaged_obj.name)
object.element_params = {"HUD_BRIGHT", "HUD_MSL_HIDDEN"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}

-- MSL reticle. The real-reference HUD is clean before acquisition, so the
-- seeker circle appears only with genuine IR lock feedback. It still follows
-- the seeker LOS and remains scoped to INT S by HUD_INT_origin.
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "msl-recticle"}, "CenterCenter", {0, 0}, HUD_INT_origin.name)
object.element_params = {"HUD_BRIGHT", "HUD_IR_LOCK_BLINK", "HUD_IR_MISSILE_TARGET_AZIMUTH", "HUD_IR_MISSILE_TARGET_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"parameter_in_range", 1, 0.95, 1.05},
	{"move_left_right_using_parameter", 2, move_scale}, -- segue LOS do seeker
	{"move_up_down_using_parameter", 3, move_scale},
}

-- INT M
local HUD_INT_M_origin = addPlaceholder(nil, {0,0})
HUD_INT_M_origin.element_params = {"AVIONICS_MASTER_MODE"}
HUD_INT_M_origin.controllers = {
	{"parameter_in_range", 0, AVIONICS_MASTER_MODE_ID.INT_M - 0.05, AVIONICS_MASTER_MODE_ID.INT_M + 0.05},
}

local function addHudMissileEnvelope(parent)
	local height = 74
	local width = 10
	local bottom = -height / 2
	local scale = GetScale() * height
	local origin = addPlaceholder("HUD_INT_M_Envelope", {92, 8}, parent)
	origin.element_params = {"HUD_DLZ_MAX", "F5EM_COMBAT_READY_STATE", "WPN_SELECTED_WEAPON_TYPE"}
	origin.controllers = {
		{"parameter_in_range", 0, -0.001, 1.001},
		{"parameter_in_range", 1, 0.5, 2.5},
		{"parameter_compare_with_number", 2, WPN_WEAPON_TYPE_IDS.AA_MISSILE},
	}

	local line = addSimpleLine(nil, height, {-width / 2, bottom}, 0, origin.name, nil, width / 20)
	line.element_params = {"HUD_BRIGHT", "HUD_DLZ_MIN", "HUD_DLZ_MAX"}
	line.controllers = {
		{"opacity_using_parameter", 0},
		{"line_object_set_point_using_parameters", 0, 1, 1, 0, scale},
		{"line_object_set_point_using_parameters", 1, 2, 2, 0, scale},
	}
	line = addSimpleLine(nil, height, {width / 2, bottom}, 0, origin.name, nil, width / 20)
	line.element_params = {"HUD_BRIGHT", "HUD_DLZ_MIN", "HUD_DLZ_BEST"}
	line.controllers = {
		{"opacity_using_parameter", 0},
		{"line_object_set_point_using_parameters", 0, 1, 1, 0, scale},
		{"line_object_set_point_using_parameters", 1, 2, 2, 0, scale},
	}

	local marks = {
		{"HUD_DLZ_MIN", -width / 2},
		{"HUD_DLZ_BEST", width / 2},
		{"HUD_DLZ_MAX", -width / 2},
	}
	for _, mark in ipairs(marks) do
		local tick = addStrokeLine(nil, width, {mark[2], bottom}, -90, origin.name)
		tick.element_params = {"HUD_BRIGHT", mark[1]}
		tick.controllers = {{"opacity_using_parameter", 0}, {"move_up_down_using_parameter", 1, scale}}
	end

	local caret = addStrokeSymbol("HUD_INT_M_Target_Range", {"f5em_stroke_symbols", "AA-DLZ-range"}, "CenterCenter", {8, bottom}, origin.name)
	caret.element_params = {"HUD_BRIGHT", "HUD_DLZ_NOW"}
	caret.controllers = {{"opacity_using_parameter", 0}, {"move_up_down_using_parameter", 1, scale}}
	local scale_text = addStrokeText(nil, "  ", STROKE_FNT_DFLT_100_NARROW, "CenterBottom", {0, height / 2 + 4}, origin.name, nil, {"%2.0f"})
	scale_text.element_params = {"HUD_BRIGHT", "RDR_RANGE"}
	scale_text.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
	-- [F-5EM 2026-07-20] RMAX/RNE/RMIN numeric labels are now STANDALONE elements
	-- in HUD_ALL.lua (same page root as AL/TTG) so they align in the right-column
	-- intercept stack and render reliably. Previously they were children of this
	-- envelope origin in the INT scaled root and did not appear at the new stack
	-- position. The DLZ scale bar/ticks/caret above stay here as the visual range
	-- picture.
	return origin
end

addHudMissileEnvelope(HUD_INT_M_origin.name)