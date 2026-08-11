# KB: Finance Team Cannot Access Shared Drives (L2/L3)

Version: v 1.0  
Date: 07/08/2026  
Status : Draft

## Background
Finance users require persistent mapped access to `S:` pointing to `\\finbridge-fs01\Finance` for line-of-business files, month-end processing, and shared templates.

In this environment, drive mapping moved from legacy Group Policy preference mapping to Intune script-based mapping (`Map-FinBridgeDrives.ps1`). The script must run in the signed-in user context because the target share and drive mapping are user-scoped.

Why this matters:
- Finance workflows fail immediately when `S:` is missing or broken.
- Users may still sign in successfully, which can hide the underlying mapping fault.
- A context mismatch (SYSTEM vs user) creates false positives where deployment appears successful but user access still fails.

## Symptom
What the engineer observes:
- Intune shows script deployed, but affected users still cannot open `S:` or `\\finbridge-fs01\Finance`.
- Endpoint log shows script execution entries, but mapping outcome is inconsistent.
- System log may show repeated NTFS mount warnings for `S:`.

What the user reports:
- "Finance shared drive is missing from This PC."
- "`S:` says location unavailable or network path cannot be found."
- "Issue repeats after restart or sign-in."

## Root Cause
Specific technical cause:
- `Map-FinBridgeDrives.ps1` is assigned/executed in a way that runs under SYSTEM context instead of user context.
- In SYSTEM context, the mapping attempt to `\\finbridge-fs01\Finance` does not create a valid user-session drive mapping.

Evidence that confirms root cause:
- `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` contains recent script execution for `Map-FinBridgeDrives.ps1` with SYSTEM-context marker text (`Script context is SYSTEM account`).
- Same log window can include UNC failure text (`Network name cannot be found`).
- Event Viewer System log shows Event ID `98` from source `Ntfs` associated with `S:` assignment warnings during failure window.
- Comparison check confirms mismatch behavior:
  - Affected endpoint (for example `DESKTOP-FB041`) shows SYSTEM-context marker and/or UNC failure text.
  - Control endpoint or post-fix endpoint (for example `DESKTOP-FB022`) does not show those markers for latest run and can open `S:`.

## Detection
Objective: determine in under 3 minutes whether the failure is permissions, network, authentication, or file server related before changing assignments.

Scope and exact locations to check:
- User device: affected endpoint (example `DESKTOP-FB041`) in user PowerShell.
- Affected shared drive path: `S:` and `\\finbridge-fs01\Finance`.
- File server: `finbridge-fs01`.
- Network connectivity status: ICMP reachability and DNS name resolution from the affected endpoint.

3-minute fast triage commands (run in this order on the affected user device):

1. Capture user identity (authentication context evidence).
```powershell
whoami
```
Record: returned domain and username.

2. Capture current drive mappings.
```powershell
net use
net use S:
```
Record fields:
- Local drive (`S:`)
- Remote path (`\\finbridge-fs01\Finance`)
- Status (`OK`, `Unavailable`, or error)

3. Validate direct access to the shared path and capture the exact error message.
```powershell
dir \\finbridge-fs01\Finance
```
Record exact message if shown. Match against known indicators:
- "Access Denied"
- "Network Path Not Found"
- "The specified network name is no longer available"
- "Drive is unavailable"

4. Validate file server DNS resolution.
```powershell
nslookup finbridge-fs01
```
Healthy result:
- Returns server name and one or more IP addresses.
Failure indicator:
- Name does not resolve, times out, or returns no valid address.

5. Validate file server network reachability.
```powershell
ping finbridge-fs01
```
Healthy result:
- Replies received with stable latency.
Failure indicator:
- Request timed out or destination unreachable.

6. Optional verification-only policy refresh evidence (do not treat as remediation in Detection).
```powershell
gpupdate /force
```
Use only to confirm whether policy refresh changes immediate mapping state; capture output success/failure text.

7. Quick log evidence for this incident signature (command-line, no GUI required).
```powershell
Select-String -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Pattern "Map-FinBridgeDrives.ps1","Script context is SYSTEM account","Network name cannot be found" | Select-Object -Last 20
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Ntfs'; Id=98; StartTime=(Get-Date).AddHours(-4)} | Select-Object -First 10 TimeCreated, Id, ProviderName, Message
```
Record:
- Presence of `Script context is SYSTEM account`
- Presence of `Network name cannot be found`
- Ntfs Event ID `98` timestamps near user failure time

