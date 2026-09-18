-- =====================================================================
-- [Fase 20] Checklists de Emergencia PT-BR para F-5EM (FAB bold-face)
-- =====================================================================
-- Modulo de dados estruturados com as 12 emergencias mais criticas
-- segundo o manual NSCA F-5EM 2017. Cada checklist contem ate 8 passos
-- bold-face que o piloto deve executar de memoria.
--
-- O modulo publica param handles para overlay HUD/UFCP/CMFD:
--   EMER_CHECKLIST_ID     (1..N)
--   EMER_CHECKLIST_TITLE  (string)
--   EMER_CHECKLIST_STEP   (1..M passo atual)
--   EMER_CHECKLIST_TEXT   (string do passo atual)
--   EMER_CHECKLIST_ACTIVE (0/1)
--
-- API publica:
--   checklists_emer_br.start(id)  -> ativa checklist
--   checklists_emer_br.next()     -> proximo passo
--   checklists_emer_br.prev()     -> passo anterior
--   checklists_emer_br.stop()     -> fecha checklist
-- =====================================================================

local M = {}

-- Handles publicados
local H_ID     = get_param_handle("EMER_CHECKLIST_ID")
local H_TITLE  = get_param_handle("EMER_CHECKLIST_TITLE")
local H_STEP   = get_param_handle("EMER_CHECKLIST_STEP")
local H_TEXT   = get_param_handle("EMER_CHECKLIST_TEXT")
local H_ACTIVE = get_param_handle("EMER_CHECKLIST_ACTIVE")
local H_TOTAL  = get_param_handle("EMER_CHECKLIST_TOTAL")

