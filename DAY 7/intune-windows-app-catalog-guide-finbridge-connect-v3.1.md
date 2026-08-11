# DWP Step-by-Step Guide: Add a Windows App to the Intune App Catalog (Pre-Rollout)

## Purpose
This guide shows a DWP engineer how to add a Windows application to Microsoft Intune before any phased rollout begins.

Worked example used throughout:
- Application: FinBridge Connect v3.1
- Packaging: Windows LOB app as a .intunewin package
- Install command: FinBridgeConnect_Setup.exe /silent
- Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
- Detection method: Registry key
- Detection value: HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1

## Before you start
1. Confirm you have an Intune role that can create and assign applications (for example, Intune Administrator or Application Manager).
2. Confirm the app package has been built and validated in a lab:
- FinBridgeConnect_v3.1.intunewin is available.
- The silent install and uninstall commands are tested locally.
- The detection key exists after install.
3. Confirm you have a small pilot Azure AD / Entra ID group ready (for example, DWP-APP-Pilot-FinBridge).

## 1. Where to add an app in Intune
1. Sign in to the Intune admin center.
2. Navigate to:
- Home > Apps > Windows > Add
3. UI label check (important): Intune UI labels can vary by tenant version, portal refresh, or policy experience updates. If your portal does not show exactly Apps > Windows > Add, verify the equivalent Add app action under the Apps workload in your live tenant.

## 2. Choose the correct app type
1. In the Add app flow, choose Select app type.
2. Use this mapping:
- Windows LOB app (.intunewin): choose Windows app (Win32).
- Microsoft Store app: choose Microsoft Store app (new) (or equivalent Store app label in your tenant).
- Web link shortcut app: choose Web link.
3. For this worked example, select Windows app (Win32) because FinBridge Connect is packaged as .intunewin.
4. UI label check (important): App type labels frequently change between tenants. Verify the option description references Win32/.intunewin for LOB packaging before continuing.

## 3. Create the LOB Windows app record (Win32)
1. Upload package:
- Select the FinBridgeConnect_v3.1.intunewin file.
2. UI label check (important): Upload buttons may be named Select file, Choose file, or App package file. Verify you are attaching the .intunewin package.

### 3.1 App information (required fields)
1. Enter Name: FinBridge Connect
2. Enter Description: FinBridge secure connectivity client for enterprise access.
3. Enter Publisher: FinBridge
4. Enter Version: 3.1
5. Save and move to the next page.
6. UI label check (important): Some tenants label Version as Display version or App version. Verify version value remains 3.1 in summary before create.

### 3.2 Program (required fields)
1. Install command: FinBridgeConnect_Setup.exe /silent
2. Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
3. Install behavior (context):
- Select System when app needs machine-wide install, admin-level writes, or HKLM detection.
- Select User only for user-profile installs without admin-level dependencies.
4. For this app, choose System because detection is under HKLM and this is a machine-level deployment.
5. UI label check (important): Install behavior may appear as Install context. Verify the chosen context is device/system-level, not user-only.

### 3.3 Requirements (required fields)
1. Operating system architecture:
- Select architecture used by target estate (typically 64-bit for modern corporate Windows 10/11 fleets).
2. Minimum operating system:
- Set a supported baseline that matches your endpoint standard (for example, Windows 10 22H2 or Windows 11 baseline used in your tenant).
3. UI label check (important): Minimum OS labels vary by release channel naming. Verify against your current corporate minimum supported build policy.

### 3.4 Detection rules (required fields)
1. Add a detection rule.
2. Choose Rule type: Registry.
3. Configure:
- Key path: HKLM\SOFTWARE\FinBridge\Connect
- Value name: Version
- Detection method: String comparison (equals)
- Expected value: 3.1
4. Save detection rule.
5. Why this matters: Intune marks install success only if the detection condition is true after installation.
6. UI label check (important): Detection operator labels can vary (Equals, Is equal to, Match). Verify the logical comparison is exact value equals 3.1.

