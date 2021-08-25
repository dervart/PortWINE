#!/bin/bash
# Author: PortWINE-Linux.ru
export pw_full_command_line=("$0" $*)
if [ -f "$1" ]; then
    export portwine_exe="$(readlink -f "$1")"
fi
. "$(dirname $(readlink -f "$0"))/runlib"
kill_portwine

portwine_launch () {
    start_portwine
    PORTWINE_MSI=`basename "${portwine_exe}" | grep .msi`
    PORTWINE_BAT=`basename "${portwine_exe}" | grep .bat`
    if [ ! -z "${PW_VIRTUAL_DESKTOP}" ] && [ "${PW_VIRTUAL_DESKTOP}" == "1" ] ; then
        pw_screen_resolution=`xrandr --current | grep "*" | awk '{print $1;}' | head -1`
        pw_run explorer "/desktop=portwine,${pw_screen_resolution}" "$portwine_exe"
    elif [ ! -z "${PORTWINE_MSI}" ]; then
        pw_run msiexec /i "$portwine_exe"
    elif [ ! -z "${PORTWINE_BAT}" ] || [ ! -z "${portwine_exe}" ]; then
        pw_run ${WINE_WIN_START} "$portwine_exe"
    else
        pw_run explorer
    fi
}

portwine_create_shortcut () {
    if [ ! -z "${portwine_exe}" ]; then
        PORTPROTON_EXE="${portwine_exe}"
    else
        PORTPROTON_EXE=$(zenity --file-selection --file-filter=""*.exe" "*.bat"" \
        --title="${sc_path}" --filename="${PORT_WINE_PATH}/data/pfx/drive_c/")
        if [ $? -eq 1 ];then exit 1; fi
    fi
    if [ ! -z "${PORTWINE_CREATE_SHORTCUT_NAME}" ] ; then
        export PORTPROTON_NAME="${PORTWINE_CREATE_SHORTCUT_NAME}"
    else
        PORTPROTON_NAME="$(basename "${PORTPROTON_EXE}" | sed s/".exe"/""/gi )"
    fi
    PORTPROTON_PATH="$( cd "$( dirname "${PORTPROTON_EXE}" )" >/dev/null 2>&1 && pwd )"
    if [ -x "`which wrestool 2>/dev/null`" ]; then
        wrestool -x --output="${PORTPROTON_PATH}/" -t14 "${PORTPROTON_EXE}"
        cp "$(ls -S -1 "${PORTPROTON_EXE}"*".ico"  | head -n 1)" "${PORTPROTON_EXE}.ico"
        icotool -x --output="${PORTPROTON_PATH}/" "${PORTPROTON_EXE}.ico"
        cp "$(ls -S -1 "${PORTPROTON_EXE}"*".png"  | head -n 1)" "${PORTPROTON_EXE}.png"
        cp -f "${PORTPROTON_EXE}.png" "${PORT_WINE_PATH}/data/img/${PORTPROTON_NAME}.png"
        rm -f "${PORTPROTON_PATH}/"*.ico
        rm -f "${PORTPROTON_PATH}/"*.png
    fi
    name_desktop="${PORTPROTON_NAME}"
    echo "[Desktop Entry]" > "${PORT_WINE_PATH}/${name_desktop}.desktop"
    echo "Name=${PORTPROTON_NAME}" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    if [ -z "${PW_CHECK_AUTOINSTAL}" ]
    then echo "Exec=env PW_GUI_DISABLED_CS=1 "\"${PORT_SCRIPTS_PATH}/start.sh\" \"${PORTPROTON_EXE}\" "" \
    >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    else echo "Exec=env "\"${PORT_SCRIPTS_PATH}/start.sh\" \"${PORTPROTON_EXE}\" "" \
    >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    fi
    echo "Type=Application" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    echo "Categories=Game" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    echo "StartupNotify=true" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    echo "Path="${PORT_SCRIPTS_PATH}/"" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    echo "Icon="${PORT_WINE_PATH}/data/img/${PORTPROTON_NAME}.png"" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"
    `zenity --question --title "${inst_set}." --text "${ss_done}" --no-wrap ` &> /dev/null
    if [ $? -eq "0" ]; then
        cp -f "${PORT_WINE_PATH}/${name_desktop}.desktop" /home/${USER}/.local/share/applications/
    fi
    xdg-open "${PORT_WINE_PATH}" 2>1 >/dev/null &
}

