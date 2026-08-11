# Title: Runbook - Finance Team Cannot Access Shared Drives
# Version: 1.0
# Date: 10/08/2026
# Author: Ajmal
# Reviewed: self
# Status: draft
# Change: initial version from RCA

## Prerequisites
- [ ] Access: Sign in to Intune admin center at `https://intune.microsoft.com` and confirm you can open Devices > Scripts and remediations > Platform scripts > Windows. [ELEVATED]
- [ ] Access: Confirm you can edit assignments for script `Map-FinBridgeDrives.ps1` in Intune admin center. [ELEVATED]
- [ ] Access: Open Group Policy Management (`gpmc.msc`) and confirm you can link or re-enable Finance user GPOs in `OU=Finance`. [ELEVATED]
- [ ] Access: Confirm local administrator rights on at least two affected endpoints (`DESKTOP-FB041` and `DESKTOP-FB022`). [ELEVATED]
- [ ] Access: Confirm read access to endpoint log path `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`. [ELEVATED]
- [ ] Access: Confirm read access to endpoint Event Viewer System log (`Event Viewer > Windows Logs > System`). [ELEVATED]
- [ ] Tools: Open Intune admin center in browser.
- [ ] Tools: Open Group Policy Management Console (`gpmc.msc`). [ELEVATED]
- [ ] Tools: Open Event Viewer (`eventvwr.msc`). [ELEVATED]
- [ ] Tools: Open elevated PowerShell console (`Run as administrator`). [ELEVATED]
- [ ] Mandatory end-user info: Capture one affected username (UPN format).
- [ ] Mandatory end-user info: Capture one affected device name (for example `DESKTOP-FB041`).
- [ ] Mandatory end-user info: Capture first failure time and latest failure time (local timezone).
- [ ] Mandatory end-user info: Capture exact error text or screenshot shown when opening `S:` or `\\finbridge-fs01\Finance`.
- [ ] Mandatory end-user info: Capture whether issue occurs after sign out and sign in.
- [ ] Mandatory incident info: Capture script name `Map-FinBridgeDrives.ps1` and current assignment scope from Intune.
- [ ] Mandatory rollback info: Capture the exact display name of the last known-good Finance drive-mapping GPO from change records. [ELEVATED]

## Procedure
1. Action: Sign in to `https://intune.microsoft.com` and navigate to Devices > Scripts and remediations > Platform scripts > Windows > `Map-FinBridgeDrives.ps1`. [ELEVATED]
   Expected result: Script overview page opens for `Map-FinBridgeDrives.ps1`.

2. Action: Open `Map-FinBridgeDrives.ps1` and select Properties > Edit in the script settings section. [ELEVATED]
   Expected result: Script settings edit pane opens.

3. Action: Set `Run this script using the logged on credentials` to `Yes`. [ELEVATED]
   Expected result: Script is configured to run in user context.

4. Action: Set `Enforce script signature check` to `No`.
   Expected result: Signature enforcement is disabled for this script deployment.

5. Action: Select Review + save in the script settings pane. [ELEVATED]
   Expected result: Intune confirms script settings were saved.

6. Action: Open `Map-FinBridgeDrives.ps1` > Assignments > Edit assignments. [ELEVATED]
   Expected result: Assignment edit page opens.

7. Action: Add the Finance user group in `Included groups`. [ELEVATED]
   Expected result: Finance user group appears in included assignments.

8. Action: Add the Finance device group in `Excluded groups`. [ELEVATED]
   Expected result: Finance device group appears in excluded assignments.

9. Action: Select Review + save on the assignments page. [ELEVATED]
   Expected result: Intune confirms assignments were updated.

10. Action: On `DESKTOP-FB041`, open Settings > Accounts > Access work or school > select connected work account > Info > Sync.
    Expected result: Manual sync completes and shows current time in Last sync.

11. Action: On `DESKTOP-FB041`, sign out the affected Finance user session.
    Expected result: User returns to Windows sign-in screen.

12. Action: On `DESKTOP-FB041`, sign in as the same affected Finance user.
    Expected result: New user session opens successfully.

13. Action: On `DESKTOP-FB041`, open File Explorer and browse to `\\finbridge-fs01\Finance`.
    Expected result: Share opens without error.

14. Action: On `DESKTOP-FB041`, open File Explorer > This PC.
    Expected result: Drive `S:` is listed and mapped.

15. Action: On `DESKTOP-FB041`, open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` in Notepad. [ELEVATED]
    Expected result: Current Intune script execution log is visible.

16. Action: In `IntuneManagementExtension.log`, search for `Map-FinBridgeDrives.ps1`.
    Expected result: Latest run entry for the script is located.

17. Action: In `IntuneManagementExtension.log`, confirm the latest run does not show `Script context is SYSTEM account`.
    Expected result: No SYSTEM-context marker is present for latest run.

18. Action: In `IntuneManagementExtension.log`, confirm the latest run does not show `Network name cannot be found`.
    Expected result: No UNC failure message is present for latest run.

19. Action: On `DESKTOP-FB041`, open Event Viewer (`eventvwr.msc`) > Windows Logs > System > Filter Current Log > Event sources: `Ntfs` > Event IDs: `98`.
    Expected result: Filtered list shows Ntfs Event 98 records only.

20. Action: In filtered System log, verify no new Event ID 98 is generated after the fix timestamp.
    Expected result: No new post-fix `S:` assignment warning appears.

21. Action: Repeat steps 10 through 20 on `DESKTOP-FB022`.
    Expected result: Second endpoint shows same successful mapping and clean log pattern.

22. Action: Return to Intune > `Map-FinBridgeDrives.ps1` > Assignments > Edit assignments and expand to full Finance user group rollout if pilot users succeeded. [ELEVATED]
    Expected result: Full Finance user scope is assigned with user-context execution.

23. Action: Update incident ticket with exact navigation path used, endpoint names validated, and log evidence timestamps.
    Expected result: Ticket contains reproducible execution evidence for closure and audit.

## Verification
1. Action: Sign in to `https://intune.microsoft.com` and go to Devices > Scripts and remediations > Platform scripts > Windows > `Map-FinBridgeDrives.ps1` > Device status. [ELEVATED]
   Expected result: Device status page opens and target devices are listed.

