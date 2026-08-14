# L2/L3 KB: Floor 6 Login / Performance Incident
**v 1.0, 07/08/2026, status : Draft**

## Background
Floor 6 Legal runs on Windows 11 devices managed through Intune, Entra ID, and standard Microsoft 365 identity controls. Users must be able to sign in, receive policy, and open core legal applications quickly because the floor supports live client work, document access, and time-sensitive legal operations.

This incident is about sign-in failure or very slow sign-in after recent platform changes. It is not the Copilot security issue and not the desktop shortcut issue unless a shared root cause is later proven.

## Symptom
The engineer will usually hear one of two reports:

- "I cannot log in."
- "I can log in, but it takes a long time."

What the engineer may observe:

- Multiple users on Floor 6 are affected at the same time.
- Some users fail during sign-in, while others eventually sign in but only after a long delay.
- The issue starts during Monday morning sign-in, not as a random one-off later in the day.
- The user may not know whether the delay is caused by password, lockout, policy processing, profile loading, or a device/app issue.

## Root Cause
The most likely technical cause is a shared Floor 6 configuration or deployment problem that affects sign-in processing. Based on the runbook and RCA, the leading candidates are:

1. A floor-wide Intune or policy change that delays or blocks authentication processing.
2. A Windows 11 profile or sign-in processing issue that causes long delays during profile load.
3. A Friday document management app deployment that triggered a logon script, policy conflict, or app startup issue.
4. A lockout or conditional access problem affecting a cohort rather than one user.

The issue is confirmed when the evidence shows all three of these together:

- The target app was installed or assigned during the Friday deployment window.
- The Intune Management Extension logs show installation, timeout, restart loop, or detection failures.
- The Monday morning sign-in logs or security logs show a corresponding spike in failed logons, lockouts, or slow sign-in behavior.

If those facts are not all present, do not call the app the cause yet. Move to the Intune, policy, or conditional access path instead.

## Detection
Use the evidence below to confirm the issue before changing anything.

### 1. Collect the local diagnostic bundle first
Path: affected endpoint

Command:
```powershell
.\Floor6-LoginDiagnostic-HandCorrected.ps1 -CollectDiagnostics -OutputPath "C:\Diagnostic_Results"
```

What to look for in the output JSON:
- `AppDeployment.AppsInstalledInDeploymentWindow`
- `IntuneManagement.ErrorsFound`
- `EventLogs.SecurityLog.FailedLogins`

Expected result:
- You have one JSON file on the test device that can be used to decide whether this is app, Intune, or auth related.

### 2. Check Entra sign-in logs
Path: Entra admin center > Monitoring & health > Sign-in logs

What to look for:
- User sign-ins from Floor 6 around Monday morning.
- Status = Failure, Interrupted, or unusually long sign-in duration.
- Conditional Access blocks or repeated failed sign-in attempts.
- Device or location clustering across Floor 6.

Event IDs / log clues:
- In the local Security log, failed authentication may align with Event ID 4625.
- If users are being locked out, watch for Event ID 4740 on the domain controller or identity log source.

Expected result:
- A cluster of failures or lockouts around the same time window supports a shared sign-in issue.

### 3. Check the affected machine logs
Path: affected endpoint > Event Viewer and file system logs

