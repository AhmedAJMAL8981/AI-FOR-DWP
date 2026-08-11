# Intune Compliance Policy – Windows 11 Security Baseline Translation
**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Scope:** Windows 11 managed devices enrolled in Microsoft Intune  
**Grace Period:** 7 days applied to all settings  

---

## Overview

This document translates the DWP Windows 11 security baseline requirements into exact Intune compliance policy settings. Each entry includes the setting name as it appears in the Intune portal, the value to configure, a plain-English effect, known false-positive risks, and a recommendation to reduce noise without weakening security.

> **UI Path (verified from Intune admin centre):**  
> Microsoft Intune admin centre → Devices → Manage devices → Compliance → Create policy → Platform: Windows 10 and later
>
> **Basics tab:**  
> - **Name:** Enter a descriptive policy name (e.g. `DWP-Win11-Security-Baseline-Compliance`)  
> - **Description:** Enter a summary of the policy purpose (e.g. `Enforces DWP Windows 11 security baseline compliance requirements including BitLocker, Secure Boot, OS version, Defender, Firewall, and PIN/password.`)

---

## Compliance Settings Tab – Custom Compliance

The first section visible under the **Compliance settings** tab is **Custom Compliance**. This is separate from the built-in settings covered in Requirements 1–7.

| Field | Detail |
|---|---|
| **Custom compliance** | Toggle: **Require** / **Not configured** |
| **Select your discovery script** | Click to select a PowerShell discovery script uploaded to Intune |
| **Upload and validate the JSON file with your custom compliance settings** | Select a JSON file defining the custom compliance rules |

**For this baseline:** Set **Custom compliance** to **Not configured**. The DWP Windows 11 security baseline requirements are fully covered by the built-in compliance settings (Requirements 1–7). Custom compliance is only needed if you have additional checks not available as native Intune settings.

> If custom compliance is required in future, a PowerShell discovery script and a matching JSON rules file must both be prepared and uploaded before this setting can be set to **Require**.

---

## Compliance Settings Tab – Configuration Manager Compliance

Below Custom Compliance, the **Configuration Manager Compliance** section appears in the Intune compliance settings tab.

| Field | Baseline Value | Notes |
|---|---|---|
| **Require device compliance from Configuration Manager** | **Not configured** | Only set to **Require** if devices are co-managed with SCCM/ConfigMgr and you want to factor ConfigMgr compliance state into Intune compliance. DWP devices are Intune-only; leave as **Not configured**. |

---

## Device Health Section – Microsoft Attestation Service

Requirements 1, 2, and 7 (Code integrity) all appear under the **Device Health** section in the Intune compliance settings tab. The UI labels this section:

> *"Microsoft Attestation Service evaluation settings — Use these settings to confirm that a device has protective measures enabled at boot time."*

The three settings shown under **Windows 10 and 11** within Device Health are:

| Setting | Baseline Value |
|---|---|
| BitLocker | **Require** |
| Secure Boot | **Require** |
| Code integrity | **Require** |

---

## Requirement 1 – BitLocker must be enabled on the OS drive

| Field | Detail |
|---|---|
| **Setting Name** | Require BitLocker |
| **Intune UI Path** | Device Health → Require BitLocker |
| **Value** | Require |
| **Grace Period** | 7 days |

**Effect:**  
Forces the device to report that BitLocker Drive Encryption is active on the OS (C:) drive. If BitLocker is not enabled or the drive is not fully encrypted, the device is marked non-compliant.

**False-Positive Risk:**  
- Device is encrypting (BitLocker started but not yet completed) — reports as non-compliant until encryption finishes.  
- BitLocker is enabled but the device has not yet sent a fresh compliance check-in to Intune.  
- Virtual machines (e.g. AVD session hosts) where the underlying disk is encrypted at the hypervisor layer but Windows does not report BitLocker active.  
- Devices where BitLocker was silently enabled via MBAM/SCCM and the Intune health attestation service has not yet received an updated report.

