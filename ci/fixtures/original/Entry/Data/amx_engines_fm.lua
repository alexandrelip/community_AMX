amx_engines_fm = {
    [1] =
    {
        pos                 = { -5.500, 0.100, 0 }, -- Recuado para o comprimento mais curto do AMX em relação ao CG
        elevation           = 0,               -- Ângulo do bico de exaustão
        diameter            = 0.75,            -- Diâmetro do bico do motor Spey 807 (menor que o do caça original)
        exhaust_length_ab   = 0,
        exhaust_length_ab_K = 0,
        -- O motor Spey é um projeto mais antigo e gera fumaça visível, especialmente em RPM máximo
        smokiness_level     = 0.25, -- Aumentado de 0.01 (limpo) para 0.25 (fumaça moderada/alta)
    },                         -- end of [1]
}
