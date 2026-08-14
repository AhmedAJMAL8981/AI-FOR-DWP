# Runbook: Floor 6 Copilot Unauthorized Data Access Concern
Date: 2026-08-14
Scope: Floor 6 Legal
Incident type: Potential unauthorized client-matter exposure via Copilot
Priority: P1-SECURITY

## 1. Prerequisites

1. Open or upgrade the incident to P1-SECURITY in the ticket system.
Expected result: Ticket priority shows P1-SECURITY.

2. Assign Security, Compliance, and Legal as required responders in the ticket.
Expected result: All three responder groups are attached.

3. Obtain Microsoft 365 Global Admin or License Admin rights. [ELEVATED]
Expected result: You can manage user licenses and service plans.

4. Obtain Microsoft Graph PowerShell access with Group and User license scopes. [ELEVATED]
Expected result: You can connect with required scopes.

5. Confirm the target user group name is exactly Floor 6 Legal.
Expected result: Group name is verified in Entra.

6. Prepare an evidence log file location for command outputs.
Expected result: A writable folder exists for evidence exports.

7. Start a security bridge channel for live updates.
Expected result: Incident bridge is active with Security and Service Desk.

## 2. Procedure

1. Connect to Microsoft Graph with required scopes. [ELEVATED]
Action:
```powershell
Connect-MgGraph -Scopes "Group.Read.All","GroupMember.Read.All","User.ReadWrite.All","Organization.Read.All","Directory.Read.All"
```
Expected result: Graph session opens without scope errors.

2. Resolve the Floor 6 Legal group object. [ELEVATED]
Action:
```powershell
$floor6Group = Get-MgGroup -Filter "displayName eq 'Floor 6 Legal'"
```
Expected result: $floor6Group contains one group with a valid Id.

3. Export Floor 6 group members to evidence file. [ELEVATED]
Action:
```powershell
$members = Get-MgGroupMember -GroupId $floor6Group.Id -All
$members | Select-Object Id,AdditionalProperties | Out-File "C:\Diagnostic_Results\Floor6_GroupMembers.txt"
```
Expected result: Evidence file is created with member entries.

4. Discover tenant SKUs and identify Copilot SKU IDs. [ELEVATED]
Action:
```powershell
Get-MgSubscribedSku | Select-Object SkuId,SkuPartNumber,ServicePlans | Out-File "C:\Diagnostic_Results\Tenant_SKUs.txt"
```
Expected result: SKU export file exists for auditable selection.

5. Record the Copilot SKU ID used for containment in the ticket. [ELEVATED]
Expected result: Ticket contains the exact SkuId selected from Tenant_SKUs.txt.

6. Remove Copilot license assignment from one pilot user in Floor 6. [ELEVATED]
Action:
```powershell
$pilotUserId = $members[0].Id
Set-MgUserLicense -UserId $pilotUserId -AddLicenses @() -RemoveLicenses @("<COPILOT_SKU_ID>")
```
Expected result: Command returns success and pilot user license update completes.

7. Validate pilot user no longer has Copilot entitlement. [ELEVATED]
Action:
```powershell
Get-MgUserLicenseDetail -UserId $pilotUserId | Select-Object SkuId,SkuPartNumber
```
Expected result: Copilot SKU is absent from pilot user license details.

8. Remove Copilot license from remaining Floor 6 members in a controlled loop. [ELEVATED]
Action:
```powershell
foreach ($m in $members) {
  Set-MgUserLicense -UserId $m.Id -AddLicenses @() -RemoveLicenses @("<COPILOT_SKU_ID>")
}
```
Expected result: All Floor 6 users are processed without fatal errors.

9. Export post-change license state for all Floor 6 users. [ELEVATED]
Action:
```powershell
$report = foreach ($m in $members) {
  [pscustomobject]@{
    UserId = $m.Id
    LicenseCount = (Get-MgUserLicenseDetail -UserId $m.Id).Count
  }
}
$report | Export-Csv "C:\Diagnostic_Results\Floor6_PostContainment_LicenseState.csv" -NoTypeInformation
```
Expected result: CSV file is created for containment proof.

