# StartupProgramAuditor.ps1

## Purpose
A PowerShell 5.1 script for a DWP engineer to audit Windows startup programs
on an endpoint and, when needed, safely disable a named startup entry —
with the ability to roll the change back later. It is designed for
enterprise use: no destructive deletes, per-entry error isolation, and
full logging of every action.

## Startup locations covered
- Current user registry Run key: `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run`
- Local machine registry Run key: `HKLM:\Software\Microsoft\Windows\CurrentVersion\Run`
- Current user Startup folder: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`
- All Users Startup folder: `%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup`

## Parameters
| Parameter | Description |
|---|---|
| `-DryRun` | Preview only — no changes are made. Can be used alone (lists all startup programs) or with `-Disable` (previews what would be disabled). |
| `-Disable <Name>` | Name of a startup program to disable (case-insensitive match). Verifies the name exists first. |
| `-Rollback <Name>` | Name of a previously disabled startup program to restore from the backup file. |
| `-BackupFile <path>` | Path to the structured CSV backup file. Defaults to `StartupAuditData\StartupBackup.csv` next to the script. |
| `-QuarantinePath <path>` | Folder that disabled Startup-folder items are moved into. Defaults to `StartupAuditData\Quarantine`. |
| `-LogPath <path>` | Folder for the run's timestamped log file. Defaults to `StartupAuditData\Logs`. |

## DryRun option
Running with no parameters, or with `-DryRun` alone, lists every startup
program found across all four locations and makes no changes. Adding
`-DryRun` to `-Disable` previews exactly what would be disabled without
touching the registry or file system.

## Disable option
`-Disable "<ProgramName>"` looks up the name across all four startup
locations. If the name is not found, the script logs this and continues
(it does not stop or error). If found:
- Registry Run entries: the value is removed from the Run key.
- Startup folder items: the file is moved into the quarantine folder
  (never deleted).

Before removing/moving anything, the original details are recorded in the
CSV backup file, so the change can be reversed with `-Rollback`.

## Rollback option
`-Rollback "<ProgramName>"` looks up the name in the CSV backup file and
restores it:
- Registry entries are re-created with their original value.
- Quarantined files are moved back to their original path.

If no backup entry exists for the name, the script logs this and continues
without error. The backup entry is removed once a rollback succeeds.

## Idempotency
- Disabling an item that already has a backup entry is detected and
  skipped (logged as a warning) rather than repeated.
- Rolling back an item whose registry value/file already exists at the
  original location is skipped rather than overwritten.
- Running the script multiple times in the same mode does not create
  duplicate backup rows or repeat actions.

## Logging
Every run writes a timestamped log file to `StartupAuditData\Logs\StartupAudit_yyyyMMdd_HHmmss.log`,
recording every discovered item, every action taken, every skip, and every
error, plus a final summary line.

## Summary report
At the end of each run, the script displays and logs:
- Total startup programs found
- Startup programs disabled/restored (Processed)
- Startup programs skipped
- Errors encountered
- Log file location

## Example commands
```powershell
# List all startup programs (read-only)
.\StartupProgramAuditor.ps1

# Same as above, explicit
.\StartupProgramAuditor.ps1 -DryRun

# Preview disabling a specific program
.\StartupProgramAuditor.ps1 -Disable "OneDriveSetup" -DryRun

# Disable a specific program
.\StartupProgramAuditor.ps1 -Disable "OneDriveSetup"

# Restore a previously disabled program
.\StartupProgramAuditor.ps1 -Rollback "OneDriveSetup"
```

## Safety notes
- No startup entry is ever permanently deleted: registry values are backed
  up before removal, and Startup-folder files are quarantined (moved), not
  deleted.
- Each startup entry is processed in its own try/catch block, so one
  inaccessible or problematic entry cannot stop the rest of the run.
- Modifying `HKLM` Run entries and the All Users Startup folder typically
  requires local administrator rights; read-only listing generally does
  not.
- Always review a `-DryRun` preview before disabling a program on a
  production endpoint.
