# RCA — Autopilot Enrolment Failure
**Device:** DESKTOP-FB099  
**User:** FINBRIDGE\rthomas  
**Date of Failure:** 2024-03-15 09:18  
**Analyst:** DWP MDM Team  
**Status:** Root Cause Confirmed — Remediation Defined

---

## 1. Incident Summary

Device DESKTOP-FB099 failed Autopilot enrolment during provisioning on 2024-03-15. The enrolment process halted immediately with error `0x80180014`. Zero of four Intune compliance/configuration profiles were applied. The device was left in a non-compliant, unenrolled state under the Autopilot flow.

---

## 2. Diagnostic Export — Key Facts

| Field | Value |
|---|---|
| Enrolment outcome | **Failed** |
| Error code | `0x80180014` — Device is already enrolled in MDM |
| Existing MDM enrolment | Yes — Legacy manual enrolment from 2023-11-04 |
| Enrolment source | Legacy (manual MDM, not Autopilot) |
| Azure AD joined | Yes |
| Profiles applied | 0 of 4 |
| Policy last error | `0x80070005` — Access Denied |
| Failing profile | FinBridge-Win11-Security-Baseline |
| Intune P1 licence | Yes |
| Autopilot licence | Yes |
| Network | All endpoints reachable, no proxy |

---

## 3. Root Cause

**Confirmed root cause: Conflicting stale legacy MDM enrolment**

`0x80180014` is a defined Microsoft error code meaning *"The device is already enrolled in MDM."* The device carried an active MDM enrolment record from 2023-11-04 (manual/legacy enrolment type). Autopilot cannot complete enrolment over an existing conflicting MDM record — it does not overwrite or migrate legacy enrolments automatically.

The secondary error `0x80070005` (Access Denied) on policy profile application is a **consequence** of the same root cause: the PolicyManager attempted to apply profiles while the enrolment state was incomplete and locked, triggering a permissions failure at the registry/WMI layer. This is not an independent cause.

Licensing, network connectivity, TPM, and Secure Boot were all confirmed healthy and are **eliminated as contributing factors**.

---

## 4. Remediation — Ordered Steps

> **Key:** Steps marked `[ADMIN CENTER]` require only Intune/Azure AD portal access. Steps marked `[DEVICE]` require physical access or an active remote session.

---

### Phase 1 — Admin Center Cleanup (perform before touching the device)

**Step 1 — Retire the legacy MDM device record** `[ADMIN CENTER]`