**Recommendation:**  
The 7-day grace period covers most encryption-in-progress scenarios. For AVD or VM-based workloads, consider a separate compliance policy scoped to those device groups with this setting set to **Not configured**, rather than weakening the physical device baseline.

---

## Requirement 2 – Secure Boot must be enabled

| Field | Detail |
|---|---|
| **Setting Name** | Require Secure Boot to be enabled on the device |
| **Intune UI Path** | Device Health → Require Secure Boot to be enabled on the device |
| **Value** | Require |
| **Grace Period** | 7 days |

**Effect:**  
Uses Windows Health Attestation Service (HAS) to verify that the device booted with Secure Boot active. Prevents unsigned or tampered boot software from loading.

**False-Positive Risk:**  
- Older hardware (pre-2017) that shipped with Secure Boot disabled by default and cannot be enabled in firmware.  
- Dual-boot Linux/Windows configurations where Secure Boot is disabled to support unsigned kernels.  
- Some OEM development/engineering BIOS builds that ship with Secure Boot off.  
- Health Attestation Service delays — the HAS report can lag behind actual device state by several hours.

**Recommendation:**  
Do not weaken this setting. For legacy hardware that genuinely cannot support Secure Boot, create a separate compliance policy for that hardware group with a documented exception, approved via DWP security waiver process. Do not exempt the whole fleet.

---

## Requirement 3 – Minimum OS build: N-1 (22621.2861)

> **UI Section:** This setting is found under **Device Properties → Operating System Version** in the Intune compliance settings tab.

The **Device Properties** section exposes the following OS version fields. Configure only the ones listed as **Require**; leave the rest as **Not configured** unless otherwise stated.

| Field | Baseline Value | Notes |
|---|---|---|
| **Minimum OS version** | `10.0.22621.2861` | **Configure this — see Requirement 3** |
| Maximum OS version | Not configured | Leave blank unless locking to a specific build |
| Minimum OS version for mobile devices | Not configured | Not applicable — Windows 11 PC fleet |
| Maximum OS version for mobile devices | Not configured | Not applicable — Windows 11 PC fleet |
| Valid operating system builds | Not configured | Alternative to min/max version; leave blank for this baseline |

**Linux distributions (within Device Properties):**

The Device Properties section also includes a **Linux distributions** sub-section with the following description:

> *"These settings relate to Linux distributions installed on managed Windows devices and affect the compliance state of the device."*

| Field | Baseline Value | Notes |
|---|---|---|
| **Distribution name** | Not configured | Leave blank — DWP does not permit WSL (Windows Subsystem for Linux) on managed endpoints |
| **Minimum OS version** | Optional value | Leave blank |
| **Maximum OS version** | Optional value | Leave blank |

> **Note:** If WSL is permitted in your environment, use this section to restrict which Linux distributions and versions are allowed on managed Windows 11 devices.

| Field | Detail |
|---|---|
| **Setting Name** | Minimum OS version |
| **Intune UI Path** | Device Properties → Operating System Version → Minimum OS version |
| **Value** | `10.0.22621.2861` |
| **Grace Period** | 7 days |

**Effect:**  
Marks any device running a Windows 11 build older than 22621.2861 as non-compliant. Ensures devices are at most one cumulative update behind the latest known good release (22621.3155), preventing exposure to known vulnerabilities patched in recent updates.

> **Note on versioning:**  
> Windows 11 22H2 = build 22621.x. The latest known good is 22621.3155; N-1 = 22621.2861. This setting must be reviewed and updated each Patch Tuesday cycle.

**False-Positive Risk:**  
- Devices that received the Windows Update policy but have not yet rebooted to apply it.  
- Devices with a pending update blocked by active user sessions (e.g. a user ignoring restart prompts).  
- Devices with Windows Update for Business deferral rings that legitimately delay updates — the deferral period may push them below the minimum before the update arrives.  
- Devices transitioning to Windows 11 23H2 or 24H2 will report a different build branch; ensure the minimum build value is updated to match the new branch.

