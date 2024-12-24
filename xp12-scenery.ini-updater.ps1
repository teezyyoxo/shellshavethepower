# X-Plane 12 scenery_packs.ini updater
# Run this script to scan your Custom Scenery folder for any changes against the scenery_packs.ini file and automatically update it when changes are found.
# Pretty simple concept, right? 

# Created by PBandJamf (@teezyyoxo)
# 24 Dec 2024 
# Early Merry Christmas to all and Happy New Year!
# YMMV -- BE SURE TO SET YOUR $CustomSceneryPath BEFORE RUNNING THE SCRIPT (or expecting it to work, for that matter...)

# Version 2.8 (sleepbeuponme)
# - Fixed path redundancy issue (no more double "Custom Scenery").
# - Standardized paths: full paths use backslashes (Z:\), inside Custom Scenery uses forward slashes (/).
# - Better handling of missing folders – no more false positives.
# - Backup of scenery_packs.ini made BEFORE any changes.
# - Improved path formatting consistency and clearer logs.
# - Added safety checks to avoid unnecessary changes.
# - Broke the script to the point where now it will no longer run because it is bitching about paths and I hate slashes now. I'm going to bed.
# Version 2.7 (paperboy)
# - Added handling for non-existent folder references in scenery_packs.ini.
# - If a folder reference is missing, prompt the user to delete or keep the entry.
# - Ensured all conflicts are handled interactively with options to resolve them.
# - Preserved the order of entries and avoided duplicates in the updated scenery_packs.ini.
# - Backup of scenery_packs.ini created before any changes.
# - Fixed minor path formatting issues for consistency.
# Version 2.6 (up-and-up)
# - Inserted new folders directly above the first SCENERY_PACK line.
# - Preserved line breaks in scenery_packs.ini for better formatting.
# - Ensured no duplicate entries and sorted the final list of folders.
# - Backup of the existing scenery_packs.ini file is created before applying any changes.
# - Fixed path formatting issues when checking folder existence.
# Version 2.5 (hooray)
# - Fixed insertion of new folders to the correct location (line 3).
# - Ensured line breaks in scenery_packs.ini file are preserved.
# - Removed any unnecessary slashes and maintained consistent path formatting.
# Version 2.4 (doggoneit)
# - Fixed path formatting: directories in Custom Scenery now get formatted properly.
# - Drive-letter paths (C:\, Z:\) are left unmodified.
# - Updated handling for directories and added missing folders.
# Version 2.3 (headbang)
# - More work on the duplication bug.
# - Modified $NormalizedLine to ensure the paths are using forward slashes.
# - $NewContent now processed using 'Sort-Object -Unique'
# Version 2.2 (ragequit)
# - Fixed handling for *GLOBAL AIRPORTS*
# - Squashed a logic error that caused a major duplication issue.
# - Added an exit condition outside of the interactivity/user decision flow.
# Version 2.1 (slurpee)
# - Added handling for *GLOBAL AIRPORTS* even though I'm not exactly sure of its significance.
# Version 2.0 (brainblast)
# - Added a check to detect if there are no changes needed; script exits if all scenery folders are already referenced.
# - Created a temporary "comparison_cache.txt" file to aid in comparison, which is deleted after processing.
# - Backup of the existing scenery_packs.ini file is created before applying any changes.
# - Improved user prompts to confirm adding missing folders and optional review of the updated ini file.
# - Ensured the script only modifies the ini file if discrepancies are detected.
# Version 1.1
# - Specified *my* Custom Scenery folder path.
# Version 1.0
# - Initial release.

# Step 1: Define the path to the Custom Scenery folder and scenery_packs.ini file
$CustomSceneryPath = "Z:\SteamLibrary\steamapps\common\X-Plane 12\Custom Scenery"
$SceneryPacksFile = "$CustomSceneryPath\scenery_packs.ini"
$BackupFile = "$SceneryPacksFile.bak"
$ComparisonCacheFile = "$CustomSceneryPath\comparison_cache.ini"

