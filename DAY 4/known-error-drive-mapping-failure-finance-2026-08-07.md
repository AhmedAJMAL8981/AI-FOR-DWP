# Known Error Database (KEDB) Entry - Finance Shared Drive Mapping Failure

## Error Description
Finance users report they cannot access shared drives; drive letter S: is not assigned. Support can recognize this by `Map-FinBridgeDrives.ps1` failing with exit code `1` and error `Network name cannot be found`, with affected devices in `DESKTOP-FB*` / `OU=Finance`.

## Root Cause
On 2024-03-14 23:30, drive mapping was migrated from a GPO logon script running in USER context to an Intune PowerShell script running in SYSTEM context, but the script was not updated for SYSTEM-context behavior. At runtime, logs show the script executing as SYSTEM and failing to access `\\finbridge-fs01\Finance` at execution time; this aligns with the requirement for user/session credentials and network readiness that are not available to SYSTEM at login time. The script then exits with code 1 (`Network name cannot be found`), no retry is configured, and S: remains unassigned.

## Environment / Conditions
- User/device scope: All Finance users, `DESKTOP-FB*`, `OU=Finance`
- Start of observed incident: 08:00 today
- Data sources: Intune Management Extension Log + System Log
- Trigger condition: `Map-FinBridgeDrives.ps1` executed in SYSTEM context during login/startup
- Supporting indicators:
  - SYSTEM context logged at 08:00:02
  - UNC not accessible from SYSTEM at 08:00:03
  - No retry configured at 08:00:04
  - Workstation service enters running state at 08:00:05
  - GP processed successfully at 08:00:06 (not a GP processing issue)
  - Ntfs warning at 08:00:07 that S: was not assigned
- Cross-endpoint repeatability: Same pattern observed on `DESKTOP-FB041` and `DESKTOP-FB022`

## Workaround (If Recurs Before Permanent Fix)
Use direct UNC access to `\\finbridge-fs01\Finance` from the logged-in user session. If required for business continuity, apply manual user-session drive mapping for affected users/devices pending confirmation of permanent remediation rollout.

## Permanent Fix Status
Planned (implementation status pending confirmation).

## Related Incident ID(s)
Pending confirmation.