What to look for:
- Windows Security log: Event ID 4625 for failed logons.
- Domain controller security logs: Event ID 4740 for account lockouts, Event ID 4722 for account unlocks if recovery has started.
- System log on the endpoint: profile, startup, or service delays if the sign-in is slow rather than failed.
- Intune Management Extension logs: `%ProgramData%\Microsoft\IntuneManagementExtension\Logs\`

What to look for in IME logs:
- Install failures
- Timeout loops
- Restart loops
- Detection failures
- Policy processing delay around the Monday morning window

Expected result:
- IME errors combined with sign-in delays point to a deployment or policy trigger.

### 4. Check whether a floor-specific app was installed in the Friday window
Path: Intune admin center > Apps > All apps > <document management app>

What to look for:
- Assignment to Floor 6 Legal.
- Install or uninstall intent.
- Timestamp aligned to Friday afternoon.

Expected result:
- If the app landed in the Friday window and the logs show failures, the app path is confirmed.

### 5. Check policy and update history on the device
Path: affected endpoint > Settings > Windows Update > Update history
Path: affected endpoint > gpresult.html or equivalent policy report

What to look for:
- Overnight Windows Update or driver changes.
- New policy application after Intune enrollment.
- Desktop or sign-in policy changes that started after the Windows 11 move.

Expected result:
- If there is no app proof, policy/update history becomes the next most likely branch.

## Resolution
Follow the branch that matches the evidence. Do not remove app assignments without confirming the app path.

### Branch A: Friday app deployment is confirmed

### 1. Open the app record in Intune
Path: Intune admin center > Apps > All apps > <document management app>

Expected result:
- You can see the Floor 6 Legal assignment and confirm the deployment scope.

### 2. Remove the Floor 6 Legal assignment or move it to the test ring only
Path: Intune admin center > Apps > All apps > <document management app> > Assignments

Action:
- Remove the Floor 6 group assignment from install.
- If uninstall is configured, assign uninstall to Floor 6.
- Restrict the install ring to the IT test group only.

Expected result:
- Floor 6 is no longer targeted for the problem app.

### 3. Trigger sync on the pilot devices
Path: Company Portal or Intune device sync

Action:
- Sync the five pilot devices first.
- Ask pilot users to sign out and sign back in once.

Expected result:
- Pilot devices receive the updated assignment state and sign-in time improves or normalizes.

### 4. Roll out in waves only if the pilot is stable
Action:
- Proceed to the next group only after the pilot signs in successfully and no regression appears.

Expected result:
- The fix is applied gradually and safely.

### Branch B: App path is not confirmed

### 1. Stay on the Intune or Conditional Access path
Path: Entra admin center > Monitoring & health > Sign-in logs
Path: Intune admin center > Devices > Windows

Action:
- Check policy delivery.
- Check conditional access outcomes.
- Check for lockout or authentication spikes.

Expected result:
- You identify whether this is a policy, identity, or network issue before making app changes.

## Verification
Confirm the fix worked before closing the incident.

1. Re-run the diagnostic collection on one device from each wave.
Expected result: New JSON output shows no active app deployment errors and no continuing failed login spike.

2. Check the sign-in logs again.
Expected result: Sign-in duration returns to normal and failed or interrupted sign-ins stop clustering.

3. Confirm the pilot users can sign in without delay.
Expected result: Pilot users complete a normal login cycle.

4. Check the Service Desk queue.
Expected result: No new Floor 6 login tickets appear during the monitoring window.

## Rollback
If the fix makes the problem worse, reverse only the last confirmed change.

### If the app rollback worsens the issue

1. Re-open the app assignment in Intune.
Path: Intune admin center > Apps > All apps > <document management app> > Assignments

2. Restore the previous Floor 6 install assignment.

3. Remove any uninstall assignment for Floor 6.

4. Sync the five pilot devices only.

5. Validate pilot login behavior before any wider rollback.

Expected result:
- The environment returns to the last known stable assignment state.

### If the issue is not app-related

1. Stop app-path changes immediately.
2. Escalate to Intune and Identity with the JSON bundle, sign-in logs, and IME logs.

Expected result:
- The team pivots to the correct root-cause path without causing more disruption.

## Preventive
Put this control in place so the issue is caught before Monday morning:

**Friday Floor 6 Sign-In Canary**

Before any Windows 11, Intune, or floor-specific app change is released to all of Floor 6 Legal, one pilot user must complete a successful sign-in on a pilot device after the change is applied. The canary must include a normal login, a policy refresh, and a timing check.

Why this works:
- It catches sign-in failure, long login delay, policy conflicts, and app-induced login regressions on Friday instead of Monday morning.

## Related
- [Runbook: Floor 6 Login/Performance Incident Response](RUNBOOK-Floor6-LoginPerformance-20260814.md)
- [RCA - Floor 6 Login/Performance Incident](RCA-Floor6-LoginPerformance-20260814.md)
- [CRITICAL: Authentication & Login Crisis – Floor 6 Legal Department](INCIDENT-CRITICAL-Authentication-LoginCrisis-Floor6-20260814.md)
- [Prevention Note: Floor 6 Login / Performance](PREVENTION-NOTE-Floor6-LoginPerformance-20260814.md)
- [L2/L3 KB: Floor 6 Desktop Shortcuts / Profile Symptom](L2-L3-KB-DesktopShortcuts-Floor6-20260814.md)