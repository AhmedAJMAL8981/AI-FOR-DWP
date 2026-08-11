# Root Cause Analysis — Autopilot Enrolment Failure
**Reference:** INC-2024-031501  
**Device:** DESKTOP-FB099  
**User:** FINBRIDGE\rthomas  
**Date of Incident:** 2024-03-15  
**Date of RCA:** 2024-03-15  
**Analyst:** DWP MDM Team  
**Status:** Root Cause Confirmed — Remediation Defined  
**Severity:** Medium — single device, no data loss, user blocked from provisioned workstation  

---

## 1. Incident Description

On 2024-03-15 at 09:18, device DESKTOP-FB099 failed Windows Autopilot enrolment during scheduled provisioning for user FINBRIDGE\rthomas. The Autopilot flow halted immediately at the enrolment stage with error `0x80180014`. No Intune configuration or compliance profiles were applied. The device was left in a non-compliant, unmanaged state and could not be issued to the user.

A full MDM diagnostic export was captured at 09:22 on the same date and forms the primary evidence base for this analysis.

---

## 2. Supporting Evidence

### 2.1 MDM Diagnostic Export (2024-03-15 09:22)

```
=== MDM Diagnostic Export ===
Device       : DESKTOP-FB099
User         : FINBRIDGE\rthomas
Date         : 2024-03-15 09:22
OS build     : 22621.2861

— EnrollmentStatus —
EnrollmentType  : Autopilot
EnrollmentState : Failed
ErrorCode       : 0x80180014
ErrorDescription: The device is already enrolled in MDM.
Timestamp       : 2024-03-15 09:18:44

— PolicyManager —
ProfilesAttempted : 4
ProfilesApplied   : 0
LastError         : 0x80070005 (Access denied)
FailedProfile     : FinBridge-Win11-Security-Baseline
Timestamp         : 2024-03-15 09:19:01

— ComplianceEngine —
EvaluationResult : Could not evaluate
Reason           : Enrolment not complete
Timestamp        : 2024-03-15 09:19:45

— DeviceInfo —
AzureADJoined   : Yes
MDMEnrolled     : Yes (previous enrolment)
EnrolmentSource : Legacy (manual MDM enrolment, 2023-11-04)
AutopilotProfile: FinBridge-Autopilot-Standard
TPMVersion      : 2.0
TPMStatus       : Ready
SecureBoot      : Enabled

— NetworkCheck —
EndpointReach : login.microsoftonline.com          : OK
EndpointReach : enrollment.manage.microsoft.com    : OK
EndpointReach : enterpriseregistration.windows.net : OK
ProxyDetected : No

— Licensing —
M365LicenseFound : Yes
IntuneP1License  : Yes
AutopilotLicense : Yes
```

### 2.2 Structured Evidence Table

| Evidence Item | Value | Significance |
|---|---|---|
| Enrolment outcome | Failed | Confirms the incident |
| Error code | `0x80180014` | Confirmed Microsoft MDM error: device already enrolled |
| Error description | "The device is already enrolled in MDM" | Direct statement of conflict from MDM stack |
| Existing enrolment | Legacy manual, 2023-11-04 | Identifies the conflicting record and its age (~16 months) |
| Enrolment source | Legacy (not Autopilot) | Confirms enrolment type mismatch |
| Profiles applied | 0 of 4 | Full policy failure — no configuration reached the device |
| Policy error | `0x80070005` Access Denied | Downstream consequence of incomplete enrolment state |
| Failing profile | FinBridge-Win11-Security-Baseline | Security baseline not applied — compliance gap |
| Compliance evaluation | Could not evaluate | Device not in a state where compliance can be assessed |
| Azure AD joined | Yes | AAD join itself is not the problem |
| TPM 2.0 / Secure Boot | Ready / Enabled | Hardware pre-requisites met |
| Licensing | M365, Intune P1, Autopilot all present | Licensing eliminated as a cause |
| Network | All endpoints reachable, no proxy | Network eliminated as a cause |

### 2.3 Error Code Reference

