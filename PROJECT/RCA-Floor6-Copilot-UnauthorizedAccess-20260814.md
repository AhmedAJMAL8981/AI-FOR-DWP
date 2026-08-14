# RCA - Floor 6 Copilot Unauthorized Data Access Concern
Date: 2026-08-14
Scope: Floor 6 Legal
Incident Time: 09:14

## Findings
- A paralegal reported Copilot surfaced a client matter she believes she never had access to.
- Based on supplied evidence, this is a potential unauthorized data access event.
- This is not a normal support issue and must be treated as a security incident stream.
- Root cause cannot yet be confirmed from supplied evidence alone.

## Supporting Evidence
- Report describes possible access to data outside expected role boundaries.
- Data involved appears to be legal client matter information (high sensitivity).
- Potential confidentiality/compliance impact is high even with one confirmed report.

## Contradicting Evidence
- No audit logs were provided to confirm what data was shown, source system, or effective permissions at query time.
- No supplied evidence confirms whether direct access to the same data was possible outside Copilot.
- No evidence provided of broader spread beyond one reported user.

## Confidence Level
Medium

## Root Cause Statement
Condition:
- Reported possible unauthorized client-matter visibility through Copilot.

Cause:
- Unconfirmed. Possible access control or data connector permission issue, but supplied evidence is insufficient to confirm exact cause.

Impact:
- Potential confidentiality breach risk for legal matter data.

Evidence:
- User report indicates potential access beyond assigned matter scope.
- No audit/log proof provided yet for definitive cause.

## Technical Action <Exact command, script, rollback step, exclusion action, or remediation action>
Immediate security containment action (exact): temporarily disable Copilot availability for Floor 6 security group while preserving evidence.

```powershell
# Example containment command pattern (tenant admin / licensing team):
# Remove Copilot service plan from Floor 6 users via group-based licensing workflow.
# (Use your tenant's exact SKU and service plan IDs.)

Connect-MgGraph -Scopes "Group.ReadWrite.All","User.ReadWrite.All","Organization.Read.All"

$floor6Group = Get-MgGroup -Filter "displayName eq 'Floor 6 Legal'"
$members = Get-MgGroupMember -GroupId $floor6Group.Id -All

# Replace with your tenant values
$copilotSkuId = "<COPILOT_SKU_GUID>"
$copilotServicePlanId = "<COPILOT_SERVICEPLAN_GUID>"

foreach ($m in $members) {
  $uid = $m.Id
  Set-MgUserLicense -UserId $uid -AddLicenses @() -RemoveLicenses @($copilotSkuId)
}
```

Security escalation action (mandatory):
- Open/upgrade incident as P1-SECURITY and notify Security + Compliance + Legal immediately.

## User Communication
Floor 6 team,

We have received a report of possible unexpected Copilot access to legal matter content. We are treating this as a security issue and have started a priority investigation. As a precaution, we may temporarily restrict Copilot access for some users while we validate permissions and logs. Your core systems remain under active monitoring, and we will share verified updates as soon as they are available.
