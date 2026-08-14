# Runbook: Floor 6 Login/Performance Incident Response
Date: 2026-08-14
Scope: Floor 6 Legal (45 users)
Audience: DWP Service Desk and Endpoint Engineers
Use case: Engineer is following this cold under pressure

## 1) Prerequisites

1. Confirm you are assigned incident owner in the ticket system.
Expected result: Ticket shows you as active owner.

2. Confirm impact scope is Floor 6 Legal only.
Expected result: Ticket notes show affected cohort is 45 users on Floor 6.

3. Obtain local administrator access on at least one affected endpoint.
Expected result: You can open an elevated PowerShell window on the test endpoint.

4. Obtain Microsoft Intune Administrator access. [ELEVATED]
Expected result: You can open Intune Admin Center and view policy assignments.

5. Obtain Azure AD Conditional Access read access. [ELEVATED]
Expected result: You can open Entra sign-in logs and Conditional Access outcomes.

6. Obtain Microsoft Graph PowerShell access with app management scopes. [ELEVATED]
Expected result: Graph connection works and returns app objects.

7. Confirm the diagnostic script exists on your workstation: Floor6-LoginDiagnostic-HandCorrected.ps1.
Expected result: Script is present and executable.

8. Create output folder C:\Diagnostic_Results on the test endpoint.
Expected result: Folder exists and is writable.

9. Identify one pilot group of 5 devices and record hostnames.
Expected result: You have a fixed pilot list before any remediation.

10. Start an incident bridge channel for updates.
Expected result: Floor lead and Service Desk see a live update channel.

## 2) Procedure

1. Run diagnostic collection on one affected pilot device. [ELEVATED]
Action:
```powershell
.\Floor6-LoginDiagnostic-HandCorrected.ps1 -CollectDiagnostics -OutputPath "C:\Diagnostic_Results"
```
Expected result: A JSON output file is created in C:\Diagnostic_Results.

2. Open the newest diagnostic JSON file.
Expected result: You can read AppDeployment, IntuneManagement, and EventLogs sections.

3. Check whether AppDeployment.AppsInstalledInDeploymentWindow contains at least one target app.
Expected result: You record YES or NO for app-in-window.

4. Check whether IntuneManagement.ErrorsFound contains installation, timeout, restart loop, or detection failures.
Expected result: You record YES or NO for IME deployment errors.

5. Check whether EventLogs.SecurityLog.FailedLogins has a Monday morning spike.
Expected result: You record YES or NO for auth failure spike.

6. Set incident path to App Deployment Confirmed only if steps 3, 4, and 5 are all YES.
Expected result: You have a single explicit path decision documented in ticket notes.

7. Set incident path to Intune or CA investigation if any of steps 3, 4, or 5 is NO.
Expected result: You do not perform app rollback on incomplete evidence.

8. Connect to Graph for app assignment operations. [ELEVATED]
Action:
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.Read.All"
```
Expected result: Graph session is connected without errors.

9. Resolve the target app object. [ELEVATED]
Action:
```powershell
$app = Get-MgDeviceAppManagementMobileApp -All |
  Where-Object { $_.DisplayName -match "Document.*Management|FinBridge" } |
  Select-Object -First 1
