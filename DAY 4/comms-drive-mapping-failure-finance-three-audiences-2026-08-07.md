# End-User Communication - Three Audiences

## Audience 1 - Non-Technical Executive
Your access and data are safe. Since 08:00 today, 45 Finance users on DESKTOP-FB devices in the Finance unit could not open shared drives. Logs on two devices show a recent setup change made drive connection run in the wrong sign-in mode, so the S: drive was not assigned; policy processing was successful and is not the cause. Resolution timing is pending confirmation. Please continue normal work and use the temporary path shared by IT if needed.

## Audience 2 - Affected End-User Team (10 People, Non-Technical)
Your data is safe, and this is an access issue only. Since 08:00 today, 45 Finance users on DESKTOP-FB devices have not been able to open shared drives because a recent background setup change made drive connection run in the wrong sign-in mode, so S: was not assigned. IT also confirmed policy processing is working and not the cause, with the same pattern seen on two devices. If you see this issue, use the temporary shared folder path and contact the Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note
Incident summary (same facts):
- Since 08:00 today, 45 Finance users (DESKTOP-FB*, OU=Finance) cannot access shared drives.
- Evidence source: Intune Management Extension + System log.
- Repro pattern present on DESKTOP-FB041 and DESKTOP-FB022.

Root cause:
- Mapping workflow was migrated on 2024-03-14 23:30 from GPO logon script (USER) to Intune PowerShell (SYSTEM) without updating for SYSTEM-context UNC/timing constraints; result is failed access to `\\finbridge-fs01\Finance` and S: unassigned.

Exact action taken:
- Reviewed timeline/log chain on DESKTOP-FB041.
- Correlated same signature on DESKTOP-FB022.
- Excluded GP as primary cause via GroupPolicy Event 1500 success.
- Isolated migration context mismatch as cause chain.
- Remediation implementation status: pending confirmation.

Config/detail evidence:
- 08:00:01 ScriptRunner starts Map-FinBridgeDrives.ps1.
- 08:00:02 Script context = SYSTEM.
- 08:00:03 Warning: `\\finbridge-fs01\Finance` inaccessible from SYSTEM at execution time.
- 08:00:03 Error: exit code 1, "Network name cannot be found".
- 08:00:04 No retry configured.
- 08:00:05 Workstation service enters running state.
- 08:00:06 GP Event 1500 successful.
- 08:00:07 Ntfs Event 98: S: not assigned.

Verification step:
- Confirmed same failure signature across at least two endpoints (FB041, FB022), and confirmed GP success does not align with failure timing/context.

Preventive action needed:
- Restore/implement USER-context mapping path (or equivalent user-session-targeted method).
- Add retry/delay guard for network-dependent mapping at startup.
- Add pre-change execution-context validation (USER vs SYSTEM) plus pilot ring + rollback criteria.
- Owners/target dates: pending confirmation.
