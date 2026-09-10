-- =====================================================================
--  SFM_Data - Embraer / Alenia AMX (A-1)
--  Motor: Rolls-Royce Spey Mk 807 (49.1 kN estático, sem AB)
-- =====================================================================

AMX_SFM = {
    aerodynamics = {
        Cy0       = 0.0,
        Mzalfa    = 4.8,     -- Agilidade de arfagem para ataque ao solo
        Mzalfadt  = 0.7,     -- Amortecimento de arfagem
        kjx       = 3.80,    -- Inércia de rolagem
        kjz       = 0.00115, -- Inércia de arfagem
        Czbe      = -0.014,  -- Estabilidade direcional (guinada)
        cx_gear   = 0.085,   -- Arrasto do trem de pouso
        cx_flap   = 0.065,   -- Arrasto dos flaps duplos Slotted
        cy_flap   = 0.85,    -- Sustentação extra dos flaps (Capacidade STOL)
        cx_brk    = 0.10,    -- Arrasto dos freios aerodinâmicos laterais

        table_data = {
            -- Mach    Cx0      Cya     B       B4      Omxmax  Aldop   Cymax
            { 0.000,   0.0250,  0.075,  0.0450, 0.15,   3.50,   24.000, 1.300 },
            { 0.200,   0.0250,  0.075,  0.0450, 0.15,   3.50,   24.000, 1.300 },
            { 0.400,   0.0260,  0.078,  0.0480, 0.16,   3.50,   23.000, 1.350 },
            { 0.600,   0.0280,  0.082,  0.0520, 0.18,   3.50,   22.000, 1.400 },
            { 0.750,   0.0310,  0.090,  0.0550, 0.19,   3.20,   20.000, 1.380 },
            -- Divergência de Arrasto Transônica (Barreira de Mach 0.95)
            { 0.800,   0.0350,  0.095,  0.0600, 0.20,   3.00,   18.000, 1.350 },
            { 0.850,   0.0500,  0.100,  0.0700, 0.25,   2.80,   16.000, 1.300 },
            { 0.900,   0.0850,  0.090,  0.1000, 0.35,   2.50,   14.000, 1.200 },
            { 0.950,   0.1500,  0.080,  0.1500, 0.40,   2.00,   12.000, 1.100 },
            -- Supersônico (Parede de Arrasto)
            { 1.000,   0.2800,  0.065,  0.2000, 0.50,   1.50,   10.000, 1.000 },
            { 1.050,   0.3500,  0.055,  0.2500, 0.60,   1.00,   10.000, 0.900 },
            { 1.100,   0.4500,  0.050,  0.3000, 0.70,   0.80,    9.000, 0.850 },
            { 1.200,   0.6000,  0.045,  0.4000, 0.80,   0.50,    8.000, 0.800 },
            { 1.500,   0.9000,  0.040,  0.8000, 1.50,   0.10,    5.000, 0.500 },
        },
    },

    engine = {
        Nmg     = 60.0,
        MinRUD  = 0,
        MaxRUD  = 1,
        MaksRUD = 1.0,
        ForsRUD = 1.0,
        typeng  = 0,     -- Corrigido: 0 = Turbojet/Turbofan sem pós-combustor no SFM
        hMaxEng = 13.0,  -- Teto operacional em km (~42.600 ft)
        dcx_eng = 0.0124,
        cemax   = 0.65,  -- SFC
        cefor   = 0.65,
        dpdh_m  = 1800,
        dpdh_f  = 1800,

        table_data = {
            -- Mach    Pmax (N)   Pfor (N)
            { 0.00,    49100,     49100 },
            { 0.20,    47500,     47500 },
            { 0.30,    46000,     46000 },
            { 0.40,    44500,     44500 },
            { 0.50,    42000,     42000 },
            { 0.60,    39500,     39500 },
            { 0.70,    37000,     37000 },
            { 0.80,    35000,     35000 },
            { 0.90,    32000,     32000 },
            { 1.00,    25000,     25000 },
            { 1.10,    15000,     15000 },
            { 1.20,    10000,     10000 },
            { 1.50,     5000,      5000 },
            { 3.90,     1000,      1000 },
        },
    },

    -- =================================================================
    --  SUB-TABELAS OBRIGATÓRIAS QUE FALTAVAM (CORREÇÃO DE CRASH)
    -- =================================================================
    
    -- Inércia e Centro de Gravidade
    inertia = {
        Ixx = 11500.0, -- Momento de inércia no eixo X (Roll)
        Iyy = 28500.0, -- Momento de inércia no eixo Y (Pitch)
        Izz = 38000.0, -- Momento de inércia no eixo Z (Yaw)
        Ixz = 0.0,
        cg  = { 0.0, 0.0, 0.0 }, -- Posição do CG em relação à origem do EDM
    },

    -- Comportamento de Estol / Spin
    stalls = {
        critical_aoa       = 22.0, -- Ângulo de ataque crítico (graus)
        critical_aoa_flaps = 20.0,
        stuck_aoa          = 32.0,
    },

    -- Estabilidade Direcional (Leme de Direção)
    fin = {
        Cy0        = 0.0,
        Czbe       = -0.015,
        cx_brk_aer = 0.06,
    },
}

