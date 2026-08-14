# RCA - Floor 6 Login/Performance Incident
Date: 2026-08-14
Scope: Floor 6 Legal (45 users)
Incident Time: 09:14

## Findings
- A large number of users on Floor 6 reported login failure or very slow login.
- Floor 6 was recently migrated to Windows 11 and enrolled in Intune.
- A new document management application was deployed Friday afternoon.
- Based only on supplied evidence, a single confirmed root cause cannot yet be proven.
- This must be handled as a separate incident stream from Copilot data exposure and desktop shortcut loss.

## Supporting Evidence
- Impact is cohort-level ("at least a dozen" in a 45-user floor), which points to a shared configuration, policy, or deployment factor.
- The issue appeared after recent platform and management changes (Windows 11 migration + Intune enrollment).
- A floor-specific app deployment occurred on Friday.

## Contradicting Evidence
- No hard evidence was provided that the Friday app directly caused login failures.
- No provided sign-in logs, Intune failure logs, or event logs confirm whether auth failure, policy delay, profile load delay, or app startup conflict is the trigger.
- Some users reported different symptoms (can’t log in vs very slow login), which may indicate more than one mechanism.

## Confidence Level
Low

## Root Cause Statement
Condition:
- Monday morning, Floor 6 users cannot log in or experience severe login delays.

Cause:
- Not yet confirmed from supplied evidence. Most likely this is a shared configuration/deployment issue in the Floor 6 cohort, but evidence is currently insufficient to confirm one cause.

Impact:
- Significant productivity disruption for Legal operations.

Evidence:
- Cohort-level impact, recent Windows 11 and Intune changes, and Friday app deployment are known facts.
- No direct telemetry evidence provided to confirm causal link.

## Technical Action <Exact command, script, rollback step, exclusion action, or remediation action>
Immediate safe triage command (evidence collection first):

```powershell
.\Floor6-LoginDiagnostic-HandCorrected.ps1 -CollectDiagnostics -OutputPath "C:\Diagnostic_Results"
```

If and only if evidence confirms Friday app deployment as the cause (app installed in deployment window + IME errors + Monday auth/event spike), execute rollback ring removal in Intune via Graph PowerShell:

```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.Read.All"

$app = Get-MgDeviceAppManagementMobileApp -All |
  Where-Object { $_.DisplayName -match "Document.*Management|FinBridge" } |
  Select-Object -First 1

$floor6Group = Get-MgGroup -Filter "displayName eq 'Floor 6 Legal'"

$assignments = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id
$targetAssignment = $assignments |
  Where-Object {
    $_.Target.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.groupAssignmentTarget' -and
    $_.Target.AdditionalProperties['groupId'] -eq $floor6Group.Id
  }

if ($targetAssignment) {
  Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $targetAssignment.Id
}
```

## User Communication
Floor 6 team,

We know many of you are seeing login problems or very slow sign-in this morning, and we understand the disruption this is causing. We are actively investigating this as a high-priority issue and collecting technical evidence from affected devices now. We are also reviewing recent system changes on Floor 6 to identify and remove the cause safely. We will continue to share updates as we confirm facts.
