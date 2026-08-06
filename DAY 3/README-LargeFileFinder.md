# LargeFileFinder.ps1

## Purpose
A simple, read-only PowerShell 5.1 script for a DWP engineer to identify
the largest files in a chosen folder, to help track down what is using up
disk space on a Windows endpoint. It never deletes, moves, or modifies
any file - it only reports.

## Parameters
| Parameter | Description |
|---|---|
| `-Path <folder>` | The folder to scan (including subfolders). If not supplied, the script prompts for it. |
| `-Top <number>` | How many of the largest files to display. Defaults to `10`. |
| `-DryRun` | The script is read-only by design and never makes changes. This switch is provided for consistency with other DWP scripts and simply confirms a read-only run. |
| `-LogPath <path>` | Folder for the run's timestamped log file. Defaults to `LargeFileFinderData\Logs` next to the script. |

## DryRun option
This script never modifies anything, so `-DryRun` behaves the same as a
normal run. It exists so the script follows the same safe-by-default
pattern as other DWP tools in this toolkit.

## Logging
Every run writes a timestamped log file to
`LargeFileFinderData\Logs\LargeFileFinder_yyyyMMdd_HHmmss.log`, recording
the folder scanned, every file reported, every skipped/inaccessible item,
and a final summary.

## Error handling
- If the target folder does not exist, the script logs an error and stops
  cleanly (no scan to run).
- Files or subfolders that cannot be accessed (e.g. permission denied) are
  skipped and logged as warnings; the scan continues with the remaining
  files.

## Summary report
At the end of each run, the script displays and logs:
- Total files scanned
- Largest file found (name and size)
- Total size of the files reported (the `-Top` files shown)
- Errors encountered
- Log file location

## Example commands
```powershell
# Scan Downloads and show the 10 largest files (default)
.\LargeFileFinder.ps1 -Path "C:\Users\jbloggs\Downloads"

# Show the 25 largest files under D:\Data
.\LargeFileFinder.ps1 -Path "D:\Data" -Top 25

# Run without specifying -Path; the script will prompt for a folder
.\LargeFileFinder.ps1

# Explicit read-only run (no different from a normal run)
.\LargeFileFinder.ps1 -Path "C:\Users\jbloggs" -DryRun
```

## Safety notes
- Read-only: the script only reads file metadata (name, size, dates). It
  never deletes, moves, renames, or edits any file or folder.
- Safe to run on production endpoints and does not require administrator
  rights beyond normal read access to the folder being scanned.
- Scanning very large or deep folder structures (e.g. an entire `C:\`
  drive) may take some time; scope `-Path` to the folder you actually
  need to investigate where possible.
