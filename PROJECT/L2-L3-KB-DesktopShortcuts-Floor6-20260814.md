# L2/L3 KB: Floor 6 Desktop Shortcuts / Profile Symptom
**v 1.0, 07/08/2026, status : Draft**

## Background
Floor 6 Legal devices are managed through Windows 11, Intune, and standard user profile mechanisms. Desktop shortcuts matter because they are the primary launch path for legal productivity apps, line-of-business tools, and mapped resources; when they disappear, users can still sign in but lose efficient access to the tools they need.

This incident is a post-login desktop/profile issue. It is not a Copilot security event and not an authentication outage, unless another incident proves a shared trigger.

## Symptom
The engineer typically sees a user with a normal sign-in who reports that desktop icons or shortcuts have vanished after login. Common user statements are:

- "My desktop shortcuts are gone."
- "My desktop looks reset."
- "My wallpaper, taskbar, or desktop customizations disappeared after sign-in."
- "The apps are still installed, but the shortcuts are missing."

What the engineer may observe:

- The user can log in successfully.
- The desktop folder is empty or missing expected .lnk files.
- One or more shortcuts may still exist in the Public desktop or Start Menu paths.
- The affected user may be in a temporary or failed profile state such as .000.
- Multiple Floor 6 users may report the same symptom after Windows 11 migration, Intune enrollment, or a Friday app deployment.

## Root Cause
The technical root cause is usually one of three things:

1. User profile load failure or partial profile creation after Windows 11 migration. The user signs in, but Windows does not load the normal profile correctly and shortcuts/settings do not appear.
2. Intune policy, Group Policy, or app deployment removed, hid, or failed to restore desktop shortcuts during the Floor 6 rollout.
3. The Friday document management app altered the desktop or profile state indirectly through deployment actions, shell integration, or post-install tasks.

The confirming evidence depends on the branch:

- Profile branch is confirmed when Event ID 1509 or 1516 appears in the System log and the user is in a temporary profile path such as C:\Users\username.000.
- Policy/app branch is confirmed when profile events are absent, shortcut files are missing from the user and Public desktop paths, and Intune or app assignment logs show a change in the incident window.

The key point is that the symptom is not a Windows 11 cosmetic issue by itself. It is a profile, policy, or app-state change that removed the user-visible .lnk files or prevented the normal profile from loading.

## Detection
Confirm the issue with evidence before changing anything.

### 1. Check the user profile path
Path: affected device > File Explorer or PowerShell

What to look for:
- Normal profile path: C:\Users\<username>
- Temporary profile path: C:\Users\<username>.000 or another suffix

Expected result:
- If the user is in a temporary profile, the profile branch is strongly indicated.

### 2. Check Windows System event log for profile errors
Path: Event Viewer > Windows Logs > System

Event IDs to check:
- 1509: User Profile Service failed the sign-in.
- 1516: Windows detected that the registry is still in use by other applications or services during profile handling.

PowerShell example:
```powershell
Get-EventLog System -After (Get-Date).AddDays(-2) -InstanceId 1509,1516 | Select-Object TimeGenerated, InstanceId, Message
```

What to look for:
- Errors at the first login after Windows 11 migration or after the weekend.
- Messages referencing profile load failure, user hive issues, or redirected profile problems.

Expected result:
- Presence of 1509 or 1516 supports profile load failure as the root cause.

### 3. Check the actual desktop folders
Paths:
- C:\Users\<username>\Desktop
- C:\Users\Public\Desktop
- C:\Users\<username>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs

What to look for:
- Missing .lnk files in the user desktop folder.
- Shortcuts that still exist in Public Desktop or Start Menu, which tells you the application is still installed and only the user desktop is affected.
- Empty desktop folder after sign-in.

Expected result:
- If shortcuts exist in Start Menu or Public Desktop but not the user desktop, the issue is likely profile or desktop-state specific, not an app removal issue.

### 4. Check group policy and Intune state
Path: Intune admin center > Devices > Windows > <device> > Device configuration / Compliance
Path: Run gpresult on the affected device

What to look for:
- Policies referencing desktop, shell, Start Menu, taskbar, or user customization restrictions.
- New or changed policies applied around Friday afternoon or the first affected login.
- App deployment or assignment changes for the Friday document management app.

Useful checks:
```powershell
gpresult /h C:\Diagnostic_Results\gpresult.html
Get-ChildItem "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs" -ErrorAction SilentlyContinue
```

Expected result:
- If a policy or deployment change lines up with the symptom and profile errors are absent, the issue is policy/app driven.

### 5. Check application deployment logs if the Friday app is suspected
Path: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ and the app deployment record in Intune

What to look for:
- Installation time aligned to Friday afternoon.
- Installation failure, timeout, restart loop, or post-install actions that touch shell or profile settings.
- Assignment to Floor 6 Legal in Intune.

Expected result:
- A deployment or assignment change at the incident window supports the app branch.

## Resolution
Follow the branch that matches the evidence.

