#!/bin/zsh
# PowerProbe - A macOS Power Diagnostics Script
# Version: 1.5.0
# Created by @PBandJamf

# Changelog:
# v1.5.0 - Fixed "too many arguments" error in check_pm_logs by restructuring log processing and using more robust parsing
# v1.4.11 - Fixed "too many arguments" error by adjusting how shutdown cause logs are processed
# v1.4.10 - Fixed "too many arguments" error in check_pm_logs by adjusting how log output is filtered
# v1.4.9 - Fixed check_pm_logs to only show shutdown causes and error codes, formatted output with descriptions
# v1.4.8 - Fixed "Sleep/Wakes since" placement and removed "too many arguments" error
# v1.4.7 - Fixed issue with check_pm_logs producing error "too many arguments"
# v1.4.6 - Fixed date conversion issue and placed "Sleep/Wakes since" in the correct section
# v1.4.5 - Fixed repeated assertion output; only print assertion states once
# v1.4.4 - Fixed placement of "Sleep/Wakes since" in Sleep/Wake Analytics; improved filtering to exclude verbose logs in analytics
# v1.4.3 - Fixed formatting issues in Sleep/Wake History; filtered out unwanted lines from log output
# v1.4.2 - Fixed placement of "Sleep/Wakes since" in correct section; improved filtering to exclude verbose logs in analytics
# v1.4.1 - Excluded assertion-related lines from Sleep/Wake History output (PreventUserIdleSystemSleep, PreventUserIdleDisplaySleep)
# v1.4.0 - Fixed formatting issues in Sleep/Wake History; filtered out unwanted lines from log output
# v1.3.0 - Formatted Sleep/Wake History into a table with separate analytics
# v1.2.0 - Added timestamps to Sleep/Wake History
# v1.1.0 - Improved Sleep/Wake History readability
# v1.0.0 - Initial release

VERSION="1.5.0"

print_header() {
    echo "\n🔋 PowerProbe v$VERSION - macOS Power Diagnostics"
    echo "Created by @PBandJamf\n"
}

check_pm_logs() {
    echo "📜 Recent Power Management Logs (Shutdown Causes):"
    echo "---------------------------------------------------------"
    
    # Run the log command, limiting output to relevant logs containing "Previous shutdown cause"
    logs=$(log show --predicate 'eventMessage contains "Previous shutdown cause"' --last 24h)

    if [ -z "$logs" ]; then
        echo "No shutdown causes found in the last 24 hours."
    else
        echo "$logs" | grep -oP '(?<=Previous shutdown cause: )\d+' | while read -r shutdown_code; do
            # Map shutdown code to description
            case $shutdown_code in
                7) description="CPU thread error. If this occurs during boot, try Safe Mode by holding ⇧shift at boot to limit what opens during startup." ;;
                6) description="Unknown. Please share any information you may have." ;;
                5) description="Correct Shut Down. Shutdown was initiated normally." ;;
                3) description="Hard shutdown. Check if the power button was stuck down." ;;
                2) description="Power supply disconnected. Check power supply/battery." ;;
                1) description="Restart. Restart was initiated normally." ;;
                0) description="Battery disconnected. May indicate a hardware issue with the battery or controller." ;;
                -3) description="Multiple temperature sensors exceeded limits. Run diagnostics with Apple Diagnostics." ;;
                -14) description="Electricity spike/surge. Check power supply." ;;
                -20) description="BridgeOS T2-initiated shutdown. Shutdown caused by T2 chip." ;;
                -60) description="Battery fully drained. May indicate a hardware issue." ;;
                -61) description="Watchdog timer detected unresponsive application, shutting down." ;;
                -62) description="Watchdog timer detected unresponsive application, restarting system." ;;
                -63) description="Unknown. Please share any information you may have." ;;
                -64) description="Unknown. Please share any information you may have." ;;
                -65) description="Potential OS issue. Try reinstalling macOS." ;;
                -71) description="SO-DIMM memory temperature exceeds limits. Check memory modules." ;;
                -74) description="Battery temperature exceeds limits. Reset SMC." ;;
                -75) description="Communication issue with AC adapter." ;;
                -78) description="Incorrect current value from AC adapter." ;;
                -79) description="Incorrect current value from battery." ;;
                -81) description="Thermal shutdown for overtemp. Check thermal components." ;;
                -86) description="Proximity temperature exceeds limits." ;;
                -95) description="CPU temperature exceeds limits." ;;
                -100) description="Power supply temperature exceeds limits." ;;
                -102) description="Overvoltage. Safety shutdown." ;;
                -103) description="Battery cell under voltage detected." ;;
                -104) description="Unknown. Please share any information you may have." ;;
                -108) description="Unverified memory issue." ;;
                -112) description="Unverified memory issue." ;;
                -127) description="PMU forced shutdown. Check power button." ;;
                -128) description="Possible memory issue." ;;
                *) description="Unknown error code." ;;
            esac

            # Print the shutdown cause with its description
            echo "$shutdown_code: $description"
        done
    fi
    echo "---------------------------------------------------------"
    echo ""
}