**Recommendation:**  
Align the minimum build update cadence with your Windows Update for Business deferral ring schedule. If your pilot ring defers 7 days and production defers 14 days, only enforce the new minimum build after the longest deferral period expires. Automate the compliance policy update using a PowerShell + Graph API script on Patch Tuesday +15 days.

---

## Requirement 4 – Windows Defender real-time protection must be on

| Field | Detail |
|---|---|
| **Setting Name** | Require real-time protection |
| **Intune UI Path** | Microsoft Defender Antivirus → Require real-time protection |
| **Value** | Require |
| **Grace Period** | 7 days |

**Effect:**  
Verifies that Windows Defender (Microsoft Defender Antivirus) real-time protection is active and not disabled. Ensures continuous on-access scanning for malware.

**False-Positive Risk:**  
- Third-party AV products (e.g. Symantec, CrowdStrike AV component) that disable Windows Defender automatically when installed — Defender reports as off even though the endpoint is protected.  
- Tamper protection policies preventing Defender from re-enabling after a conflict state.  
- MDE (Microsoft Defender for Endpoint) passive mode configurations used in migration scenarios.  
- Brief window after a Defender platform update where the service restarts and temporarily reports as off.

**Recommendation:**  
If third-party AV is deployed alongside Defender, use the **Windows Security Centre** reports to confirm actual protection status. If the fleet is fully on Defender/MDE only, this setting is safe as-is. For mixed environments, consider suppressing this check via a scoped exclusion group for devices with approved third-party AV, managed through an Intune device filter.

---

## Requirement 5 – Firewall must be enabled for all profiles

| Field | Detail |
|---|---|
| **Setting Name** | Microsoft Defender Firewall (Domain), Microsoft Defender Firewall (Private), Microsoft Defender Firewall (Public) |
| **Intune UI Path** | Microsoft Defender Firewall → Microsoft Defender Firewall (each profile separately) |
| **Value** | Require (set for Domain, Private, and Public profiles individually) |
| **Grace Period** | 7 days |

**Effect:**  
Verifies that Windows Firewall is active for the Domain network profile (corporate LAN/VPN), Private profile (home networks), and Public profile (untrusted networks such as coffee shop Wi-Fi). All three must be on for the device to be compliant.

**False-Positive Risk:**  
- Third-party firewall software (e.g. Symantec Endpoint Protection firewall) that disables Windows Firewall — Intune checks Windows Firewall state specifically, not third-party equivalents.  
- Group Policy Objects pushing firewall configuration can sometimes create a race condition where the GPO disables Windows Firewall before the Intune policy re-enables it.  
- VPN clients that temporarily alter network profiles during connection/disconnection transitions.

**Recommendation:**  
Ensure GPO and Intune firewall policies are not conflicting. If a third-party firewall is in use and is approved as the DWP standard, raise a security waiver and exclude the relevant devices from this check. Do not set any profile to **Not configured** as a blanket fix — the Public profile is the highest risk and must remain enforced.

---

## Requirement 6 – A PIN or password must be configured

> **UI Section:** These settings are found under **System Security → Password** in the Intune compliance settings tab, under the **Windows 10 and later** sub-heading.

All password fields visible in the UI are listed below. The UI shows default values before configuration — configure each field to the baseline value shown.

| Field | UI Default | Baseline Value | Notes |
|---|---|---|---|
| **Require a password to unlock mobile devices** | Not configured | **Require** | Core requirement — must be set |
| **Simple passwords** | Not configured (greyed until above = Require) | **Block** | Prevents PINs like 1234 or 1111 |
| **Password type** | Device default | **Alphanumeric** | Enforces letters + numbers |
| **Minimum password length** | 4 | **8** | UI default of 4 is insufficient |
| **Maximum minutes of inactivity before password is required** | Not configured | **15** | Lock screen idle timeout |
| **Password expiration (days)** | 41 | **Not configured** | Managed via Entra ID / AD password policy; do not duplicate here |

