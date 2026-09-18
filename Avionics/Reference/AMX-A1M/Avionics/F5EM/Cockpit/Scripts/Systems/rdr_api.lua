local RDR = {
	POWER = get_param_handle("RDR_POWER"),
    MODE = get_param_handle("RDR_MODE"),               -- 0=RWS, 1=TWS, 2=VS, 3=ACM  [Grifo simulation Lua-side]
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
    VERT = get_param_handle("RDR_VERT"),
    HORIZ = get_param_handle("RDR_HORIZ"),
    -- [Fase 1 -- Grifo-F simulation handles]
    AA_AG = get_param_handle("RDR_AA_AG"),             -- 0=A/A, 1=A/G  (toggle de master mode do radar)
    ACM_SUB = get_param_handle("RDR_ACM_SUB"),         -- 0=BORE, 1=VACQ (vertical narrow), 2=AACQ (HUD area)
    TRACK_COUNT = get_param_handle("RDR_TRACK_COUNT"), -- numero de track files ativos em TWS (0..10)
    NATIVE_TRACK_COUNT = get_param_handle("RDR_NATIVE_TRACK_COUNT"), -- fire-control nativo
    AUX_TRACK_COUNT = get_param_handle("RDR_AUX_TRACK_COUNT"),       -- awareness Export
    SCAN_AZ_DEG = get_param_handle("RDR_SCAN_AZ_DEG"),
    SCAN_BARS = get_param_handle("RDR_SCAN_BARS"),
    SCAN_CENTER_AZ = get_param_handle("RDR_SCAN_CENTER_AZ"),
    SCAN_LEFT_NORM = get_param_handle("RDR_SCAN_LEFT_NORM"),
    SCAN_RIGHT_NORM = get_param_handle("RDR_SCAN_RIGHT_NORM"),
    SCAN_LEFT_DEG = get_param_handle("RDR_SCAN_LEFT_DEG"),
    SCAN_RIGHT_DEG = get_param_handle("RDR_SCAN_RIGHT_DEG"),
    SCAN_CURRENT_BAR = get_param_handle("RDR_SCAN_CURRENT_BAR"),
    SCAN_ELEV_CENTER = get_param_handle("RDR_SCAN_ELEV_CENTER"),
    SCAN_ELEV_SPAN = get_param_handle("RDR_SCAN_ELEV_SPAN"),
    HSD_RANGE_SCALE = get_param_handle("RDR_HSD_RANGE_SCALE"),
}

RADAR = {
    TDC_RANGE = get_param_handle("RADAR_TDC_RANGE"),
    TDC_AZIMUTH = get_param_handle("RADAR_TDC_AZIMUTH"),
    TDC_RANGE_CARRET_SIZE = get_param_handle("RADAR_TDC_RANGE_CARRET_SIZE"),
    STT_AZIMUTH = get_param_handle("RADAR_STT_AZIMUTH"),
    STT_ELEVATION = get_param_handle("RADAR_STT_ELEVATION"),
    STT_RANGE = get_param_handle("RADAR_STT_RANGE"),
    STT_VALID = get_param_handle("RADAR_STT_VALID"),   -- [F-5EM 2026-07-09] 1=lock STT vivo, 0=obsoleto (engine congela STT_RANGE no kill/perda)
    STT_FRIENDLY = get_param_handle("RADAR_STT_FRIENDLY"),
    MODE = get_param_handle("RADAR_MODE"),
    BIT = get_param_handle("RADAR_BIT"),
    IFF_INTERROGATOR_STATUS = get_param_handle("IFF_INTERROGATOR_STATUS"),
    SCAN_ZONE_ORIGIN_AZIMUTH = get_param_handle("SCAN_ZONE_ORIGIN_AZIMUTH"),
    SCAN_ZONE_ORIGIN_ELEVATION = get_param_handle("SCAN_ZONE_ORIGIN_ELEVATION"),
    SCAN_ZONE_VOLUME_AZIMUTH = get_param_handle("SCAN_ZONE_VOLUME_AZIMUTH"),
    SCAN_ZONE_VOLUME_ELEVATION = get_param_handle("SCAN_ZONE_VOLUME_ELEVATION"),
    PITCH_BANK_STABILIZATION = get_param_handle("RADAR_PITCH_BANK_STABILIZATION"),
    PITCH_STABILIZATION = get_param_handle("RADAR_PITCH_STABILIZATION"),
    BANK_STABILIZATION = get_param_handle("RADAR_BANK_STABILIZATION"),
    ACQUSITION_ZONE_VOLUME_AZIMUTH = get_param_handle("ACQUSITION_ZONE_VOLUME_AZIMUTH"),
    SCAN_VOLUME_CUT_OFF_DISTANCE_MAX = get_param_handle("SCAN_VOLUME_CUT_OFF_DISTANCE_MAX"),
    SCAN_VOLUME_CUT_OFF_DISTANCE_MIN = get_param_handle("SCAN_VOLUME_CUT_OFF_DISTANCE_MIN"),
    CLOSEST_RANGE_RESPONSE = get_param_handle("CLOSEST_RANGE_RESPONSE"),

    NORM_RANGE = get_param_handle("RADAR_NORM_RANGE"),
	NORM_AZIMUTH = get_param_handle("RADAR_NORM_AZIMUTH"),

    SCAN_ZONE_ORIGIN_AZIMUTH_NORM = get_param_handle("SCAN_ZONE_ORIGIN_AZIMUTH_NORM"),
    SCAN_ZONE_ORIGIN_ELEVATION_NORM = get_param_handle("SCAN_ZONE_ORIGIN_ELEVATION_NORM"),

    TDC_RANGE_NORM = get_param_handle("RADAR_TDC_RANGE_NORM"),
    TDC_AZIMUTH_NORM = get_param_handle("RADAR_TDC_AZIMUTH_NORM"),
    TDC_ALT_UPPER 	= get_param_handle("RADAR_TDC_ALT_UPPER"),
    TDC_ALT_LOWER 	= get_param_handle("RADAR_TDC_ALT_LOWER"),

    STT_AZIMUTH_NORM = get_param_handle("RADAR_STT_AZIMUTH_NORM"),
    STT_RANGE_NORM = get_param_handle("RADAR_STT_RANGE_NORM"),
    STT_HDG = get_param_handle("RADAR_STT_HDG"),
    STT_ANGLE = get_param_handle("RADAR_STT_ANGLE"),
    STT_REL_SPD = get_param_handle("RADAR_STT_REL_SPD"),
    STT_ALT = get_param_handle("RADAR_STT_ALT"),
    STT_SPD = get_param_handle("RADAR_STT_SPD"),
    STT_VX = get_param_handle("RADAR_STT_VX"),
    STT_VY = get_param_handle("RADAR_STT_VY"),
    STT_VZ = get_param_handle("RADAR_STT_VZ"),

    HIT_HIST = get_param_handle("RADAR_HIT_HIST"),
}