check_power_history() {
    echo "📊 Sleep/Wake History:"
    echo "---------------------------------------------------------"
    printf "%-25s %-10s %-40s\n" "Timestamp" "Event" "Details"
    echo "---------------------------------------------------------"
    pmset -g log | grep -E "(Sleep|Wake)" | grep -v -E "(Total|Prevent|pid|Assertions)" | awk '{
        timestamp = $1 " "$2;
        event = "Unknown";
        details = "";
        if ($0 ~ /Created MaintenanceWake/) {
            event = "Wake";
            details = "Maintenance Wake";
        } else if ($0 ~ /Released MaintenanceWake/) {
            event = "Sleep";
            details = "Maintenance Wake Released";
        } else if ($0 ~ /Sleep/) {
            event = "Sleep";
            details = "System Entered Sleep Mode";
        } else if ($0 ~ /Wake/) {
            event = "Wake";
            details = "System Woke Up";
        }
        printf "%-25s %-10s %-40s\n", timestamp, event, details;
    }' | tail -10
    echo "---------------------------------------------------------\n"
}

check_power_analytics() {
    echo "📊 Sleep/Wake Analytics:"
    echo "---------------------------------------------------------"
    
    # Get Last Boot Time using `last` command
    last_boot=$(last reboot | head -n 1 | awk '{print $5, $6, $7, $8, $9}')
    
    # Get total number of sleep/wake events
    total_sleep_wakes=$(pmset -g log | grep -E "Sleep|Wake" | wc -l)

    # Print user-friendly information
    echo "Last boot: $last_boot"
    echo "Total number of sleep/wake events since boot: $total_sleep_wakes"
    
    # Sleep Assertions (Renaming for friendly readability)
    echo "\nSleep Assertions:"
    echo "---------------------------------------------------------"
    
    # Check for assertion states
    display_sleep_active=$(pmset -g log | grep -c "PreventUserIdleDisplaySleep")
    system_sleep_active=$(pmset -g log | grep -c "PreventSystemSleep")
    user_inactivity_sleep_active=$(pmset -g log | grep -c "PreventUserIdleSystemSleep")

    if [ "$display_sleep_active" -gt 0 ]; then
        echo "Prevent Sleep when Display is Active: 1"
    else
        echo "Prevent Sleep when Display is Active: 0"
    fi
    
    if [ "$system_sleep_active" -gt 0 ]; then
        echo "Prevent System Sleep: 1"
    else
        echo "Prevent System Sleep: 0"
    fi

    if [ "$user_inactivity_sleep_active" -gt 0 ]; then
        echo "Prevent Sleep due to User Inactivity: 1"
    else
        echo "Prevent Sleep due to User Inactivity: 0"
    fi

    echo "---------------------------------------------------------"
    echo ""
}

check_battery_status() {
    echo "🔋 Battery Information:"
    pmset -g batt || echo "No battery information available."
    echo ""
}

check_power_adapter() {
    echo "🔌 Power Adapter Details:"
    ioreg -p IODeviceTree -r -n AppleSmartBattery | grep -i "ExternalConnected" || echo "No power adapter detected."
    echo ""
}

check_thermal_events() {
    echo "🔥 Recent Thermal Events:"
    log show --predicate "subsystem == 'com.apple.thermalmonitord'" --last 30m | grep -i "throttle" || echo "No thermal throttling detected."
    echo ""
}

main() {
    print_header
    check_pm_logs
    check_power_history
    check_power_analytics
    check_battery_status
    check_power_adapter
    check_thermal_events
    echo "✅ Diagnostics complete."
}

main