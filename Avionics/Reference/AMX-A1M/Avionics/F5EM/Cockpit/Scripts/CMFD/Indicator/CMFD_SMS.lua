dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/avionics_api.lua")
dofile(LockOn_Options.script_path .. "Systems/weapon_system_api.lua")
dofile(LockOn_Options.script_path.."CMFD/CMFD_SMS_ID_defs.lua")

local aspect = GetAspect()

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.SMS}}
default_parent      = page_root.name


local object

object = addStrokeText(nil, "NO WEAPON\nDELIVERY", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, nil, nil, {"%05.0f"})
object = encapsulateObject(object)
object.element_params = {"SMS_ON"}
object.controllers = {{"parameter_compare_with_number", 0, 0}}
object = addOSSText(2, "OFF", object.name)

object = addPlaceholder()
object.element_params = {"SMS_ON"}
object.controllers = {{"parameter_compare_with_number", 0, 1}}

default_parent      = object.name


function addStoreFull()
    local stores = 7
    local stores_radius = 0.03
    local stores_size_x = 1
    local stores_nb_y = 0.8
    local guns_size_x = 0.5

    local object
    local base = addPlaceholder(nil, {0,0})
    base.element_params    = {"SMS_MODE"}
    base.controllers       = {{"parameter_in_range", 0, SMS_MODE_IDS.SAFE - 0.05, SMS_MODE_IDS.EJ + 0.05}}
    
    for i=1,stores do
        object = addMeshCircle(nil, stores_radius, {(i-(stores+1)/2) * stores_size_x / (stores-1), stores_nb_y}, base.name, nil, nil, nil, nil, nil, CMFD_MATERIAL_YELLOW)
        object = addStrokeText(nil, i, CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {(i-(stores+1)/2) * stores_size_x / (stores-1), stores_nb_y}, base.name, nil, nil, CMFD_FONT_K)
        object.additive_alpha = false
        object = addStrokeLine(nil, math.abs((i-(stores+1)/2) * stores_size_x / (stores-1)) + 4 * stores_radius, {(i-(stores+1)/2) * stores_size_x / (stores-1), stores_nb_y-stores_radius*1.3}, 180, base.name)
        object = addStrokeText(nil, "TANK", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {(i-(stores+1)/2) * stores_size_x / (stores-1), stores_nb_y - math.abs((i-(stores+1)/2) * stores_size_x / (stores-1)) - 8 * stores_radius}, base.name, nil, {"%s"})
        object.element_params = {default_element_params, "WPN_POS_"..i.."_TEXT"}
        object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}
        object = addStrokeBox(nil, 0.3, 0.062, "CenterCenter", {0,0}, object.name)
        object.element_params = {default_element_params, "WPN_POS_"..i.."_SEL"}
        object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}
        object = addStrokeBoxDashed(nil, 0.3, 0.062, 0.02, 0.02, {0,0}, object.parent_element)
        object.element_params = {default_element_params, "WPN_POS_"..i.."_SEL"}
        object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}}
    end

    
    object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "f5em"}, "CenterCenter", {0, stores_nb_y + guns_size_x/2.5}, base.name, nil, 0.003)
    object.stroke_thickness = 0.5


    object = addStrokeText(nil, "100", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-guns_size_x/2, stores_nb_y + guns_size_x/2}, base.name, nil,{"%03.0f"})
    object.element_params = {default_element_params, "WPN_GUNS_L"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}
    object = addStrokeBox(nil, 0.15, 0.062, "CenterCenter", {0,0}, object.name)
    object.element_params = {default_element_params, "WPN_GUNS_L_SEL"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}
    object = addStrokeBoxDashed(nil, 0.15, 0.062, 0.02, 0.02, {0,0}, object.parent_element)
    object.element_params = {default_element_params, "WPN_GUNS_L_SEL"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}}

    -- object = addStrokeText(nil, "100", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {guns_size_x/2, stores_nb_y + guns_size_x/2}, nil, nil,{"%03.0f"})
    -- object.element_params = {default_element_params, "WPN_GUNS_R"}
    -- object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}
    -- object = addStrokeBox(nil, 0.15, 0.062, "CenterCenter", {0,0}, object.name)
    -- object.element_params = {default_element_params, "WPN_GUNS_R_SEL"}
    -- object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}
    -- object = addStrokeBoxDashed(nil, 0.15, 0.062, 0.02, 0.02, {0,0}, object.parent_element)
    -- object.element_params = {default_element_params, "WPN_GUNS_R_SEL"}
    -- object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}}

    -- RELEASE
    object = addStrokeText(nil, "RELEASE", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, base.name)
    object.element_params = {default_element_params, "WPN_RELEASE"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

    -- RDY
    object = addStrokeText(nil, "RDY", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, base.name)
    object.element_params = {default_element_params, "WPN_READY", "WPN_RELEASE"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, 0}}