portwine_start_debug () {
    kill_portwine
    export PW_LOG=1
    export PW_WINEDBG_DISABLE=0
    echo "${port_deb1}" > "${PORT_WINE_PATH}/${portname}.log"
    echo "${port_deb2}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-------------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "PortWINE version:" >> "${PORT_WINE_PATH}/${portname}.log"
    read install_ver < "${PORT_WINE_TMP_PATH}/${portname}_ver"
    echo "${portname}-${install_ver}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "------------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Scripts version:" >> "${PORT_WINE_PATH}/${portname}.log"
    cat "${PORT_WINE_TMP_PATH}/scripts_ver" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ "${PW_USE_RUNTIME}" = 0 ] ; then
        echo "RUNTIME is disabled" >> "${PORT_WINE_PATH}/${portname}.log"
    else
        echo "RUNTIME is enabled" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "----------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ ! -z "${portwine_exe}" ] ; then
        echo "Debug for programm:" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "${portwine_exe}" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "---------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "GLIBC version:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo `ldd --version | grep -m1 ldd | awk '{print $NF}'` >> "${PORT_WINE_PATH}/${portname}.log"
    echo "--------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ "${PW_VULKAN_USE}" = "0" ]; then echo "PW_VULKAN_USE=${PW_VULKAN_USE} - DX9-11 to OpenGL" >> "${PORT_WINE_PATH}/${portname}.log"
    elif [ "${PW_VULKAN_USE}" = "dxvk" ]; then  echo "PW_VULKAN_USE=${PW_VULKAN_USE}" >> "${PORT_WINE_PATH}/${portname}.log"
    else echo "PW_VULKAN_USE=${PW_VULKAN_USE}" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "--------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Version WINE in the Port:" >> "${PORT_WINE_PATH}/${portname}.log"
    print_var PW_WINE_USE >> "${PORT_WINE_PATH}/${portname}.log"
    [ -f "${WINEDIR}/version" ] && cat "${WINEDIR}/version" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Date and time of start debug for ${portname}:" >> "${PORT_WINE_PATH}/${portname}.log"
    date >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "The installation path of the ${portname}:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "$PORT_WINE_PATH" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "----------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Operating system" >> "${PORT_WINE_PATH}/${portname}.log"
    lsb_release -d | sed s/Description/ОС/g >> "${PORT_WINE_PATH}/${portname}.log"
    echo "--------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Desktop Environment" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "$DESKTOP_SESSION" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "${XDG_CURRENT_DESKTOP}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "--------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Kernel" >> "${PORT_WINE_PATH}/${portname}.log"
    uname -r >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "CPU" >> "${PORT_WINE_PATH}/${portname}.log"
    cat /proc/cpuinfo | grep "model name" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "RAM" >> "${PORT_WINE_PATH}/${portname}.log"
    free -m >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Graphic cards and drivers" >> "${PORT_WINE_PATH}/${portname}.log"
    "${PW_WINELIB}/runtime/bin/glxinfo" -B >> "${PORT_WINE_PATH}/${portname}.log"
    echo "----------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Vulkan info device name:" >> "${PORT_WINE_PATH}/${portname}.log"
    "${PW_WINELIB}/runtime/bin/vulkaninfo" | grep deviceName >> "${PORT_WINE_PATH}/${portname}.log"
    "${PW_WINELIB}/runtime/bin/vkcube" --c 50
    if [ $? -eq 0 ]; then
        echo "Vulkan cube test passed successfully" >> "${PORT_WINE_PATH}/${portname}.log"
    else
        echo "Vkcube test completed with error" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    if [ ! -x "`which gamemoderun 2>/dev/null`" ]
    then
        echo "---------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "!!!gamemod not found!!!"  >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "-------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "winetricks.log:" >> "${PORT_WINE_PATH}/${portname}.log"
    cat "${WINEPREFIX}/winetricks.log" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ ! -z "${PORTWINE_DB_FILE}" ]; then
        echo "Use ${PORTWINE_DB_FILE} db file:" >> "${PORT_WINE_PATH}/${portname}.log"
        cat "${PORTWINE_DB_FILE}" | sed '/##/d' >> "${PORT_WINE_PATH}/${portname}.log"
    else
        echo "Use ${PORT_SCRIPTS_PATH}/portwine_db/default db file:" >> "${PORT_WINE_PATH}/${portname}.log"
        cat "${PORT_SCRIPTS_PATH}/portwine_db/default" | sed '/##/d' >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "-----------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Log WINE:" >> "${PORT_WINE_PATH}/${portname}.log"

    export DXVK_HUD="full"

    portwine_launch &
    sleep 1 && zenity --info --title "DEBUG" --text "${port_debug}" --no-wrap &> /dev/null && kill_portwine
    deb_text=$(cat "${PORT_WINE_PATH}/${portname}.log"  | awk '! a[$0]++') 
    echo "$deb_text" > "${PORT_WINE_PATH}/${portname}.log"
    "$pw_yad" --title="${portname}.log" --borders=10 --no-buttons --text-align=center \
    --text-info --show-uri --wrap --center --width=1200 --height=550  --uri-color=red \
    --filename="${PORT_WINE_PATH}/${portname}.log"
}

