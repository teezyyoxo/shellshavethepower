# X-Plane 12 scenery_packs.ini updater
# Run this script to scan your Custom Scenery folder for any changes against the scenery_packs.ini file and automatically update it when changes are found.
# Pretty simple concept, right? 

# Created by PBandJamf (@teezyyoxo)
# 24 Dec 2024 
# Early Merry Christmas to all and Happy New Year!

# YMMV -- BE SURE TO SET YOUR $CustomSceneryPath BEFORE RUNNING THE SCRIPT (or expecting it to work, for that matter...)

# Version 1.0
# - Initial release.

# Define the path to X-Plane's Custom Scenery folder and scenery_packs.ini file
$CustomSceneryPath = "C:\Path\To\X-Plane 12\Custom Scenery"
$SceneryPacksFile = "$CustomSceneryPath\scenery_packs.ini"
$BackupFile = "$SceneryPacksFile.bak"

# Ensure the paths exist
if (!(Test-Path $CustomSceneryPath)) {
    Write-Host "Error: Custom Scenery folder not found at $CustomSceneryPath" -ForegroundColor Red
    exit
}

# Get a list of all directories in the Custom Scenery folder
$SceneryFolders = Get-ChildItem -Path $CustomSceneryPath -Directory | Select-Object -ExpandProperty Name

# Check if scenery_packs.ini exists, create it if missing
if (!(Test-Path $SceneryPacksFile)) {
    Write-Host "scenery_packs.ini not found. Creating a new one..." -ForegroundColor Yellow
    New-Item -ItemType File -Path $SceneryPacksFile | Out-Null
} else {
    # Backup the existing ini file
    Write-Host "Creating a backup of the existing scenery_packs.ini..." -ForegroundColor Cyan
    Copy-Item -Path $SceneryPacksFile -Destination $BackupFile -Force
    Write-Host "Backup created at $BackupFile" -ForegroundColor Green
}

# Read the existing contents of scenery_packs.ini
$SceneryPacksContent = Get-Content -Path $SceneryPacksFile -ErrorAction SilentlyContinue

# Extract the existing folder references from the ini file
$ExistingReferences = @()
foreach ($Line in $SceneryPacksContent) {
    if ($Line -match "^SCENERY_PACK\s+(.*)$") {
        $ExistingReferences += $Matches[1] -replace "^.+\\", "" # Extract folder name
    }
}

# Find missing folders
$MissingFolders = $SceneryFolders | Where-Object { $_ -notin $ExistingReferences }

if ($MissingFolders.Count -eq 0) {
    Write-Host "All scenery folders are already referenced in scenery_packs.ini." -ForegroundColor Green
    Write-Host "No changes detected. Exiting script." -ForegroundColor Yellow
    exit
}

# Interactive: Ask if the user wants to add missing folders
Write-Host "The following folders are not referenced in scenery_packs.ini:" -ForegroundColor Cyan
$MissingFolders | ForEach-Object { Write-Host "- $_" }

$AddMissing = Read-Host "Do you want to add these folders to the ini file? (yes/no)"
if ($AddMissing -ne "yes") {
    Write-Host "No changes made to scenery_packs.ini." -ForegroundColor Yellow
    exit
}

# Append missing folders to the ini file
$AppendEntries = $MissingFolders | ForEach-Object { "SCENERY_PACK Custom Scenery\$_" }
Add-Content -Path $SceneryPacksFile -Value $AppendEntries

Write-Host "Missing folders have been added to scenery_packs.ini." -ForegroundColor Green

# Optional: Offer to open the ini file for review
$ReviewFile = Read-Host "Do you want to open scenery_packs.ini for review? (yes/no)"
if ($ReviewFile -eq "yes") {
    Invoke-Item -Path $SceneryPacksFile
}
