Symptom : Autopilot enrolment on DESKTOP-FB099 stopped immediately with error `0x80180014`. No Intune configuration or compliance profiles were applied, and the device could not be issued to the user.

Cause : The device already had an active legacy manual MDM enrolment from 2023-11-04. The RCA confirms that `0x80180014` means the device is already enrolled in MDM, which conflicts with Autopilot enrolment.

Scope : DESKTOP-FB099 is confirmed affected, and the RCA states the wider risk applies to devices enrolled before the Autopilot rollout that still carry legacy MDM records. The incident was isolated to provisioning and did not involve data loss or a service outage.

Workaround : Retire the legacy Intune record, delete the Intune device object, delete the Azure AD device object, and remove the local MDM enrolment state with `dsregcmd /leave` before resetting the device to OOBE. After that, allow Autopilot to run again from OOBE.

Permanent fix: Complete the legacy offboarding process before any device enters the Autopilot workflow. The RCA calls for a mandatory Intune audit gate in the device re-issue process so existing MDM enrolments are cleared first.

How to spot it: The key signal is error `0x80180014` with the description "The device is already enrolled in MDM." The RCA also records `0x80070005` from PolicyManager, zero of four profiles applied, and a compliance evaluation that could not run because enrolment was not complete.