# Step 2: Verify that the paths exist
if (!(Test-Path $CustomSceneryPath)) {
    Write-Host "Error: Custom Scenery folder not found at $CustomSceneryPath" -ForegroundColor Red
    exit
}

# Step 3: Read the existing content of the scenery_packs.ini file
if (!(Test-Path $SceneryPacksFile)) {
    Write-Host "scenery_packs.ini not found. Creating a new one..." -ForegroundColor Yellow
    New-Item -ItemType File -Path $SceneryPacksFile | Out-Null
    $SceneryPacksContent = @()
} else {
    $SceneryPacksContent = Get-Content -Path $SceneryPacksFile -ErrorAction SilentlyContinue
}

# Step 4: Create a backup of the scenery_packs.ini file
Write-Host "Creating a backup of the existing scenery_packs.ini..." -ForegroundColor Cyan
Copy-Item -Path $SceneryPacksFile -Destination $BackupFile -Force
Write-Host "Backup created at $BackupFile" -ForegroundColor Green

# Step 5: Extract existing folder references (normalize path to not include trailing slash)
$ExistingReferences = @()
foreach ($Line in $SceneryPacksContent) {
    if ($Line -match "^SCENERY_PACK\s+(.*)$") {
        $folderPath = $Matches[1].Trim()
        # Ensure all relative paths within Custom Scenery use forward slashes and normalize
        $folderPath = $folderPath.TrimEnd('\')
        $folderPath = $folderPath.Replace('\', '/')
        $ExistingReferences += $folderPath
    }
}

# Step 6: Check if any of the existing references point to non-existent folders
$NonExistentFolders = @()
foreach ($Existing in $ExistingReferences) {
    # Only append Custom Scenery path if it is not already included in the reference
    if ($Existing.StartsWith("Custom Scenery")) {
        $FullPath = "$CustomSceneryPath\$Existing"  # Backslashes for full path
    } else {
        $FullPath = "$CustomSceneryPath\$Existing"  # Same handling for relative path
    }

    # Ensure the path uses backslashes for full paths
    $FullPath = $FullPath.Replace('/', '\')

    Write-Host "Checking path: $FullPath" -ForegroundColor Cyan

    if (-not (Test-Path $FullPath)) {
        Write-Host "Non-existent folder: $Existing (Full Path: $FullPath)" -ForegroundColor Red
        $NonExistentFolders += $Existing
    }
}

# Step 7: Handle non-existent folders interactively
if ($NonExistentFolders.Count -gt 0) {
    Write-Host "The following folder references do not exist in the Custom Scenery folder:" -ForegroundColor Yellow
    $NonExistentFolders | ForEach-Object { Write-Host "- $_" }

    $ResolveMissing = Read-Host "Would you like to remove these non-existent references from scenery_packs.ini? (yes/no)"
    if ($ResolveMissing -eq "yes") {
        foreach ($Missing in $NonExistentFolders) {
            # Remove non-existent references from $SceneryPacksContent
            $SceneryPacksContent = $SceneryPacksContent | Where-Object { $_ -notmatch [regex]::Escape($Missing) }
            Write-Host "Removed non-existent reference: $Missing" -ForegroundColor Green
        }
        # Rebuild $ExistingReferences after removing non-existent folders
        $ExistingReferences = @()
        foreach ($Line in $SceneryPacksContent) {
            if ($Line -match "^SCENERY_PACK\s+(.*)$") {
                $folderPath = $Matches[1].Trim()
                $folderPath = $folderPath.TrimEnd('\')
                $folderPath = $folderPath.Replace('\', '/')
                $ExistingReferences += $folderPath
            }
        }
    }
}

# Step 8: Get a list of all directories in the Custom Scenery folder
$SceneryFolders = Get-ChildItem -Path $CustomSceneryPath -Directory | Select-Object -ExpandProperty Name

# Step 9: Normalize folder names by removing trailing slashes for consistent comparison
$CurrentFolderList = $SceneryFolders | ForEach-Object { "Custom Scenery/$_" } | Sort-Object

# Step 10: Detect similar folder names with trailing slashes or case differences
$ConflictingEntries = @()

foreach ($Existing in $ExistingReferences) {
    foreach ($Current in $CurrentFolderList) {
        if ($Existing -like $Current) {
            # Check if there's a conflict (ignoring trailing slashes or case)
            $ExistingNoSlash = $Existing.TrimEnd('\')
            $CurrentNoSlash = $Current.TrimEnd('\')
            if ($ExistingNoSlash -ieq $CurrentNoSlash -and $Existing -ne $Current) {
                $ConflictingEntries += [PSCustomObject]@{
                    Existing = $Existing
                    Current = $Current
                }
            }
        }
    }
}

# Step 11: Prompt user for any conflicts
if ($ConflictingEntries.Count -gt 0) {
    Write-Host "The following conflicts were found:" -ForegroundColor Yellow
    $ConflictingEntries | ForEach-Object {
        Write-Host "Conflict: $($_.Existing) vs $($_.Current)"
    }

    $ResolveConflict = Read-Host "Would you like to resolve these conflicts? (yes/no)"
    if ($ResolveConflict -eq "yes") {
        foreach ($Conflict in $ConflictingEntries) {
            $UserChoice = Read-Host "Do you want to delete the duplicate line '$($Conflict.Existing)'? (yes/no)"
            if ($UserChoice -eq "yes") {
                # Remove the offending line from the ini file
                $SceneryPacksContent = $SceneryPacksContent | Where-Object { $_ -notmatch [regex]::Escape($Conflict.Existing) }
                Write-Host "Deleted duplicate entry: $($Conflict.Existing)" -ForegroundColor Green
            }
        }
    }
}

# Step 12: Proceed with adding missing folders
$MissingFolders = $CurrentFolderList | Where-Object { $_ -notin $ExistingReferences }
if ($MissingFolders.Count -eq 0) {
    Write-Host "All scenery folders are already referenced in scenery_packs.ini." -ForegroundColor Green
    Write-Host "No changes detected. Exiting script." -ForegroundColor Yellow
    exit
}

# Step 13: Print the differences
Write-Host "The following folders are not referenced in scenery_packs.ini:" -ForegroundColor Cyan
$MissingFolders | ForEach-Object { Write-Host "- $_" }

# Step 14: Prompt the user to commit changes
$AddMissing = Read-Host "Do you want to add these folders to the ini file? (yes/no)"
if ($AddMissing -ne "yes") {
    Write-Host "No changes made to scenery_packs.ini." -ForegroundColor Yellow
    exit
}

# Step 15: Insert missing folders at line 3
$AppendEntries = $MissingFolders | ForEach-Object { "SCENERY_PACK $_" }

# Ensure we have at least 3 lines before inserting
if ($SceneryPacksContent.Count -ge 3) {
    # Insert the missing entries at line 3, preserving the line breaks
    $SceneryPacksContent = $SceneryPacksContent[0..2] + $AppendEntries + $SceneryPacksContent[3..($SceneryPacksContent.Count - 1)]
} else {
    # If there are fewer than 3 lines, append them at the end
    $SceneryPacksContent += $AppendEntries
}

# Step 16: Write updated content back to the ini file, preserving line breaks
$SceneryPacksContent -join "`r`n" | Set-Content -Path $SceneryPacksFile -Encoding ASCII

Write-Host "Missing folders have been added to scenery_packs.ini at line 3, and the order has been preserved." -ForegroundColor Green

# Step 17: Delete the comparison cache file
if (Test-Path $ComparisonCacheFile) {
    Remove-Item -Path $ComparisonCacheFile -Force
    Write-Host "Deleted comparison cache file: $ComparisonCacheFile" -ForegroundColor Green
}

Write-Host "Scenery packs update completed." -ForegroundColor Green
exit
