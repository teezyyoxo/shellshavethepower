# PowerShell script to diagnose unexpected power events
# Created by @PBandJamf
# Version: 1.0.1
# Changelog:
# - Added versioning and changelog
# - Included script creator information

Write-Output "Power Event Diagnosis Script - Version 1.0.1"
Write-Output "Created by @PBandJamf"

# Gather power-related information
$powerInfo = powercfg /energy /output energy-report.html /duration 10
$lastWakeInfo = powercfg /lastwake
$sleepStudy = powercfg /sleepstudy

# Gather relevant event logs (System & Application)
$eventSystem = Get-WinEvent -LogName System -MaxEvents 100 | Where-Object {
    $_.Id -in @(41, 6008, 1074, 1076) # Kernel-Power, Unexpected Shutdown, User Initiated, Service Crash
}

$eventApp = Get-WinEvent -LogName Application -MaxEvents 100 | Where-Object {
    $_.Message -match 'faulting module|crash|unexpected'
}

# Find the most recent unexpected shutdown or reboot
$lastEvent = $eventSystem | Sort-Object TimeCreated -Descending | Select-Object -First 1

# Correlate findings
$report = @"
===== Power Event Diagnosis Report =====

**Most Recent Unexpected Shutdown/Reboot:**
Timestamp: $($lastEvent.TimeCreated)
Event ID: $($lastEvent.Id)
Message: $($lastEvent.Message)

**Power Configuration Analysis:**
Last Wake Reason:
$lastWakeInfo

Sleep Study Report:
$sleepStudy

**Recent System & Application Errors:**
System Events:
$($eventSystem | Format-Table TimeCreated, Id, Message -AutoSize | Out-String)

Application Events:
$($eventApp | Format-Table TimeCreated, Id, Message -AutoSize | Out-String)

**Suggestions:**
- If Kernel-Power (Event 41): Possible power failure or hardware issue.
- If Event 6008: Indicates an unexpected shutdown; check for overheating or power loss.
- If a crash points to a specific DLL or service, investigate further.
- Check `energy-report.html` for power diagnostics.

"@

# Output report
Write-Output $report

# Optionally, save to a file
$report | Out-File -FilePath "PowerEventReport.txt"