| Field | Detail |
|---|---|
| **Setting Name** | Require a password to unlock mobile devices |
| **Intune UI Path** | System Security → Password → Require a password to unlock mobile devices |
| **Value** | Require |
| **Grace Period** | 7 days |

> ⚠️ **UI Path Note — Possible Change:** The section may now appear as **System Security → Password** rather than referencing "mobile devices." Verify the current label in your tenant at:  
> `Devices → Compliance policies → Create policy → Windows 10 and later → System Security`

**Effect:**  
Requires users to have a password, PIN, or Windows Hello credential configured to unlock the device. Prevents unattended access to an unlocked device.

**False-Positive Risk:**  
- Windows Hello for Business enrolled devices may occasionally fail to report PIN presence correctly during the initial provisioning window.  
- Shared kiosk devices or shared workstations configured with auto-logon — these are by design unlocked and will be flagged.  
- Devices in OOBE / first-run setup state that have not yet completed user provisioning.

**Recommendation:**  
For kiosk or shared-device scenarios, create a dedicated compliance policy assigned to a Kiosk Devices Entra group with this setting set to **Not configured**. Do not relax the setting fleet-wide. Ensure Windows Hello for Business is deployed via Intune configuration profile to maximise compliance reporting accuracy.

---

## Requirement 7 – Device must not be jailbroken or rooted

| Field | Detail |
|---|---|
| **Setting Name** | No jailbreak or root |
| **Intune UI Path** | Device Health → No jailbreak or root |
| **Value** | Require |
| **Grace Period** | 7 days |

> **Note:** This setting is primarily enforced on iOS/Android in Intune. For Windows 11 devices, the equivalent concept is covered through:  
> - **Code integrity** (Device Health → Require code integrity)  
> - **Secure Boot** (Requirement 2 above)  
> - **Health attestation** checks  
>
> For Windows 11 compliance policies, it is strongly recommended to enable **Require code integrity** as the Windows equivalent control.

| **Additional Setting** | **Value** |
|---|---|
| Require code integrity | **Require** |
| **Intune UI Path** | Device Health → Code integrity |

> **UI Note:** In the Intune portal, Code integrity appears directly in the **Device Health** section alongside BitLocker and Secure Boot (see Device Health Section above). Set the toggle to **Require**.

**Effect (Code Integrity):**  
Uses Windows Health Attestation to verify that kernel-mode code integrity (KMCI) is enforced — meaning only drivers and system files signed by Microsoft are allowed to load. Detects tampering, unsigned driver injection, or kernel-level rootkits.

**False-Positive Risk:**  
- Test-signing mode enabled on developer machines — intentionally disables code integrity for driver development.  
- Health Attestation Service reporting lag (same as Secure Boot — can lag several hours).  
- Some older OEM diagnostic tools that install unsigned drivers.

**Recommendation:**  
Enable both **Require Secure Boot** (Requirement 2) and **Require code integrity** together — they are complementary controls. For developer workstations with a documented need for test-signing, create a scoped exclusion group with a security waiver. Do not disable code integrity fleet-wide.

---

## Compliance Settings – Microsoft Defender for Endpoint

The **Microsoft Defender for Endpoint** section appears in the Intune compliance settings tab. It integrates MDE threat intelligence into device compliance evaluation.

> The UI includes a link: **Microsoft Defender for Endpoint rules** — this opens the MDE connector configuration in the Intune admin centre.

| Field | UI Default | Baseline Value | Notes |
|---|---|---|---|
| **Require the device to be at or under the machine risk score** | Not configured | **Not configured** | Leave as **Not configured** unless MDE is fully deployed and threat signal integration with Intune has been validated. Options when enabled: Clear, Low, Medium, High. |

**When to enable:** If DWP has Microsoft Defender for Endpoint deployed and the MDE–Intune connector is active, set this to **Clear** or **Low** to block devices with active threat detections from accessing corporate resources via Conditional Access.

---

## Post-Assignment Validation Steps

### Where to check device compliance status

