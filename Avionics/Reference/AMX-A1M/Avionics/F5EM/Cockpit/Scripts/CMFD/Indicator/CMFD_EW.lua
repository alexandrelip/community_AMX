dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_SMS_ID_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/weapon_system_api.lua")


local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_in_range", 0, SUB_PAGE_ID.EW - 0.05, SUB_PAGE_ID.EW + 0.05}}

local object

local rwr_on_object = addPlaceholder(nil, nil)
rwr_on_object.element_params = {"RWR_ON", "CMFD"..CMFDNu.."Format"}
rwr_on_object.controllers = {
    {"parameter_compare_with_number", 0, 0, 1},
    {"parameter_in_range", 1, SUB_PAGE_ID.EW - 0.05, SUB_PAGE_ID.EW + 0.05},
}

-- OSSs
object = addOSSText(28, "ALL", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_MODE_PRI"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}
object = addOSSText(28, "PRI", rwr_on_object.name)
object = encapsulateObject(object)
object.element_params = {default_element_params, "RWR_MODE_PRI"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

object = addOSSText(27, "SRCH", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_SEARCH"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

object = addOSSText(27, "TRCK", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_SEARCH"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

object = addOSSText(25, "CH/F\nMAN", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_CH_F_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}
object = addOSSText(25, "CH/F\nSEMI", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_CH_F_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}
object = addOSSText(25, "CH/F\nAUTO", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_CH_F_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}}


object = addOSSText(24, "PROG\n0", rwr_on_object.name, nil, nil, {"PROG\n%02.0f"})
object.element_params = {default_element_params, "RWR_PROG"}
object.controllers = {default_controllers[1],  {"text_using_parameter", 1, 0}}

-- [Fase 2C] Nome do programa EW selecionado (logo abaixo do OSS24 PROG)
-- + Q'tdes chaff/flare por salvo. Ajuda o piloto a saber o que esta carregado
-- antes de chamar MAN PROG ou tirar do AUTO.
object = addOSSText(24, "\n\nXXX", rwr_on_object.name, nil, nil, {"\n\n%s"}, CMFD_FONT_CYAN)
object.element_params = {default_element_params, "EW_PROG_NAME"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

object = addOSSText(24, "\n\n\nC0 F0", rwr_on_object.name, nil, nil, {"\n\n\nC%01.0f F%01.0f"}, CMFD_FONT_CYAN)
object.element_params = {default_element_params, "EW_PROG_CHAFF", "EW_PROG_FLARE"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}}


object = addOSSText(5, "STR\n0", rwr_on_object.name, nil, nil, {"STR\n%0.0f"})
object.element_params = {default_element_params, "RWR_STR"}
object.controllers = {default_controllers[1],  {"text_using_parameter", 1, 0}}

object = addOSSText(6, "PFM\n0", rwr_on_object.name, nil, nil, {"PFM\n%0.0f"})
object.element_params = {default_element_params, "RWR_PFM"}
object.controllers = {default_controllers[1],  {"text_using_parameter", 1, 0}}

object = addOSSText(7, "EVENT\nMARK", rwr_on_object.name)

object = addOSSText(9, "SIM", rwr_on_object.name, nil, nil)
object.element_params = {default_element_params, "WPN_MASS"}
object.controllers = {default_controllers[1],  {"parameter_compare_with_number", 1, WPN_MASS_IDS.SIM}}

object = addOSSStrokeBox(9, 1, rwr_on_object.name, nil, nil, nil, 3)
object.element_params = {default_element_params, "WPN_MASS", "RWR_SIM"}
object.controllers = {default_controllers[1],  {"parameter_compare_with_number", 1, WPN_MASS_IDS.SIM}, {"parameter_compare_with_number", 2, 1}}


object = addOSSText(10, "CH/F\nWARN\n00/00", rwr_on_object.name, nil, nil, {"CH/F\nWARN\n%02.0f/", "%02.0f"})
object.element_params = {default_element_params, "RWR_WARN_CH", "RWR_WARN_F"}
object.controllers = {default_controllers[1],  {"text_using_parameter", 1, 0},{"text_using_parameter", 2, 1}}

object = addOSSText(11, "MAN\nPROG\n0", rwr_on_object.name, nil, nil, {"MAN\nPROG\n%02.0f"})
object.element_params = {default_element_params, "RWR_MAN_PROG"}
object.controllers = {default_controllers[1],  {"text_using_parameter", 1, 0}}

-- Grid

function addScreen(parent)
    save_parent = default_parent
    default_parent = parent

    local object = addStrokeText(nil, "RWR OFF", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, 0}, nil, nil, {"%05.0f"}, CMFD_FONT_Y)
    object = encapsulateObject(object)
    object.element_params = {"RWR_ON"}
    object.controllers = {{"parameter_compare_with_number", 0, 0}}

    object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "rwr-reticle"}, "CenterCenter", {0, 0}, nil, nil, 0.012, CMFD_MATERIAL_CYAN)
    object = encapsulateObject(object)
    object.element_params = {"RWR_ON"}
    object.controllers = {{"parameter_in_range", 0, 0.5, 2.5}}

    default_parent = object.name

    ---------------------- Threats
    MaxThreats          = 16

    for i=1,MaxThreats do
        local place = addPlaceholder(nil, {0,0})
        if i <= 5 then 
            place.element_params = {
                "RWR_CONTACT_" .. string.format("%02i", i) .. "_SIGNAL", 
                "RWR_CONTACT_" .. string.format("%02i", i) .. "_AZIMUTH", 
                "RWR_SEARCH",
            }
            place.controllers = {
                {"parameter_in_range", 0, 0.5, 10},
                {"rotate_using_parameter", 1, 1},
                {"compare_parameters", 0, 2, 1},
            }
        else
            place.element_params = {
                "RWR_CONTACT_" .. string.format("%02i", i) .. "_SIGNAL", 
                "RWR_CONTACT_" .. string.format("%02i", i) .. "_AZIMUTH",
                "RWR_MODE_PRI",
                "RWR_SEARCH",
            }
            place.controllers = {
                {"parameter_in_range", 0, 0.5, 10},
                {"rotate_using_parameter", 1, 1},
                {"parameter_compare_with_number", 2, 0},
                {"compare_parameters", 0, 3, 1},
            }
        end

        place = addPlaceholder(nil, {0,0.6}, place.name)
        place.element_params = {
            "RWR_CONTACT_" .. string.format("%02i", i) .. "_POWER", 
            "RWR_CONTACT_" .. string.format("%02i", i) .. "_AZIMUTH", 
        }
        place.controllers = {
            {"move_up_down_using_parameter", 0, -GetScale()*0.4},
            {"rotate_using_parameter", 1, -1},
        }
        local contact_prefix = "RWR_CONTACT_" .. string.format("%02i", i)
        local contact_iff = contact_prefix .. "_IFF"

        object = addStrokeText(nil, "??", CMFD_STRINGDEFS_DEF_X1, "CenterCenter", {0, 0}, place.name, nil, {"%s"}, CMFD_FONT_W)
        object.element_params = {default_element_params, contact_prefix .. "_TYPE", contact_iff}
        object.controllers = {
            default_controllers[1],
            {"text_using_parameter", 1},
            {"change_color_when_parameter_equal_to_number", 2, 0, 1, 1, 1},
            {"change_color_when_parameter_equal_to_number", 2, 1, 0, 1, 0},
            {"change_color_when_parameter_equal_to_number", 2, 2, 1, 0, 0},
        }

        if i==1 then
            object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "rwr-threat"}, "CenterCenter", {0, 0}, place.name, nil, 0.01, CMFD_MATERIAL_WHITE)
            object.element_params = {contact_iff}
            object.controllers = {
                {"change_color_when_parameter_equal_to_number", 0, 0, 1, 1, 1},
                {"change_color_when_parameter_equal_to_number", 0, 1, 0, 1, 0},
                {"change_color_when_parameter_equal_to_number", 0, 2, 1, 0, 0},
            }
            object = encapsulateObject(object)
            object.element_params = {contact_prefix .. "_NEW"}
            object.controllers = {{"parameter_compare_with_number", 0, 0}}
        end

        object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "rwr-track"}, "CenterBottom", {0, 0}, place.name, nil, 0.01, CMFD_MATERIAL_WHITE)
        object.element_params = {contact_iff}
        object.controllers = {
            {"change_color_when_parameter_equal_to_number", 0, 0, 1, 1, 1},
            {"change_color_when_parameter_equal_to_number", 0, 1, 0, 1, 0},
            {"change_color_when_parameter_equal_to_number", 0, 2, 1, 0, 0},
        }
        object = encapsulateObject(object)
        object.element_params = {contact_prefix .. "_SIGNAL"}
        object.controllers = {{"parameter_compare_with_number", 0, 2}}

        object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "rwr-msl"}, "CenterCenter", {0, 0}, place.name, nil, 0.01, CMFD_MATERIAL_WHITE)
        object.element_params = {contact_iff}
        object.controllers = {
            {"change_color_when_parameter_equal_to_number", 0, 0, 1, 1, 1},
            {"change_color_when_parameter_equal_to_number", 0, 1, 0, 1, 0},
            {"change_color_when_parameter_equal_to_number", 0, 2, 1, 0, 0},
        }
        object = encapsulateObject(object)
        object.element_params = {contact_prefix .. "_SIGNAL"}
        object.controllers = {{"parameter_compare_with_number", 0, 3}, {"blinking"}}

        object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "rwr-new"}, "CenterCenter", {0, 0}, place.name, nil, 0.01, CMFD_MATERIAL_WHITE)
        object.element_params = {contact_iff}
        object.controllers = {
            {"change_color_when_parameter_equal_to_number", 0, 0, 1, 1, 1},
            {"change_color_when_parameter_equal_to_number", 0, 1, 0, 1, 0},
            {"change_color_when_parameter_equal_to_number", 0, 2, 1, 0, 0},
        }
        object = encapsulateObject(object)
        object.element_params = {contact_prefix .. "_NEW"}
        object.controllers = {{"parameter_compare_with_number", 0, 1}}
    end

    -- Link-BR2/E-99 awareness overlay. Nearby bearings use radial lanes;
    -- symbols never consume RWR signal, lock, launch or priority handles.
    for i=1,8 do
        local slot = string.format("%02d", i)
        local prefix = "EW_DL_TRACK_" .. slot
        local bearing = addPlaceholder(nil, {0,0})
        bearing.element_params = {
            prefix .. "_VALID",
            prefix .. "_SOURCE_KIND",
            prefix .. "_BRG",
            "AVIONICS_HDG",
            "CMFD"..tostring(CMFDNu).."FULL",
        }
        bearing.controllers = {
            {"parameter_in_range", 0, 0.95, 1.05},
            {"parameter_in_range", 1, 0.95, 2.05},
            {"rotate_using_parameter", 2, -math.rad(1)},
            {"rotate_using_parameter", 3, math.rad(1)},
            -- The eight-track radial picture does not fit inside an EW split
            -- mini-panel. Keep it on the full EW page so it cannot spill into
            -- the radar occupying the upper pane.
            {"parameter_in_range", 4, 0.95, 1.05},
        }

        local marker = addPlaceholder(nil, {0,0.30}, bearing.name)
        marker.element_params = {prefix .. "_LANE"}
        marker.controllers = {{"move_up_down_using_parameter", 0, 0.05}}
        object = addStrokeBox(nil, 0.034, 0.034, "CenterCenter", {0,0},
            marker.name, nil, "CMFD_IND_MAGENTA")
        object.init_rot = {45}

        local label = addPlaceholder(nil, {0,0}, marker.name)
        label.element_params = {prefix .. "_BRG", "AVIONICS_HDG"}
        label.controllers = {
            {"rotate_using_parameter", 0, math.rad(1)},
            {"rotate_using_parameter", 1, -math.rad(1)},
        }
        object = addStrokeText(nil, "DL", CMFD_STRINGDEFS_DEF_X04,
            "LeftCenter", {0.028, 0.012}, label.name, nil, nil, CMFD_FONT_MAGENTA)
        object.element_params = {prefix .. "_SOURCE_KIND"}
        object.controllers = {{"parameter_in_range", 0, 0.95, 1.05}}
        object = addStrokeText(nil, "E", CMFD_STRINGDEFS_DEF_X04,
            "LeftCenter", {0.028, 0.012}, label.name, nil, nil, CMFD_FONT_MAGENTA)
        object.element_params = {prefix .. "_SOURCE_KIND"}
        object.controllers = {{"parameter_in_range", 0, 1.95, 2.05}}
    end


    -- Other Objects
    -- Chaff
    object = addStrokeText(nil, "CH", CMFD_STRINGDEFS_DEF_X15, "CenterCenter", {-0.5, -0.55}, nil, nil)
    object = addStrokeBox(nil, 0.25, 0.1, "CenterCenter", {-0.5, -0.675})

    -- Less than warn count
    object = addStrokeText(nil, "30", CMFD_STRINGDEFS_DEF_X15, "CenterCenter", {-0.5, -0.675}, nil, nil, {"%0.0f"}, CMFD_FONT_Y)
    object.element_params = {default_element_params, "WPN_CHAFF_COUNT", "RWR_WARN_CH"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}, {"change_color_when_parameter_equal_to_number", 1, 0, 1, 0, 1}, {"compare_parameters", 1, 2, -1}}

    -- More than warn count
    object = addStrokeText(nil, "30", CMFD_STRINGDEFS_DEF_X15, "CenterCenter", {-0.5, -0.675}, nil, nil, {"%0.0f"})
    object.element_params = {default_element_params, "WPN_CHAFF_COUNT", "RWR_WARN_CH"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}, {"compare_parameters", 1, 2, 1}}

    -- Flare
    object = addStrokeText(nil, "F", CMFD_STRINGDEFS_DEF_X15, "CenterCenter", {0.5, -0.55}, nil, nil)
    object = addStrokeBox(nil, 0.25, 0.1, "CenterCenter", {0.5, -0.675})

    -- Less than warn count
    object = addStrokeText(nil, "15", CMFD_STRINGDEFS_DEF_X15, "CenterCenter", {0.5, -0.675}, nil, nil, {"%0.0f"}, CMFD_FONT_Y)
    object.element_params = {default_element_params, "WPN_FLARE_COUNT", "RWR_WARN_F"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}, {"change_color_when_parameter_equal_to_number", 1, 0, 1, 0, 1}, {"compare_parameters", 1, 2, -1}}

    -- More than warn count
    object = addStrokeText(nil, "15", CMFD_STRINGDEFS_DEF_X15, "CenterCenter", {0.5, -0.675}, nil, nil, {"%0.0f"})
    object.element_params = {default_element_params, "WPN_FLARE_COUNT", "RWR_WARN_F"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}, {"compare_parameters", 1, 2, 1}}

    object = addStrokeText(nil, "CH/F - OFF", CMFD_STRINGDEFS_DEF_X15, "CenterCenter", {0, -0.675}, nil, nil, {"%s"})
    object.element_params = {default_element_params, "RWR_ON"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

    object = addStrokeText(nil, "CH/F - SAFE", CMFD_STRINGDEFS_DEF_X15, "CenterCenter", {0, -0.675}, nil, nil, {"%s"}, CMFD_FONT_Y)
    object.element_params = {default_element_params, "RWR_ON", "BASE_SENSOR_WOW_LEFT_GEAR"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}, {"parameter_compare_with_number", 2, 1}}

    object = addStrokeText(nil, "CH/F - SIM", CMFD_STRINGDEFS_DEF_X15, "CenterCenter", {0, -0.675}, nil, nil, {"%s"}, CMFD_FONT_W)
    object.element_params = {default_element_params, "RWR_ON", "RWR_SIM", "BASE_SENSOR_WOW_LEFT_GEAR", "WPN_MASS"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}, {"parameter_compare_with_number", 2, 1}, {"parameter_compare_with_number", 3, 0}, {"parameter_compare_with_number", 4, WPN_MASS_IDS.SIM}}

    -- [Fase EW-1] Indicador do bridge Export.lua (F5EM_EW_bridge_consumer.lua).
    -- SRC = "BR" quando o bridge esta vivo publicando handles reais (LoGetSnares
    -- + surrogates SAM/naval); "-- " quando o bridge esta ausente/desligado e o
    -- CMFD cai no engine avSimpleRWR puro. Codigo NATO do primario ao lado
    -- (0 = desconhecido, resto = codigo por familia via classify_nato_type).
    object = addStrokeText(nil, "BR --", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.55, 0.75}, nil, nil, {"BR --"}, CMFD_FONT_Y)
    object.element_params = {default_element_params, "RWR_BRIDGE_ALIVE"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

    object = addStrokeText(nil, "BR ON", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {-0.55, 0.75}, nil, nil, {"BR ON"}, CMFD_FONT_CYAN)
    object.element_params = {default_element_params, "RWR_BRIDGE_ALIVE"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

    -- PRI TYPE: renderiza codigo NATO do primario quando o bridge esta vivo E
    -- classificou algo (!=0). Fica no canto sup direito do scope, complementa
    -- (nao substitui) a string "aXa" que rwr.lua ja escreve em cada contato.
    object = addStrokeText(nil, "T000", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.55, 0.75}, nil, nil, {"T%03.0f"}, CMFD_FONT_CYAN)
    object.element_params = {default_element_params, "RWR_BRIDGE_ALIVE", "RWR_PRI_TYPE_NATO"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}, {"text_using_parameter", 2, 0}, {"parameter_in_range", 2, 0.5, 999}}

    -- [Fase EW-6] Friend/foe (IFF) do primario, abaixo do codigo NATO.
    -- FRD (verde) = amigo confirmado; FOE (vermelho) = inimigo confirmado
    -- (SAM/naval do scan de coalizao, ou snare com coalizao conhecida).
    -- Sem rotulo quando desconhecido (RWR_PRI_IFF==0) -> nunca inventa amigo.
    object = addStrokeText(nil, "FRD", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.55, 0.63}, nil, nil, {"FRD"}, CMFD_FONT_G)
    object.element_params = {default_element_params, "RWR_BRIDGE_ALIVE", "RWR_PRI_IFF"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, 1}}

    object = addStrokeText(nil, "FOE", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.55, 0.63}, nil, nil, {"FOE"}, CMFD_FONT_R)
    object.element_params = {default_element_params, "RWR_BRIDGE_ALIVE", "RWR_PRI_IFF"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, 2}}

    object = addStrokeText(nil, "UNK", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.55, 0.63}, nil, nil, {"UNK"}, CMFD_FONT_W)
    object.element_params = {default_element_params, "RWR_BRIDGE_ALIVE", "RWR_PRI_IFF"}
    object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}, {"parameter_compare_with_number", 2, 0}}

    object = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X04,
        "CenterCenter", {0, 0.84}, nil, nil, {"%s"}, CMFD_FONT_CYAN)
    object.element_params = {default_element_params, "RWR_TOP_THREAT_DETAIL"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

    default_parent = save_parent
end

local area_width = 1
local area_height = aspect + 0.3

local top_base = addPlaceholder(nil, {0, area_height / 2 - 0.3}, page_root.name)
top_base.element_params = {"CMFD"..CMFDNu.."Format"}
top_base.controllers = {{"parameter_in_range", 0, SUB_PAGE_ID.EW - 0.05, SUB_PAGE_ID.EW + 0.05}}
addScreen(top_base.name)

page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.MENU2, 1}}

