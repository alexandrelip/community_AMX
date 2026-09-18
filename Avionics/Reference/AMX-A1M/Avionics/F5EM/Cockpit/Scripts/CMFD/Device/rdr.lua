dofile(LockOn_Options.script_path.."Systems/rdr_api.lua")
local RADAR_AG = dofile(LockOn_Options.script_path.."Systems/radar_ag_logic.lua")
local RADAR_CONTROLS = dofile(LockOn_Options.script_path.."Systems/radar_control_logic.lua")


local RDR = {
    POWER = get_param_handle("RDR_POWER"),
    MODE = get_param_handle("RDR_MODE"),               -- 0=RWS, 1=TWS, 2=VS, 3=ACM  [Grifo sim]
    OPR = get_param_handle("RDR_OPR"),
    CNTL = get_param_handle("RDR_CNTL"),
    INTC = get_param_handle("RDR_INTC"),
    HIS = get_param_handle("RDR_HIS"),
    WP = get_param_handle("RDR_WP"),
    MTR_AA = get_param_handle("RDR_MTR_AA"),
    MTR_AG = get_param_handle("RDR_MTR_AG"),
    ALT_TRK = get_param_handle("RDR_ALT_TRK"),
    FREQ = get_param_handle("RDR_FREQ"),
    RANGE = get_param_handle("RDR_RANGE"),
    -- Aneis de alcance do B-scope: o indicador so sabe formatar um parametro,
    -- nao multiplica-lo, entao as fracoes vao prontas.
    RANGE_Q1 = get_param_handle("RDR_RANGE_Q1"),
    RANGE_Q2 = get_param_handle("RDR_RANGE_Q2"),
    RANGE_Q3 = get_param_handle("RDR_RANGE_Q3"),
    HORIZ_PITCH = get_param_handle("RDR_HORIZ_PITCH"),
    HORIZ_ROLL = get_param_handle("RDR_HORIZ_ROLL"),
    HPT_HDG = get_param_handle("RDR_HPT_HDG"),
    HPT_REL_SPD = get_param_handle("RDR_HPT_REL_SPD"),
    HPT_DIR = get_param_handle("RDR_HPT_DIR"),
    HPT_DIR_LR = get_param_handle("RDR_HPT_DIR_LR"),
    HPT_AVAIL = get_param_handle("RDR_HPT_AVAIL"),
    HPT_TTT_MIN = get_param_handle("RDR_HPT_TTT_MIN"),
    HPT_TTT_SEC = get_param_handle("RDR_HPT_TTT_SEC"),
    -- [Fase 1 -- Grifo-F sim]
    AA_AG = get_param_handle("RDR_AA_AG"),
    ACM_SUB = get_param_handle("RDR_ACM_SUB"),
    AG_SUB = get_param_handle("RDR_AG_SUB"),
    AG_PRF = get_param_handle("RDR_AG_PRF"),
    ASSIST_ID = get_param_handle("RADAR_ASSIST_ID"),
    ASSIST_RANGE_REQ_NM = get_param_handle("RDR_ASSIST_RANGE_REQ_NM"),
    SCAN_AZ_DEG = get_param_handle("RDR_SCAN_AZ_DEG"),
    SCAN_BARS = get_param_handle("RDR_SCAN_BARS"),
    SCAN_CENTER_AZ = get_param_handle("RDR_SCAN_CENTER_AZ"),
    HSD_RANGE = get_param_handle("HSD_RAD_SEL"),
    HSD_RANGE_SCALE = get_param_handle("RDR_HSD_RANGE_SCALE"),
    DTC_LOADED = get_param_handle("CMFD_DTU_DTC_LOADED"),
    DTC_MODE = get_param_handle("DTC_RDR_DEFAULT_MODE"),
    DTC_RANGE_NM = get_param_handle("DTC_RDR_DEFAULT_RANGE_NM"),
    DTC_BARS = get_param_handle("DTC_RDR_DEFAULT_BARS"),
    DTC_AZ_SCAN_DEG = get_param_handle("DTC_RDR_DEFAULT_AZ_SCAN_DEG"),
}

local assist_range_last_id = 0
local dtc_loaded_prev = 0