end

addStoreFull()



-- SAFE
local SMS_mode_safe = addPlaceholder("SMS_mode_safe", {0,0})
SMS_mode_safe.element_params = {"SMS_MODE"}
SMS_mode_safe.controllers = {{"parameter_compare_with_number", 0, SMS_MODE_IDS.SAFE}}

object = addOSSText(2, "SAFE", SMS_mode_safe.name)

object = addOSSText(3, "GDS", SMS_mode_safe.name)
object.element_params = {default_element_params, "SMS_INV"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

object = addOSSText(4, "WPN", SMS_mode_safe.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.WPN}}

object = addOSSText(4, "RACK", SMS_mode_safe.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.RACK}}

object = addOSSText(5, "INV", SMS_mode_safe.name)

object = addOSSText(6, "SJ", SMS_mode_safe.name)
object.element_params = {default_element_params, "SMS_INV"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

object = addStrokeText(nil, "SIM", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, SMS_mode_safe.name)
object.element_params = {default_element_params, "WPN_MASS", "SMS_INV"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_MASS_IDS.SIM}, {"parameter_compare_with_number", 2, 0}}

-- INV
local SMS_submode_inv = addPlaceholder("SMS_submode_inv", {0,0})
SMS_submode_inv.element_params = {"SMS_INV"}
SMS_submode_inv.controllers = {{"parameter_compare_with_number", 0, 1}}

object = addStrokeText(nil, "INV", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, SMS_submode_inv.name, nil, nil)
object.element_params = {default_element_params, "SMS_INV", "WPN_MASS"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}, {"parameter_in_range", 2, WPN_MASS_IDS.SAFE -0.05, WPN_MASS_IDS.LIVE + 0.05}}

object = addStrokeText(nil, "SIM-INV", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, SMS_submode_inv.name, nil, nil)
object.element_params = {default_element_params, "SMS_INV", "WPN_MASS"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, WPN_MASS_IDS.SIM}}

object = addOSSStrokeBox(5, 1, SMS_submode_inv.name)

object = addOSSText(3, "CLR\nWPN", SMS_submode_inv.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.WPN}}

object = addOSSText(3, "CLR\nRACK", SMS_submode_inv.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.RACK}}

object = addOSSText(6, "SIML", SMS_submode_inv.name)
object = addOSSText(7, "LOAD", SMS_submode_inv.name)
object = addOSSText(8, "NO\nARMR", SMS_submode_inv.name)
object = addOSSText(9, "ST5", SMS_submode_inv.name)
object = addOSSText(10, "ST6", SMS_submode_inv.name)
object = addOSSText(11, "ST7", SMS_submode_inv.name)
object = addOSSText(24, "ST1", SMS_submode_inv.name)
object = addOSSText(25, "ST2", SMS_submode_inv.name)
object = addOSSText(26, "ST3", SMS_submode_inv.name)
object = addOSSText(27, "ST4", SMS_submode_inv.name)
object = addOSSText(28, "GUN", SMS_submode_inv.name)

-- SJ
local SMS_mode_sj = addPlaceholder("SMS_mode_sj", {0,0})
SMS_mode_sj.element_params = {"SMS_MODE"}
SMS_mode_sj.controllers = {{"parameter_compare_with_number", 0, SMS_MODE_IDS.SJ}}

object = addOSSText(2, "SJ", SMS_mode_sj.name)

object = addOSSText(4, "WPN", SMS_mode_sj.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.WPN}}

object = addOSSText(4, "RACK", SMS_mode_sj.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.RACK}}

object = addOSSText(5, "JET", SMS_mode_sj.name)
object = addOSSStrokeBox(5, 1, SMS_mode_sj.name)
object.element_params = {default_element_params, "WPN_MASS", "WPN_LATEARM"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_MASS_IDS.LIVE}, {"parameter_compare_with_number", 2, WPN_LATEARM_IDS.ON}}

local sj_station_oss = {
    {9, 5}, {10, 6}, {11, 7},
    {24, 1}, {25, 2}, {26, 3}, {27, 4},
}
for _, station_oss in ipairs(sj_station_oss) do
    local oss = station_oss[1]
    local station = station_oss[2]
    object = addOSSText(oss, "ST"..tostring(station), SMS_mode_sj.name)
    object = addOSSStrokeBox(oss, 1, SMS_mode_sj.name)
    object.element_params = {default_element_params, "WPN_SJ_STO"..tostring(station).."_SEL"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}
end

object = addStrokeText(nil, "SIM-NO SJ", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, SMS_mode_sj.name, nil, nil)
object.element_params = {default_element_params, "WPN_MASS"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_MASS_IDS.SIM}}

