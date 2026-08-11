# Autopilot Enrolment Failure Communication

## Audience 1 — Non-technical executive
Your access and data were not lost. DESKTOP-FB099 failed during device setup because it already had an old management record from 2023-11-04, so no setup profiles were applied and the device could not be issued. The issue was isolated to this one device, and no action is needed from you.

## Audience 2 — Affected end-user team
Hi team, one device setup failed because DESKTOP-FB099 already had an old management record from 2023-11-04, so the new setup could not finish and no setup profiles were applied. If you see the same issue, stop the setup and report it straight away. Please contact the Service Desk.

## Audience 3 — Engineer-to-engineer internal note
Root cause: DESKTOP-FB099 hit Autopilot enrolment failure `0x80180014` because the device already had a legacy manual MDM enrolment from 2023-11-04; the MDM export states "The device is already enrolled in MDM." PolicyManager then reported `0x80070005` and 0 of 4 profiles were applied, so compliance could not evaluate because enrolment was not complete.

Exact action taken: retire the legacy Intune record, delete the Intune device object, delete the Azure AD device object, remove the local MDM state with `dsregcmd /leave`, restart the device, reset it to OOBE, and rerun Autopilot from OOBE.

Config detail: the device was Azure AD joined, MDMEnrolled as a previous enrolment, and associated with the FinBridge-Autopilot-Standard profile. The diagnostic export also showed OS build 22621.2861, TPM 2.0 ready, Secure Boot enabled, no proxy detected, and all required Microsoft endpoints reachable.

Verification step: confirm the Intune record shows Managed by Microsoft Intune with enrolment type Autopilot, all 4 profiles succeeded, and compliance is marked Compliant. On the device, `dsregcmd /status` should show `AzureAdJoined : YES` and a populated `MDMUrl`, and `HKLM\SOFTWARE\Microsoft\Enrollments` should contain one GUID only with EnrolmentType = Autopilot (value 8).

Preventive action needed: add the mandatory Intune audit/offboarding gate before any device enters the Autopilot re-issue workflow, and do not proceed until any existing MDM enrolment record has been retired and deleted.