```
Expected result: Variable $app contains one app with a valid Id.

10. Resolve the Floor 6 group object. [ELEVATED]
Action:
```powershell
$floor6Group = Get-MgGroup -Filter "displayName eq 'Floor 6 Legal'"
```
Expected result: Variable $floor6Group contains one group with a valid Id.

11. Get current assignments for the target app. [ELEVATED]
Action:
```powershell
$assignments = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id
```
Expected result: Variable $assignments contains current app assignments.

12. Select the Floor 6 assignment entry. [ELEVATED]
Action:
```powershell
$targetAssignment = $assignments | Where-Object {
  $_.Target.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.groupAssignmentTarget' -and
  $_.Target.AdditionalProperties['groupId'] -eq $floor6Group.Id
}
```
Expected result: Variable $targetAssignment contains one assignment or null.

13. Remove the Floor 6 assignment if it exists. [ELEVATED]
Action:
```powershell
if ($targetAssignment) {
  Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $targetAssignment.Id
}
```
Expected result: Floor 6 is no longer in active app assignment.

14. Add Floor 6 to uninstall assignment in Intune if uninstall is configured. [ELEVATED]
Expected result: Intune shows uninstall intent for Floor 6 group.

15. Restrict active deployment ring to IT Test Group only. [ELEVATED]
Expected result: Intune assignments show test ring only for install intent.

16. Trigger device sync for the 5 pilot devices. [ELEVATED]
Expected result: Pilot devices show recent check-in and policy/app sync start.

17. Ask pilot users to sign out and sign back in once.
Expected result: Pilot users complete one fresh login cycle.

18. Record pilot login duration for each of the 5 pilot devices.
Expected result: You have measurable before/after login timing.

19. Proceed to Wave 2 only if all 5 pilot logins are successful.
Expected result: Go or no-go decision is documented in incident notes.

20. Apply same assignment removal/uninstall state to next 10 devices by group wave. [ELEVATED]
Expected result: Wave 2 devices receive same app state as pilot.

21. Proceed to Wave 3 only if Wave 2 has no regression reports.
Expected result: Go or no-go decision is documented in incident notes.

22. Apply same assignment removal/uninstall state to remaining 30 devices. [ELEVATED]
Expected result: All 45 users are covered by the same remediation state.

23. Post a status update to Floor 6 after each wave completes.
Expected result: Users receive progress updates without promised completion time.

24. If app path was not confirmed at step 6, run Intune/CA path checks instead of app rollback. [ELEVATED]
Expected result: Remediation stays evidence-driven and avoids wrong rollback.

## 3) Verification

1. Re-run diagnostic collection on 1 device from each wave. [ELEVATED]
Action:
```powershell
.\Floor6-LoginDiagnostic-HandCorrected.ps1 -CollectDiagnostics -OutputPath "C:\Diagnostic_Results"
```
Expected result: New JSON files exist for Wave 1, Wave 2, and Wave 3 samples.

2. Confirm AppDeployment.AppsInstalledInDeploymentWindow is empty on sampled devices.
Expected result: Target app is no longer present in deployment window evidence.

3. Confirm IntuneManagement.ErrorsFound no longer shows active install/restart loop patterns.
Expected result: IME error volume is reduced or absent for target app.

4. Confirm EventLogs.SecurityLog.FailedLogins does not show continuing spike.
Expected result: Failed login events are normalizing.

5. Validate 5 random user sign-ins across Floor 6.
Expected result: Users can sign in without excessive delay.

6. Confirm Service Desk queue is no longer receiving new Floor 6 login incidents.
Expected result: No new clustered login tickets for Floor 6.

7. Close incident only after two consecutive monitoring checks show stable state.
Expected result: Ticket closure is backed by evidence and stability checks.

## 4) Rollback

Use this section immediately if symptoms worsen after remediation.

1. Reconnect to Graph with write scopes. [ELEVATED]
Action:
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.Read.All"
```
Expected result: Graph session is active.

2. Re-resolve app and Floor 6 group objects. [ELEVATED]
Action:
```powershell
$app = Get-MgDeviceAppManagementMobileApp -All |
  Where-Object { $_.DisplayName -match "Document.*Management|FinBridge" } |
  Select-Object -First 1
$floor6Group = Get-MgGroup -Filter "displayName eq 'Floor 6 Legal'"
```
Expected result: $app.Id and $floor6Group.Id are populated.

3. Restore previous install assignment for Floor 6 in Intune. [ELEVATED]
Expected result: Floor 6 is back on original assignment state.

4. Remove Floor 6 from uninstall assignment in Intune. [ELEVATED]
Expected result: Uninstall intent is no longer targeted to Floor 6.

5. Trigger sync on 5 pilot devices only. [ELEVATED]
Expected result: Pilot devices receive rollback state first.

6. Validate pilot login behavior before wider rollback.
Expected result: Pilot outcome confirms whether rollback helps or harms.

7. Apply rollback to remaining waves only if pilot rollback is stable. [ELEVATED]
Expected result: Controlled rollback prevents full-floor re-impact.

8. If rollback fails to stabilize login, stop app-path changes immediately.
Expected result: No further harmful changes are introduced.

9. Switch incident path to Intune policy and CA investigation. [ELEVATED]
Expected result: Team focuses on alternate confirmed evidence path.

10. Escalate to Intune and Identity on-call leads with collected JSON and log artifacts. [ELEVATED]
Expected result: Senior teams receive complete evidence bundle for rapid intervention.

## 5) Notes

- Treat this as three separate incident streams unless evidence proves one common cause:
  - Login/performance
  - Copilot unauthorized access concern
  - Desktop shortcuts/profile behavior

- Copilot unauthorized access concern requires immediate security escalation and must not be handled as routine support.

- Do not execute app rollback unless all three app-causation checks are true:
  - App installed in Friday deployment window
  - Intune Management Extension shows relevant deployment errors
  - Monday auth/event spike is present

- Elevated permissions are required for Graph write actions, Intune assignment edits, and some endpoint diagnostics.

- If Graph commands are blocked by tenant policy, perform the same assignment changes in Intune Admin Center UI and capture screenshots for evidence.

- Avoid fixed restoration promises in user communication; provide factual wave-by-wave updates only.