object = addStrokeText(nil, "SAFE-NO SJ", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, SMS_mode_sj.name, nil, nil)
object.element_params = {default_element_params, "WPN_MASS"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_MASS_IDS.SAFE}}

object = addStrokeText(nil, "SAFE-NO SJ", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, SMS_mode_sj.name, nil, nil)
object.element_params = {default_element_params, "WPN_LATEARM", "WPN_MASS"}
object.controllers = {default_controllers[1], {"parameter_in_range", 1, WPN_LATEARM_IDS.GUARD-0.05, WPN_LATEARM_IDS.SAFE + 0.05}, {"parameter_compare_with_number", 2, WPN_MASS_IDS.LIVE}}

object = addStrokeText(nil, "JET", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, SMS_mode_sj.name, nil, nil)
object.element_params = {default_element_params, "WPN_MASS", "WPN_LATEARM"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_MASS_IDS.LIVE}, {"parameter_compare_with_number", 2, WPN_LATEARM_IDS.ON}}

-- EJ
local SMS_mode_ej = addPlaceholder("SMS_mode_ej", {0,0})
SMS_mode_ej.element_params = {"SMS_MODE"}
SMS_mode_ej.controllers = {{"parameter_compare_with_number", 0, SMS_MODE_IDS.EJ}}

object = addOSSText(2, "E-J", SMS_mode_ej.name)

object = addOSSText(4, "WPN", SMS_mode_ej.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.WPN}}

object = addOSSText(4, "RACK", SMS_mode_ej.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.RACK}}

-- AA
local SMS_mode_aa = addPlaceholder("SMS_mode_aa", {0,0})
SMS_mode_aa.element_params = {"SMS_MODE"}
SMS_mode_aa.controllers = {{"parameter_compare_with_number", 0, SMS_MODE_IDS.AA}}

object = addOSSText(2, "A/A", SMS_mode_aa.name)

-- object = addOSSText(3, "GDS", SMS_mode_aa.name)

object = addOSSText(4, "WPN", SMS_mode_aa.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.WPN}}

object = addOSSText(4, "RACK", SMS_mode_aa.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.RACK}}

object = addOSSText(5, "INV", SMS_mode_aa.name)