-- Tabela de checklists (12 itens)
M.checklists = {
    [1] = {
        title = "FOGO MOTOR ESQUERDO",
        steps = {
            "1. THROTTLE ESQUERDO - OFF",
            "2. FIRE HANDLE ESQ  - PULL",
            "3. AGT/EXT          - DISCHARGE",
            "4. RAIO ELETRICO    - OFF se necessario",
            "5. INICIAR APROACH IMEDIATO",
            "6. DECLARAR EMERGENCIA - 7700 / GUARD",
            "7. POUSO COM SINGLE ENGINE PROCEDURE",
        },
    },
    [2] = {
        title = "FOGO MOTOR DIREITO",
        steps = {
            "1. THROTTLE DIREITO - OFF",
            "2. FIRE HANDLE DIR  - PULL",
            "3. AGT/EXT          - DISCHARGE",
            "4. INICIAR APROACH IMEDIATO",
            "5. DECLARAR EMERGENCIA - 7700 / GUARD",
            "6. POUSO COM SINGLE ENGINE",
        },
    },
    [3] = {
        title = "FALHA HIDRAULICA UTILITY",
        steps = {
            "1. MANTER 250 KIAS minimo",
            "2. FLAPS - EMER (alavanca alt)",
            "3. TREM  - GRAVITY EXTEND",
            "4. EVITAR ROLLS BRUSCOS",
            "5. POUSO LONGO, SEM AERO BRAKE",
            "6. AVISAR SAR / EMERGENCIA",
        },
    },
    [4] = {
        title = "FALHA HIDRAULICA FLIGHT CONTROL",
        steps = {
            "1. REDUZIR Q (velocidade) - 250 KIAS",
            "2. EVITAR MANOBRAS BRUSCAS",
            "3. CHECAR PRESSAO P/E (gauges)",
            "4. POUSO ASAP no campo mais proximo",
            "5. SE TRAVA TOTAL - EJECAO",
        },
    },
    [5] = {
        title = "FALHA ELETRICA TOTAL",
        steps = {
            "1. BATTERY - CHECK ON",
            "2. AC GEN  - L+R RESET",
            "3. INVERTER - ON",
            "4. SE PERSISTIR: ESSENTIAL BUS only",
            "5. SAI mantem atitude",
            "6. POUSAR ASAP, no flap, no AB",
        },
    },
    [6] = {
        title = "FALHA AOA / PITOT",
        steps = {
            "1. PITOT HEAT - ON",
            "2. CRUZAR REFERENCIAS com SAI/GPS",
            "3. EVITAR estol baixa velocidade",
            "4. POUSAR por SAI + GS visual",
            "5. APROACH em 165 KIAS estabilizada",
        },
    },
    [7] = {
        title = "STALL EM MANOBRA",
        steps = {
            "1. ALIVIAR back-stick imediato",
            "2. THROTTLE - IDLE (evitar yaw)",
            "3. NEUTRO ailerons e rudder",
            "4. NOSE LOW para recuperar AOA",
            "5. CHECAR ALT (recuperar > 5k AGL)",
        },
    },
    [8] = {
        title = "SPIN",
        steps = {
            "1. THROTTLE - IDLE",
            "2. CONTROLES - NEUTRO + ailerons NEUTRO",
            "3. RUDDER - OPOSTO ao spin (full)",
            "4. STICK - FORWARD (centrado)",
            "5. APOS PARAR: NEUTRO rudder",
            "6. SE < 10k AGL: EJECAO",
        },
    },
    [9] = {
        title = "FALHA AB (AFTERBURNER)",
        steps = {
            "1. AB OFF - throttle MIL",
            "2. LIMITAR 0.95 Mach (evitar surge)",
            "3. CRUZEIRO ECONOMICO 0.80M",
            "4. POUSO sem AB, flaps full 45",
        },
    },
    [10] = {
        title = "BIRD STRIKE / ENGINE FOD",
        steps = {
            "1. AVALIAR vibracao e EGT",
            "2. SE FOGO: aplicar proc Fogo Motor",
            "3. SE SURGE: throttle IDLE no afetado",
            "4. SINGLE ENGINE APPROACH",
            "5. DECLARAR EMERGENCIA",
        },
    },
    [11] = {
        title = "FUMACA OU FOGO CABINE",
        steps = {
            "1. MASCARA - 100%% OXIGENIO",
            "2. CANOPY VENT - ABERTA",
            "3. ELEC ESS BUS - se origem eletrica",
            "4. POUSO IMEDIATO no campo proximo",
            "5. SE NAO DISSIPAR: EJECAO",
        },
    },
    [12] = {
        title = "EJECAO (CRITERIOS BOLD-FACE)",
        steps = {
            "1. ALT < 2000 ft AGL + sem controle",
            "2. FOGO descontrolado",
            "3. SPIN nao recuperavel < 10k ft",
            "4. POSICAO: VERTICAL, costas firmes",
            "5. MAO no PUNHO INFERIOR (ou superior)",
            "6. PUXAR FIRMEMENTE 2 SEGUNDOS",
            "7. APOS EJECAO: 4 LINHAS / canopy",
            "8. APOS POUSO: kit + farol + SAR",
        },
    },
}

-- Estado interno
local current_id = 0
local current_step = 1

-- Inicializa handles
H_ID:set(0)
H_TITLE:set("")
H_STEP:set(0)
H_TEXT:set("")
H_ACTIVE:set(0)
H_TOTAL:set(0)

local function publish()
    if current_id == 0 then
        H_ID:set(0)
        H_TITLE:set("")
        H_STEP:set(0)
        H_TEXT:set("")
        H_ACTIVE:set(0)
        H_TOTAL:set(0)
        return
    end
    local cl = M.checklists[current_id]
    if not cl then return end
    H_ID:set(current_id)
    H_TITLE:set(cl.title)
    H_TOTAL:set(#cl.steps)
    H_STEP:set(current_step)
    H_TEXT:set(cl.steps[current_step] or "")
    H_ACTIVE:set(1)
end

function M.start(id)
    if not M.checklists[id] then return false end
    current_id = id
    current_step = 1
    publish()
    return true
end

function M.next()
    if current_id == 0 then return false end
    local cl = M.checklists[current_id]
    if not cl then return false end
    if current_step < #cl.steps then
        current_step = current_step + 1
        publish()
        return true
    end
    return false
end

function M.prev()
    if current_id == 0 then return false end
    if current_step > 1 then
        current_step = current_step - 1
        publish()
        return true
    end
    return false
end

function M.stop()
    current_id = 0
    current_step = 1
    publish()
end

function M.count()
    return #M.checklists
end

return M