1. Sign in to [Intune admin center](https://intune.microsoft.com) as an Intune Administrator
2. Navigate to **Devices → All devices**
3. Search for `DESKTOP-FB099`
4. If two records exist (one Legacy, one Autopilot), select the **Legacy** record (Enrolment type: Device enrolment manager or blank)
5. Select **Retire** — this removes MDM management without wiping the device
6. Wait for the retire action to show status **Succeeded** before proceeding

**Step 2 — Delete the device object from Intune** `[ADMIN CENTER]`

1. Return to **Devices → All devices**
2. Select the DESKTOP-FB099 record (now retired)
3. Select **Delete** and confirm
4. Verify the device no longer appears in the device list

**Step 3 — Delete the device object from Azure AD** `[ADMIN CENTER]`

1. Navigate to [Azure portal](https://portal.azure.com) → **Azure Active Directory → Devices → All devices**
2. Search for `DESKTOP-FB099`
3. Select the device → **Delete**
4. Confirm deletion — this removes the stale Azure AD join record so Autopilot can create a clean one

**Step 4 — Confirm Autopilot device profile assignment** `[ADMIN CENTER]`

1. In Intune admin center navigate to **Devices → Enrolment → Windows → Windows Autopilot devices**
2. Confirm `DESKTOP-FB099` (matched by serial number or hardware hash) is present and assigned to the **FinBridge-Autopilot-Standard** deployment profile
3. If absent, re-import the hardware hash via CSV (**Import** button) before proceeding

---

### Phase 2 — Device-Side Cleanup

**Step 5 — Remove the stale MDM enrolment from the device** `[DEVICE]`

> This step removes the locally cached MDM enrolment record. It is required even after the Intune-side delete, as the device retains its own enrolment state independently.

1. Open an elevated PowerShell prompt on the device
2. Run the following to confirm the existing enrolment:
   ```powershell
   Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" | Select-Object Name
   ```
3. Identify the GUID corresponding to the legacy enrolment (EnrollmentType = 6 or MDM)
4. Run `dsregcmd /leave` to unjoin from Azure AD and clear the MDM enrolment state:
   ```cmd
   dsregcmd /leave
   ```
5. Restart the device

**Step 6 — Reset the device to OOBE for Autopilot** `[DEVICE]`

> A full reset is required to return the device to the Out-Of-Box Experience (OOBE) state that Autopilot expects. Do not attempt to re-run Autopilot from within a live Windows session.

Option A — Reset via Settings (preferred if device is accessible):
1. Go to **Settings → System → Recovery**
2. Select **Reset this PC → Remove everything**
3. Choose **Cloud download** (ensures latest OS image) or **Local reinstall**
4. Select **Just remove my files** (not full drive clean unless the device is being reissued)
5. Confirm and allow the reset to complete — device will reboot to OOBE

Option B — Remote Autopilot Reset via Intune (if physical access is not available): `[ADMIN CENTER]`
1. In Intune admin center → **Devices → All devices** (if the device re-appears after Step 2–3 actions settle)
2. Select DESKTOP-FB099 → **Autopilot Reset**
3. Confirm — this pushes a remote OOBE reset without full data wipe

---

### Phase 3 — Re-enrolment and Verification

**Step 7 — Allow Autopilot to run** `[DEVICE]`

1. At OOBE, connect to a network with access to Autopilot endpoints
2. Autopilot will detect the device profile (FinBridge-Autopilot-Standard) automatically
3. Allow provisioning to complete — do not interrupt

---

## 5. Verification Checks

After Autopilot completes, confirm the following before releasing the device to the user:

| Check | Where | Expected result |
|---|---|---|
| Enrolment state | Intune → Devices → DESKTOP-FB099 → Overview | **Managed by: Microsoft Intune**, Enrolment type: Autopilot |
| Profiles applied | Intune → Devices → DESKTOP-FB099 → Device configuration | All 4 profiles: **Succeeded** |
| Compliance state | Intune → Devices → DESKTOP-FB099 → Device compliance | **Compliant** |
| Azure AD join | On device: `dsregcmd /status` | `AzureAdJoined : YES`, `MDMUrl` populated |
| No legacy enrolment | On device: Registry path `HKLM\SOFTWARE\Microsoft\Enrollments` | Only one GUID present, EnrolmentType = Autopilot (value 8) |
| Error codes absent | Intune → Devices → DESKTOP-FB099 → Overview | No error codes in Enrolment status field |

---

## 6. Preventive Action — Legacy Enrolment Offboarding Process

**Problem pattern:** Devices enrolled via legacy/manual MDM before the organisation migrated to Autopilot retain their old MDM records. If re-provisioned without cleanup, Autopilot will fail with `0x80180014` on every such device.

**Recommended preventive controls:**

1. **Pre-provisioning checklist — mandatory Intune audit before any Autopilot re-enrolment**
   - Before issuing any device for Autopilot provisioning, an admin must verify in Intune that the device has no existing MDM enrolment record
   - Add this as a formal gate in the device offboarding/reissue ServiceNow workflow

2. **Bulk legacy enrolment audit**
   - Export all Intune device records filtered by Enrolment type ≠ Autopilot
   - Cross-reference against the Autopilot device list
   - Retire and delete any overlap before those devices reach provisioning

3. **Intune device cleanup script for repeatable offboarding**
   - Use the Microsoft Graph API or the Intune PowerShell SDK to automate retire + delete for devices matching the legacy enrolment pattern:
   ```powershell
   # Requires Microsoft.Graph.Intune module
   Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"
   $device = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'DESKTOP-FB099'"
   Invoke-MgRetireDeviceManagementManagedDevice -ManagedDeviceId $device.Id
   ```

4. **Autopilot pre-provisioning mode** — Consider enabling [Autopilot pre-provisioning (White Glove)](https://learn.microsoft.com/en-us/autopilot/pre-provision) for the FinBridge deployment. This allows IT to complete the device phase before user handoff, surfacing enrolment conflicts in a controlled environment rather than at the user's desk.

---

## 7. Error Code Reference

| Code | Meaning | Source |
|---|---|---|
| `0x80180014` | The device is already enrolled in MDM — enrolment conflict | Microsoft-defined MDM error |
| `0x80070005` | Access Denied — the MDM service could not write to a required resource | Standard Windows HRESULT |

---

## 8. Timeline of Events

| Time | Event |
|---|---|
| 2023-11-04 | Device enrolled via legacy manual MDM |
| 2024-03-15 09:18 | Autopilot enrolment attempted — failed with `0x80180014` |
| 2024-03-15 09:19 | PolicyManager attempted profile application — failed `0x80070005` (0 of 4 profiles) |
| 2024-03-15 09:19 | Compliance engine evaluation failed — enrolment not complete |
| 2024-03-15 09:22 | MDM diagnostic export captured |

---

*Document produced by DWP MDM analyst. Based on MDM diagnostic export dated 2024-03-15.*
