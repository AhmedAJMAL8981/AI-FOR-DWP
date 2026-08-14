# Runbook: Floor 6 Desktop Shortcuts/Profile Symptom
Date: 2026-08-14
Scope: Floor 6 Legal
Incident type: Missing desktop shortcuts after recent Windows 11 migration/Intune enrollment

## 1. Prerequisites

1. Open the active incident ticket and confirm this is the Desktop Shortcuts/Profile stream.
Expected result: Ticket is tagged as Desktop/Profile and separated from Login and Copilot streams.

2. Confirm at least one affected user and one unaffected user are available for comparison.
Expected result: You have two usernames and device names recorded.

3. Get local admin access on one affected device. [ELEVATED]
Expected result: You can start an elevated PowerShell session on the affected device.

4. Get Intune read access for device and policy assignment views. [ELEVATED]
Expected result: You can open Intune device and policy assignment pages.

5. Get Entra/Graph app assignment write access only if app rollback may be required. [ELEVATED]
Expected result: You can run Connect-MgGraph with DeviceManagementApps.ReadWrite.All and Group.Read.All.

6. Create the working evidence folder C:\Diagnostic_Results on the affected device.
Expected result: Folder exists and you can write files to it.

7. Confirm the current user is logged into their normal profile path.
Expected result: Profile path resolves to C:\Users\<username> and not a temporary profile suffix such as .000.

## 2. Procedure

1. Run system profile error check on the affected device. [ELEVATED]
Action:
```powershell
Get-EventLog System -After (Get-Date).AddDays(-2) -InstanceId 1509,1516 | Select-Object TimeGenerated, InstanceId, Message
```
Expected result: You obtain profile error evidence for the last 2 days.

2. List shortcut files on the affected user desktop.
Action:
```powershell
Get-ChildItem "$env:USERPROFILE\Desktop" -Filter *.lnk -ErrorAction SilentlyContinue | Select-Object Name, LastWriteTime
```
Expected result: You get a list of user desktop shortcuts or an empty result.

3. List shortcut files on the Public desktop.
Action:
```powershell
Get-ChildItem "C:\Users\Public\Desktop" -Filter *.lnk -ErrorAction SilentlyContinue | Select-Object Name, LastWriteTime
```
Expected result: You get a list of common shortcuts available to all users.

4. Save all three outputs from steps 1-3 into the incident ticket.
Expected result: Ticket contains timestamped evidence and no data gaps.

5. Run the same shortcut listing on one unaffected comparison device.
Expected result: You have a baseline list for comparison.

6. Compare affected vs unaffected shortcut lists and record missing entries.
Expected result: Missing shortcuts are explicitly identified by name.

7. Check whether the missing shortcuts exist in Start Menu program paths.
Action:
```powershell
Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter *.lnk -ErrorAction SilentlyContinue | Select-Object FullName
```
Expected result: You confirm whether shortcut targets still exist in Start Menu paths.

8. Record decision A if profile errors (1509/1516) are present.
Expected result: Ticket path is set to Profile issue path.

9. Record decision B if no profile errors exist but shortcuts are missing.
Expected result: Ticket path is set to Policy/App impact path.

10. For Policy/App impact path, verify whether Friday document app is assigned to Floor 6 in Intune. [ELEVATED]
Expected result: You record Assigned or Not Assigned for Floor 6 Legal group.

11. If Friday app assignment is confirmed and evidence links shortcut loss to app rollout, remove Floor 6 assignment. [ELEVATED]
Action:
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.Read.All"
$app = Get-MgDeviceAppManagementMobileApp -All | Where-Object { $_.DisplayName -match "Document.*Management|FinBridge" } | Select-Object -First 1
$floor6Group = Get-MgGroup -Filter "displayName eq 'Floor 6 Legal'"
$assignments = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id
$targetAssignment = $assignments | Where-Object {
  $_.Target.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.groupAssignmentTarget' -and
  $_.Target.AdditionalProperties['groupId'] -eq $floor6Group.Id
}
if ($targetAssignment) {
  Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $targetAssignment.Id
}
```
Expected result: Floor 6 app assignment is removed and no longer visible in app assignments.

12. Trigger Intune sync on 1 pilot affected device. [ELEVATED]
Expected result: Device check-in time updates and policy/app state refresh begins.

13. Ask pilot user to sign out and sign back in once.
Expected result: One clean login cycle is completed.

14. Re-check user desktop shortcut list on the pilot device.
Expected result: Missing shortcuts are restored or remain missing with updated evidence.

15. Continue to next affected devices only if pilot result is stable.
Expected result: Controlled rollout decision is documented in the ticket.

## 3. Verification

1. Verify the affected user now sees required desktop shortcuts.
Expected result: User confirms required shortcuts are visible and usable.

2. Open at least two restored shortcuts and verify application launch.
Expected result: Shortcuts open correct applications or locations.

3. Re-run profile error check after remediation. [ELEVATED]
Action:
```powershell
Get-EventLog System -After (Get-Date).AddHours(-2) -InstanceId 1509,1516 | Select-Object TimeGenerated, InstanceId, Message
```
Expected result: No new profile errors are logged after the fix.

4. Validate two additional affected devices with the same check.
Expected result: Symptom behavior is consistent across sampled devices.

5. Confirm Service Desk is not receiving new shortcut-loss reports from Floor 6.
Expected result: No new matching tickets for at least one monitoring interval.

6. Close only this Desktop/Profile incident stream when all checks pass.
Expected result: Ticket is closed with evidence and without impacting other streams.

## 4. Rollback

Use these actions immediately if shortcut behavior worsens after assignment removal or remediation.

1. Reconnect to Graph with write scopes. [ELEVATED]
Action:
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.Read.All"
```
Expected result: Graph session is active.

2. Re-open Intune app assignments for the same app and capture current state screenshot. [ELEVATED]
Expected result: You have rollback evidence of current assignment state.

3. Re-add Floor 6 Legal group to the previous app assignment in Intune. [ELEVATED]
Expected result: Assignment is restored to prior state.

4. Remove any temporary uninstall/exclusion assignment created during remediation. [ELEVATED]
Expected result: Only intended original assignments remain.

5. Trigger Intune sync on the same pilot device first. [ELEVATED]
Expected result: Pilot device receives rollback state before wider rollout.

6. Ask pilot user to sign out and sign back in once.
Expected result: Pilot user session reflects rollback state.

7. Re-check shortcut list on pilot user desktop.
Expected result: You confirm whether rollback improved or worsened state.

8. Stop broad rollout immediately if pilot rollback worsens symptoms.
Expected result: No additional users are impacted.

9. Escalate to Desktop Engineering and Intune Engineering with collected evidence bundle. [ELEVATED]
Expected result: Senior teams receive logs, assignment history, and comparison outputs.

## 5. Notes

- Treat this as separate from the Copilot incident unless evidence proves a direct link.
- Treat this as separate from login/auth failures unless shared telemetry proves a common cause.
- Do not assume Friday app caused the shortcut issue without evidence from logs and assignment timing.
- Do not delete user profile folders as a first action in this runbook.
- If temporary profile indicators are found (for example username.000), escalate before destructive profile actions.
- Any Copilot unauthorized data report requires immediate security escalation in its own ticket stream.