local rdr ={
    power = 1,
    -- [Grifo-F] Modo de display padrao = TWS (1) em vez de RWS (0): o scope
    -- abre ja com os diamantes/track files + vetor de velocidade + data block
    -- do alvo primario (visual do Grifo). RWS continua disponivel ciclando OSS2.
    mode = 1,
    opr = 1,
    cntl = 0,
    wp = 0,
    his = 1,
    mtr_aa = 0,
    mtr_ag = 0,
    alt_trk = 1,
    freq = 0,
    -- [Fase 1] Grifo-F: alcances {5,10,20,40,80} NM (sem 160 do APQ-159 stock).
    -- Default 20 NM (search inicial razoavel para BVR Derby).
    ranges = {5, 10, 20, 40, 80},
    range = 3,
    vert = 0,
    horiz = 0,
    intc = 2,
    -- [Fase 1] Grifo-F sim
    aa_ag = 0,           -- 0=A/A, 1=A/G
    acm_sub = 0,         -- 0=BORE, 1=VACQ, 2=AACQ
    ag_sub = RADAR_AG.GMT,
    scan_az_deg = 60,
    scan_bars = 4,
    scan_center_az = 0,

    stt_az_last = 0,
    stt_el_last = 0,
    stt_range_last = 0,
    stt_time_last = 0,
    stt_count_last = 0,
    
    avionics_mode_last = 0,
}

    

function update_rdr()
    rdr.power = RDR.POWER:get()

    local dtc_loaded = RDR.DTC_LOADED:get()
    if dtc_loaded > 0.5 and dtc_loaded_prev <= 0.5 then
        local profile = RADAR_CONTROLS.dtc_radar_profile(
            rdr.ranges, RDR.DTC_MODE:get(), RDR.DTC_RANGE_NM:get(),
            RDR.DTC_BARS:get(), RDR.DTC_AZ_SCAN_DEG:get())
        if profile then
            rdr.mode = profile.mode
            rdr.range = profile.range_index
            rdr.scan_bars = profile.bars
            rdr.scan_az_deg = profile.azimuth_deg
            rdr.scan_center_az = 0
        end
    end
    dtc_loaded_prev = dtc_loaded

    local assist_id = RDR.ASSIST_ID:get() or 0
    if assist_id <= 0 then
        assist_range_last_id = 0
    elseif assist_id ~= assist_range_last_id then
        rdr.range = RADAR_CONTROLS.range_index_for_request(
            rdr.ranges, rdr.range, RDR.ASSIST_RANGE_REQ_NM:get())
        assist_range_last_id = assist_id
    end

    RDR.MODE:set(rdr.mode)
    RDR.OPR:set(rdr.opr)
    RDR.CNTL:set(rdr.cntl)
    RDR.INTC:set(rdr.intc)
    RDR.WP:set(rdr.wp)
    RDR.HIS:set(rdr.his)
    RDR.MTR_AA:set(rdr.mtr_aa)
    RDR.MTR_AG:set(rdr.mtr_ag)
    RDR.ALT_TRK:set(rdr.alt_trk)
    RDR.FREQ:set(rdr.freq)
    RDR.RANGE:set(rdr.ranges[rdr.range])
    RDR.RANGE_Q1:set(rdr.ranges[rdr.range] * 0.25)
    RDR.RANGE_Q2:set(rdr.ranges[rdr.range] * 0.50)
    RDR.RANGE_Q3:set(rdr.ranges[rdr.range] * 0.75)
    -- [Fase 1] Publica handles novos.
    RDR.AA_AG:set(rdr.aa_ag)
    RDR.ACM_SUB:set(rdr.acm_sub)
    RDR.AG_SUB:set(rdr.ag_sub)
    RDR.AG_PRF:set(RADAR_AG.prf(rdr.ag_sub))
    RDR.SCAN_AZ_DEG:set(rdr.scan_az_deg)
    RDR.SCAN_BARS:set(rdr.scan_bars)
    local full_azimuth = RADAR.NORM_AZIMUTH:get()
    if full_azimuth <= 0 then full_azimuth = math.rad(120) end
    rdr.scan_center_az = RADAR_CONTROLS.scan_center_for_tdc(
        rdr.scan_center_az, RADAR.TDC_AZIMUTH:get(),
        rdr.scan_az_deg, full_azimuth)
    RDR.SCAN_CENTER_AZ:set(rdr.scan_center_az)
    RDR.HSD_RANGE_SCALE:set(RADAR_CONTROLS.hsd_range_scale(
        rdr.ranges[rdr.range], RDR.HSD_RANGE:get()))

    RADAR.NORM_RANGE:set(rdr.ranges[rdr.range] * 1852)

    RDR.HORIZ_PITCH:set(math.min(math.max(sensor_data.getPitch(),math.rad(-45)), math.rad(45)))
    RDR.HORIZ_ROLL:set(sensor_data.getRoll())

    -- [F-5EM DGFT fix 2026-07-08] Publica o Highest Priority Target quando ha
    -- lock STT valido, mesmo se o lock veio do DGFT do stick (master mode
    -- DGFT_S/M) e nao apenas quando RADAR.MODE==3 (ACM/CMFD).
    -- [F-5EM auto-lock 2026-07-08] Estendido p/ INT_S/M tambem.
    local _amm_hpt = get_avionics_master_mode()
    local _hpt_aa_locked = (
        (_amm_hpt == AVIONICS_MASTER_MODE_ID.DGFT_S or _amm_hpt == AVIONICS_MASTER_MODE_ID.DGFT_M
         or _amm_hpt == AVIONICS_MASTER_MODE_ID.INT_S  or _amm_hpt == AVIONICS_MASTER_MODE_ID.INT_M)
        and RADAR.STT_RANGE:get() > 0
    )
    if RADAR.MODE:get() == 3 or _hpt_aa_locked then
        RDR.HPT_HDG:set(round_to(math.deg(RADAR.STT_HDG:get()),1)%360)
        RDR.HPT_REL_SPD:set(RADAR.STT_REL_SPD:get() * 1.94)
        RDR.HPT_DIR_LR:set(RADAR.STT_AZIMUTH:get() >= 0 and "R" or "L")
        RDR.HPT_DIR:set(math.abs(math.deg(RADAR.STT_AZIMUTH:get())))
        local ttt = RADAR.STT_RANGE:get() / RADAR.STT_REL_SPD:get()
        ttt = math.max(math.min(ttt, 6039),0)
        RDR.HPT_TTT_MIN:set(math.floor(ttt/60))
        RDR.HPT_TTT_SEC:set(math.floor(ttt%60))
        RDR.HPT_AVAIL:set(1)
    else        
        RDR.HPT_AVAIL:set(0)
    end
    local amm = get_avionics_master_mode()
    if (amm == AVIONICS_MASTER_MODE_ID.DGFT_M or amm == AVIONICS_MASTER_MODE_ID.DGFT_S) and rdr.avionics_mode_last ~= amm then rdr.range = 2 end
   
    rdr.avionics_mode_last = amm