-- Left Sec

local origin = addPlaceholder(nil, {0,0}, page_root.name)
origin.element_params = {"CMFD"..CMFDNu.."FULL", "CMFD"..CMFDNu.."SelLeft"}
origin.controllers = {
    {"parameter_in_range", 0, -0.05, 0.05},
    {"parameter_in_range", 1, SUB_PAGE_ID.EW - 0.05, SUB_PAGE_ID.EW + 0.05},
}
local panel_y = -((aspect-0.45)/2 + 0.3)
local panel_background = addFillBox(nil, 0.96, aspect-0.42,
    "CenterCenter", {-0.5, panel_y}, origin.name, nil, CMFD_MATERIAL_DARK)
panel_background.additive_alpha = false

local rwr_on_object = addPlaceholder(nil, nil, origin.name)
rwr_on_object.element_params = {"RWR_ON"}
rwr_on_object.controllers = {{"parameter_compare_with_number", 0, 0, 1}}

object = addOSSText(23, "A\nL\nL", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_MODE_PRI"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}
object = addOSSText(23, "P\nR\nI", rwr_on_object.name)
object = encapsulateObject(object)
object.element_params = {default_element_params, "RWR_MODE_PRI"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

object = addOSSText(22, "T\nR\nC\nK", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_SEARCH"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}
object = addOSSText(22, "S\nR\nC\nH", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_SEARCH"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

object = addOSSText(21, "M\nA\nN", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_CH_F_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}
object = addOSSText(21, "S\nE\nM\nI", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_CH_F_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}
object = addOSSText(21, "A\nU\nT\nO", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_CH_F_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}}


object = addPlaceholder(nil, {-0.5, -((aspect-0.45)/2 + 0.3)}, origin.name)
object.controllers = {{"scale", 0.6, 0.6, 0.6}}

addScreen(object.name)

object = addStrokeText(nil, "STR\n0", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.55,0.55},object.name,nil, {"STR\n%0.0f"})
object.element_params = {default_element_params, "RWR_STR", "RWR_ON"}
object.controllers = {default_controllers[1],  {"text_using_parameter", 1, 0}, {"parameter_compare_with_number", 2, 0, 1} , {"scale", 1.667, 1.667}}


-- Right Sec
origin = addPlaceholder(nil, {0, 0}, page_root.name)
origin.element_params = {"CMFD"..CMFDNu.."FULL", "CMFD"..CMFDNu.."SelRight"}
origin.controllers = {
    {"parameter_in_range", 0, -0.05, 0.05},
    {"parameter_in_range", 1, SUB_PAGE_ID.EW - 0.05, SUB_PAGE_ID.EW + 0.05},
}
panel_background = addFillBox(nil, 0.96, aspect-0.42,
    "CenterCenter", {0.5, panel_y}, origin.name, nil, CMFD_MATERIAL_DARK)
panel_background.additive_alpha = false

rwr_on_object = addPlaceholder(nil, nil, origin.name)
rwr_on_object.element_params = {"RWR_ON"}
rwr_on_object.controllers = {{"parameter_compare_with_number", 0, 0, 1}}

object = addOSSText(12, "A\nL\nL", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_MODE_PRI"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

object = addOSSText(12, "P\nR\nI", rwr_on_object.name)
object = encapsulateObject(object)
object.element_params = {default_element_params, "RWR_MODE_PRI"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

object = addOSSText(13, "S\nR\nC\nH", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_SEARCH"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

object = addOSSText(13, "T\nR\nC\nK", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_SEARCH"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}

object = addOSSText(14, "M\nA\nN", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_CH_F_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}
object = addOSSText(14, "S\nE\nM\nI", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_CH_F_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}
object = addOSSText(14, "A\nU\nT\nO", rwr_on_object.name)
object.element_params = {default_element_params, "RWR_CH_F_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 2}}

object = addPlaceholder(nil, {0.5, -((aspect-0.45)/2 + 0.3)}, origin.name)
object.controllers = {{"scale", 0.6, 0.6, 0.6}}

addScreen(object.name)

object = addStrokeText(nil, "STR\n0", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0.55,0.55},object.name,nil, {"STR\n%0.0f"})
object.element_params = {default_element_params, "RWR_STR", "RWR_ON"}
object.controllers = {default_controllers[1],  {"text_using_parameter", 1, 0}, {"parameter_compare_with_number", 2, 0, 1} , {"scale", 1.667, 1.667}}
