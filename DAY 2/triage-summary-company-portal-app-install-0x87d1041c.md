# Triage Summary - T-1004

## Summary (one line)
Company app fails to install from Company Portal with error 0x87D1041C.

## Impact (who/how many/business urgency)
- Who is affected: At least one reported user/device (to-verify).
- How many are affected: Single known report currently; app-wide deployment impact unknown (to-verify).
- Business urgency: Medium (to-verify), potentially High if the app is business-critical for daily operations (to-verify).

## Known Facts
- Ticket reference: T-1004.
- Symptom: Company app does not install from Company Portal.
- Reported error: 0x87D1041C.

## Missing Information to Gather
- User/device identifiers and endpoint ownership details (to-verify).
- Exact app name/version and assignment intent for the affected user/device (to-verify).
- Whether failure occurs on one device only or multiple devices/users (to-verify).
- Whether device is compliant/healthy in management portal at time of install (to-verify).
- Last successful sync/check-in time for the device (to-verify).
- Install context and requirement rule outcomes shown in management tooling (to-verify).
- Any recent packaging/deployment change for this app before failures started (to-verify).
- Exact timestamp of failed attempt and screenshot/log evidence (to-verify).

## Likely Category
Endpoint Management - Company Portal/Intune App Deployment Failure (to-verify).

## First Diagnostic Step
Validate deployment targeting and device check-in state first: confirm the app assignment includes the affected user/device and trigger a policy sync, then reattempt install while capturing timestamped failure evidence.