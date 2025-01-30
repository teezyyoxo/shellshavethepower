#!/bin/zsh
# PowerProbe - A macOS Power Diagnostics Script
# Version: 1.0.0
# Created by @PBandJamf

VERSION="1.0.0"

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
    pmset -g log | grep -E "(Sleep|Wake)" | tail -15 || echo "No sleep/wake events found."
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
