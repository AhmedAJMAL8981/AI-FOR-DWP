<#
.SYNOPSIS
    DWP Large File Finder - PowerShell 5.1, read-only, safe for beginners.

.DESCRIPTION
    Scans a chosen folder (and its subfolders) and reports the largest
    files found, so a DWP engineer can quickly identify what is taking up
    disk space on an endpoint. The script never modifies, moves, or
    deletes any file - it only reads file information and reports on it.

    Every folder/file access is wrapped in its own try/catch so a single
    inaccessible file or folder (e.g. permissions denied) is logged and
    skipped instead of stopping the whole scan.

.PARAMETER Path
    The folder to scan. Prompted for if not supplied.

.PARAMETER Top
    How many of the largest files to display. Defaults to 10.

.PARAMETER DryRun
    Included for consistency with other DWP scripts in this toolkit. This
    script is read-only by design (it never changes anything), so -DryRun
    simply confirms no changes will be made and runs the same scan/report.

.PARAMETER LogPath
    Folder where the timestamped log file for this run is written.
    Defaults to a LargeFileFinderData\Logs folder next to this script.

.EXAMPLE
    .\LargeFileFinder.ps1 -Path "C:\Users\jbloggs\Downloads"
    Lists the 10 largest files under the Downloads folder.

.EXAMPLE
    .\LargeFileFinder.ps1 -Path "D:\Data" -Top 25
    Lists the 25 largest files under D:\Data.

.EXAMPLE
    .\LargeFileFinder.ps1 -Path "C:\Users\jbloggs" -DryRun
    Explicitly read-only run (equivalent to a normal run - no changes are
    ever made by this script).

.NOTES
    Read-only script: it never deletes, moves, or modifies any file.
    Requires read access to the folder being scanned; folders/files that
    cannot be accessed are logged and skipped.
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path,

    [int]$Top = 10,

    [switch]$DryRun,

    [string]$LogPath = (Join-Path $PSScriptRoot "LargeFileFinderData\Logs")
)

# --- Prompt for a folder if one was not supplied as a parameter ---
if ([string]::IsNullOrWhiteSpace($Path)) {
    $Path = Read-Host "Enter the folder path to scan"
}

# --- Logging setup: one timestamped log file per run, used by Write-Log below ---
$runTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
if (-not (Test-Path $LogPath)) { New-Item -Path $LogPath -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $LogPath "LargeFileFinder_$runTimestamp.log"

function Write-Log {
    # Writes a single timestamped line to both the console and the run's log file
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $logFile -Value $line
    switch ($Level) {
        "WARN"  { Write-Warning $Message }
        "ERROR" { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line }
    }
}

Write-Log "============================================="
Write-Log "DWP Large File Finder$(if ($DryRun) { ' (DryRun)' })"
Write-Log "Target folder: $Path"
Write-Log "Top: $Top"
Write-Log "============================================="

# --- Validate the target folder before scanning ---
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Log "Folder not found or is not a directory: $Path" "ERROR"
    Write-Log "Log file location: $logFile"
    return
}

if ($DryRun) {
    Write-Log "DryRun specified - this script is read-only and makes no changes regardless." "INFO"
}

# --- Run counters used for the end-of-run summary ---
$totalScanned = 0
$errorCount = 0
$allFiles = @()

# --- Recursively enumerate files; folders/files that error out are logged and skipped ---
try {
    $items = Get-ChildItem -Path $Path -File -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable scanErrors
}
catch {
    Write-Log "Unexpected error starting scan of '$Path': $_" "ERROR"
    $errorCount++
    $items = @()
}

# Get-ChildItem -ErrorAction SilentlyContinue collects per-item errors (e.g. access
# denied) into $scanErrors instead of throwing, so the scan continues for the rest.
foreach ($err in $scanErrors) {
    Write-Log "Skipped inaccessible item: $($err.Exception.Message)" "WARN"
    $errorCount++
}

foreach ($file in $items) {
    try {
        $totalScanned++
        $allFiles += [PSCustomObject]@{
            Name           = $file.Name
            Location       = $file.DirectoryName
            'Size(MB)'     = [math]::Round($file.Length / 1MB, 2)
            SizeBytes      = $file.Length
            DateModified   = $file.LastWriteTime
        }
    }
    catch {
        # Guards against a file becoming inaccessible/locked between enumeration and read
        Write-Log "Skipped file that could not be read: $($file.FullName) - $_" "WARN"
        $errorCount++
    }
}

# --- Determine the largest files and display/log the report ---
$largestFiles = $allFiles | Sort-Object SizeBytes -Descending | Select-Object -First $Top

Write-Log "Largest $Top file(s) found:"
foreach ($f in $largestFiles) {
    Write-Log ("{0} | {1} | {2} MB | Modified: {3}" -f $f.Name, $f.Location, $f.'Size(MB)', $f.DateModified)
}

$largestFiles | Format-Table Name, Location, 'Size(MB)', DateModified -AutoSize

# --- End-of-run summary ---
$largestFileFound = $largestFiles | Select-Object -First 1
$totalReportedSizeMB = [math]::Round((($largestFiles | Measure-Object -Property SizeBytes -Sum).Sum / 1MB), 2)

$summary = [PSCustomObject]@{
    TotalFilesScanned    = $totalScanned
    LargestFileFound     = if ($largestFileFound) { "$($largestFileFound.Name) ($($largestFileFound.'Size(MB)') MB)" } else { "None" }
    TotalSizeReportedMB  = $totalReportedSizeMB
    ErrorsEncountered    = $errorCount
    LogFile              = $logFile
}

Write-Log ("===== Summary: TotalFilesScanned={0} LargestFileFound={1} TotalSizeReportedMB={2} Errors={3} =====" -f `
        $summary.TotalFilesScanned, $summary.LargestFileFound, $summary.TotalSizeReportedMB, $summary.ErrorsEncountered)
Write-Log "Log file location: $logFile"

$summary | Format-List