pw_winecfg () {
    start_portwine
    pw_run winecfg
}

pw_winefile () {
    start_portwine
    pw_run explorer
}

pw_winecmd () {
    export PW_USE_TERMINAL=1
    start_portwine
    cd "${WINEPREFIX}/drive_c"
    ${pw_runtime} xterm -e env LD_LIBRARY_PATH="${PW_AND_RUNTIME_LIBRARY_PATH}${LD_LIBRARY_PATH}" "${WINELOADER}" cmd
}

pw_winereg () {
    start_portwine
    pw_run regedit
}

pw_winetricks () {
    update_winetricks
    export PW_USE_TERMINAL=1
    export PW_WINE_VER="PROTON_STEAM"
    init_wine_ver
    cabextract_fix
    start_portwine
    ${PW_TERM} "${PORT_WINE_TMP_PATH}/winetricks" -q -f
}

pw_edit_db () {
    pw_gui_for_edit_db ENABLE_VKBASALT PW_NO_ESYNC PW_NO_FSYNC PW_DXR_ON PW_VULKAN_NO_ASYNC PW_USE_NVAPI \
    PW_OLD_GL_STRING PW_HIDE_NVIDIA_GPU PW_FORCE_USE_VSYNC PW_VIRTUAL_DESKTOP PW_WINEDBG_DISABLE PW_USE_TERMINAL \
    PW_WINE_ALLOW_XIM PW_HEAP_DELAY_FREE PW_NO_WRITE_WATCH PW_GUI_DISABLED_CS
    [ "$?" == 0 ] && /bin/bash -c ${pw_full_command_line[*]} & 
    exit 0
}

pw_autoinstall_from_db () {
    . "$PORT_SCRIPTS_PATH/autoinstall"
    $PW_YAD_SET
}