object = addOSSText(6, "SJ", SMS_mode_aa.name)
object.element_params = {default_element_params, "SMS_INV"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

local SMS_mode_aa_oss = addPlaceholder("SMS_mode_aa_oss", {0,0}, SMS_mode_aa.name)
SMS_mode_aa_oss.element_params = {"SMS_INV"}
SMS_mode_aa_oss.controllers = {{"parameter_compare_with_number", 0, 0}}

object = addOSSText(3, "SNAP", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_SIGHT"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_SIGHT_IDS.SNAP}}
object = addOSSText(3, "LCOS", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_SIGHT"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_SIGHT_IDS.LCOS}}
object = addOSSText(3, "SSLC", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_SIGHT"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_SIGHT_IDS.SSLC}}

object = addOSSText(7, "QTY TYPE", SMS_mode_aa_oss.name, nil, nil, {"%01.0f ", "%s"})
object.element_params = {default_element_params, "WPN_AA_QTY", "WPN_AA_NAME"}
object.controllers = {default_controllers[1], {"parameter_in_range", 1, -0.05, 999}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}}

object = addOSSText(8, "AMN\nQTY", SMS_mode_aa_oss.name, nil, nil, {"INTRG\n%01.0f"})
object.element_params = {default_element_params, "WPN_AA_INTRG_QTY"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

object = addOSSText(9, "RR\nRATE", SMS_mode_aa_oss.name, nil, nil, {"RR\n%01.0f"})
object.element_params = {default_element_params, "WPN_AA_RR"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

object = addOSSText(10, "DL", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_RR_SRC"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_RR_SRC_IDS.DL}}
object = addOSSText(10, "MAN", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_RR_SRC"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_RR_SRC_IDS.MAN}}

object = addOSSText(11, "DL", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_SLV_SRC"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_SLV_SRC_IDS.M}}
object = addOSSText(11, "BST", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_SLV_SRC"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_SLV_SRC_IDS.S}}

object = addOSSText(25, "COOL", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_COOL"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_COOL_IDS.COOL}}
object = addOSSText(25, "WARM", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_COOL"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_COOL_IDS.WARM}}

object = addOSSText(26, "SPOT", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_SCAN"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_SCAN_IDS.SPOT}}
object = addOSSText(26, "SCAN", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_SCAN"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_SCAN_IDS.SCAN}}

object = addOSSText(27, "TD", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_LIMIT"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_LIMIT_IDS.TD}}
object = addOSSText(27, "BP", SMS_mode_aa_oss.name)
object.element_params = {default_element_params, "WPN_AA_LIMIT"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_AA_LIMIT_IDS.BP}}

object = addOSSText(28, "STEP", SMS_mode_aa_oss.name)

object = addStrokeText(nil, "SIM", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, SMS_mode_aa.name)
object.element_params = {default_element_params, "WPN_MASS", "SMS_INV", "WPN_LATEARM"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_MASS_IDS.SIM}, {"parameter_compare_with_number", 2, 0}, {"parameter_in_range", 3, WPN_LATEARM_IDS.GUARD-0.05, WPN_LATEARM_IDS.SAFE+0.05}}

object = addStrokeText(nil, "SIM-RDY", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, SMS_mode_aa.name, nil, nil)
object.element_params = {default_element_params, "SMS_INV", "WPN_SIM_READY"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}, {"parameter_compare_with_number", 2, 1}}

-- AG
local SMS_mode_ag = addPlaceholder("SMS_mode_ag", {0,0})
SMS_mode_ag.element_params = {"SMS_MODE"}
SMS_mode_ag.controllers = {{"parameter_compare_with_number", 0, SMS_MODE_IDS.AG}}

local SMS_mode_ag_oss = addPlaceholder(nil, {0,0}, SMS_mode_ag.name)
SMS_mode_ag_oss.element_params = {"SMS_INV"}
SMS_mode_ag_oss.controllers = {{"parameter_compare_with_number", 0, 0}}

object = addOSSText(4, "WPN", SMS_mode_ag.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.WPN}}

object = addOSSText(4, "RACK", SMS_mode_ag.name)
object.element_params = {default_element_params, "SMS_CARGOTYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_CARGO_TYPE_IDS.RACK}}

object = addOSSText(5, "INV", SMS_mode_ag.name)

object = addOSSText(6, "SJ", SMS_mode_ag.name)
object.element_params = {default_element_params, "SMS_INV"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

object = addOSSText(2, "A/G", SMS_mode_ag.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.DTOS-0.05, AVIONICS_MASTER_MODE_ID.MAN + 0.05}}

object = addOSSText(2, "GUN", SMS_mode_ag.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.GUN-0.5, AVIONICS_MASTER_MODE_ID.GUN_R + 0.05}}

local SMS_mode_ag_gun = addPlaceholder(nil, {0,0}, SMS_mode_ag_oss.name)
SMS_mode_ag_gun.element_params = {"SMS_MODE", "AVIONICS_MASTER_MODE"}
SMS_mode_ag_gun.controllers = {{"parameter_compare_with_number", 0, SMS_MODE_IDS.AG}, {"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.GUN - 0.05, AVIONICS_MASTER_MODE_ID.GUN_R + 0.05}}

object = addOSSText(8, "FREE", SMS_mode_ag_gun.name)

object = addOSSText(3, "STRF", SMS_mode_ag_gun.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.GUN-0.5, AVIONICS_MASTER_MODE_ID.GUN_R + 0.05}}

object = addOSSText(3, "MAN", SMS_mode_ag_gun.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, AVIONICS_MASTER_MODE_ID.GUN_M}}

local SMS_mode_ag_nogun = addPlaceholder(nil, {0,0}, SMS_mode_ag_oss.name)
SMS_mode_ag_nogun.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
SMS_mode_ag_nogun.controllers = {default_controllers[1], {"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.DTOS-0.5, AVIONICS_MASTER_MODE_ID.MAN + 0.05}}

object = addOSSText(28, "QTY TYPE", SMS_mode_ag_nogun.name, nil, nil, {"%01.0f ", "%s"})
object.element_params = {default_element_params, "WPN_AG_QTY", "WPN_AG_NAME"}
object.controllers = {default_controllers[1], {"parameter_in_range", 1, -0.05, 999}, {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}}

object = addStrokeText(nil, "L CODE\n1688", CMFD_STRINGDEFS_DEF_X08,
    "CenterCenter", {0.46, -0.36}, SMS_mode_ag_nogun.name, nil, nil, {"L CODE\n%04.0f"})
object.element_params = {default_element_params, "WPN_LASER_SELECTED", "WPN_LASER_CODE"}
object.controllers = {default_controllers[1],
    {"parameter_compare_with_number", 1, 1},
    {"text_using_parameter", 2, 0}}

object = addOSSText(8, "REL", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params}
object.controllers = {default_controllers[1]}

object = addOSSText(3, "CCIP", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.CCIP-0.05, AVIONICS_MASTER_MODE_ID.CCIP_R + 0.05}}

object = addOSSText(3, "MAN", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, AVIONICS_MASTER_MODE_ID.MAN}}

object = addOSSText(3, "CCRP", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, AVIONICS_MASTER_MODE_ID.CCRP}}

object = addOSSText(3, "DTOS", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.DTOS-0.05, AVIONICS_MASTER_MODE_ID.DTOS_R + 0.05}}

object = addOSSText(7, "SD", SMS_mode_ag_oss.name, nil, nil, {"SD\n%03.0f"})
object.element_params = {default_element_params, "WPN_SD"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

object = addOSSText(9, "N+T", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "SMS_FUSE_SEL", "WPN_SELECTED_WEAPON_TYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_FUSE_SEL_IDS.NT}, {"parameter_compare_with_number", 2 , WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}

object = addOSSText(9, "N", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "SMS_FUSE_SEL", "WPN_SELECTED_WEAPON_TYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_FUSE_SEL_IDS.N}, {"parameter_compare_with_number", 2 , WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}

object = addOSSText(9, "T", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "SMS_FUSE_SEL", "WPN_SELECTED_WEAPON_TYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_FUSE_SEL_IDS.T}, {"parameter_compare_with_number", 2 , WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}

object = addOSSText(9, "SAFE", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "SMS_FUSE_SEL", "WPN_SELECTED_WEAPON_TYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_FUSE_SEL_IDS.SAFE}, {"parameter_compare_with_number", 2 , WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}

object = addOSSText(10, "IMPC", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "SMS_FUSE_TYPE", "WPN_SELECTED_WEAPON_TYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_FUSE_TYPE_IDS.IMPC}, {"parameter_compare_with_number", 2 , WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}

object = addOSSText(10, "PROX", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "SMS_FUSE_TYPE", "WPN_SELECTED_WEAPON_TYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_FUSE_TYPE_IDS.PROX}, {"parameter_compare_with_number", 2 , WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}

object = addOSSText(10, "1TIME", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "SMS_FUSE_TYPE", "WPN_SELECTED_WEAPON_TYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_FUSE_TYPE_IDS.ONETIME}, {"parameter_compare_with_number", 2 , WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}

-- object = addOSSText(11, "AD", SMS_mode_ag_nogun.name, nil, nil, {"AD %04.1f"})
-- object.element_params = {default_element_params, "SMS_TIME_ALT_SEL", "WPN_SELECTED_WEAPON_TYPE"}
-- object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_TIME_ALT_SEL_IDS.AD}, {"text_using_parameter", 1, 0 }, {"parameter_compare_with_number", 2 , WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}

-- object = addOSSText(11, "ADBA", SMS_mode_ag_nogun.name, nil, nil, {"AD %04.1f\nBA %04i"})
-- object.element_params = {default_element_params, "SMS_TIME_ALT_SEL", "WPN_SELECTED_WEAPON_TYPE"}
-- object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_TIME_ALT_SEL_IDS.ADBA}, {"text_using_parameter", 1, 0 }, {"parameter_compare_with_number", 2 , WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}

-- object = addOSSText(11, "FDBA", SMS_mode_ag_nogun.name, nil, nil, {"FD %04.1f\nBA %04i"})
-- object.element_params = {default_element_params, "SMS_TIME_ALT_SEL", "WPN_SELECTED_WEAPON_TYPE"}
-- object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_TIME_ALT_SEL_IDS.FDBA}, {"text_using_parameter", 1, 0 }, {"parameter_compare_with_number", 2 , WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}

object = addOSSText(24, "IS", SMS_mode_ag_nogun.name, nil, nil, {"%03.0fM"})
object.element_params = {default_element_params, "WPN_SELECTED_WEAPON_TYPE", "AVIONICS_MASTER_MODE", "WPN_IS_M"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}, {"parameter_in_range", 2, AVIONICS_MASTER_MODE_ID.DTOS - 0.05, AVIONICS_MASTER_MODE_ID.CCIP_R + 0.05}, {"text_using_parameter", 3, 0 }}

object = addOSSText(24, "IS", SMS_mode_ag_nogun.name, nil, nil, {"%04.0fMS"})
object.element_params = {default_element_params, "WPN_SELECTED_WEAPON_TYPE", "WPN_IS_TIME"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_ROCKET}, {"text_using_parameter", 2, 0 }}

object = addOSSText(24, "IS", SMS_mode_ag_nogun.name, nil, nil, {"%04.0fMS"})
object.element_params = {default_element_params, "WPN_SELECTED_WEAPON_TYPE", "AVIONICS_MASTER_MODE", "WPN_IS_TIME"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}, {"parameter_compare_with_number", 2, AVIONICS_MASTER_MODE_ID.MAN}, {"text_using_parameter", 3, 0 }}

object = addOSSText(25, "RPBR", SMS_mode_ag_nogun.name, nil, nil, {"RP%02.0f\n","(BR%02.0f)"})
object.element_params = {default_element_params, "WPN_SELECTED_WEAPON_TYPE", "WPN_RP", "WPN_RP_TOTAL"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}, {"text_using_parameter", 2, 0 }, {"text_using_parameter", 3, 1 }}

object = addOSSText(25, "RPBR", SMS_mode_ag_nogun.name, nil, nil, {"RP%02.0f\n","(RR%02.0f)"})
object.element_params = {default_element_params, "WPN_SELECTED_WEAPON_TYPE", "WPN_RP", "WPN_RP_TOTAL"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_ROCKET}, {"text_using_parameter", 2, 0 }, {"text_using_parameter", 3, 1 }}

object = addOSSText(26, "SGL", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "WPN_LAUNCH_OP"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_LAUNCH_OP_IDS.SGL}}

object = addOSSText(26, "PAIR", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "WPN_LAUNCH_OP"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_LAUNCH_OP_IDS.PAIR}}

object = addOSSText(26, "SALVO", SMS_mode_ag_nogun.name)
object.element_params = {default_element_params, "WPN_LAUNCH_OP"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_LAUNCH_OP_IDS.SALVO}}

-- object = addOSSText(27, "PROF 1", SMS_mode_ag_nogun.name)
-- object.element_params = {default_element_params, "SMS_PROF_SEL"}
-- object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_PROF_SEL_IDS.PROF1}}

-- object = addOSSText(27, "PROF 2", SMS_mode_ag_nogun.name)
-- object.element_params = {default_element_params, "SMS_PROF_SEL"}
-- object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_PROF_SEL_IDS.PROF2}}

-- object = addOSSText(27, "PROF 3", SMS_mode_ag_nogun.name)
-- object.element_params = {default_element_params, "SMS_PROF_SEL"}
-- object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_PROF_SEL_IDS.PROF2}}