**Option 1 — Per-device view (most detailed):**
> Intune admin centre → Devices → All devices → [device name] → Compliance → click the policy name

This shows a per-setting breakdown: which settings are **Compliant**, **Not evaluated**, or the specific failing setting name.

**Option 2 — From the policy:**
> Devices → Compliance → [policy name] → Monitor tab → View report → search by device name

---

### Compliance state definitions and Conditional Access impact

| Status | Meaning | Conditional Access impact |
|---|---|---|
| **Compliant** | All settings pass | Full access to M365 and internal resources |
| **In grace period** | Non-compliant but grace period (7 days) has not expired | CA treats the device as compliant — user is not blocked yet. Clock is running. |
| **Not compliant** | Grace period expired or not set | CA blocks access — user receives access denied. Immediate remediation required. |

---

### BitLocker false positive — three most common causes and fastest checks

If a device reports **non-compliant on BitLocker** despite BitLocker being enabled, check these three causes in order:

**Cause 1: Health Attestation Service reporting lag**

The HAS report Intune received was taken before encryption completed — BitLocker is on but the report is stale (can lag several hours).

*Fastest check:*
```
manage-bde -status C:
```
If output shows `Protection Status: Protection On` and `Percentage Encrypted: 100%`, BitLocker is fully enabled. Force a fresh compliance evaluation:
> Settings → Accounts → Access work or school → Info → Sync

Recheck in Intune after 15 minutes.

---

**Cause 2: Encryption still in progress (not yet at 100%)**

Silent BitLocker encryption was triggered by enrolment or Win11 upgrade and Intune evaluated compliance before it completed.

*Fastest check:*
```
manage-bde -status C:
```
Look at `Percentage Encrypted`. If between 1–99%, encryption is running — no action needed. It will self-resolve within the 7-day grace period.

---

**Cause 3: BitLocker suspended during Win11 in-place upgrade**

The Win11 upgrade process automatically suspends BitLocker protectors to allow TPM/firmware changes. If Intune evaluates during this window, it reports non-compliant even though BitLocker will auto-resume post-reboot.

*Fastest check:*
```
manage-bde -status C:
```
Look for `Protection Status: Protection Suspended`. To force resume:
```
manage-bde -protectors -enable C:
```
Then sync Intune from Settings → Accounts → Access work or school → Info → Sync.

---

### First 24-hour monitoring checklist

| Check | Location | Pass condition |
|---|---|---|
| Non-compliant setting breakdown | Policy → Monitor → View report | "Minimum OS version" or "BitLocker" should not account for >20% of fleet unless expected |
| All flagged devices show "In grace period" | Devices → Compliance → filter by In grace period | No devices should show "Not compliant" within first 7 days |
| Conditional Access blocks | Entra ID → Monitoring → Sign-in logs → filter Failure + Device compliance | Zero CA blocks in first 7 days confirms grace period is working |
| WUfB ring correlation | Intune → Reports → Windows updates | Non-compliant devices should map to deferred rings, not random devices |

---

## Tab 4 – Assignments

> **UI Path:** Compliance policy wizard → **Assignments**

This tab controls which users or devices receive the compliance policy.

### Included Groups

| Field | Pilot Value | Production Value | Notes |
|---|---|---|---|
| **Included groups** | Add your **Pilot Devices** Entra group | All Devices (or All Users) | Do NOT assign to All users/All devices during pilot phase |
| **Excluded groups** | — | Kiosk Devices group | Exclude any groups with dedicated compliance policies (e.g. kiosk, AVD) |

> **Do not assign to All users on first deployment.** Scope to a pilot group for 7 days, review compliance reports, then broaden assignment to production.

### Assignment Filters

When adding a group, Intune opens an **Assignment filters** panel with three options:

| Option | When to use |
|---|---|
| **Do not apply a filter** ✅ | **Select this for the DWP baseline** — applies the policy to all members of the assigned group without additional device filtering |
| Include filtered devices in assignment | Use only if you have a pre-created Intune filter and want to further narrow devices within the group |
| Exclude filtered devices in assignment | Use only to carve out specific device sub-sets (e.g. exclude AVD session hosts from a broader group) |