Healthy baseline comparison (mandatory):
- Known working user: one Finance user confirmed working in same period.
- Known working shared path: `\\finbridge-fs01\Finance` opens successfully.
- Known working endpoint (example `DESKTOP-FB022`) shows:
  - `whoami` returns expected Finance identity.
  - `net use S:` shows `Remote name` = `\\finbridge-fs01\Finance`, `Status` = `OK`.
  - `nslookup finbridge-fs01` resolves correctly.
  - `ping finbridge-fs01` succeeds.

Decision points (apply exactly):
- If only one user is affected -> investigate user permissions.
- If multiple Finance users are affected -> investigate shared drive permissions.
- If all shared drives are inaccessible -> investigate file server or network connectivity.
- If drive mapping exists but access fails -> investigate access rights.

Error-to-cause shortcut for rapid triage:
- "Access Denied" -> likely permissions/authz issue.
- "Network Path Not Found" -> likely DNS/path/connectivity issue.
- "The specified network name is no longer available" -> likely file server session/SMB/network interruption.
- "Drive is unavailable" with mapping present -> stale mapping or access/authentication context issue.

## Resolution
Perform in order. Each step includes expected outcome.

1. Open Intune script settings for the mapping script.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Properties`.
- Action: select `Edit` in script settings.
- Expected result: script settings pane opens.

2. Force user-context execution.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Properties > Script settings`.
- Action:
  - Set `Run this script using the logged on credentials` = `Yes`.
  - Set `Enforce script signature check` = `No` (as per current operational baseline in runbook).
  - Select `Review + save`.
- Expected result: settings save succeeds and script is configured for user context.

3. Correct assignment scope for user-targeted mapping.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Assignments > Edit assignments`.
- Action:
  - Add Finance user group to `Included groups`.
  - Add Finance device group to `Excluded groups`.
  - Select `Review + save`.
- Expected result: assignment update confirms user-group targeting pattern.

4. Trigger policy sync on pilot affected endpoint.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > All devices > DESKTOP-FB041`.
- Action: run manual sync.
- Expected result: sync completes and `Last sync` time updates.

5. Recreate user session token and mapping context.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > All devices > DESKTOP-FB041`.
- Action: sign out affected user, then sign in as same user.
- Expected result: new user session starts with fresh policy/script processing context.

6. Validate share reachability and mapped drive immediately after sign-in.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > All devices > DESKTOP-FB041`.
- Action:
  - Open `\\finbridge-fs01\Finance` in File Explorer.
  - Open This PC and confirm `S:` exists.
- Expected result: UNC path opens and `S:` appears.

7. Validate script execution evidence is now clean.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > All devices > DESKTOP-FB041`.
- Action: inspect latest `IntuneManagementExtension.log` block for `Map-FinBridgeDrives.ps1`.
- Expected result:
  - Latest run does not contain `Script context is SYSTEM account`.
  - Latest run does not contain `Network name cannot be found`.

8. Validate event health after fix.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > All devices > DESKTOP-FB041`.
- Action: `Event Viewer > Windows Logs > System > Filter Current Log` with source `Ntfs` and Event ID `98`.
- Expected result: no new Event ID `98` entries after fix timestamp.

9. Repeat pilot validation on second endpoint before broad rollout.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Assignments > Edit assignments`.
- Action: repeat Steps 4 to 8 on `DESKTOP-FB022`.
- Expected result: second endpoint shows same successful pattern.

10. Expand rollout to full Finance user scope.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Assignments > Edit assignments`.
- Action: keep validated user-context assignment pattern and include full Finance user scope.
- Expected result: production assignment is aligned to proven pilot configuration.