2. Action: In Device status, filter by `DESKTOP-FB041` and confirm Latest run status is `Succeeded`.
   Expected result: `DESKTOP-FB041` shows `Succeeded` for the current deployment.

3. Action: In Device status, filter by `DESKTOP-FB022` and confirm Latest run status is `Succeeded`.
   Expected result: `DESKTOP-FB022` shows `Succeeded` for the current deployment.

4. Action: On `DESKTOP-FB041`, sign in as the affected Finance user and open PowerShell.
   Expected result: User PowerShell prompt opens in interactive session.

5. Action: On `DESKTOP-FB041`, run `whoami`.
   Expected result: Output shows the expected Finance user account.

6. Action: On `DESKTOP-FB041`, run `net use S:`.
   Expected result: Output shows `Remote name` as `\\finbridge-fs01\Finance` and `Status` as `OK`.

7. Action: On `DESKTOP-FB041`, open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` in Notepad. [ELEVATED]
   Expected result: Intune Management Extension log file is open.

8. Action: In that log file, search for `Map-FinBridgeDrives.ps1` and inspect the latest timestamped execution block.
   Expected result: Latest block is found for the current run window.

9. Action: In the latest execution block, confirm the text `Script context is SYSTEM account` is not present.
   Expected result: No SYSTEM-context line exists for latest run.

10. Action: In the latest execution block, confirm the text `Network name cannot be found` is not present.
    Expected result: No UNC failure line exists for latest run.

11. Action: On `DESKTOP-FB041`, open Event Viewer (`eventvwr.msc`) > Windows Logs > System > Filter Current Log > Event sources `Ntfs` and Event IDs `98`.
    Expected result: System log view is filtered to Ntfs Event 98 only.

12. Action: In filtered results, verify there is no Event 98 entry with time greater than the fix deployment time.
    Expected result: No post-fix Event 98 appears.

13. Action: Repeat steps 4 through 12 on `DESKTOP-FB022`.
    Expected result: Second endpoint shows same successful mapping and clean log pattern.

14. Action: Ask two affected Finance users to open File Explorer > This PC > `S:` > a known subfolder under `\\finbridge-fs01\Finance`.
    Expected result: Both users open files successfully without reconnect prompt or path errors.

15. Action: Update the incident ticket with Intune status screenshot, command outputs, log timestamps, and two user confirmations.
    Expected result: Ticket has complete closure evidence for audit.

## Rollback
Use this rollback if users lose access after the change or mapping failures increase.

Target execution time: under 3 minutes.

1. Action: Open `https://intune.microsoft.com` > Devices > Scripts and remediations > Platform scripts > Windows > `Map-FinBridgeDrives.ps1` > Assignments > Edit assignments. [ELEVATED]
   Expected result: Assignment editor opens for immediate containment.

2. Action: Remove all groups from `Included groups` for `Map-FinBridgeDrives.ps1`. [ELEVATED]
   Expected result: Included groups list is empty.

3. Action: Select Review + save on the assignments page. [ELEVATED]
   Expected result: Intune confirms assignment update completed.

4. Action: Open Group Policy Management (`gpmc.msc`) > Forest > Domains > your domain > `OU=Finance`, then link or re-enable the exact last known-good Finance drive-mapping GPO captured in prerequisites. [ELEVATED]
   Expected result: Known-good Finance drive-mapping GPO is active on `OU=Finance`.

5. Action: On `DESKTOP-FB041`, open elevated Command Prompt and run `gpupdate /force`. [ELEVATED]
   Expected result: Computer and user policy refresh completes successfully.

6. Action: On `DESKTOP-FB041`, sign out and sign in with the affected Finance user.
   Expected result: New logon session starts with updated policy.

7. Action: On `DESKTOP-FB041`, run `net use S:` in user PowerShell.
   Expected result: `S:` is mapped to `\\finbridge-fs01\Finance`.

8. Action: On `DESKTOP-FB041`, open Event Viewer (`eventvwr.msc`) > Windows Logs > System > Filter Current Log > Event sources `Ntfs` and Event IDs `98`, then check the latest events.
   Expected result: No new Event 98 is generated after rollback login.

9. Action: Send Service Desk message: `Rollback applied. Ask all affected Finance users to sign out and sign in now.`
   Expected result: Users receive a single clear instruction and recover via known-good GPO mapping path.

## Notes
- This incident pattern is specific to context mismatch: USER-context GPO mapping was replaced by SYSTEM-context Intune script execution.
- If `\\finbridge-fs01\Finance` fails even in user session, treat as a separate DNS/SMB reachability incident before changing mappings.
- If `S:` is already used by another mapping, change drive letter policy in the mapping script and communicate the new letter before rollout.
- If endpoint sync delays exceed 30 minutes, use a manual test mapping (`net use`) to validate share health while waiting for policy delivery.
- Related records: RCA-drive-mapping-failure-finance-2026-08-07, known-error-drive-mapping-failure-finance-2026-08-07, analysis-drive-mapping-failure-finance-2026-08-07.