### 3.5 Return codes (required fields)
1. Open Return codes (or equivalent section) and verify code mapping.
2. Recommended baseline mapping for Win32 apps:
- 0 = Success
- 3010 = Soft reboot (success with reboot required)
- 1641 = Hard reboot (success with immediate reboot)
- 1618 = Retry (another installation in progress)
- Any unlisted non-zero code = Failed
3. Keep defaults unless vendor guidance requires custom mapping.
4. UI label check (important): Some tenants expose return codes in Advanced settings. Verify the result classifications (Success/Retry/Failed) are correct before create.

## 4. Assignment basics
1. Go to Assignments for the app.
2. Understand assignment types:
- Required: Intune automatically installs for targeted users/devices.
- Available: App appears in Company Portal for optional self-service install.
- Uninstall: Intune removes the app from targeted users/devices.
3. Pilot-first rule:
- Assign new apps to a small test group first.
- Do not assign directly to the full 10,000-device fleet.
4. Why pilot first:
- Reduces blast radius if install, detection, reboot, or dependency issues exist.
- Validates performance and user impact in production-like conditions.
- Allows rollback or fix before broad deployment.
5. Worked example assignment:
- Add Required assignment to DWP-APP-Pilot-FinBridge only.
- Do not add broad production groups yet.
6. UI label check (important): Group targeting UI can differ (Included groups, Required group, Assignment targets). Verify you are targeting only the pilot group.

## 5. Review and create
1. Review all pages in the summary:
- App info values correct
- Program commands correct
- Install behavior set to System
- Requirements aligned to supported OS
- Detection rule exactly matches registry key/value
- Return codes mapped correctly
- Assignments limited to pilot group
2. Select Create.
3. UI label check (important): Final action may be Create, Save, or Review + create. Verify app object is published successfully.

## 6. Verification after creation

### 6.1 Confirm the app appears in the catalog
1. Go to Apps > Windows (or equivalent app list).
2. Search for FinBridge Connect.
3. Confirm listed details:
- Name: FinBridge Connect
- Version: 3.1
- Type: Win32
- Assignment present for pilot group
4. UI label check (important): List columns vary by tenant. Verify using app properties page if columns are hidden.

### 6.2 Check install status on an assigned test device
1. On a pilot-assigned test device, force policy sync:
- Company Portal sync or Settings > Accounts > Access work or school > Sync.
2. In Intune admin center, open the app and view device install status (or user install status, based on assignment model).
3. Confirm status transitions from pending to final state.
4. Validate local detection outcome on device:
- Verify HKLM\SOFTWARE\FinBridge\Connect\Version exists and equals 3.1.
5. UI label check (important): Status blades may be labeled Monitor, Device install status, Managed apps, or similar. Verify you are viewing the app-specific deployment status page.

### 6.3 Interpret common status values
1. Installed:
- Intune detected the app successfully using your rule.
2. Failed:
- Install command failed, app process returned a failure code, or detection rule did not match post-install state.
- First checks: command syntax, execution context (System/User), return code mapping, and detection rule path/value.
3. Not applicable:
- Target device does not meet requirement filters (for example, wrong OS version or architecture) or assignment conditions.
- First checks: requirements baseline and assignment targeting.

## 7. Ready-for-rollout gate (before phase expansion)
1. Keep deployment at pilot scope until all conditions are true:
- No critical install failures in pilot
- Detection is stable and accurate
- User impact acceptable
- Support desk informed and rollback path documented
2. Only then begin phased expansion (for example, Pilot > Wave 1 > Wave 2 > Broad).

## Quick execution checklist
1. Add app from Apps > Windows > Add (verify labels live).
2. Select Windows app (Win32) for .intunewin.
3. Populate required fields (info, program, requirements, detection, return codes).
4. Assign Required to pilot group only.
5. Create app.
6. Verify catalog visibility and pilot install status.
7. Expand rollout only after pilot success criteria are met.

## Notes for DWP engineers
- Treat portal labels in this guide as reference only; always verify equivalent labels and blade names in your own tenant.
- If labels differ, rely on function (Win32 package upload, program commands, requirements, detection, assignments, monitoring) rather than exact wording.