end

function SetCommandRdr(command,value, CMFD)
    debug_message_to_user("CMFD RDR: " ..  command .. "=" .. value)
    if value == 1 and CMFD["SelTop"]:get() == SUB_PAGE_ID.RDR and rdr.cntl == 0 then 
        if command == device_commands.CMFD1OSS2 or command == device_commands.CMFD2OSS2 then
            -- [Fase 1] cicla RWS->TWS->VS->ACM (Grifo-F sim)
            rdr.mode = (rdr.mode + 1) % 4
        elseif command == device_commands.CMFD1OSS3 or command == device_commands.CMFD2OSS3 then
            -- [Fase 1] em ACM, OSS3 cicla submode (BORE/VACQ/AACQ).
            if rdr.mode == 3 then
                rdr.acm_sub = (rdr.acm_sub + 1) % 3
            end
        elseif command == device_commands.CMFD1OSS5 or command == device_commands.CMFD2OSS5 then
            rdr.opr = (rdr.opr + 1) % 2
        elseif command == device_commands.CMFD1OSS6 or command == device_commands.CMFD2OSS6 then
            rdr.cntl = (rdr.cntl + 1) % 2
        elseif command == device_commands.CMFD1OSS7 or command == device_commands.CMFD2OSS7 then
            if rdr.aa_ag == 0 then
                rdr.scan_az_deg = RADAR_CONTROLS.next_scan_azimuth_deg(rdr.scan_az_deg)
            end
        elseif command == device_commands.CMFD1OSS8 or command == device_commands.CMFD2OSS8 then
            if rdr.aa_ag == 1 then
                rdr.ag_sub = (rdr.ag_sub + 1) % 3
            else
                rdr.scan_bars = RADAR_CONTROLS.next_scan_bars(rdr.scan_bars)
            end
        elseif command == device_commands.CMFD1OSS9 or command == device_commands.CMFD2OSS9 then
            -- [Fase 1] OSS9 (base page) alterna A/A vs A/G master mode do radar.
            rdr.aa_ag = (rdr.aa_ag + 1) % 2
        elseif command == device_commands.CMFD1OSS10 or command == device_commands.CMFD2OSS10 then
            if rdr.aa_ag == 0 and rdr.dev then
                rdr.dev:performClickableAction(device_commands.RDR_EXT_TOGGLE, 1, true)
            end
        elseif command == device_commands.CMFD1OSS24 or command == device_commands.CMFD2OSS24 then
        elseif command == device_commands.CMFD1OSS25 or command == device_commands.CMFD2OSS25 then
        elseif command == device_commands.CMFD1OSS26 or command == device_commands.CMFD2OSS26 then
        elseif command == device_commands.CMFD1OSS27 or command == device_commands.CMFD2OSS27 then
            rdr.range = math.max( 1, rdr.range - 1)
        elseif command == device_commands.CMFD1OSS28 or command == device_commands.CMFD2OSS28 then
            rdr.range = math.min( #rdr.ranges, rdr.range + 1)
        end
    elseif value == 1 and CMFD["SelTop"]:get() == SUB_PAGE_ID.RDR and rdr.cntl == 1 then 
        if command == device_commands.CMFD1OSS2 or command == device_commands.CMFD2OSS2 then
            -- [Fase 1] cicla RWS->TWS->VS->ACM (Grifo-F sim) na CNTL tambem
            rdr.mode = (rdr.mode + 1) % 4
        elseif command == device_commands.CMFD1OSS3 or command == device_commands.CMFD2OSS3 then
        elseif command == device_commands.CMFD1OSS4 or command == device_commands.CMFD2OSS4 then
            rdr.his = (rdr.his + 1) % 5
            if rdr.his == 0 then rdr.his = 1 end
            RADAR.HIT_HIST:set(rdr.his)
        elseif command == device_commands.CMFD1OSS5 or command == device_commands.CMFD2OSS5 then
            rdr.opr = (rdr.opr + 1) % 2
        elseif command == device_commands.CMFD1OSS6 or command == device_commands.CMFD2OSS6 then
            rdr.cntl = (rdr.cntl + 1) % 2
        elseif command == device_commands.CMFD1OSS8 or command == device_commands.CMFD2OSS8 then
        elseif command == device_commands.CMFD1OSS9 or command == device_commands.CMFD2OSS9 then
        elseif command == device_commands.CMFD1OSS10 or command == device_commands.CMFD2OSS10 then
        elseif command == device_commands.CMFD1OSS24 or command == device_commands.CMFD2OSS24 then
        elseif command == device_commands.CMFD1OSS25 or command == device_commands.CMFD2OSS25 then
        elseif command == device_commands.CMFD1OSS26 or command == device_commands.CMFD2OSS26 then
            rdr.alt_trk = (rdr.alt_trk + 1) % 2
        elseif command == device_commands.CMFD1OSS27 or command == device_commands.CMFD2OSS27 then
            rdr.mtr_ag = (rdr.mtr_ag + 1) % 2
        elseif command == device_commands.CMFD1OSS28 or command == device_commands.CMFD2OSS28 then
            rdr.mtr_aa = (rdr.mtr_aa + 1) % 2
        end
    elseif value == 1 and CMFD["FULL"]:get() == 0 and CMFD["SelLeft"]:get() == SUB_PAGE_ID.RDR then
        if command == device_commands.CMFD1OSS23 or command == device_commands.CMFD2OSS23 then
        elseif command == device_commands.CMFD1OSS22 or command == device_commands.CMFD2OSS22 then
        elseif command == device_commands.CMFD1OSS21 or command == device_commands.CMFD2OSS21 then
        end 
    elseif value == 1 and CMFD["FULL"]:get() == 0 and CMFD["SelRight"]:get() == SUB_PAGE_ID.RDR then 
        if command == device_commands.CMFD1OSS12 or command == device_commands.CMFD2OSS12 then
        elseif command == device_commands.CMFD1OSS13 or command == device_commands.CMFD2OSS13 then
        elseif command == device_commands.CMFD1OSS14 or command == device_commands.CMFD2OSS14 then
        end 
    end
end


function post_initialize_rdr()
    debug_message_to_user("post_initialize_rdr")
    rdr.dev = GetDevice(devices.RDR)
end

register_as_cmfd_item(SUB_PAGE_ID.RDR, post_initialize_rdr, update_rdr, SetCommandRdr)