### Branch A: Profile load failure

### 1. Preserve user data first
Path: affected device

Action:
- Back up user data if the local profile contains anything not already redirected or synced.
- Record the profile path, event log evidence, and missing shortcut list.

Expected result:
- You have evidence before any profile repair.

### 2. Repair the corrupted profile
Path: Windows on the affected device > System Properties > User Profiles or PowerShell

Action:
- Remove the corrupted local profile only after evidence capture and backup.
- Allow the user to sign out and sign back in to generate a clean profile.

PowerShell example:
```powershell
Remove-Item "C:\Users\<username>" -Recurse -Force
```

Expected result:
- Windows creates a fresh profile on the next sign-in.
- Desktop shortcuts and default shell items begin to reappear from the normal profile template or redirected storage.

### 3. Verify redirected or synced data
Path: OneDrive, folder redirection, or user data restore path

Action:
- Confirm Documents, Downloads, and other user data are still available.

Expected result:
- User data remains intact and only the local shell state was rebuilt.

### Branch B: Policy or app removed shortcuts

### 1. Confirm the app or policy assignment
Path: Intune admin center > Apps > All apps > <document management app> > Assignments

Action:
- Verify whether Floor 6 Legal is assigned.
- Check whether the deployment coincides with the symptom window.

Expected result:
- You can tie the symptom to a policy or app change, or rule it out.

### 2. Remove the Floor 6 assignment if evidence links the app to shortcut loss
Path: Intune admin center > Apps > All apps > <document management app> > Assignments

Action:
- Remove the Floor 6 Legal group assignment or move it to a smaller pilot ring.

Expected result:
- The app no longer pushes the behavior to the cohort.

### 3. Sync the pilot device
Path: Company Portal or Intune device sync

Action:
- Trigger a policy sync on one affected pilot device.
- Ask the pilot user to sign out and sign back in once.

Expected result:
- The device receives the updated assignment state and shortcuts either return or the symptom stops progressing.

### 4. Restore shortcuts if the files were deleted but the app is still installed
Path: Start Menu, installed application folder, or shortcut source location

Action:
- Re-create the required shortcuts from the application install path or Start Menu entry.

Expected result:
- The user has working launch points again without altering the application itself.

## Verification
Confirm the fix worked before closing the ticket.

1. The user can see the required desktop shortcuts again.
Expected result: The user confirms the desktop is usable.

2. At least two restored shortcuts open the correct applications.
Expected result: Launches succeed and point to the correct app or folder.

3. Re-run the profile error check.
Expected result: No new 1509 or 1516 entries appear after remediation.

4. Confirm the profile path is normal.
Expected result: The user is in C:\Users\<username> and not a temporary profile.

5. Confirm no new reports from the Floor 6 queue.
Expected result: The incident does not recur during the monitoring window.

## Rollback
If the fix makes things worse, reverse only the last change and stop broad rollout.

### If profile repair worsens the issue

1. Stop deleting or replacing additional profiles.
2. Restore the backed-up profile data if a backup was taken.
3. Escalate to Desktop Engineering and avoid further destructive profile actions.

Expected result:
- You preserve user data and prevent wider profile loss.

### If Intune or app rollback worsens the issue

1. Re-open the app assignment in Intune and restore the previous Floor 6 Legal assignment.
Path: Intune admin center > Apps > All apps > <document management app> > Assignments

2. Trigger sync on the pilot device only.

3. Ask the pilot user to sign out and back in once.

4. If the pilot worsens, stop rollout immediately and escalate with the evidence bundle.

Expected result:
- The assignment state returns to the last known good configuration before any wider impact occurs.

## Preventive
Put the following controls in place to stop recurrence:

- Validate user profile health after Windows 11 migration before declaring the device ready.
- Add a post-enrollment check that compares the user desktop, Public desktop, and Start Menu shortcut inventory.
- Require a pilot ring for any app that can touch shell, profile, or desktop state.
- Review Intune and Group Policy changes for desktop, taskbar, and Start Menu behavior before Floor 6-wide release.
- Keep a standard shortcut baseline for legal users so missing launch points can be restored quickly.

## Related
- [Runbook: Floor 6 Desktop Shortcuts/Profile Symptom](RUNBOOK-Floor6-DesktopShortcuts-20260814.md)
- [RCA - Floor 6 Desktop Shortcuts/Profile Symptom](RCA-Floor6-DesktopShortcuts-20260814.md)
- [HIGH: Desktop Profile Corruption – Missing Shortcuts & Desktop Settings](INCIDENT-HIGH-ProfileCorruption-DesktopShortcuts-Floor6-20260814.md)
- [L1 Self-Service KB: Missing Desktop Shortcuts (Floor 6)](L1-KB-DesktopShortcuts-Floor6-20260807.md)
- [L2/L3 KB: Copilot Unauthorized Data Access - Floor 6 Legal](L2-L3-KB-Copilot-UnauthorizedAccess-Floor6-20260814.md)