| Code | Official meaning | Source |
|---|---|---|
| `0x80180014` | The device is already enrolled in MDM — enrolment conflict prevents new enrolment | Microsoft-defined MDM/Intune error |
| `0x80070005` | Access Denied — the calling process does not have the required permissions to write to the target resource | Standard Windows HRESULT (Win32 error 5) |

### 2.4 Factors Eliminated

The following were assessed and eliminated as contributing causes based on the diagnostic evidence:

- **Licensing** — M365, Intune P1, and Autopilot licences all confirmed present
- **Network connectivity** — All three required Autopilot endpoints reachable; no proxy interference
- **Hardware** — TPM 2.0 ready, Secure Boot enabled; hardware pre-requisites fully met
- **Azure AD join** — Device is correctly Azure AD joined; AAD join is not the failure point
- **OS build** — Build 22621.2861 (Windows 11 22H2) is within supported range for Autopilot

---

## 3. Timeline of Events

| Date / Time | Event | Source |
|---|---|---|
| 2023-11-04 (time unknown) | Device DESKTOP-FB099 enrolled into Intune via legacy manual MDM process | MDM Diagnostic → DeviceInfo.EnrolmentSource |
| 2023-11-04 to 2024-03-14 | Device managed under legacy enrolment; no Autopilot record associated | Inferred from enrolment age |
| 2024-03-15 (time unknown, pre-09:18) | Device selected for Autopilot re-provisioning for user rthomas; legacy MDM record not reviewed or cleared | Inferred from provisioning attempt |
| **2024-03-15 09:18:44** | **Autopilot enrolment initiated — failed immediately with `0x80180014`** | MDM Diagnostic → EnrollmentStatus |
| **2024-03-15 09:19:01** | **PolicyManager attempted to apply 4 profiles — all failed with `0x80070005` Access Denied** | MDM Diagnostic → PolicyManager |
| **2024-03-15 09:19:45** | **Compliance engine evaluation aborted — "Enrolment not complete"** | MDM Diagnostic → ComplianceEngine |
| 2024-03-15 09:22 | MDM diagnostic export captured by engineer | MDM Diagnostic header timestamp |

---

## 4. Five Why Analysis

### Problem Statement
*Device DESKTOP-FB099 failed Autopilot enrolment on 2024-03-15, leaving it unmanaged and preventing the user from being issued a compliant workstation.*

---

**Why 1 — Why did Autopilot enrolment fail?**

Because the MDM stack returned error `0x80180014` — the device was already enrolled in MDM under a legacy manual enrolment from 2023-11-04. Autopilot cannot complete enrolment when a conflicting active enrolment record already exists on the device and in Intune.

---

**Why 2 — Why was there an active legacy MDM enrolment on a device being re-provisioned via Autopilot?**

