local cmfd_selection = 0
-- [2026-07-27] Paridade F-5TH = F-5EM: a disponibilidade da pagina IFR/REVO vem
-- de CMFD_HAS_IFR (publicado por cmfds.lua) em vez do gate direto de variante.
local CMFD_HAS_IFR = get_param_handle("CMFD_HAS_IFR")

function SetCommandMenu1(command,value, CMFD)
    if value == 1 then 
        local selected=-1
        if command==device_commands.CMFD1OSS1 or command==device_commands.CMFD2OSS1 then
            CMFD["Format"]:set(SUB_PAGE_ID.MENU2)
            return
        elseif command==device_commands.CMFD1OSS2 or command==device_commands.CMFD2OSS2 then
        elseif command==device_commands.CMFD1OSS4 or command==device_commands.CMFD2OSS4 then
        elseif command==device_commands.CMFD1OSS3 or command==device_commands.CMFD2OSS3 then
        elseif command==device_commands.CMFD1OSS5 or command==device_commands.CMFD2OSS5 then
        elseif command==device_commands.CMFD1OSS6 or command==device_commands.CMFD2OSS6 then selected=SUB_PAGE_ID.LDP
        elseif command==device_commands.CMFD1OSS7 or command==device_commands.CMFD2OSS7 then selected=SUB_PAGE_ID.RDR
        elseif command==device_commands.CMFD1OSS8 or command==device_commands.CMFD2OSS8 then selected=SUB_PAGE_ID.BIT
        elseif command==device_commands.CMFD1OSS9 or command==device_commands.CMFD2OSS9 then selected=SUB_PAGE_ID.DVR
        elseif command==device_commands.CMFD1OSS10 or command==device_commands.CMFD2OSS10 then selected=SUB_PAGE_ID.NAV
        elseif command==device_commands.CMFD1OSS11 or command==device_commands.CMFD2OSS11 then selected=SUB_PAGE_ID.PFL
        elseif command==device_commands.CMFD1OSS12 or command==device_commands.CMFD2OSS12 then selected=SUB_PAGE_ID.EMER
        elseif command==device_commands.CMFD1OSS13 or command==device_commands.CMFD2OSS13 then selected=SUB_PAGE_ID.DTU
        elseif command==device_commands.CMFD1OSS14 or command==device_commands.CMFD2OSS14 then selected=SUB_PAGE_ID.UFC
        elseif command==device_commands.CMFD1OSS21 or command==device_commands.CMFD2OSS21 then selected=SUB_PAGE_ID.HUD
        elseif command==device_commands.CMFD1OSS22 or command==device_commands.CMFD2OSS22 then selected=SUB_PAGE_ID.HMD
        elseif command==device_commands.CMFD1OSS23 or command==device_commands.CMFD2OSS23 then selected=SUB_PAGE_ID.EICAS
        elseif command==device_commands.CMFD1OSS24 or command==device_commands.CMFD2OSS24 then selected=SUB_PAGE_ID.ADHSI
        elseif command==device_commands.CMFD1OSS25 or command==device_commands.CMFD2OSS25 then selected=SUB_PAGE_ID.EW
        elseif command==device_commands.CMFD1OSS26 or command==device_commands.CMFD2OSS26 then selected=SUB_PAGE_ID.SMS
        elseif command==device_commands.CMFD1OSS27 or command==device_commands.CMFD2OSS27 then
            if CMFD_HAS_IFR:get() > 0.5 then selected=SUB_PAGE_ID.IFR end
        elseif command==device_commands.CMFD1OSS28 or command==device_commands.CMFD2OSS28 then selected=SUB_PAGE_ID.TSD
        end

        if selected > 0 then
            if cmfd_selection == 0 then
                if CMFD["SelLeft"]:get() == selected then
                    CMFD["SelLeft"]:set(CMFD["SelTop"]:get())
                    CMFD["SelLeftName"]:set(CMFD["SelTopName"]:get())
                end
                if CMFD["SelRight"]:get() == selected then
                    CMFD["SelRight"]:set(CMFD["SelTop"]:get())
                    CMFD["SelRightName"]:set(CMFD["SelTopName"]:get())
                end
                CMFD["SelTop"]:set(selected)
                CMFD["SelTopName"]:set(SUB_PAGE_NAME[selected])
            elseif cmfd_selection == 1 then
                if CMFD["SelTop"]:get() == selected then
                    CMFD["SelTop"]:set(CMFD["SelLeft"]:get())
                    CMFD["SelTopName"]:set(CMFD["SelLeftName"]:get())
                end
                if CMFD["SelRight"]:get() == selected then
                    CMFD["SelRight"]:set(CMFD["SelLeft"]:get())
                    CMFD["SelRightName"]:set(CMFD["SelLeftName"]:get())
                end
                CMFD["SelLeft"]:set(selected)
                CMFD["SelLeftName"]:set(SUB_PAGE_NAME[selected])
            elseif cmfd_selection == 2 then
                if CMFD["SelLeft"]:get() == selected then
                    CMFD["SelLeft"]:set(CMFD["SelRight"]:get())
                    CMFD["SelLeftName"]:set(CMFD["SelRightName"]:get())
                end
                if CMFD["SelTop"]:get() == selected then
                    CMFD["SelTop"]:set(CMFD["SelRight"]:get())
                    CMFD["SelTopName"]:set(CMFD["SelRightName"]:get())
                end
                CMFD["SelRight"]:set(selected)
                CMFD["SelRightName"]:set(SUB_PAGE_NAME[selected])
            end
        end
        if selected == SUB_PAGE_ID.TSD and cmfd_selection == 0 and CMFD["FULL"] then
            CMFD["FULL"]:set(1)
        end
        CMFD["Format"]:set(CMFD["SelTop"]:get())
    elseif value == 100 then
        if command==device_commands.CMFD1OSS1 or command==device_commands.CMFD2OSS1 then 
            CMFD["Sel"]:set(CMFD["SelTop"]:get())
            cmfd_selection = 0
        elseif command==device_commands.CMFD1OSS16 or command==device_commands.CMFD2OSS16 then
            CMFD["Sel"]:set(CMFD["SelRight"]:get())
            cmfd_selection = 2
        elseif command==device_commands.CMFD1OSS19 or command==device_commands.CMFD2OSS19 then
            CMFD["Sel"]:set(CMFD["SelLeft"]:get())
            cmfd_selection = 1
        end
        CMFD["Format"]:set(SUB_PAGE_ID.MENU1)
    end
end

register_as_cmfd_item(SUB_PAGE_ID.MENU1, nil, nil, SetCommandMenu1)