> **Note:** If no filters have been created in your tenant, the filter search panel will show "No results found." This is expected — select **Do not apply a filter** and click **Select**.

---

## Tab 3 – Actions for Noncompliance

> **UI Path:** Compliance policy wizard → **Actions for noncompliance**  
> *"Specify the sequence of actions on noncompliant devices"*

This tab defines what happens to a device after it becomes non-compliant. Actions are configured as a sequence with a schedule (number of days after noncompliance) and an optional notification message.

The table has four columns: **Action**, **Schedule (days after noncompliance)**, **Message template**, **Additional recipients**.

### Baseline Actions to Configure

| # | Action | Schedule (days) | Message template | Additional recipients | Notes |
|---|---|---|---|---|---|
| 1 | **Mark device noncompliant** | **0** | — | — | Immediate — device is flagged as non-compliant on day 0. This row is always present and cannot be removed. Value must be 0–365; field must not be empty. |
| 2 | **Send email to end user** | **1** | DWP Compliance Notification | — | Optional but recommended — notifies the user on day 1 so they can self-remediate before Conditional Access blocks access. |

> **Validation error shown in UI:** If the Schedule field for "Mark device noncompliant" is left empty, Intune shows: *"The value must be at least 0. The value must be at most 365. The value must not be empty."* Enter **0** to resolve this.

### Additional actions available (not required for this baseline)

| Action | When to use |
|---|---|
| Retire the noncompliant device | Extreme cases only — removes corporate data. Requires security approval. |
| Send push notification to device | Alternative to email for mobile-heavy fleets. |
| Remotely lock the noncompliant device | High-security environments; use with caution on shared devices. |

---

## Grace Period Summary

| Requirement | Setting | Grace Period |
|---|---|---|
| 1 – BitLocker | Require BitLocker | 7 days |
| 2 – Secure Boot | Require Secure Boot | 7 days |
| 3 – Minimum OS build | Minimum OS version: 10.0.22621.2861 | 7 days |
| 4 – Defender real-time protection | Require real-time protection | 7 days |
| 5 – Firewall (all profiles) | Firewall – Domain / Private / Public | 7 days |
| 6 – PIN or password | Require password to unlock | 7 days |
| 7 – Not jailbroken / Code integrity | Require code integrity | 7 days |

> **How grace periods work in Intune:** During the grace period a non-compliant device is marked **In grace period** rather than **Not compliant**. Conditional Access policies can be configured to block access only after the grace period expires, giving users and support teams time to remediate without immediate access loss.

---

## Flagged UI Path Warnings

The following settings have known UI labelling changes or areas of uncertainty since training data. Verify these paths in your live Intune tenant before publishing the policy.

| # | Setting | Warning |
|---|---|---|
| R6 | Require a password to unlock mobile devices | Label may have changed on Windows compliance policies — the "mobile devices" wording is a legacy label; verify current section name under System Security → Password in your tenant. |
| R7 | No jailbreak or root | This toggle is meaningful on iOS/Android only. For Windows 11, use **Require code integrity** under Device Health instead. Confirm this path has not been relocated under the Endpoint security section in your tenant version. |
| R3 | Minimum OS version | If devices have upgraded to Windows 11 23H2 (build 22631.x) or 24H2 (build 26100.x), the build number format changes. A single minimum build value only applies to one feature update branch — you may need separate policies per OS version or use the **Maximum OS version** setting to force a specific branch. |

---

## Next Steps

1. Create the compliance policy in Intune scoped to a **Pilot** device group first.  
2. Monitor the **Device compliance** report for 7 days before broadening assignment.  
3. Review false-positive flags against the risks documented above before expanding to production.  
4. Schedule a monthly review of the minimum OS build value (Requirement 3) aligned to Patch Tuesday.  
5. Integrate compliance state with Conditional Access — require compliant device for access to M365 and internal DWP resources.
