dofile(LockOn_Options.script_path.."Systems/engine_api.lua")


local EICAS_TQ = get_param_handle("EICAS_TQ")
local EICAS_TQ_ROT = get_param_handle("EICAS_TQ_ROT")
local EICAS_TQ_REQ_ROT = get_param_handle("EICAS_TQ_REQ_ROT")
local EICAS_TQ_OPT_ROT = get_param_handle("EICAS_TQ_OPT_ROT")
local EICAS_TQ_COR = get_param_handle("EICAS_TQ_COR")

local EICAS_T5 = get_param_handle("EICAS_T5")
local EICAS_T5_ROT = get_param_handle("EICAS_T5_ROT")
local EICAS_T5_COR = get_param_handle("EICAS_T5_COR")

local EICAS_OIL_PRESS = get_param_handle("EICAS_OIL_PRESS")
local EICAS_OIL_PRESS_COR = get_param_handle("EICAS_OIL_PRESS_COR")

local EICAS_OIL_TEMP = get_param_handle("EICAS_OIL_TEMP")
local EICAS_OIL_TEMP_COR = get_param_handle("EICAS_OIL_TEMP_COR")

local EICAS_NP = get_param_handle("EICAS_NP")
local EICAS_NP_COR = get_param_handle("EICAS_NP_COR")

local EICAS_NG = get_param_handle("EICAS_NG")
local EICAS_NG_COR = get_param_handle("EICAS_NG_COR")

local EICAS_OAT = get_param_handle("EICAS_OAT")

local EICAS_IGN = get_param_handle("EICAS_IGN")

local EICAS_ENG_MODE = get_param_handle("EICAS_ENG_MODE")

local EICAS_HYD = get_param_handle("EICAS_HYD")
local EICAS_HYD_COR = get_param_handle("EICAS_HYD_COR")

local EICAS_CAB_PRESS = get_param_handle("EICAS_CAB_PRESS")
local EICAS_CAB_PRESS_COR = get_param_handle("EICAS_CAB_PRESS_COR")

local EICAS_BAT_AMP = get_param_handle("EICAS_BAT_AMP")
local EICAS_BAT_AMP_COR = get_param_handle("EICAS_BAT_AMP_COR")

local EICAS_BAT_VOLT = get_param_handle("EICAS_BAT_VOLT")
local EICAS_BAT_VOLT_COR = get_param_handle("EICAS_BAT_VOLT_COR")

local EICAS_BAT_TEMP = get_param_handle("EICAS_BAT_TEMP")
local EICAS_BAT_TEMP_COR = get_param_handle("EICAS_BAT_TEMP_COR")


local EICAS_FLAP = get_param_handle("EICAS_FLAP")
local EICAS_FLAP_TXT = get_param_handle("EICAS_FLAP_TXT")

local EICAS_SPD_BRK = get_param_handle("EICAS_SPD_BRK")
local EICAS_SPD_BRK_TXT = get_param_handle("EICAS_SPD_BRK_TXT")

local EICAS_INIT = get_param_handle("EICAS_INIT")

fuel_init = 495;
fuel_random = 0 --os.time()%30
fuel_joker = 300;


local torque_tempo = -1
local np_tempo = -1
local oat_base = 25

local engine_limits_warning = 0
local fuel_imbalance_caution = 0
local fuel_joker_voice = 0
local fuel_bingo_caution = 0


local cabin_press_cor=0

local function calc_dist(dest_lat_m, dest_lon_m, orig_lat_m, orig_lon_m)
    local o_lat_m, o_alt_m, o_lon_m = sensor_data.getSelfCoordinates()
    orig_lat_m = orig_lat_m or o_lat_m
    orig_lon_m = orig_lon_m or o_lon_m

    local lat = dest_lat_m - orig_lat_m
    local lon = dest_lon_m - orig_lon_m

    return math.sqrt(lat * lat + lon * lon)

end