-- object = addOSSText(27, "PROF 4", SMS_mode_ag_nogun.name)
-- object.element_params = {default_element_params, "SMS_PROF_SEL"}
-- object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_PROF_SEL_IDS.PROF4}}

-- object = addOSSText(27, "PROF 5", SMS_mode_ag_nogun.name)
-- object.element_params = {default_element_params, "SMS_PROF_SEL"}
-- object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_PROF_SEL_IDS.PROF5}}

-- A/G CD
local CMFD_SMS_AG_CD_Origin = addPlaceholder(nil, {0,0})
CMFD_SMS_AG_CD_Origin.element_params = {"SMS_MODE"}
CMFD_SMS_AG_CD_Origin.controllers = {{"parameter_compare_with_number", 0, SMS_MODE_IDS.CD}}

object = addOSSText(2, "A/G", CMFD_SMS_AG_CD_Origin.name)

object = addOSSText(28, "CCIP", CMFD_SMS_AG_CD_Origin.name)
object = addOSSStrokeBox(28, 1, CMFD_SMS_AG_CD_Origin.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.CCIP - 0.05, AVIONICS_MASTER_MODE_ID.CCIP_R + 0.05}}


object = addOSSText(27, "MAN", CMFD_SMS_AG_CD_Origin.name)
object = addOSSStrokeBox(27, 1, CMFD_SMS_AG_CD_Origin.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, AVIONICS_MASTER_MODE_ID.MAN}}

