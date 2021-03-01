set_global_assignment -entity "LPLL32" -library "lib_LPLL32" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "LPLL32" -library "lib_LPLL32" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "LPLL32" -library "lib_LPLL32" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_LPLL32" -name SPD_FILE [file join $::quartus(sip_path) "LPLL32.spd"]

set_global_assignment -library "lib_LPLL32" -name MISC_FILE [file join $::quartus(sip_path) "LPLL32_sim/LPLL32.vho"]
