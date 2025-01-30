#!/bin/zsh
# PowerProbe - A macOS Power Diagnostics Script
# Version: 1.4.1
# Created by @PBandJamf

# Changelog:
# v1.4.1 - Excluded assertion-related lines from Sleep/Wake History output (PreventUserIdleSystemSleep, PreventUserIdleDisplaySleep)
# v1.4.0 - Fixed formatting issues in Sleep/Wake History; filtered out unwanted lines from log output
# v1.3.0 - Formatted Sleep/Wake History into a table with separate analytics
# v1.2.0 - Added timestamps to Sleep/Wake History
# v1.1.0 - Improved Sleep/Wake History readability
# v1.0.0 - Initial release

VERSION="1.4.1"

print_header() {
    echo "\n🔋 PowerProbe v$VERSION - macOS Power Diagnostics"
    echo "Created by @PBandJamf\n"
}

check_pm_logs() {
    echo "📜 Recent Power Management Logs:"
    log show --predicate "subsystem == 'com.apple.iokit.IOPMrootDomain'" --last 30m | grep -iE "sleep|wake|shutdown|hibernat" || echo "No relevant power events in last 30 minutes."
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
    
    echo "📊 Sleep/Wake Analytics:"
    echo "---------------------------------------------------------"
    pmset -g log | grep -E "(Total Sleep/Wakes|PreventUserIdleDisplaySleep|PreventSystemSleep|PreventUserIdleSystemSleep|pid)" | awk '{
        print $0;
    }'
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
    check_battery_status
    check_power_adapter
    check_thermal_events
    echo "✅ Diagnostics complete."
}

main