object = addOSSText(26, "CCRP", CMFD_SMS_AG_CD_Origin.name)
object.element_params = {default_element_params, "WPN_SELECTED_WEAPON_TYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}
object = addOSSStrokeBox(26, 1, CMFD_SMS_AG_CD_Origin.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, AVIONICS_MASTER_MODE_ID.CCRP}}

object = addOSSText(25, "DTOS", CMFD_SMS_AG_CD_Origin.name)
object.element_params = {default_element_params, "WPN_SELECTED_WEAPON_TYPE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB}}
object = addOSSStrokeBox(25, 1, CMFD_SMS_AG_CD_Origin.name)
object.element_params = {default_element_params, "AVIONICS_MASTER_MODE"}
object.controllers = {default_controllers[1], {"parameter_in_range", 1, AVIONICS_MASTER_MODE_ID.DTOS - 0.05, AVIONICS_MASTER_MODE_ID.DTOS_R + 0.05}}

object = addStrokeText(nil, "SELECT MODE", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0,0}, CMFD_SMS_AG_CD_Origin.name)


-- A/G Edit number
local CMFD_SMS_AG_EDIT_NR_Origin = addPlaceholder(nil, {0,0})
CMFD_SMS_AG_EDIT_NR_Origin.element_params = {"SMS_MODE"}
CMFD_SMS_AG_EDIT_NR_Origin.controllers = {{"parameter_in_range", 0, SMS_MODE_IDS.RP - 0.05, SMS_MODE_IDS.SD + 0.05}}