local EICAS = {
    E1_ROT = get_param_handle("EICAS_E1_ROT"),
    E1_ROT_POS = get_param_handle("EICAS_E1_ROT_POS"),
    E1_ROT_COLOR = get_param_handle("EICAS_E1_ROT_COLOR"),
    E2_ROT = get_param_handle("EICAS_E2_ROT"),
    E2_ROT_POS = get_param_handle("EICAS_E2_ROT_POS"),
    E2_ROT_COLOR = get_param_handle("EICAS_E2_ROT_COLOR"),

    E1_TEMP = get_param_handle("EICAS_E1_TEMP"),
    E1_TEMP_POS = get_param_handle("EICAS_E1_TEMP_POS"),
    E1_TEMP_COLOR = get_param_handle("EICAS_E1_TEMP_COLOR"),
    E2_TEMP = get_param_handle("EICAS_E2_TEMP"),
    E2_TEMP_POS = get_param_handle("EICAS_E2_TEMP_POS"),
    E2_TEMP_COLOR = get_param_handle("EICAS_E2_TEMP_COLOR"),

    E1_FF = get_param_handle("EICAS_E1_FF"),
    E2_FF = get_param_handle("EICAS_E2_FF"),

    E1_OIL_PRES = get_param_handle("EICAS_E1_OIL_PRES"),
    E1_OIL_PRES_POS = get_param_handle("EICAS_E1_OIL_PRES_POS"),
    E1_OIL_PRES_COLOR = get_param_handle("EICAS_E1_OIL_PRES_COLOR"),
    E2_OIL_PRES = get_param_handle("EICAS_E2_OIL_PRES"),
    E2_OIL_PRES_POS = get_param_handle("EICAS_E2_OIL_PRES_POS"),
    E2_OIL_PRES_COLOR = get_param_handle("EICAS_E2_OIL_PRES_COLOR"),

    E1_NOZZLE = get_param_handle("EICAS_E1_NOZZLE"),
    E1_NOZZLE_POS = get_param_handle("EICAS_E1_NOZZLE_POS"),
    E2_NOZZLE = get_param_handle("EICAS_E2_NOZZLE"),
    E2_NOZZLE_POS = get_param_handle("EICAS_E2_NOZZLE_POS"),

    HYD_UTIL = get_param_handle("EICAS_HYD_UTIL"),
    HYD_UTIL_POS = get_param_handle("EICAS_HYD_UTIL_POS"),
    HYD_UTIL_COLOR = get_param_handle("EICAS_HYD_UTIL_COLOR"),
    HYD_FLT = get_param_handle("EICAS_HYD_FLT"),
    HYD_FLT_POS = get_param_handle("EICAS_HYD_FLT_POS"),
    HYD_FLT_COLOR = get_param_handle("EICAS_HYD_FLT_COLOR"),

    FUEL = get_param_handle("EICAS_FUEL"),
    FUEL_POS = get_param_handle("EICAS_FUEL_POS"),
    FUEL_COLOR = get_param_handle("EICAS_FUEL_COLOR"),
    FUEL_INTR = get_param_handle("EICAS_FUEL_INTR"),
    FUEL_INTR_POS = get_param_handle("EICAS_FUEL_INTR_POS"),
    FUEL_CNTR = get_param_handle("EICAS_FUEL_CNTR"),
    FUEL_INBD = get_param_handle("EICAS_FUEL_INBD"),


    FUEL_COR = get_param_handle("EICAS_FUEL_COR"),
    FUEL_LEFT = get_param_handle("EICAS_FUEL_LEFT"),
    FUEL_LEFT_COR = get_param_handle("EICAS_FUEL_LEFT_COR"),
    FUEL_RIGHT = get_param_handle("EICAS_FUEL_RIGHT"),
    FUEL_RIGHT_COR = get_param_handle("EICAS_FUEL_RIGHT_COR"),
    FUEL_JOKER = get_param_handle("EICAS_FUEL_JOKER"),
    FUEL_BINGO = get_param_handle("UFCP_FUEL_BINGO"),
    FUEL_HMPT = get_param_handle("UFCP_FUEL_HMPT"),
    FUEL_JOKER_ROT = get_param_handle("EICAS_FUEL_JOKER_ROT"),
    FUEL_TOT_ROT = get_param_handle("EICAS_FUEL_TOT_ROT"),
    FUEL_INT_ROT = get_param_handle("EICAS_FUEL_INT_ROT"),
    FUEL_INIT = get_param_handle("EICAS_FUEL_INIT"),

    ERROR_LEFTGEN = get_param_handle("EICAS_ERROR_LEFTGEN"),
    ERROR_CANOPY = get_param_handle("EICAS_ERROR_CANOPY"),
    ERROR_RIGHTGEN = get_param_handle("EICAS_ERROR_RIGHTGEN"),
}

EICAS.FUEL_INIT:set(fuel_init)
EICAS.FUEL_JOKER:set(fuel_joker)

-- [Fase 5.2] Timers para deteccao de RPM amarelo (102.5-106.5%) prolongado.
-- Se permanecer acima de 102.5% por mais de 1.0s, escala para vermelho (3).
-- Antes esses TODOs ficavam pendentes e o alerta de overspeed nunca disparava.
local e1_rot_warn_t0 = nil
local e2_rot_warn_t0 = nil
local RPM_WARN_HOLD_SEC = 1.0


