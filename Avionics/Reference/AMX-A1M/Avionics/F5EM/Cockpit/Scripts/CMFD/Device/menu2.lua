local CMFD_VARIANT_F5EM = get_param_handle("CMFD_VARIANT_F5EM")

function SetCommandMenu2(command,value, CMFD)
    if value == 1 then
        local selected
        if command==device_commands.CMFD1OSS1 or command==device_commands.CMFD2OSS1 then
            CMFD["Format"]:set(SUB_PAGE_ID.MENU1)
            return
        elseif command==device_commands.CMFD1OSS2 or command==device_commands.CMFD2OSS2 then
            -- Função: Restaurar a configuração padrão do sistema para os formatos Primário e Secundário e para o DOI de cada modo principal.
        elseif command==device_commands.CMFD1OSS4 or command==device_commands.CMFD2OSS4 then
            -- Função: Restaurar os valores padrão do brilho da simbologia e do contraste das imagens de vídeo.
            -- Esta função é usada para se fazer uma recuperação rápida de ajustes errôneos de contraste ou brilho.
        elseif command==device_commands.CMFD1OSS6 or command==device_commands.CMFD2OSS6 then
            selected = SUB_PAGE_ID.MAP
        elseif command==device_commands.CMFD1OSS7 or command==device_commands.CMFD2OSS7 then
            selected = SUB_PAGE_ID.DLSET
        elseif command==device_commands.CMFD1OSS8 or command==device_commands.CMFD2OSS8 then
            selected = SUB_PAGE_ID.DLMSG
        elseif command==device_commands.CMFD1OSS9 or command==device_commands.CMFD2OSS9 then
            selected = SUB_PAGE_ID.EFB
        elseif command==device_commands.CMFD1OSS10 or command==device_commands.CMFD2OSS10 then
            if (CMFD_VARIANT_F5EM:get() or 0) > 0.5 then
                selected = SUB_PAGE_ID.SURV
            end
        end

        if selected then
            CMFD["SelTop"]:set(selected)
            CMFD["SelTopName"]:set(SUB_PAGE_NAME[selected])
            CMFD["Sel"]:set(selected)
            CMFD["Format"]:set(selected)
            if selected == SUB_PAGE_ID.SURV then CMFD["FULL"]:set(1) end
        end
    end
end

register_as_cmfd_item(SUB_PAGE_ID.MENU2, nil, nil, SetCommandMenu2)