object = addOSSText(2, "A/G", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText(3, "CLR", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText(4, "ENT", CMFD_SMS_AG_EDIT_NR_Origin.name)

object = addOSSText(28, "1", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText(27, "2", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText(26, "3", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText(25, "4", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText(24, "5", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText( 7, "6", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText( 8, "7", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText( 9, "8", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText(10, "9", CMFD_SMS_AG_EDIT_NR_Origin.name)
object = addOSSText(11, "0", CMFD_SMS_AG_EDIT_NR_Origin.name)

object = addStrokeText(nil, "DESCRIPTION", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {0,0}, CMFD_SMS_AG_EDIT_NR_Origin.name, nil, {"%s"})
object.element_params = {default_element_params, "CMFD_EDIT_NR_DESC"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "TITLE", CMFD_STRINGDEFS_DEF_X1, "LeftCenter", {-0.70,0.8}, CMFD_SMS_AG_EDIT_NR_Origin.name, nil, {"%s"})
object.element_params = {default_element_params, "CMFD_EDIT_NR_TITLE"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

object = addFillBox(nil, 0.2, 0.075, "CenterTop", {-0.4,0.8}, CMFD_SMS_AG_EDIT_NR_Origin.name)
object.element_params = {default_element_params, "CMFD_EDIT_NR_BLINK"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}
object = addStrokeText(nil, "\n000", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {0,0}, object.name, nil, {"\n%1.0f"}, CMFD_FONT_K)
object.element_params = {default_element_params, "CMFD_EDIT_NR_VALUE"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}



-- Secondaries

function addStoreSec(parent)
    save_default_parent = default_parent
    default_parent = parent

    local stores = 7
    local stores_radius = 0.03
    local stores_size_x = 1
    local stores_nb_y = 0.25
    local guns_size_x = 0.2
    local stores_scale_y = 1

    local object
    local base = addPlaceholder(nil, {0,0})
    base.element_params    = {"SMS_MODE"}
    base.controllers       = {{"parameter_in_range", 0, SMS_MODE_IDS.SAFE - 0.05, SMS_MODE_IDS.EJ + 0.05}}
    
    for i=2,stores-1 do
        object = addMeshCircle(nil, stores_radius, {(i-(stores+1)/2) * stores_size_x / (stores-1), stores_nb_y}, base.name, nil, nil, nil, nil, nil)
        object = addStrokeText(nil, i, CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {(i-(stores+1)/2) * stores_size_x / (stores-1), stores_nb_y}, base.name, nil, nil, CMFD_FONT_K)
        object.additive_alpha = false
        object = addStrokeLine(nil, math.abs(stores_scale_y*(i-(stores+1)/2) * stores_size_x / (stores-1)), {(i-(stores+1)/2) * stores_size_x / (stores-1), stores_nb_y-stores_radius*1.3}, 180, base.name)
        object = addStrokeText(nil, "TANK", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {(i-(stores+1)/2) * stores_size_x / (stores-1), stores_nb_y - math.abs(stores_scale_y*(i-(stores+1)/2) * stores_size_x / (stores-1)) - 3 * stores_radius}, base.name, nil, {"%s"})
        object.element_params = {default_element_params, "WPN_POS_"..i.."_TEXT"}
        object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}
        object = addStrokeBox(nil, 0.3, 0.062, "CenterCenter", {0,0}, object.name)
        object.element_params = {default_element_params, "WPN_POS_"..i.."_SEL"}
        object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}
        object = addStrokeBoxDashed(nil, 0.3, 0.062, 0.02, 0.02, {0,0}, object.parent_element)
        object.element_params = {default_element_params, "WPN_POS_"..i.."_SEL"}
        object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}}
    end

    for k,i in pairs({1, stores}) do
        object = addMeshCircle(nil, stores_radius, {(i-(stores+1)/2) * stores_size_x / (stores+2), -stores_nb_y - 2 * stores_radius}, base.name, nil, nil, nil, nil, nil)
        object = addStrokeText(nil, i, CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0,0}, object.name, nil, nil, CMFD_FONT_K)
        object.additive_alpha = false
        object = addStrokeText(nil, "TANK", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, - 3 * stores_radius}, object.parent_element, nil, {"%s"})
        object.element_params = {default_element_params, "WPN_POS_"..i.."_TEXT"}
        object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}
        object = addStrokeBox(nil, 0.3, 0.062, "CenterCenter", {0,0}, object.name)
        object.element_params = {default_element_params, "WPN_POS_"..i.."_SEL"}
        object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}
        object = addStrokeBoxDashed(nil, 0.3, 0.062, 0.02, 0.02, {0,0}, object.parent_element)
        object.element_params = {default_element_params, "WPN_POS_"..i.."_SEL"}
        object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}}
    end

    object = addStrokeText(nil, "100", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, stores_nb_y + guns_size_x/2}, base.name, nil,{"%03.0f"})
    object.element_params = {default_element_params, "WPN_GUNS_L"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}
    object = addStrokeBox(nil, 0.15, 0.062, "CenterCenter", {0,0}, object.name)
    object.element_params = {default_element_params, "WPN_GUNS_L_SEL"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}
    object = addStrokeBoxDashed(nil, 0.15, 0.062, 0.02, 0.02, {0,0}, object.parent_element)
    object.element_params = {default_element_params, "WPN_GUNS_L_SEL"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}}


    object = addStrokeText(nil, "SAFE", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {(1-(stores-1)/2) * stores_size_x / (stores-1), stores_nb_y + guns_size_x/2}, base.name)
    object.element_params = {default_element_params, "SMS_MODE"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_MODE_IDS.SAFE}}

    object = addStrokeText(nil, "A/G", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {(1-(stores-1)/2) * stores_size_x / (stores-1), stores_nb_y + guns_size_x/2}, base.name)
    object.element_params = {default_element_params, "SMS_MODE"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_MODE_IDS.AG}}

    object = addStrokeText(nil, "A/A", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {(1-(stores-1)/2) * stores_size_x / (stores-1), stores_nb_y + guns_size_x/2}, base.name)
    object.element_params = {default_element_params, "SMS_MODE"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_MODE_IDS.AA}}

    local warn_base = addPlaceholder(nil, {0,-stores_nb_y - stores_radius}, base.name)

    object = addStrokeText(nil, "SIM", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {0, 0}, warn_base.name)
    object.element_params = {default_element_params, "WPN_MASS", "WPN_LATEARM"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_MASS_IDS.SIM}, {"parameter_in_range", 2, WPN_LATEARM_IDS.GUARD-0.05, WPN_LATEARM_IDS.SAFE+0.05}}

    object = addStrokeText(nil, "SIM-RDY", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {0, 0}, warn_base.name, nil, nil)
    object.element_params = {default_element_params, "WPN_SIM_READY"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

    -- RELEASE
    object = addStrokeText(nil, "RELEASE", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {0, 0}, warn_base.name)
    object.element_params = {default_element_params, "WPN_RELEASE"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

    -- RDY
    object = addStrokeText(nil, "RDY", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {0, 0}, warn_base.name)
    object.element_params = {default_element_params, "WPN_READY", "WPN_RELEASE"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, 0}}

    default_parent = save_default_parent
end

page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."FULL", "CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,0}, {"parameter_compare_with_number", 1, SUB_PAGE_ID.MENU2, 1}}

local origin = addPlaceholder(nil,
    {-0.5, -((aspect-0.45)/2 + 0.3)}, page_root.name)
origin.element_params = {"CMFD"..CMFDNu.."SelLeft"}
origin.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.SMS}}
local panel_background = addFillBox(nil, 0.96, aspect-0.42,
    "CenterCenter", {0,0}, origin.name, nil, CMFD_MATERIAL_DARK)
