# RCA - Floor 6 Desktop Shortcuts/Profile Symptom
Date: 2026-08-14
Scope: Floor 6 Legal
Incident Time: 09:14

## Findings
- A user reported desktop shortcuts disappeared.
- This symptom is likely separate from the Copilot security concern.
- This may also be separate from login/auth failures unless shared evidence later proves a common trigger.
- Root cause cannot be confirmed from supplied evidence.

## Supporting Evidence
- Floor 6 recently had Windows 11 migration and Intune enrollment, both known to affect profile behavior and desktop configuration.
- Reported symptom is post-login profile/desktop state, not necessarily authentication failure.

## Contradicting Evidence
- No event log, profile service log, or policy output was supplied to prove profile corruption.
- No evidence yet that the Friday app removed shortcuts.
- Only one direct report is provided in evidence.

## Confidence Level
Low

## Root Cause Statement
Condition:
- User reports missing desktop shortcuts after recent platform changes.

Cause:
- Unconfirmed. Evidence is insufficient to determine whether this is profile corruption, policy behavior, migration artifact, or app side effect.

Impact:
- User productivity impact, but not currently a confirmed security incident.

Evidence:
- Single user report plus recent migration/enrollment context.
- No confirming logs provided.

## Technical Action <Exact command, script, rollback step, exclusion action, or remediation action>
Run non-destructive checks first:

```powershell
# Profile-related event check
Get-EventLog System -After (Get-Date).AddDays(-2) -InstanceId 1509,1516 | Select-Object TimeGenerated, InstanceId, Message

# Check user and public desktop shortcut presence
Get-ChildItem "$env:USERPROFILE\Desktop" -Filter *.lnk -ErrorAction SilentlyContinue | Select-Object Name, LastWriteTime
Get-ChildItem "C:\Users\Public\Desktop" -Filter *.lnk -ErrorAction SilentlyContinue | Select-Object Name, LastWriteTime
```

If evidence later confirms Friday app changed desktop/startup behavior, remove Floor 6 assignment first before wider rollback:

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

## User Communication
Floor 6 team,

We know some users are seeing missing desktop shortcuts. We are checking this as a separate issue from the login and Copilot incidents so we can fix each problem correctly. Right now we are gathering device evidence and validating whether this is a profile or policy effect from recent changes. We will provide updates as findings are confirmed.