###MAIN###
if [ ! -z "${PORTWINE_DB_FILE}" ] ; then 
    export YAD_EDIT_DB="--button=EDIT  DB!!${loc_edit_db} ${PORTWINE_DB}:118"
    [ -z "${PW_COMMENT_DB}" ] && PW_COMMENT_DB="PortWINE database file for "\"${PORTWINE_DB}"\" was found."
    if [ -z "${PW_VULKAN_USE}" ] || [ -z "${PW_WINE_USE}" ] ; then
        unset PW_GUI_DISABLED_CS
        [ -z "${PW_VULKAN_USE}" ] && export PW_VULKAN_USE=dxvk 
        [ -z "${PW_WINE_USE}" ] && export PW_WINE_USE=proton_steam
    fi
    case "${PW_VULKAN_USE}" in      
        "vkd3d")
            export PW_DEFAULT_VULKAN_USE='VKD3D  (DX 12 to Vulkan)\!DXVK  (DX 9-11 to Vulkan)\!OPENGL ' ;;
        "0")
            export PW_DEFAULT_VULKAN_USE='OPENGL \!DXVK  (DX 9-11 to Vulkan)\!VKD3D  (DX 12 to Vulkan)' ;;
        *)
            export PW_DEFAULT_VULKAN_USE='DXVK  (DX 9-11 to Vulkan)\!VKD3D  (DX 12 to Vulkan)\!OPENGL ' ;;
    esac
    case "${PW_WINE_USE}" in
        "proton_ge")
            export PW_DEFAULT_WINE_USE='PROTON_GE   (FSR included)\!PROTON_STEAM' ;;
        *)
            export PW_DEFAULT_WINE_USE='PROTON_STEAM\!PROTON_GE   (FSR included)' ;;
    esac
else
    export PW_DEFAULT_VULKAN_USE='DXVK  (DX 9-11 to Vulkan)\!VKD3D  (DX 12 to Vulkan)\!OPENGL '
    export PW_DEFAULT_WINE_USE='PROTON_STEAM\!PROTON_GE   (FSR included)'
    unset PW_GUI_DISABLED_CS
fi
if [ ! -z "${portwine_exe}" ]; then
    if [ -z "${PW_GUI_DISABLED_CS}" ] || [ "${PW_GUI_DISABLED_CS}" = 0 ] ; then
        OUTPUT_START=$("${pw_yad}" --text-align=center --text "$PW_COMMENT_DB" --wrap-width=150 --borders=15 --form --center  \
        --title "$portname"  --image "$PW_GUI_ICON_PATH/port_proton.png" --separator=";" \
        --window-icon="$PW_GUI_ICON_PATH/port_proton.png" \
        --field="Run with :CB" "${PW_DEFAULT_VULKAN_USE}" \
        --field="Run with :CB" "${PW_DEFAULT_WINE_USE}" \
        --field=":LBL" "" \
        "${YAD_EDIT_DB}" \
        --button='CREATE SHORTCUT'!!"${loc_creat_shortcut}":100 \
        --button='DEBUG'!!"${loc_debug}":102 \
        --button='LAUNCH'!!"${loc_launch}":106 )
        export PW_YAD_SET="$?" 
        if [ "$PW_YAD_SET" == "1" ] || [ "$PW_YAD_SET" == "252" ] ; then exit 0 ; fi
        export VULKAN_MOD=`echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $1}' | awk '{print $1}'`
        export PW_WINE_VER=`echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $2}' | awk '{print $1}'`
    elif [ ! -z "${PORTWINE_DB_FILE}" ]; then
        portwine_launch
    fi
