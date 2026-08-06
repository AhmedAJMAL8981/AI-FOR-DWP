# Clear-EndpointTempFiles.ps1

A safe, reversible temp-file cleanup script for DWP-managed Windows endpoints
(PowerShell 5.1). Files are never permanently removed in a single step -
they are moved into a quarantine folder and can be restored with `-Rollback`.

## How it works

- **"Delete" = move, not remove.** Matching files are moved into
  `CleanupData\Quarantine\<RunId>\` next to the script. A manifest CSV
  (`Manifest_<RunId>.csv`) records the original path and quarantine path for
  every file moved in that run.
- **Idempotent.** Because a delete simply moves a file out of the target
  folder, re-running the cleanup finds nothing left to act on for files
  already handled - no errors, no duplicate work. Rollback likewise skips
  any entry whose quarantined file is already gone or whose original path
  is already occupied.
- **Locked files are not fatal.** Each file is wrapped in its own try/catch.
  If a file can't be opened exclusively (in use by another process), it's
  logged as a warning and skipped; the script keeps going.
- **Everything is logged.** Every run writes a timestamped log file to
  `CleanupData\Logs\TempCleanup_<RunId>.log`.

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `-TargetPaths` | `$env:TEMP`, `$env:WINDIR\Temp` | Folders to clean, recursively. |
| `-DaysOld` | `0` | Only files last written more than this many days ago are eligible. `0` means all files currently present. |
| `-DryRun` | off | Reports what would be deleted; makes no changes on disk (no quarantine folder or manifest is created). |
| `-Rollback` | off | Restores files from a previous run instead of cleaning up. |
| `-ManifestFile` | most recent | Used with `-Rollback` to pick a specific run's manifest CSV instead of the latest one. |
| `-QuarantinePath` | `CleanupData\Quarantine` next to the script | Where "deleted" files are stored until rolled back or manually purged. |
| `-LogPath` | `CleanupData\Logs` next to the script | Where the run's log file is written. |

## Examples

```powershell
# See what would be cleaned up, without changing anything
.\Clear-EndpointTempFiles.ps1 -DryRun

# Clean up temp files older than 7 days
.\Clear-EndpointTempFiles.ps1 -DaysOld 7

# Undo the most recent cleanup run
.\Clear-EndpointTempFiles.ps1 -Rollback

# Undo a specific run
.\Clear-EndpointTempFiles.ps1 -Rollback -ManifestFile "C:\...\CleanupData\Quarantine\Manifest_20260805_101500.csv"
```

## Notes

- Quarantined files remain in `CleanupData\Quarantine` until rolled back;
  periodically purge old run folders once you're confident they're no
  longer needed (this script does not auto-purge quarantine).
- `CleanupData` (quarantine + logs) is excluded from scanning even if it
  happens to live under one of the target paths, so a run never processes
  its own output.
