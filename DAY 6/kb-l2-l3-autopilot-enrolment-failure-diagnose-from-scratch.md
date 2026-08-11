v 1.0, 07/08/2026, status : Draft

# Autopilot enrolment failure on DESKTOP-FB099

## Background
Windows Autopilot provisions a device and applies Intune policy so the user receives a managed, compliant workstation. This matters because the device is not ready for issue until enrolment completes and the required profiles are applied.

## Symptom
The engineer sees Autopilot stop at enrolment with error 0x80180014, no Intune configuration or compliance profiles applied, and the device left unmanaged. The user reports that the workstation could not be issued.

## Root Cause
The device already had a legacy manual MDM enrolment from 2023-11-04, and the diagnostic export confirms EnrollmentStatus.ErrorCode = 0x80180014 with the description "The device is already enrolled in MDM." The same export shows MDMEnrolled = Yes (previous enrolment), EnrolmentSource = Legacy (manual MDM enrolment, 2023-11-04), ProfilesApplied = 0, PolicyManager.LastError = 0x80070005, and ComplianceEngine.Reason = Enrolment not complete.

## Detection
Start with the MDM diagnostic export captured at 2024-03-15 09:22 and check the following fields exactly: EnrollmentStatus.ErrorCode, EnrollmentStatus.ErrorDescription, DeviceInfo.MDMEnrolled, DeviceInfo.EnrolmentSource, PolicyManager.ProfilesAttempted, PolicyManager.ProfilesApplied, PolicyManager.LastError, PolicyManager.FailedProfile, and ComplianceEngine.Reason. The RCA evidence does not contain Windows event IDs, so the confirmed indicators are the diagnostic export fields above rather than event log numbers.

In the device-side check, run dsregcmd /status and confirm AzureAdJoined = Yes and that the device is still reporting a previous MDM enrolment. In the registry, check HKLM:\SOFTWARE\Microsoft\Enrollments and look for more than one enrolment GUID or a legacy record alongside the Autopilot state.

For a comparison check, compare the affected device against a healthy Autopilot device in the same deployment: the healthy device should show EnrolmentSource = Autopilot, ProfilesApplied = 4, and ComplianceEngine evaluation completed, while DESKTOP-FB099 shows EnrolmentSource = Legacy, ProfilesApplied = 0, and ComplianceEngine.Reason = Enrolment not complete.

## Resolution
1. Microsoft Intune admin center > Devices > All devices: search for DESKTOP-FB099, select the legacy device record, and choose Retire. Expected result: the retire action shows Succeeded for the legacy managed device record.
2. Microsoft Intune admin center > Devices > All devices: select the retired DESKTOP-FB099 record and choose Delete. Expected result: the old Intune record is removed from the list.
3. Azure portal > Microsoft Entra ID > Devices > All devices: search for DESKTOP-FB099 and delete the Azure AD device object. Expected result: the stale device object is removed.
4. On the device: remove the local MDM state with dsregcmd /leave and restart. Expected result: the device leaves the old join state and returns cleanly to the next setup cycle.
5. On the device: reset the device to OOBE, then rerun Autopilot from OOBE. Expected result: Autopilot detects the FinBridge-Autopilot-Standard profile and completes the device setup.

## Verification
Confirm in Intune that DESKTOP-FB099 now shows Managed by Microsoft Intune with Enrolment type = Autopilot, all 4 profiles are Succeeded, and compliance is Compliant. On the device, dsregcmd /status should show AzureAdJoined = YES and a populated MDMUrl, and HKLM:\SOFTWARE\Microsoft\Enrollments should contain one GUID only with EnrolmentType = Autopilot (value 8).

## Rollback
If the cleanup makes the device worse, stop the Autopilot attempt and restore the last known working state by leaving the device in its pre-reset condition, then re-check the Intune and Entra ID records before making further changes. If the device no longer reaches the setup stage, use the confirmed cleanup sequence from the RCA again rather than adding new changes.

## Preventive
Add a mandatory Intune audit and offboarding gate before any device enters the Autopilot re-issue workflow. The process must require an engineer to confirm there is no existing MDM enrolment record and to clear legacy enrolments before the device is allowed into Autopilot.

## Related
Related RCA: [rca-full-autopilot-enrolment-failure-DESKTOP-FB099.md](rca-full-autopilot-enrolment-failure-DESKTOP-FB099.md). Related known error: [known-error-autopilot-enrolment-failure-DESKTOP-FB099.md](known-error-autopilot-enrolment-failure-DESKTOP-FB099.md). Related comms and closure notes are in [comms-autopilot-enrolment-failure-three-audiences.md](comms-autopilot-enrolment-failure-three-audiences.md) and [closure-note-autopilot-enrolment-failure-DESKTOP-FB099.md](closure-note-autopilot-enrolment-failure-DESKTOP-FB099.md).