else
    button_click () {
        [ ! -z "$1" ] && echo "$1" > "${PORT_WINE_TMP_PATH}/tmp_yad_form"
        if [ ! -z `pidof -s yad` ] ; then
            kill -s SIGUSR1 `pgrep -a yad | grep "\-\-key=${KEY} \-\-notebook" | awk '{print $1}'`
        fi
    }
    export -f button_click

    open_changelog () {
        "${pw_yad}" --title="Changelog" --borders=10 --no-buttons --text-align=center \
        --text-info --show-uri --wrap --center --width=1200 --height=550 --uri-color=red \
        --filename="${PORT_WINE_PATH}/data/changelog"
    }
    export -f open_changelog

    gui_clear_pfx () {
        if gui_question "${port_clear_pfx}" ; then
            pw_clear_pfx
        fi
    }
    export -f gui_clear_pfx

    gui_rm_portproton () {
        if gui_question "${port_del2}" ; then
            rm -fr "${PORT_WINE_PATH}"
            rm -fr "${HOME}/.PortWINE"
            rm -f `grep -il PortProton "${HOME}/.local/share/applications"/*`
            update-desktop-database -q "${HOME}/.local/share/applications"
        fi
    }
    export -f gui_rm_portproton

    gui_wine_uninstaller () {
        start_portwine
        pw_run uninstaller
    }
    export -f gui_wine_uninstaller

    gui_open_var () {
        xdg-open "${PORT_SCRIPTS_PATH}/var"
    }
    export -f gui_open_var

    export KEY=$RANDOM
    "${pw_yad}" --plug=$KEY --tabnum=3 --form --columns=2 \
    --field="CLEAR PREFIX":"BTN" '@bash -c "button_click gui_clear_pfx"'  \
    --field="EDIT SCRIPT VAR":"BTN" '@bash -c "button_click gui_open_var"' \
    --field="WINE UNINSTALLER":"BTN" '@bash -c "button_click gui_wine_uninstaller"' \
    --field="REMOVE PORTPROTON":"BTN" '@bash -c "button_click gui_rm_portproton"' & \

    "${pw_yad}" --plug=$KEY --tabnum=2 --form --columns=2  --scroll \
    --field="   Wargaming Game Center"!"$PW_GUI_ICON_PATH/wgc.png":"BTN" '@bash -c "button_click PW_WGC"' \
    --field="   Battle.net Launcher"!"$PW_GUI_ICON_PATH/battle_net.png":"BTN" '@bash -c "button_click PW_BATTLE_NET"' \
    --field="   Epic Games Launcher"!"$PW_GUI_ICON_PATH/epicgames.png":"BTN" '@bash -c "button_click PW_EPIC"' \
    --field="   GoG Galaxy Launcher"!"$PW_GUI_ICON_PATH/gog.png":"BTN" '@bash -c "button_click PW_GOG"' \
    --field="   Ubisoft Game Launcher"!"$PW_GUI_ICON_PATH/ubc.png":"BTN" '@bash -c "button_click PW_UBC"' \
    --field="   Steam Client Launcher"!"$PW_GUI_ICON_PATH/steam.png":"BTN" '@bash -c "button_click PW_STEAM"' \
    --field="   EVE Online Launcher"!"$PW_GUI_ICON_PATH/eve.png":"BTN" '@bash -c "button_click PW_EVE"' \
    --field="   Origin Launcher"!"$PW_GUI_ICON_PATH/origin.png":"BTN" '@bash -c "button_click PW_ORIGIN"' \
    --field="   OSU"!"$PW_GUI_ICON_PATH/osu.png":"BTN" '@bash -c "button_click PW_OSU"' & \

    "${pw_yad}" --plug=${KEY} --tabnum=1 --columns=3 --form --separator=";" \
    --image "$PW_GUI_ICON_PATH/port_proton.png" \
    --field=":CB" "  DXVK  (DX 9-11 to Vulkan)"\!"VKD3D  (DX 12 to Vulkan)"\!"OPENGL " \
    --field=":LBL" "" \
    --field='DEBUG'!!"${loc_debug}":"BTN" '@bash -c "button_click DEBUG"' \
    --field='WINECFG'!!"${loc_winecfg}":"BTN" '@bash -c "button_click WINECFG"' \
    --field=":CB" "  PROTON_STEAM"\!"  PROTON_GE   (FSR included)" \
    --field=":LBL" "" \
    --field='WINEFILE'!!"${loc_winefile}":"BTN" '@bash -c "button_click WINEFILE"' \
    --field='WINECMD'!!"${loc_winecmd}":"BTN" '@bash -c "button_click WINECMD"' \
    --field="${portname}-${install_ver} (${scripts_install_ver})"!!"":"FBTN" '@bash -c "open_changelog"' \
    --field=":LBL" "" \
    --field='WINEREG'!!"${loc_winereg}":"BTN" '@bash -c "button_click WINEREG"' \
    --field='WINETRICKS'!!"${loc_winetricks}":"BTN" '@bash -c "button_click WINETRICKS"' &> "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" & \

    "${pw_yad}" --key=$KEY --notebook --borders=10 --width=1000 --height=168 --no-buttons --text-align=center \
    --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "$portname" --separator=";" \
    --tab-pos=right --tab="PORT_PROTON" --tab="AUTOINSTALL" --tab="    SETTINGS" --center
    YAD_STATUS="$?"
    if [ "$YAD_STATUS" == "1" ] || [ "$YAD_STATUS" == "252" ] ; then exit 0 ; fi

    if [ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form" ] ; then
        export PW_YAD_SET=`cat "${PORT_WINE_TMP_PATH}/tmp_yad_form" | head -n 1 | awk '{print $1}'`
        try_remove_file "${PORT_WINE_TMP_PATH}/tmp_yad_form"
    fi
    if [ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" ] ; then
        cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan"
        export VULKAN_MOD=`cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\; | awk '{print $1}' | awk -F";" '{print $1}'`
        export PW_WINE_VER=`cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\; | awk -F";" '{print $5}' | awk '{print $1}'`
        try_remove_file "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan"
    fi
fi
if [ ! -z "${VULKAN_MOD}" ] ; then
    if [ "${VULKAN_MOD}" = "DXVK" ] ; then export PW_VULKAN_USE="dxvk"
    elif [ "${VULKAN_MOD}" = "VKD3D" ]; then export PW_VULKAN_USE="vkd3d"
    elif [ "${VULKAN_MOD}" = "OPENGL" ]; then export PW_VULKAN_USE="0"
    fi
fi

init_wine_ver 

if [ -z "${PW_DISABLED_CREAT_DB}" ] ; then 
    if [ ! -z "${PORTWINE_DB}" ] ; then
        PORTWINE_DB_FILE=`grep -il "\#${PORTWINE_DB}.exe" "${PORT_SCRIPTS_PATH}/portwine_db"/*`
        if [ -z "${PORTWINE_DB_FILE}" ] ; then
            echo "#!/bin/bash"  > "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            echo "#Author: "${USER}"" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            echo "#"${PORTWINE_DB}.exe"" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            echo "#Rating=1-5" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            cat "${PORT_SCRIPTS_PATH}/portwine_db/default" | grep "##" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            export PORTWINE_DB_FILE="${PORT_SCRIPTS_PATH}/portwine_db/${PORTWINE_DB}"
        fi

        edit_db_from_gui PW_VULKAN_USE PW_WINE_USE

        PW_DB_TMP=`cat "${PORTWINE_DB_FILE}"` 
        echo "${PW_DB_TMP}" | awk '! a[$0]++' > "${PORTWINE_DB_FILE}"
        unset PW_DB_TMP
    fi
fi
case "$PW_YAD_SET" in
    1|252) exit 0 ;;
    100) portwine_create_shortcut ;;
    DEBUG|102) portwine_start_debug ;;
    106) portwine_launch ;;
    WINECFG|108) pw_winecfg ;;
    WINEFILE|110) pw_winefile ;;
    WINECMD|112) pw_winecmd ;;
    WINEREG|114) pw_winereg ;;
    WINETRICKS|116) pw_winetricks ;;
    118) pw_edit_db ;;
    *) pw_autoinstall_from_db ;;
esac

stop_portwine
