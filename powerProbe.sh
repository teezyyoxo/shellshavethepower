#!/bin/zsh
# PowerProbe - A macOS Power Diagnostics Script
# Version: 1.1.0
# Created by @PBandJamf

# Changelog:
# v1.1.0 - Improved Sleep/Wake History readability
# v1.0.0 - Initial release

VERSION="1.1.0"

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
    pmset -g log | grep -E "(Sleep|Wake)" | awk '{
        if ($0 ~ /Created MaintenanceWake/) {
            print "Wake Event: Maintenance Wake";
        } else if ($0 ~ /Released MaintenanceWake/) {
            print "Sleep Event: Maintenance Wake Released";
        } else if ($0 ~ /Sleep/) {
            print "System Entered Sleep Mode";
        } else if ($0 ~ /Wake/) {
            print "System Woke Up";
        } else {
            print $0;
        }
    }' | tail -10 || echo "No sleep/wake events found."
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
