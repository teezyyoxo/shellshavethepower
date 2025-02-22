# PowerShell script to diagnose unexpected power events
# Created by @PBandJamf
# Version: 1.1.1
# Changelog:
# - Fixed unused variable warning for $powerInfo
# - Renamed function 'Generate-Report' to use an approved verb
# - Renamed variable 'event' to avoid conflict with PowerShell automatic variables

Write-Output "Power Event Diagnosis Script - Version 1.1.1"
Write-Output "Created by @PBandJamf"

# Gather power-related information
$powerInfo = powercfg /energy /output energy-report.html /duration 10
Write-Output "Power diagnostics report generated: energy-report.html"
Write-Output $powerInfo

$lastWakeInfo = powercfg /lastwake
$sleepStudy = powercfg /sleepstudy

# Gather relevant event logs (System & Application)
$eventSystem = Get-WinEvent -LogName System -MaxEvents 100 | Where-Object {
    $_.Id -in @(41, 6008, 1074, 1076) # Kernel-Power, Unexpected Shutdown, User Initiated, Service Crash
}

$eventApp = Get-WinEvent -LogName Application -MaxEvents 100 | Where-Object {
    $_.Message -match 'faulting module|crash|unexpected'
}

# Find recent unexpected shutdowns in the past week
$recentEvents = $eventSystem | Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-7) } | Sort-Object TimeCreated -Descending

function Get-PowerEventReport($evt) {
    return @"
===== Power Event Diagnosis Report =====

**Timestamp:** $($evt.TimeCreated)
**Event ID:** $($evt.Id)
**Message:** $($evt.Message)

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
}

# Interactive Selection Loop
while ($true) {
    Write-Output "\nRecent unexpected shutdown/reboot events in the past week:" 
    $index = 1
    foreach ($evt in $recentEvents) {
        Write-Output "$index. $($evt.TimeCreated)"
        $index++
    }

    $selection = Read-Host "Enter the number of the event to diagnose (or press CTRL+C to exit)"
    if ($selection -match '^[0-9]+$' -and [int]$selection -le $recentEvents.Count) {
        $selectedEvent = $recentEvents[[int]$selection - 1]
        Write-Output (Get-PowerEventReport $selectedEvent)
    } else {
        Write-Output "Invalid selection. Please enter a valid number."
    }
    
    $continue = Read-Host "Would you like to diagnose another event? (yes/no, press CTRL+C to exit)"
    if ($continue -ne "yes") { break }
}