function update_eicas()

    -- rpm --
    -- Se o RPM chegar acima de 103% de rpm por mais de um segundo, a cor do indicador mudará de amarelo para vermelho ou se chegar a 107% de rpm acenderá no EFI / EICAS a indicação em vermelho “LEFT ENG” ou “RIGHT ENG”.

    e1_rot = sensor_data.getEngineLeftRPM() * 100
    if e1_rot <= 60 then e1_rot_pos = e1_rot / 60 * 90
    else e1_rot_pos = 90 + (e1_rot-60) / 30 * 90 end
    
    if e1_rot < 48.5 then
        EICAS.E1_ROT_COLOR:set(2)
        e1_rot_warn_t0 = nil
    elseif e1_rot < 102.5 then
        EICAS.E1_ROT_COLOR:set(0)
        e1_rot_warn_t0 = nil
    elseif e1_rot < 106.5 then
        -- amarelo; vira vermelho (3) se hold passar de 1s
        local now = get_absolute_model_time()
        if e1_rot_warn_t0 == nil then e1_rot_warn_t0 = now end
        if (now - e1_rot_warn_t0) >= RPM_WARN_HOLD_SEC then
            EICAS.E1_ROT_COLOR:set(3)
        else
            EICAS.E1_ROT_COLOR:set(1)
        end
    else
        EICAS.E1_ROT_COLOR:set(3)
        e1_rot_warn_t0 = nil
    end

    e2_rot = sensor_data.getEngineRightRPM() * 100
    if e2_rot <= 60 then e2_rot_pos = e2_rot / 60 * 90
    else e2_rot_pos = 90 + (e2_rot-60) / 30 * 90 end

    if e2_rot < 48.5 then
        EICAS.E2_ROT_COLOR:set(2)
        e2_rot_warn_t0 = nil
    elseif e2_rot < 102.5 then
        EICAS.E2_ROT_COLOR:set(0)
        e2_rot_warn_t0 = nil
    elseif e2_rot < 106.5 then
        local now = get_absolute_model_time()
        if e2_rot_warn_t0 == nil then e2_rot_warn_t0 = now end
        if (now - e2_rot_warn_t0) >= RPM_WARN_HOLD_SEC then
            EICAS.E2_ROT_COLOR:set(3)
        else
            EICAS.E2_ROT_COLOR:set(1)
        end
    else
        EICAS.E2_ROT_COLOR:set(3)
        e2_rot_warn_t0 = nil
    end

    EICAS.E1_ROT:set(e1_rot)
    EICAS.E1_ROT_POS:set(e1_rot_pos)
    EICAS.E2_ROT:set(e2_rot)
    EICAS.E2_ROT_POS:set(e2_rot_pos)

    -- EGT --
    -- Se a indicação ultrapassar 686ºC acenderá no EFI / EICAS a indicação em vermelho “LEFT ENG” ou “RIGHT ENG”, o mesmo ocorrerá se ficar por mais de 10 segundos entre 675ºC e 685ºC além da cor passar de amarelo para vermelho.
    e1_temp = get_cockpit_draw_argument_value(12)
    if e1_temp <= 0.03 then e1_temp = e1_temp * 140/0.03
    elseif e1_temp <= 0.1 then e1_temp = 140 + (e1_temp-0.03) * 60/0.07
    elseif e1_temp <= 0.274 then e1_temp = 200 + (e1_temp-0.1) * 300/0.174
    elseif e1_temp <= 0.78 then e1_temp = 500 + (e1_temp-0.274) * 300/(0.78-0.174)
    else e1_temp = 800 + (e1_temp-0.78) * 400/(1-0.78)
    end

    if e1_temp < 324.5 then EICAS.E1_TEMP_COLOR:set(0) 
    elseif e1_temp < 674.5 then EICAS.E1_TEMP_COLOR:set(1)
    elseif e1_temp < 684.5 then EICAS.E1_TEMP_COLOR:set(2)
    else EICAS.E1_TEMP_COLOR:set(3)
    end

    if e1_temp <= 500 then e1_temp_pos = e1_temp / 500 * 90
    elseif e1_temp <= 700 then e1_temp_pos = 90 + (e1_temp - 500) / 200 * 150
    else e1_temp_pos = 240 + (e1_temp - 700) / 500 * 60
    end

    e2_temp = get_cockpit_draw_argument_value(14)
    if e2_temp <= 0.03 then e2_temp = e2_temp * 140/0.03
    elseif e2_temp <= 0.1 then e2_temp = 140 + (e2_temp-0.03) * 60/0.07
    elseif e2_temp <= 0.274 then e2_temp = 200 + (e2_temp-0.1) * 300/0.174
    elseif e2_temp <= 0.78 then e2_temp = 500 + (e2_temp-0.274) * 300/(0.78-0.174)
    else e2_temp = 800 + (e2_temp-0.78) * 400/(1-0.78)
    end

    if e2_temp < 324.5 then EICAS.E2_TEMP_COLOR:set(0) 
    elseif e2_temp < 674.5 then EICAS.E2_TEMP_COLOR:set(1)
    elseif e2_temp < 684.5 then EICAS.E2_TEMP_COLOR:set(2)
    else EICAS.E2_TEMP_COLOR:set(3)
    end

    if e2_temp <= 500 then e2_temp_pos = e2_temp / 500 * 90
    elseif e2_temp <= 700 then e2_temp_pos = 90 + (e2_temp - 500) / 200 * 150
    else e2_temp_pos = 240 + (e2_temp - 700) / 500 * 60
    end

    EICAS.E1_TEMP:set(round_to(e1_temp,5))
    EICAS.E1_TEMP_POS:set(e1_temp_pos)
    EICAS.E2_TEMP:set(round_to(e2_temp,5))
    EICAS.E2_TEMP_POS:set(e2_temp_pos)


    -- fuel flow --
    e1_ff = sensor_data.getEngineLeftFuelConsumption()*60*60*2.20462
    e2_ff = sensor_data.getEngineRightFuelConsumption()*60*60*2.20462

    EICAS.E1_FF:set(round_to(e1_ff,100))
    EICAS.E2_FF:set(round_to(e2_ff,100))

    -- fuel --
    -- O indicador é duplo e está localizado no painel principal, lado direito, contém duas seções para indicar a quantidade de combustível dos sistemas esquerdo e direito em libras e manda uma indicação ao EFI / EICAS, este faz com que o valor total da indicação dos dois sistemas seja mostrado no CMFD (se a MASTER AVIONICS  estiver ligada).
    -- No totalizador há três cores possíveis, abaixo de 800lbs a cor é vermelho, acima de 800lbs é verde ou cyan (azul). Será verde no somatório do combustível interno com os tanques externos e cyan se houver apenas combustível nos tanques internos.
    -- Quando a diferença entre os ponteiros esquerdo e direito estiverem superior a 300lbs e um dos sistemas estiver abaixo de 1500lbs, acenderá no EFI / EICAS a indicação em amarelo “BALANCE”.
    fuel = sensor_data.getTotalFuelWeight() * 2.20462
    EICAS.FUEL_POS:set(fuel / 11000)
    fuel = round_to(fuel, 5)
    EICAS.FUEL:set(fuel)
    if fuel <= 800 then EICAS.FUEL_COLOR:set(0)
    elseif fuel <= 4470 then EICAS.FUEL_COLOR:set(1)
    else EICAS.FUEL_COLOR:set(2) end

    fuel_intr = get_cockpit_draw_argument_value(22)*2500 + get_cockpit_draw_argument_value(23)*2500
    EICAS.FUEL_INTR_POS:set(fuel_intr / 11000)

    local fuel_cntr = round_to((fuel - fuel_intr)/3,5)
    local fuel_inbd = round_to((fuel - fuel_intr)/3*2,5)
    if fuel_cntr < 50 then fuel_cntr = 0 end
    if fuel_inbd < 50 then fuel_inbd = 0 end

    fuel_intr = round_to(fuel_intr,5)
    EICAS.FUEL_INTR:set(fuel_intr)
    EICAS.FUEL_CNTR:set(fuel_cntr)
    EICAS.FUEL_INBD:set(fuel_inbd)

    -- oil pressure --
    -- Se a indicação for inferior a 5PSI ou ultrapassar 55PSI por mais de 10 segundos acenderá no EFI / EICAS a indicação em vermelho “LEFT OIL” ou “RIGHT OIL”.
    e1_oil_press = get_cockpit_draw_argument_value(112)*100
    e1_oil_press_pos = e1_oil_press/100
    e2_oil_press = get_cockpit_draw_argument_value(113)*100
    e2_oil_press_pos = e2_oil_press/100

    if e1_oil_press < 4.5 then EICAS.E1_OIL_PRES_COLOR:set(0)
    elseif e1_oil_press < 19.5 then EICAS.E1_OIL_PRES_COLOR:set(1)
    elseif e1_oil_press < 54.5 then EICAS.E1_OIL_PRES_COLOR:set(2)
    else EICAS.E1_OIL_PRES_COLOR:set(3) end

    if e2_oil_press < 4.5 then EICAS.E2_OIL_PRES_COLOR:set(0)
    elseif e2_oil_press < 19.5 then EICAS.E2_OIL_PRES_COLOR:set(1)
    elseif e2_oil_press < 54.5 then EICAS.E2_OIL_PRES_COLOR:set(2)
    else EICAS.E2_OIL_PRES_COLOR:set(3) end

    EICAS.E1_OIL_PRES:set(e1_oil_press)
    EICAS.E1_OIL_PRES_POS:set(e1_oil_press_pos)
    EICAS.E2_OIL_PRES:set(e2_oil_press)
    EICAS.E2_OIL_PRES_POS:set(e2_oil_press_pos)

    -- nozzle pos --
    -- A simbologia do indicador de NOZZLE vai de 0% a 100%, com divisão de 1%, no CMFD possui marcações em 0%, 16%, 30%, 40%, 50%, 60%, 70%, 80%, 90% e 100%.
    e1_nozzle = get_cockpit_draw_argument_value(107)*100
    e1_nozzle_pos = e1_nozzle / 100
    e2_nozzle = get_cockpit_draw_argument_value(108)*100
    e2_nozzle_pos = e2_nozzle / 100

    EICAS.E1_NOZZLE:set(e1_nozzle)
    EICAS.E1_NOZZLE_POS:set(e1_nozzle_pos)
    EICAS.E2_NOZZLE:set(e2_nozzle)
    EICAS.E2_NOZZLE_POS:set(e2_nozzle_pos)

    -- hydraulic pressure --
    -- Cada sistema possui uma indicação individual de aviso de baixa pressão, caso a pressão seja inferior à 1500 (±100) PSI e só se apagará quando a pressão for superior a 1800 (±100) PSI devido a switch de pressão fazendo com que acenda no EFI uma indicação em amarelo “UTIL HYD” ou “FLT HYD”.
    -- Se a temperatura do fluido aumentar para 220º (±5º) F (±105ºC), a mesma luz de aviso também irá acender. Essa luz só se apagará quando a temperatura cair para 210º (±10º) F (±99ºC).
    hyd_util = get_cockpit_draw_argument_value(109)*4000
    hyd_util_pos = hyd_util/4000
    hyd_flt = get_cockpit_draw_argument_value(110)*4000
    hyd_flt_pos = hyd_flt/4000

    if hyd_util < 1499.5 then EICAS.HYD_UTIL_COLOR:set(0)
    elseif hyd_util < 2799.5 then EICAS.HYD_UTIL_COLOR:set(1)
    elseif hyd_util < 3200 then EICAS.HYD_UTIL_COLOR:set(2)
    else EICAS.HYD_UTIL_COLOR:set(3) end

    if hyd_flt < 1499.5 then EICAS.HYD_FLT_COLOR:set(0)
    elseif hyd_flt < 2799.5 then EICAS.HYD_FLT_COLOR:set(1)
    elseif hyd_flt < 3200 then EICAS.HYD_FLT_COLOR:set(2)
    else EICAS.HYD_FLT_COLOR:set(3) end

    EICAS.HYD_UTIL:set(round_to(hyd_util,100))
    EICAS.HYD_UTIL_POS:set(hyd_util_pos)
    EICAS.HYD_FLT:set(round_to(hyd_flt,100))
    EICAS.HYD_FLT_POS:set(hyd_flt_pos)

    -- ----------------- mostrador de temperatura entre turbinas t5
    -- local t5 = sensor_data.getEngineLeftTemperatureBeforeTurbine() * 1.067
    -- if t5 < -50 then t5 = -50 end
    -- if t5 > 1200 then t5 = 1200 end

    -- -- ponteiro de t5
    -- local t5_rot = t5
    -- if t5_rot < 200 then t5_rot = 200 end
    -- if t5_rot > 1200 then t5_rot = 1200 end
    -- t5_rot = - (t5_rot -700) * math.pi / 600

    -- t5=round_to(t5, 10)
    
    -- -- cor do ponteiro e valor digital de torque
    -- -- TODO: - Se, por qualquer motivo, os dados não estiverem disponíveis, uma etiqueta branca OFF, localizada no centro da apresentação analógica, substitui os ponteiros.
    -- if t5 < 860 then t5_cor = 0 -- verde
    -- elseif (t5 < 900) then t5_cor = 1 -- amarelo 
    -- else t5_cor = 2 -- vermelho
    -- end

    -- ------------------- pressão de óleo
    -- local oil_press=sensor_data.getEngineLeftRPM()
    -- if oil_press > 45 then oil_press = 99+(oil_press-45)/20*13
    -- elseif oil_press > 35 then oil_press = 92+(oil_press-35)/10*7
    -- elseif oil_press > 28 then oil_press = 64+(oil_press-28)/7*28
    -- elseif oil_press > 16 then oil_press = (oil_press-16)/12*64
    -- else oil_press = 0
    -- end
    -- if oil_press > 112 then oil_press = 112 end --simulação

    -- if oil_press < 0 then oil_press = 0 end
    -- if oil_press > 200 then oil_press = 200 end

    -- -- cor do ponteiro e valor digital da pressão de óleo
    -- -- TODO: - Se os dados não estiverem disponíveis, a janela apresenta “XXX”.
    -- if oil_press < 40 then 
    --     if oil_press_cor ~= 2 then set_warning(WARNING_ID.OIL_PRESS, 1) end
    --     oil_press_cor = 2
    -- elseif oil_press < 90 then 
    --     if oil_press_cor ~= 1 then set_warning(WARNING_ID.OIL_PRESS, 0) end
    --     oil_press_cor = 1
    -- elseif oil_press < 121 then 
    --     if oil_press_cor ~= 0 then set_warning(WARNING_ID.OIL_PRESS, 0) end
    --     oil_press_cor = 0
    -- elseif oil_press < 130 then 
    --     if oil_press_cor ~= 1 then set_warning(WARNING_ID.OIL_PRESS, 0) end
    --     oil_press_cor = 1
    -- else 
    --     if oil_press_cor ~= 2 then set_warning(WARNING_ID.OIL_PRESS, 1) end
    --     oil_press_cor = 2
    -- end

    -- ------------------- temperatura do óleo
    -- local oil_temp=oat + sensor_data.getEngineLeftRPM()*0.76

    -- if oil_temp < -50 then oil_temp = -50 end
    -- if oil_temp > 150 then oil_temp = 150 end

    -- -- cor do ponteiro e valor digital da temperatura do óleo
    -- -- TODO: - Se os dados não estiverem disponíveis, a janela apresenta “XXX”.
    -- if oil_temp < -40 then 
    --     if oil_temp_cor ~= 2 then set_warning(WARNING_ID.OIL_TEMP, 1) end
    --     oil_temp_cor = 2
    -- elseif oil_temp < 10 then 
    --     if oil_temp_cor ~= 1 then set_warning(WARNING_ID.OIL_TEMP, 0) end
    --     oil_temp_cor = 1
    -- elseif oil_temp < 106 then 
    --     if oil_temp_cor ~= 0 then set_warning(WARNING_ID.OIL_TEMP, 0) end
    --     oil_temp_cor = 0
    -- elseif oil_temp < 110 then 
    --     if oil_temp_cor ~= 1 then set_warning(WARNING_ID.OIL_TEMP, 0) end
    --     oil_temp_cor = 1
    -- else 
    --     if oil_temp_cor ~= 2 then set_warning(WARNING_ID.OIL_TEMP, 1) end
    --     oil_temp_cor = 2
    -- end
    
    -- ------------------- rotação da hélice %
    -- local np = sensor_data.getEngineLeftRPM()

    -- if get_avionics_onground() then
    --     if np > 70 then np = 100
    --     elseif np > 64.8 then np = 50 + (np-64.8)/5.2 * 50
    --     elseif np > 55 then np = 15+(np-55)/9.8 * 35
    --     else np = np / 55 * 15
    --     end
    -- else
    --     if np > 64 then np = 99 + (np-64)/36 * 2
    --     elseif np > 55 then np = (np-55)/10 * 50
    --     else np = 0
    --     end
    -- end

    -- if np < 0 then np = 0 end
    -- if np > 130 then np = 130 end

    -- -- gerencia contador de 20s para aviso verde virar amarelo e 5s para virar vermelho
    -- if np_tempo >= 0 then np_tempo = np_tempo + update_time_step end
    -- if sensor_data.getWOW_LeftMainLandingGear() > 0 then
    --     if ((np >=25 and np < 40) or (np >= 52 and np < 68) or (np >= 87 and np < 98) or (np > 102)) then
    --         if np_tempo == -1 then np_tempo=0 end
    --     else np_tempo =- 1 end
    -- else 
    --     if np >= 102 and np < 109 then
    --         if np_tempo == -1 then np_tempo=0 end
    --     else np_tempo = -1 end
    -- end

    -- -- cor do valor digital da rotação da hélice
    -- if sensor_data.getWOW_LeftMainLandingGear() > 0 then
    --     if np < 109 then np_cor = 0 
    --     else np_cor = 2 end
    --     if (np >= 102 and np < 109) and np_tempo > 20 then np_cor = 1 end
    --     if ((np >=25 and np < 40) or (np >= 52 and np < 68) or (np >= 87 and np < 98)) and np_tempo > 5 then np_cor=2 end
    -- else 
    --     if np < 98 then np_cor = 1
    --     elseif np < 109 then np_cor = 0
    --     else np_cor = 2 end
    --     if np >= 102 and np < 109 and np_tempo > 20 then np_cor = 1 end
    -- end

    -- ----------------- rotação do gerador de gases
    -- local ng = sensor_data.getEngineLeftRPM()
    -- if ng < 0 then ng = 0 end
    -- if ng > 130 then ng = 130 end

    -- ng = round_to(ng, 0.2)

    -- -- cor do valor digital da rotação da gerador de gases
    -- if sensor_data.getWOW_LeftMainLandingGear() > 0 then
    --     if ng < 64.6 then ng_cor = 1 
    --     elseif ng <  104 then ng_cor = 0
    --     else ng_cor = 2 end
    -- else
    --     if ng < 75 then ng_cor = 1 
    --     elseif ng <  104 then ng_cor = 0
    --     else ng_cor = 2 end
    -- end

    -- ----------------- indicador de ignição
    -- local ign=0

    -- ----------------- indicador de modo de operação
    -- local eng_mode=""
    -- if sensor_data.getWOW_LeftMainLandingGear() > 0 then
    --     eng_mode="TO"  -- TakeOff, Alternate Takeoff, CLimb, CRuise
    -- end

    -- ------------------- indicador digital de pressão hidráulica
    -- local hyd=sensor_data.getEngineLeftRPM()*50
    -- if hyd > 3200 then hyd = 3200 end -- simulação
    
    -- if hyd < 0 then hyd = 0 end
    -- if hyd > 5000 then hyd = 5000 end

    -- hyd = round_to(hyd, 100)
    -- -- cor do valor digital da da pressão hidráulica
    -- -- TODO: - Se os dados não estiverem disponíveis, a janela apresenta “XXX”.
    -- if hyd < 2700 then 
    --     if hyd_cor ~=1 then set_caution(CAUTION_ID.HYD_RESS,1) end 
    --     hyd_cor = 1
    -- elseif hyd < 3300 then 
    --     if hyd_cor ~=0 then set_caution(CAUTION_ID.HYD_RESS,0) end 
    --     hyd_cor = 0
    -- else 
    --     if hyd_cor ~=1 then set_caution(CAUTION_ID.HYD_RESS,1) end 
    --     hyd_cor = 1
    -- end

    -- ------------------- indicador digital de pressão cabine
    -- local cabin_press = sensor_data.getBarometricAltitude()*3.28084
    
    -- if cabin_press > 7000 and get_aircraft_draw_argument_value(38) == 0 then cabin_press = 7000 end

    -- if cabin_press < -7000 then cabin_press = -7000 end
    -- if cabin_press > 40000 then cabin_press = 40000 end
    -- cabin_press = round_to(cabin_press, 500)
    -- -- cor do valor digital da da pressão cabine
    -- if cabin_press < 16000 then 
    --     if cabin_press_cor == 1 then set_caution(CAUTION_ID.CAB_ALT, 0) end
    --     if cabin_press_cor == 2 then set_warning(WARNING_ID.CAB_ALT, 0) end
    --     cabin_press_cor = 0
    -- elseif cabin_press < 25000 then 
    --     if cabin_press_cor == 2 then set_warning(WARNING_ID.CAB_ALT, 0) end
    --     if cabin_press_cor ~= 1 then set_caution(CAUTION_ID.CAB_ALT, 1) end
    --     cabin_press_cor = 1
    -- else 
    --     if cabin_press_cor == 1 then set_caution(CAUTION_ID.CAB_ALT, 0) end
    --     if cabin_press_cor ~= 2 then set_warning(WARNING_ID.CAB_ALT, 1) end
    --     cabin_press_cor = 2
    -- end

    -- ------------------- indicador digital de bateria
    -- local bat_amp = 127
    -- bat_amp = round_to(bat_amp,5)
    -- if bat_amp < 0 then bat_amp = 0 end
    -- if bat_amp > 950 then bat_amp = 950 end
    -- if bat_amp <= 400 then bat_amp_cor = 0 
    -- else bat_amp_cor = 1 end

    -- local bat_volt = 24
    -- if get_elec_generator_on() and get_engine_on() then bat_volt = 28.8 end

    -- bat_volt = round_to(bat_volt,0.1)
    -- if bat_volt < 0 then bat_volt = 0 end
    -- if bat_volt > 40 then bat_volt = 40 end
    -- if bat_volt <= 30 then bat_volt_cor = 0 
    -- else bat_volt_cor = 2 end

    -- local bat_temp = 37
    -- bat_temp = round_to(bat_temp,1)
    -- if bat_temp < -30 then bat_temp = -30 end
    -- if bat_temp > 100 then bat_temp = 100 end
    -- if bat_temp <= 76 then 
    --     if bat_temp_cor == 2 then set_warning(WARNING_ID.BAT_TEMP,0) end
    --     bat_temp_cor = 0 
    -- else 
    --     if bat_temp_cor == 0 then set_warning(WARNING_ID.BAT_TEMP,1) end
    --     bat_temp_cor = 2 
    -- end

    -- ------------------- indicador combustível
    -- local fuel_flow = sensor_data.getEngineLeftFuelConsumption()*60*60;
    -- if fuel_flow < 0 then fuel_flow = 0 end
    -- --if fuel_flow > 500 then fuel_flow = 500 end

    -- fuel_init = EICAS_FUEL_INIT:get()
    -- if fuel_init > 1465 then fuel_init = 1465 end
    -- if fuel_init < 0 then fuel_init = 0 end
    -- fuel_init = fuel_init - sensor_data.getEngineLeftFuelConsumption()*update_time_step

    -- -- Se os dados de fluxo de combustível não estiverem disponíveis por mais de 5 minutos, o campo apresenta os caracteres “XXXX” na cor vermelha e os dados não mais estarão disponíveis.
    -- fuel_joker = EICAS_FUEL_JOKER:get()

    -- if fuel_joker > 1465 then fuel_joker = 1465 end
    -- if fuel_joker < 95 then fuel_joker = 95 end

    -- -- Calculate the remaining fuel after navigating to the homepoint
    -- local fuel_bingo = UFCP_FUEL_BINGO:get()
    -- local hmpt = UFCP_FUEL_HMPT:get()
    -- local dest_lat_m = nav_fyt_list[hmpt+1].lat_m
    -- local dest_lon_m = nav_fyt_list[hmpt+1].lon_m
    -- local distance = calc_dist(dest_lat_m, dest_lon_m)
    -- local cruise_flow = 1.0 / 1852 -- hardcoded 1kg / nm
    -- fuel_bingo = fuel_bingo + distance * cruise_flow

    -- local fuel_joker_rot
    -- if fuel_bingo <= 300 then
    --     fuel_joker_rot = (115.5- 55/300*fuel_bingo)*math.pi/180
    -- else
    --     fuel_joker_rot = (60.5- 152/1300* (fuel_bingo-305))*math.pi/180
    -- end

    -- local fuel = sensor_data.getTotalFuelWeight() + fuel_random
    -- if fuel < 0 then fuel = 0 end
    -- if fuel > 495 then fuel = 495 end
    -- local fuel_left = fuel / 2 -- simple model
    -- if fuel_left < 0 then fuel_left = 0 end
    -- if fuel_left > 245 then fuel_left = 245 end
    -- local fuel_right = fuel - fuel_left -- simple model
    -- if fuel_right < 0 then fuel_right = 0 end
    -- if fuel_right > 250 then fuel_right = 250 end
    -- fuel = round_to(fuel, 5)
    -- fuel_left = round_to(fuel_left, 5)
    -- fuel_right = round_to(fuel_right, 5)
    -- if math.abs(fuel_left - fuel_right) >= 60 then 
    --     if fuel_imbalance_caution == 0 then 
    --         set_caution(CAUTION_ID.FUEL_IMB, 1)
    --         fuel_imbalance_caution = 1
    --     end
    -- else
    --     if fuel_imbalance_caution == 1 then 
    --         set_caution(CAUTION_ID.FUEL_IMB, 0)
    --         fuel_imbalance_caution = 0
    --     end
    -- end

    -- local fuel_tot_rot = 0
    -- if fuel_init <= 300 then
    --     fuel_tot_rot = math.rad((300 - fuel_init) * 10 / 50) + math.rad((1770 - 300) * 12.5 / 100)
    -- else
    --     fuel_tot_rot = math.rad((1770 - fuel_init) * 12.5 / 100)
    -- end

    -- local fuel_int_rot = 0
    -- if fuel <= 300 then
    --     fuel_int_rot = math.rad((300 - fuel) * 10 / 50) + math.rad((500 - 300) * 12.5 / 100)
    -- else
    --     fuel_int_rot = math.rad((500 - fuel) * 12.5 / 100)
    -- end

    -- -- cores dos indicadores de combustível
    -- if fuel <= 125 then 
    --     if fuel_cor ~= 2 then set_warning(WARNING_ID.FUEL_LVL,1) end
    --     fuel_cor = 2
    -- else 
    --     if fuel_cor ~= 0 then set_warning(WARNING_ID.FUEL_LVL,0) end
    --     fuel_cor = 0 
    -- end
    -- if fuel_left <= 60 then fuel_left_cor = 2
    -- else fuel_left_cor = 0 end
    -- if fuel_right <= 60 then fuel_right_cor = 2
    -- else fuel_right_cor = 0 end

    -- if (torque_cor == 2 or t5_cor == 2 or ng_cor == 2 or np_cor == 2) and engine_limits_warning == 0 then
    --     set_warning(WARNING_ID.ENG_LMTS,1)
    --     engine_limits_warning = 1
    -- elseif (torque_cor ~= 2 and t5_cor ~= 2 and ng_cor ~= 2 and np_cor ~= 2) and engine_limits_warning ~= 0 then 
    --     set_warning(WARNING_ID.ENG_LMTS,0)
    --     engine_limits_warning = 0
    -- end

    -- if (fuel < fuel_joker or fuel_init < fuel_joker) and fuel_joker_voice == 0 then
    --     set_voice(VOICE_ID.JOKER, 1)
    --     fuel_joker_voice = 1
    -- elseif fuel >= fuel_joker and fuel_init >= fuel_joker and fuel_joker_voice ~= 0 then
    --     set_voice(VOICE_ID.JOKER, 0)
    --     fuel_joker_voice = 0
    -- end

    -- if (fuel <= fuel_bingo or fuel_init <= fuel_bingo) and fuel_bingo_caution == 0 then
    --     set_caution(CAUTION_ID.BINGO,1)
    --     fuel_bingo_caution = 1
    -- elseif fuel > fuel_bingo and fuel_init > fuel_bingo and fuel_bingo_caution ~= 0 then
    --     set_caution(CAUTION_ID.BINGO,0)
    --     fuel_bingo_caution = 0
    -- end

    -- EICAS_TQ:set(torque)
    -- EICAS_TQ_ROT:set(torque_rot)
    -- EICAS_TQ_REQ_ROT:set(torque_req_rot)
    -- EICAS_TQ_OPT_ROT:set(torque_opt_rot)
    -- EICAS_TQ_COR:set(torque_cor)

    -- EICAS_T5:set(t5)
    -- EICAS_T5_ROT:set(t5_rot)
    -- EICAS_T5_COR:set(t5_cor)
    
    -- EICAS_OIL_PRESS:set(oil_press)
    -- EICAS_OIL_PRESS_COR:set(oil_press_cor)

    -- EICAS_OIL_TEMP:set(oil_temp)
    -- EICAS_OIL_TEMP_COR:set(oil_temp_cor)

    -- EICAS_NP:set(np)
    -- EICAS_NP_COR:set(np_cor)

    -- EICAS_NG:set(ng)
    -- EICAS_NG_COR:set(ng_cor)

    -- EICAS_OAT:set(oat)

    -- EICAS_IGN:set(ign)

    -- EICAS_ENG_MODE:set(eng_mode)

    -- EICAS_HYD:set(hyd)
    -- EICAS_HYD_COR:set(hyd_cor)

    -- EICAS_CAB_PRESS:set(cabin_press)
    -- EICAS_CAB_PRESS_COR:set(cabin_press_cor)

    -- EICAS_BAT_AMP:set(bat_amp)
    -- EICAS_BAT_AMP_COR:set(bat_amp_cor)

    -- EICAS_BAT_VOLT:set(bat_volt)
    -- EICAS_BAT_VOLT_COR:set(bat_volt_cor)

    -- EICAS_BAT_TEMP:set(bat_temp)
    -- EICAS_BAT_TEMP_COR:set(bat_temp_cor)

    -- EICAS_FUEL_FLOW:set(round_to(fuel_flow,5))
    -- EICAS_FUEL:set(fuel)
    -- EICAS_FUEL_COR:set(fuel_cor)
    -- EICAS_FUEL_LEFT:set(fuel_left)
    -- EICAS_FUEL_LEFT_COR:set(fuel_left_cor)
    -- EICAS_FUEL_RIGHT:set(fuel_right)
    -- EICAS_FUEL_RIGHT_COR:set(fuel_right_cor)
    -- EICAS_FUEL_INIT:set(round_to(fuel_init,5))
    -- EICAS_FUEL_JOKER:set(round_to(fuel_joker,5))
    -- EICAS_FUEL_JOKER_ROT:set(fuel_joker_rot)
    -- EICAS_FUEL_INT_ROT:set(fuel_int_rot)
    -- EICAS_FUEL_TOT_ROT:set(fuel_tot_rot)


    -- flap_pos = sensor_data.getFlapsPos()
    -- if flap_pos < 0.1 then
    --     EICAS_FLAP:set(0)
    --     EICAS_FLAP_TXT:set("UP")
    -- elseif flap_pos > 0.9 then 
    --     EICAS_FLAP:set(1)
    --     EICAS_FLAP_TXT:set("DOWN")
    -- else 
    --     EICAS_FLAP:set(0)
    --     EICAS_FLAP_TXT:set("----")
    -- end


    -- -- - Se os dados não estiverem disponíveis, a janela apresenta “XXX”.
    -- if sensor_data.getSpeedBrakePos() <0.1 then
    --     EICAS_SPD_BRK:set(0)
    --     EICAS_SPD_BRK_TXT:set("CLOSED")
    -- else 
    --     EICAS_SPD_BRK:set(1)
    --     EICAS_SPD_BRK_TXT:set("OPEN")
    -- end