## Verification
1. Confirm Intune run success on pilot devices.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Device status`.
- Required fields:
  - Device name = `DESKTOP-FB041` and `DESKTOP-FB022`.
  - `Latest run status` = `Succeeded`.

2. Confirm mapping in user context on both pilot devices.
- Endpoint check command: `whoami` then `net use S:`.
- Required output fields:
  - Correct Finance user identity from `whoami`.
  - `Remote name` = `\\finbridge-fs01\Finance`.
  - `Status` = `OK`.

3. Confirm no failure markers in latest IME script run block.
- Exact log location: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.
- Required text checks:
  - `Map-FinBridgeDrives.ps1` present in latest execution block.
  - `Script context is SYSTEM account` absent.
  - `Network name cannot be found` absent.

4. Confirm Event ID health state after deployment time.
- Exact log location: `Event Viewer > Windows Logs > System`.
- Required filter fields:
  - Source = `Ntfs`.
  - Event ID = `98`.
- Pass condition:
  - No Event ID `98` with timestamp greater than the fix deployment timestamp.

5. Confirm user experience outcome with business validation.
- Action: ask at least two previously affected Finance users to open `S:` and a known subfolder.
- Pass condition: both users open files successfully with no reconnect prompt or path error.

## Rollback
Use rollback if access errors increase or broader outage begins after change.

1. Contain the Intune rollout immediately.
- Azure portal path: `portal.azure.com > Microsoft Intune > Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Assignments > Edit assignments`.
- Action: remove all `Included groups`, then `Review + save`.
- Expected result: Intune script no longer targets users.

2. Re-enable known-good Finance GPO mapping path.
- Console path: `Group Policy Management (gpmc.msc) > Forest > Domains > <domain> > OU=Finance`.
- Action: link or re-enable the exact last known-good Finance drive-mapping GPO recorded in prerequisites/change record.
- Expected result: known-good GPO mapping is active.

3. Force policy refresh on pilot endpoint and renew session.
- Endpoint action path: elevated CMD/PowerShell on `DESKTOP-FB041`.
- Action: run `gpupdate /force`, then user sign out/sign in.
- Expected result: refreshed user policy applies on new session.

4. Verify rollback mapping state and event state.
- Exact checks:
  - `net use S:` shows `Remote name` = `\\finbridge-fs01\Finance` and `Status` = `OK`.
  - `Event Viewer > Windows Logs > System` filter `Ntfs`, Event ID `98` shows no new events after rollback login time.
- Expected result: user access restored through known-good GPO path.

5. Send standardized rollback communication.
- Action text: `Rollback applied. Ask all affected Finance users to sign out and sign in now.`
- Expected result: users perform one clear action and recover quickly.

## Preventive
Implement these concrete controls to prevent recurrence:

1. Enforce assignment guardrail for user-scoped mappings.
- Change: add a mandatory Intune pre-deployment checklist item requiring `Run this script using the logged on credentials = Yes` for any drive mapping script.
- Tool/process implementation:
  - Add this as a required field in change template.
  - Block approval if field screenshot is missing.

2. Enforce group-model policy for mapping scripts.
- Change: standardize assignment pattern to `Included = user groups`, `Excluded = device groups` for Finance drive mappings.
- Tool/process implementation:
  - Maintain a named assignment baseline document.
  - Weekly script assignment drift review against baseline.

3. Add automated log signature detection on pilot endpoints.
- Change: schedule endpoint compliance script to parse `IntuneManagementExtension.log` for:
  - `Script context is SYSTEM account`
  - `Network name cannot be found`
- Tool/process implementation:
  - Alert to Service Desk queue if either marker appears after deployment window.
  - Auto-hold rollout expansion until alert is cleared.

4. Add mandatory two-endpoint comparison gate before full rollout.
- Change: require documented comparison of `DESKTOP-FB041` vs `DESKTOP-FB022` (or designated pair) using:
  - `net use S:` output fields
  - IME latest script block markers
  - `Ntfs` Event ID `98` count after fix timestamp
- Tool/process implementation:
  - Add a "comparison evidence" section in incident/change ticket that must be completed before broad assignment.

5. Create NTFS Event ID 98 threshold alert for Finance mapping changes.
- Change: monitor pilot devices for spikes of `System` log source `Ntfs`, Event ID `98` in 30-minute windows after mapping deployment.
- Tool/process implementation:
  - If threshold breached, auto-trigger rollback checklist and freeze assignment expansion.

## Related
- `runbook-finance-shared-drives-access.md`
- `analysis-drive-mapping-failure-finance-2026-08-07.md`
- `closure-note-drive-mapping-failure-finance-2026-08-07.md`
- `RCA-drive-mapping-failure-finance-2026-08-07` (record name from incident system)
- `known-error-drive-mapping-failure-finance-2026-08-07` (record name from incident system)