10. Preserve the reporting user session artifacts before device changes.
Expected result: Copilot prompt/output screenshots and incident notes are attached to ticket.

11. Submit formal security escalation note to Security and Legal.
Expected result: Ticket contains timestamped escalation note.

12. Issue Floor 6 user communication for precautionary containment.
Expected result: User message is sent and logged in ticket.

## 3. Verification

1. Confirm Copilot SKU is removed from 3 sampled Floor 6 users. [ELEVATED]
Action:
```powershell
$sample = $members | Select-Object -First 3
foreach ($s in $sample) { Get-MgUserLicenseDetail -UserId $s.Id | Select-Object SkuPartNumber }
```
Expected result: Copilot SKU is not present in sampled outputs.

2. Confirm no new Copilot access reports are opened from Floor 6 during monitoring window.
Expected result: No new related incidents appear in Service Desk queue.

3. Confirm Security team acknowledges evidence sufficiency for ongoing investigation.
Expected result: Security confirms containment and evidence intake in ticket.

4. Confirm Legal/Compliance decision on next communication step is recorded.
Expected result: Ticket includes approved communication direction.

5. Close only containment task, not the security investigation, until Security signs off.
Expected result: Containment marked complete and investigation remains active.

## 4. Rollback

Use rollback only with Security and Legal approval.

1. Reconnect to Graph with license write scopes. [ELEVATED]
Action:
```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All","Organization.Read.All","Directory.Read.All"
```
Expected result: Graph session is active.

2. Confirm the exact Copilot SKU ID from evidence file before reassigning. [ELEVATED]
Expected result: Correct SkuId is identified from Tenant_SKUs.txt.

3. Reassign Copilot SKU to one pilot Floor 6 user only. [ELEVATED]
Action:
```powershell
$copilotSku = "<COPILOT_SKU_ID>"
Set-MgUserLicense -UserId $pilotUserId -AddLicenses @(@{SkuId=$copilotSku}) -RemoveLicenses @()
```
Expected result: Pilot user license assignment succeeds.

4. Validate pilot user license details immediately. [ELEVATED]
Action:
```powershell
Get-MgUserLicenseDetail -UserId $pilotUserId | Select-Object SkuId,SkuPartNumber
```
Expected result: Copilot SKU is present for pilot user.

5. Stop rollback if pilot user reproduces unauthorized visibility.
Expected result: No wider re-enable occurs after negative pilot result.

6. Reassign Copilot SKU to remaining users only if pilot is clean and approved. [ELEVATED]
Action:
```powershell
foreach ($m in $members) {
  Set-MgUserLicense -UserId $m.Id -AddLicenses @(@{SkuId=$copilotSku}) -RemoveLicenses @()
}
```
Expected result: Controlled re-enable is completed only after approval.

7. Export post-rollback license state to CSV. [ELEVATED]
Action:
```powershell
$report = foreach ($m in $members) {
  [pscustomobject]@{
    UserId = $m.Id
    LicenseCount = (Get-MgUserLicenseDetail -UserId $m.Id).Count
  }
}
$report | Export-Csv "C:\Diagnostic_Results\Floor6_PostRollback_LicenseState.csv" -NoTypeInformation
```
Expected result: Rollback evidence file is attached to ticket.

## 5. Notes

- Treat this as a security incident stream and keep it separate from login/performance and desktop-shortcut streams.
- Do not promise restoration time to users during active security investigation.
- Do not modify or delete evidence artifacts from the reporting user device.
- Do not close the security incident based on containment alone.
- If Graph license operations are blocked by tenant policy, execute equivalent license removal in Microsoft 365 admin center and capture screenshots for evidence.
- If more than one user reports similar Copilot behavior, escalate severity review immediately with Security.

## User Communication

Floor 6 team,

We received a report of possible unexpected Copilot access to legal matter content. We are treating this as a security issue and investigating with priority. As a precaution, we are temporarily restricting Copilot access for Floor 6 while we validate permissions and audit evidence. We will share verified updates as they are confirmed.