end

function SetCommandEicas(command,value, CMFD)
    if value == 1 then 
        if command==device_commands.CMFD1OSS13 or command==device_commands.CMFD2OSS13 then
            fuel_joker = fuel_joker + 5
            EICAS.FUEL_JOKER:set(fuel_joker)
        elseif command==device_commands.CMFD1OSS14 or command==device_commands.CMFD2OSS14 then 
            fuel_joker = fuel_joker - 5
            EICAS.FUEL_JOKER:set(fuel_joker)
        elseif (command==device_commands.CMFD1OSS11 or command==device_commands.CMFD2OSS11) and EICAS_INIT:get() == 1 then
            fuel_init = fuel_init + 5
            EICAS.FUEL_INIT:set(fuel_init)
        elseif (command==device_commands.CMFD1OSS12 or command==device_commands.CMFD2OSS12) and EICAS_INIT:get() == 1 then
            fuel_init = fuel_init - 5
            EICAS.FUEL_INIT:set(fuel_init)
        elseif command==device_commands.CMFD1OSS25 or command==device_commands.CMFD2OSS25 then oat_base = oat_base - 1
        elseif command==device_commands.CMFD1OSS26 or command==device_commands.CMFD2OSS26 then oat_base = oat_base + 1
        end
    end
end

function post_initialize_eicas()
    local birth = LockOn_Options.init_conditions.birth_place
    if birth=="GROUND_HOT" then
        EICAS_INIT:set(1)
    elseif birth=="AIR_HOT" then
    elseif birth=="GROUND_COLD" then
        EICAS_INIT:set(1)
    end
    fuel_init=round_to(sensor_data.getTotalFuelWeight() + fuel_random,5)
    fuel_joker=round_to(fuel_init/2,5)
end

register_as_cmfd_item(SUB_PAGE_ID.EICAS, post_initialize_eicas, update_eicas, SetCommandEicas)