panel_background.additive_alpha = false

object = addStrokeText(nil, "NO WEAPON\nDELIVERY", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {0, 0}, origin.name, nil, {"%05.0f"})
object.element_params = {default_element_params, "SMS_ON"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

object = addStrokeText(nil, "OFF", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-2  / 6, 0.35}, object.name)
object.element_params = {default_element_params, "SMS_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_MODE_IDS.SAFE}}


object = addPlaceholder(nil, nil, origin.name)
object.element_params = {"SMS_ON"}
object.controllers = {{"parameter_compare_with_number", 0, 1}}

addStoreSec(object.name)

origin = addPlaceholder(nil,
    {0.5, -((aspect-0.45)/2 + 0.3)}, page_root.name)
origin.element_params = {"CMFD"..CMFDNu.."SelRight"}
origin.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.SMS}}
panel_background = addFillBox(nil, 0.96, aspect-0.42,
    "CenterCenter", {0,0}, origin.name, nil, CMFD_MATERIAL_DARK)
panel_background.additive_alpha = false

object = addStrokeText(nil, "NO WEAPON\nDELIVERY", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {0, 0}, origin.name)
object.element_params = {default_element_params, "SMS_ON"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

object = addStrokeText(nil, "OFF", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-2  / 6, 0.35}, object.name)
object.element_params = {default_element_params, "SMS_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, SMS_MODE_IDS.SAFE}}

object = addPlaceholder(nil, nil, origin.name)
object.element_params = {"SMS_ON"}
object.controllers = {{"parameter_compare_with_number", 0, 1}}

addStoreSec(object.name)