Because the device was enrolled into MDM manually in November 2023 (prior to the organisation's Autopilot deployment) and was never offboarded from legacy MDM management before being re-issued. The old enrolment record persisted in both Intune and on the device itself.

---

**Why 3 — Why was the legacy enrolment not removed before the Autopilot provisioning attempt?**

Because there was no documented or enforced pre-provisioning checklist requiring an Intune enrolment audit before a device enters the Autopilot workflow. The engineer preparing the device for re-issue did not check Intune for an existing enrolment record and the process did not require it.

---

**Why 4 — Why is there no pre-provisioning Intune audit step in the device re-issue process?**

Because the Autopilot deployment process was designed for net-new devices that had never been enrolled. When the organisation later began re-provisioning legacy-enrolled devices through the Autopilot pipeline, the process was not updated to account for the pre-existing MDM state those devices carry. The gap between legacy MDM and Autopilot workflows was not identified as a risk.

---

**Why 5 — Why was the gap between legacy MDM and Autopilot workflows not identified as a risk?**

Because there was no formal migration plan or transition audit when the organisation moved from manual MDM enrolment to Autopilot. Devices enrolled before the Autopilot rollout were not catalogued or scheduled for legacy enrolment cleanup. The assumption was made that legacy devices would either be retired naturally or would self-migrate, neither of which is technically valid for Autopilot.

---

### Root Cause Statement

> The absence of a formal offboarding gate in the device re-issue process — specifically, a mandatory check and removal of existing MDM enrolments before Autopilot provisioning — allowed a device carrying a 16-month-old legacy MDM record to enter the Autopilot pipeline unchanged, causing an enrolment conflict and a complete provisioning failure.

---

## 5. Impact Assessment

| Impact Area | Detail |
|---|---|
| User impact | rthomas unable to receive provisioned workstation; delay to productivity |
| Security posture | FinBridge-Win11-Security-Baseline not applied; device not compliant during the gap period |
| Compliance | Device returned 0 of 4 compliance/configuration profiles — compliance evaluation not possible |
| Scope | Single device confirmed; wider risk exists for all devices enrolled before Autopilot rollout (see Section 6) |
| Data loss | None |
| Service outage | None — isolated to this device's provisioning |

---

## 6. Remediation Steps

> Steps marked `[ADMIN CENTER]` require Intune/Azure AD portal access only.  
> Steps marked `[DEVICE]` require physical access or an active remote session on DESKTOP-FB099.

### Phase 1 — Intune and Azure AD Cleanup

**Step 1 — Retire the legacy MDM record** `[ADMIN CENTER]`
1. Sign in to Intune admin center → **Devices → All devices**
2. Search for `DESKTOP-FB099`
3. Select the device record with Enrolment type = Legacy/Device enrolment manager
4. Select **Retire** → confirm
5. Wait for retire action status to show **Succeeded**

**Step 2 — Delete the Intune device record** `[ADMIN CENTER]`
1. Return to **Devices → All devices** → select the now-retired DESKTOP-FB099 record
2. Select **Delete** → confirm
3. Verify the device no longer appears in the device list

**Step 3 — Delete the Azure AD device object** `[ADMIN CENTER]`
1. Azure portal → **Azure Active Directory → Devices → All devices**
2. Search for `DESKTOP-FB099` → select → **Delete** → confirm
3. This clears the stale AAD join record so Autopilot can register cleanly

**Step 4 — Confirm Autopilot profile assignment** `[ADMIN CENTER]`
1. Intune admin center → **Devices → Enrolment → Windows → Windows Autopilot devices**
2. Confirm DESKTOP-FB099 is present (matched by hardware hash/serial) and assigned to **FinBridge-Autopilot-Standard**
3. If absent, re-import hardware hash via CSV before proceeding

### Phase 2 — Device-Side Cleanup

**Step 5 — Remove the local MDM enrolment record** `[DEVICE]`
```powershell
# Confirm existing enrolment GUIDs
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" | Select-Object Name

# Remove Azure AD join and local MDM state
dsregcmd /leave
```
Restart the device after running `dsregcmd /leave`.

**Step 6 — Reset device to OOBE** `[DEVICE]`

Option A (physical access): **Settings → System → Recovery → Reset this PC → Remove everything → Cloud download**

Option B (remote, if Step 1–3 are complete and device re-appears in Intune): `[ADMIN CENTER]`  
Intune → DESKTOP-FB099 → **Autopilot Reset** → confirm

### Phase 3 — Re-enrolment

**Step 7 — Autopilot provisioning** `[DEVICE]`
1. At OOBE, connect to network with Autopilot endpoint access
2. Allow Autopilot to detect the FinBridge-Autopilot-Standard profile automatically
3. Allow provisioning to complete without interruption

---

## 7. Verification Checks

Confirm all of the following before releasing the device to rthomas:

| Check | Location | Expected result |
|---|---|---|
| Enrolment state | Intune → DESKTOP-FB099 → Overview | Managed by: Microsoft Intune; Enrolment type: Autopilot |
| Profiles applied | Intune → DESKTOP-FB099 → Device configuration | All 4 profiles: **Succeeded** |
| Compliance state | Intune → DESKTOP-FB099 → Device compliance | **Compliant** |
| Azure AD join | On device: `dsregcmd /status` | `AzureAdJoined : YES`; `MDMUrl` populated |
| Single enrolment GUID | On device: `HKLM\SOFTWARE\Microsoft\Enrollments` | One GUID only; EnrolmentType = Autopilot (value 8) |
| No error codes | Intune → DESKTOP-FB099 → Overview | Enrolment status field clear of errors |

---

## 8. Preventive Actions

### 8.1 Immediate — Manual Pre-Provisioning Gate (implement now)

Add a mandatory Intune audit step to the existing device re-issue ServiceNow workflow:

> *Before any device is submitted for Autopilot provisioning, the assigning engineer must confirm in Intune admin center that the device has no existing MDM enrolment record. If a record exists, the legacy offboarding procedure (Steps 1–5 above) must be completed and verified before the Autopilot workflow begins. This check is a hard gate — provisioning must not proceed without it.*

### 8.2 Short-Term — Bulk Legacy Enrolment Audit (within 2 weeks)

1. Export all Intune managed devices filtered by Enrolment type ≠ Autopilot
2. Cross-reference against the Autopilot device list (Intune → Enrolment → Windows Autopilot devices)
3. Identify all devices present in both lists (i.e. enrolled legacy but also assigned an Autopilot profile)
4. Retire and delete all conflicting legacy records before those devices reach provisioning
5. Document the count of affected devices and report to service owner

The following PowerShell provides a starting point using the Microsoft Graph SDK:

```powershell
# Requires: Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

# Export all managed devices with non-Autopilot enrolment type
$legacyDevices = Get-MgDeviceManagementManagedDevice -All |
    Where-Object { $_.EnrollmentType -ne "windowsAutoEnrollment" -and $_.OperatingSystem -eq "Windows" } |
    Select-Object DeviceName, Id, EnrollmentType, EnrolledDateTime

$legacyDevices | Export-Csv -Path ".\legacy-enrolled-devices.csv" -NoTypeInformation
Write-Output "Exported $($legacyDevices.Count) legacy-enrolled devices for review"
```

> **Note:** Review the CSV before running any bulk retire/delete actions. Do not automate deletions without human review of each record.

### 8.3 Medium-Term — Process Update (within 30 days)

1. Update the Autopilot provisioning runbook to include the legacy enrolment check as a named step with screenshots
2. Add a ServiceNow workflow task item: *"Confirm device has no existing Intune enrolment record"* as a mandatory checkbox before the Autopilot task is opened
3. Brief the provisioning team on the failure mode and the new gate in the next team meeting

### 8.4 Strategic — Autopilot Pre-Provisioning (White Glove) Evaluation

Consider enabling [Autopilot pre-provisioning mode](https://learn.microsoft.com/en-us/autopilot/pre-provision) for the FinBridge deployment. This allows IT to complete the device-phase of Autopilot provisioning (profile application, policy, apps) in a controlled environment before the device reaches the user. Enrolment conflicts would be caught by IT before user handoff rather than at the user's desk, reducing both the impact and the visibility of failures.

---

## 9. Lessons Learned

| Lesson | Action |
|---|---|
| Legacy MDM enrolments are not automatically cleared when a device is assigned an Autopilot profile | Add explicit offboarding to re-issue process |
| `0x80180014` will occur on any legacy-enrolled device entering the Autopilot pipeline without cleanup | Treat as a known failure mode; add to known error KB |
| The Autopilot pipeline was not designed for re-enrolment scenarios without prior process design | Re-issue workflow must be treated as distinct from new-device Autopilot provisioning |
| A bulk of devices may be at risk of the same failure | Bulk audit required before further re-provisioning from the legacy estate |

---

## 10. Document Control

| Field | Value |
|---|---|
| Document reference | RCA-INC-2024-031501 |
| Device | DESKTOP-FB099 |
| Incident date | 2024-03-15 |
| RCA completed | 2024-03-15 |
| Author | DWP MDM Team |
| Review required | Service Owner, Provisioning Team Lead |
| Next review / closure | Upon confirmation of successful Autopilot re-enrolment and bulk audit completion |

---

*This document is based solely on the MDM diagnostic export dated 2024-03-15 09:22. All findings are derived from evidence present in the export. No assumptions have been made beyond the defined scope.*