-- =====================================================================
--  SFM_Data - Embraer / Alenia AMX-T (A-1B Biplace)
--  Motor: Rolls-Royce Spey Mk 807 (49.1 kN estático, sem AB)
-- =====================================================================

AMX_T_SFM = {
    aerodynamics = {
        Cy0       = 0.0,
        Mzalfa    = 4.3,     -- Ajustado: Arfagem ligeiramente mais pesada (era 4.8) devido ao 2º cockpit
        Mzalfadt  = 0.8,     -- Ajustado: Amortecimento maior no eixo pitch (era 0.7)
        kjx       = 3.80,    -- Inércia de rolagem (mantida, envergadura é idêntica)
        kjz       = 0.00130, -- Ajustado: Inércia de arfagem maior (era 0.00115)
        Czbe      = -0.014,  -- Estabilidade direcional (guinada)
        cx_gear   = 0.085,   -- Arrasto do trem de pouso
        cx_flap   = 0.065,   -- Arrasto dos flaps duplos Slotted
        cy_flap   = 0.85,    -- Sustentação extra dos flaps
        cx_brk    = 0.10,    -- Arrasto dos freios aerodinâmicos

        table_data = {
            -- Mach    Cx0      Cya     B       B4      Omxmax  Aldop   Cymax
            { 0.000,   0.0255,  0.075,  0.0460, 0.15,   3.30,   23.000, 1.280 },
            { 0.200,   0.0255,  0.075,  0.0460, 0.15,   3.30,   23.000, 1.280 },
            { 0.400,   0.0265,  0.078,  0.0490, 0.16,   3.30,   22.500, 1.330 },
            { 0.600,   0.0285,  0.082,  0.0530, 0.18,   3.30,   21.500, 1.380 },
            { 0.750,   0.0315,  0.090,  0.0560, 0.19,   3.00,   19.500, 1.360 },
            -- Divergência de Arrasto Transônica (Barreira de Mach 0.95)
            { 0.800,   0.0355,  0.095,  0.0610, 0.20,   2.80,   17.500, 1.330 },
            { 0.850,   0.0510,  0.100,  0.0710, 0.25,   2.60,   15.500, 1.280 },
            { 0.900,   0.0860,  0.090,  0.1010, 0.35,   2.30,   13.500, 1.180 },
            { 0.950,   0.1520,  0.080,  0.1510, 0.40,   1.90,   11.500, 1.080 },
            -- Supersônico (Parede de Arrasto)
            { 1.000,   0.2850,  0.065,  0.2010, 0.50,   1.40,    9.500, 0.980 },
            { 1.050,   0.3550,  0.055,  0.2510, 0.60,   0.90,    9.500, 0.880 },
            { 1.100,   0.4550,  0.050,  0.3010, 0.70,   0.70,    8.500, 0.830 },
            { 1.200,   0.6050,  0.045,  0.4010, 0.80,   0.40,    7.500, 0.780 },
            { 1.500,   0.9050,  0.040,  0.8010, 1.50,   0.10,    4.500, 0.480 },
        },
    },

    engine = {
        Nmg     = 60.0,
        MinRUD  = 0,
        MaxRUD  = 1,
        MaksRUD = 1.0,
        ForsRUD = 1.0,
        typeng  = 0,     -- 0 = Turbojet/Turbofan sem pós-combustor
        hMaxEng = 13.0,  -- Teto operacional em km
        dcx_eng = 0.0124,
        cemax   = 0.65,
        cefor   = 0.65,
        dpdh_m  = 1800,
        dpdh_f  = 1800,

        table_data = {
            -- Mach    Pmax (N)   Pfor (N)
            { 0.00,    49100,     49100 },
            { 0.20,    47500,     47500 },
            { 0.30,    46000,     46000 },
            { 0.40,    44500,     44500 },
            { 0.50,    42000,     42000 },
            { 0.60,    39500,     39500 },
            { 0.70,    37000,     37000 },
            { 0.80,    35000,     35000 },
            { 0.90,    32000,     32000 },
            { 1.00,    25000,     25000 },
            { 1.10,    15000,     15000 },
            { 1.20,    10000,     10000 },
            { 1.50,     5000,      5000 },
            { 3.90,     1000,      1000 },
        },
    },

    -- =================================================================
    --  SUB-TABELAS DE INÉRCIA RECALIBRADAS PARA O AMX-T (BIPLACE)
    -- =================================================================
    
    inertia = {
        Ixx = 11800.0, -- Inércia em Roll (ligeiro aumento devido a aviônicos no cockpit traseiro)
        Iyy = 31200.0, -- Ajustado: Inércia em Pitch maior (era 28500.0 no monoplace)
        Izz = 41000.0, -- Ajustado: Inércia em Yaw maior (era 38000.0 no monoplace)
        Ixz = 0.0,
        cg  = { 0.15, 0.0, 0.0 }, -- CG deslocado levemente para a frente (0.15m) devido ao 2º piloto
    },

    stalls = {
        critical_aoa       = 21.0, -- Limite de AoA levemente menor devido à fuselagem mais longa/pesada
        critical_aoa_flaps = 19.5,
        stuck_aoa          = 30.0,
    },

    fin = {
        Cy0        = 0.0,
        Czbe       = -0.015,
        cx_brk_aer = 0.06,
    },
}
--[[ {
    aerodynamics = {     -- Cx = Cx_0 + Cy^2*B2 +Cy^4*B4
        Cy0        = 0.0, -- Zero AoA lift coefficient
        Mzalfa     = 4.8, -- Pitch agility (Ajustado para aeronave de ataque mais pesada)
        Mzalfadt   = 0.7, -- Pitch agility damping
        kjx        = 3.80, -- Roll inertia (Menor que o caça, envergadura curta, mas carrega peso nas pontas)
        kjz        = 0.00115, -- Pitch inertia
        Czbe       = -0.014, -- Coefficient, along Z axis (yaw orientation)
        cx_gear    = 0.085, -- Drag do trem de pouso
        cx_flap    = 0.065, -- Drag com flaps full (AMX tem flaps duplos grandes, gera bastante arrasto)
        cy_flap    = 0.85, -- Lift com flaps full (Aumentado bastante, o AMX tem excelente sustentação STOL)
        cx_brk     = 0.10, -- Drag dos speedbrakes (Freios aerodinâmicos na lateral da fuselagem)

        table_data = {
            --      Mach    Cx0      Cya     B       B4      Omxmax  Aldop   Cymax
            -- Voo Subsônico (Baixo arrasto, excelente manobrabilidade)
            { 0.000, 0.0250, 0.075, 0.0450, 0.15, 3.50, 24.000, 1.300 },
            { 0.200, 0.0250, 0.075, 0.0450, 0.15, 3.50, 24.000, 1.300 },
            { 0.400, 0.0260, 0.078, 0.0480, 0.16, 3.50, 23.000, 1.350 },
            { 0.600, 0.0280, 0.082, 0.0520, 0.18, 3.50, 22.000, 1.400 },
            { 0.750, 0.0310, 0.090, 0.0550, 0.19, 3.20, 20.000, 1.380 },

            -- Divergência de Arrasto (Aproximação de Mach crítico)
            { 0.800, 0.0350, 0.095, 0.0600, 0.20, 3.00, 18.000, 1.350 },
            { 0.850, 0.0500, 0.100, 0.0700, 0.25, 2.80, 16.000, 1.300 },
            { 0.900, 0.0850, 0.090, 0.1000, 0.35, 2.50, 14.000, 1.200 },
            { 0.950, 0.1500, 0.080, 0.1500, 0.40, 2.00, 12.000, 1.100 }, -- VNE estrutural do AMX

            -- Barreira do Som (A "Parede Aerodinâmica")
            -- Cx0 (arrasto de forma) e B (arrasto induzido) sobem violentamente para impedir voo supersônico irreal.
            { 1.000, 0.2800, 0.065, 0.2000, 0.50, 1.50, 10.000, 1.000 },
            { 1.050, 0.3500, 0.055, 0.2500, 0.60, 1.00, 10.000, 0.900 },
            { 1.100, 0.4500, 0.050, 0.3000, 0.70, 0.80, 9.000,  0.850 },
            { 1.200, 0.6000, 0.045, 0.4000, 0.80, 0.50, 8.000,  0.800 },

            -- Limite Máximo Teórico (Apenas em caso de mergulho extremo para a engine não bugar)
            { 1.500, 0.9000, 0.040, 0.8000, 1.50, 0.10, 5.000,  0.500 },
        }, -- end of table

        -- M        - Mach number
        -- Cx0      - Coefficient, drag, profile (Aumentado drasticamente no transônico para criar a "parede" Mach 1)
        -- Cya      - Normal force coefficient of the wing/body.
        -- B        - Polar quad coeff (Arrasto induzido)
        -- B4       - Polar 4th power coeff
        -- Omxmax   - Roll rate (Rad/s). Ajustado para máx de ~200 graus/s (3.5 rad/s)
        -- Aldop    - Alfadop Max AOA at current M (Limitado realisticamente a 24 graus)
        -- Cymax    - Coefficient, lift, maximum possible.
    },             -- end of aerodynamics

    engine = {     --Rolls-Royce Spey Mk 807
        Nmg     = 60.0, -- RPM at idle (Mantido padrão ~60%)
        MinRUD  = 0, -- Min state of the throttle
        MaxRUD  = 1, -- Max state of the throttle (Sem AB, o max é 1.0)
        MaksRUD = 1.0, -- Military power state of the throttle (Igual ao MaxRUD, sem detentor de AB)
        ForsRUD = 1.0, -- Afterburner state of the throttle (Não existe, setado para 1.0)
        typeng  = 4,
        hMaxEng    = 13.0, -- Max altitude for safe engine operation em km (Teto operacional real do AMX é ~13km / 42.650 ft)
        dcx_eng    = 0.0124, -- Engine drag coefficient
        cemax      = 0.65, -- Specific fuel consumption for MIL (Spey é bem eficiente, ajustado para ~0.65)
        cefor      = 0.65, -- Specific fuel consumption for AB (Igual ao MIL, pois não há AB)
        dpdh_m     = 1800, -- Altitude coefficient for max thrust (Perde empuxo mais rápido que caças de alta altitude)
        dpdh_f     = 1800, -- Altitude coefficient for AB thrust (Igual ao MIL)
        table_data = {
            --        M     Pmax (Newtons)  Pfor (Newtons)
            -- O motor Spey 807 gera 49.1 kN (49100 N) estático ao nível do mar.
            -- Como não há pós-combustor, Pmax e Pfor recebem os mesmos valores.
            -- O empuxo cai rapidamente com o aumento do Mach devido à arquitetura do turbofan subsônico.
            [1]  = { 0.00, 49100, 49100 },
            [2]  = { 0.20, 47500, 47500 },
            [3]  = { 0.30, 46000, 46000 },
            [4]  = { 0.40, 44500, 44500 },
            [5]  = { 0.50, 42000, 42000 },
            [6]  = { 0.60, 39500, 39500 },
            [7]  = { 0.70, 37000, 37000 },
            [8]  = { 0.80, 35000, 35000 },
            [9]  = { 0.90, 32000, 32000 },

            -- Acima de Mach 0.95 (VNE do AMX), o arrasto das pás do fan derruba a eficiência.
            -- Valores mantidos apenas para a engine física não quebrar caso a aeronave entre em mergulho.
            [10] = { 1.00, 25000, 25000 },
            [11] = { 1.10, 15000, 15000 },
            [12] = { 1.20, 10000, 10000 },
            [13] = { 1.50, 5000, 5000 },
            [14] = { 3.90, 1000, 1000 },
        }, -- end of table_data
        -- M    - Mach number
        -- Pmax    - Engine thrust at military power (Newtons)
        -- Pfor    - Engine thrust at AFB (Newtons - Igual ao Pmax no AMX)
    }, -- end of engine
}
 ]]--