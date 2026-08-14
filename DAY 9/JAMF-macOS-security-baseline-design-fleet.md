# JAMF macOS Security Baseline Translation
**Author:** DWP Engineer  
**Date:** 2026-08-14  
**Scope:** 25-device macOS fleet for the Design team  
**Platform:** JAMF Pro / macOS configuration profiles

---

## Overview

This document translates the DWP macOS security baseline into the closest JAMF Pro configuration profile settings for a small Design team fleet.

Each requirement includes the payload type, the value to configure, the plain-English effect, and the most common false-positive risks. Where JAMF UI wording or payload placement has changed across versions, the row is flagged so the reader verifies the exact label in their own JAMF instance instead of assuming the wording in this document is exact.

> **UI Path Note:** JAMF Pro menu names can vary slightly by version and tenant layout. Verify the current location in your own instance before publishing the profile.

> **Suggested entry point:**
> JAMF Pro → Computers → Configuration Profiles → New

> **Basics tab:**
> - **Name:** Use a descriptive profile name such as `DWP-macOS-Security-Baseline-Design`
> - **Description:** Summarise the intent, for example `Enforces FileVault, Gatekeeper, Firewall, password lock after sleep, minimum macOS version monitoring, and automatic security updates for the Design team fleet.`
> - **Scope:** Target the 25-device Design team smart group or static computer group

---

## Configuration Profile Payloads

The baseline is best implemented as one main configuration profile plus inventory/compliance reporting for the OS version requirement.

| Requirement | Payload type | Value | Effect | False-positive risk |
| --- | --- | --- | --- | --- |
| FileVault disk encryption must be enabled | Security & Privacy / FileVault | Enable FileVault and escrow the personal recovery key to JAMF | Enforces full-disk encryption so data remains protected if the device is lost, stolen, or repurposed. | New Macs may still be encrypting the disk when the profile is evaluated. Devices can also appear noncompliant if the escrowed key has not yet checked in or a user changed the account password during encryption. |
| Gatekeeper must be enabled (identified developers only) | Security & Privacy / Gatekeeper | Allow apps from identified developers only | Prevents unsigned or unknown apps from launching without user approval. | Notarized apps, Mac App Store apps, and vendor tools distributed through other managed channels may still trigger user concern or support tickets even when they are allowed. |
| Minimum macOS version: current stable minus one point release | Not a reliable native configuration profile control; use Smart Group / Extension Attribute / Policy reporting | Require the device to be at or above the approved OS version threshold for the current stable minus one point release | Flags devices that are behind the supported macOS release level so they can be remediated or blocked from access. | Devices waiting on user reboot, holding deferred updates, or still in the middle of a staged rollout can temporarily look out of compliance. Apple point releases also move the baseline, so the value must be refreshed as part of maintenance. |
| Firewall must be enabled | Security & Privacy / Firewall | Turn on the built-in application firewall | Blocks unsolicited inbound connections unless they are explicitly allowed. | Third-party endpoint firewall products and network/security agents may make the Mac effectively protected even when JAMF only sees the built-in macOS firewall state. |
| Login password required after sleep/screen saver | Security & Privacy / General or Login Window; exact label may vary | Require a password immediately after sleep or screen saver begins | Forces re-authentication whenever the Mac wakes from sleep or the screen saver locks the session. | Shared devices, remote support sessions, and users with long idle-lock preferences can create drift between the enforced profile and the live user experience if enforcement is not continuous. |
| Automatic security updates enabled | Software Update | Enable automatic installation of security updates and system data files | Lets macOS install security fixes without waiting for a manual maintenance action. | Devices that are offline, deferred by policy, or waiting for a restart can appear noncompliant even though the setting is correct. Apple has also changed software update control names across macOS releases, so the exact UI wording may differ. |

---

## Requirement 1 – FileVault must be enabled

| Field | Detail |
|---|---|
| **Payload type** | Security & Privacy → FileVault |
| **Value** | Enable FileVault; escrow the recovery key to JAMF |
| **Effect** | Encrypts the entire disk so local data is unreadable without valid credentials and the recovery key. |

**False-Positive Risk:**
- Encryption is still in progress after enrollment or after a major macOS upgrade.
- The personal recovery key has not yet been escrowed back to JAMF.
- The device has not checked in since FileVault was enabled.
- A password reset or account migration interrupted escrow reporting.

**Recommendation:**
Use a FileVault-specific smart group or inventory view to confirm both encryption state and escrow state before treating the device as genuinely noncompliant. For a 25-device fleet, this reduces noise without weakening the control.

---

## Requirement 2 – Gatekeeper must be enabled

| Field | Detail |
|---|---|
| **Payload type** | Security & Privacy → Gatekeeper |
| **Value** | Allow apps from identified developers only |
| **Effect** | Restricts app launches so only Apple-approved or identified-developer applications run without manual override. |

**False-Positive Risk:**
- The device is using signed and notarized apps that users still consider “blocked” because of the warning dialog.
- A managed app exception exists but the user is looking at the old warning state.
- A third-party security product or app-control agent is also intercepting application launches.

**Recommendation:**
If the design team relies on non-App Store creative tools, publish an approved software list and explain the expected first-launch prompts. That keeps support tickets from being mistaken for policy drift.

---

## Requirement 3 – Minimum macOS version must be current stable minus one point release

> **Important:** JAMF does not always expose a direct, universal configuration profile control for a minimum macOS version in the same way that security settings such as FileVault or Firewall are exposed. In most JAMF environments this is enforced through inventory, smart groups, extension attributes, and policy scope rather than a single profile payload.

| Field | Detail |
|---|---|
| **Payload type** | Inventory / Smart Computer Group / Extension Attribute / Policy scope |
| **Value** | Set the approved minimum to the current stable macOS release minus one point version |
| **Effect** | Keeps the fleet on a supported version and identifies devices that need an operating system update before they drift too far behind. |

**False-Positive Risk:**
- The device has downloaded the update but has not restarted.
- A staged rollout or deferral policy is intentionally holding the device back.
- Apple has released a new point update and the minimum value has not yet been revised.
- A device has been offline long enough that its inventory data is stale.

**Recommendation:**
Treat this as a reporting and enforcement workflow rather than a single configuration profile setting. For a small fleet, a smart group based on OS version is usually the cleanest way to maintain visibility.

---

## Requirement 4 – Firewall must be enabled

| Field | Detail |
|---|---|
| **Payload type** | Security & Privacy → Firewall |
| **Value** | Turn on the built-in application firewall |
| **Effect** | Blocks unsolicited inbound traffic unless an app or rule is explicitly allowed. |

**False-Positive Risk:**
- Third-party firewall tools are installed and macOS Firewall is disabled by design.
- Network security software temporarily changes firewall state during installation or update.
- The device has not checked in since the firewall was enabled.

**Recommendation:**
If the design fleet uses any third-party endpoint security stack, decide whether the Jamf control should measure the built-in firewall only or the broader security posture. Do not assume one is a substitute for the other.

---

## Requirement 5 – Login password required after sleep/screen saver

| Field | Detail |
|---|---|
| **Payload type** | Security & Privacy → General or Login Window; exact label may vary |
| **Value** | Require a password immediately after sleep or screen saver begins |
| **Effect** | Re-locks the Mac as soon as it sleeps or the screen saver starts, preventing unattended access. |

**False-Positive Risk:**
- The user is working through a remote support session that temporarily suppresses lock behavior.
- A shared or kiosk-style device has a legitimate exception.
- The local user has changed the lock timing and the profile has not yet re-applied.

**Recommendation:**
This is one of the controls most likely to show UI naming drift across JAMF and macOS releases. Verify the current payload and field label in your tenant before publishing the profile.

---

## Requirement 6 – Automatic security updates must be enabled

| Field | Detail |
|---|---|
| **Payload type** | Software Update |
| **Value** | Enable automatic installation of security updates and system data files |
| **Effect** | Lets macOS install security fixes without waiting for a manual update cycle. |

**False-Positive Risk:**
- The device is offline when the compliance or inventory check runs.
- A pending restart is required before the update state is fully reflected.
- Apple renamed the update toggle or grouped it differently on the current macOS release.

**Recommendation:**
Do not rely on this setting alone for patch enforcement. Pair it with OS version reporting so you can distinguish “auto-update enabled” from “actually patched.”

---

## JAMF Label Drift Watchlist

Verify the exact JAMF UI/payload wording for these controls in your own instance rather than trusting this document as an exact label reference:

- FileVault payload naming
- Gatekeeper payload naming
- Login password after sleep/screen saver wording
- Automatic security updates wording under Software Update
- Minimum macOS version handling, because many JAMF tenants implement it through smart groups rather than a single profile field

---

## Deployment Notes

### Recommended scope

- Target the 25-device Design team fleet through a smart computer group or a static group.
- If the team includes test devices, keep them in a separate group so they do not pollute compliance reporting.
- Use a staged rollout if you expect FileVault escrow or OS version drift from older devices.

### Suggested validation steps

1. Confirm the profile is scoped to the intended 25 devices only.
2. Verify FileVault is enabled and the key is escrowed on at least one sample machine.
3. Confirm Firewall and Gatekeeper state on a checked-in device.
4. Check that the smart group for minimum macOS version updates after inventory refresh.
5. Review any devices flagged noncompliant to determine whether the cause is real drift or a stale check-in.

### First 24-hour noise checks

| Check | What to look for | Expected result |
|---|---|---|
| FileVault escrow status | Encryption completed and recovery key present | Devices move from pending to compliant after check-in |
| OS version inventory freshness | Last inventory update timestamp | Devices should show current version data after the next inventory run |
| Firewall/Gatekeeper state | Profile applied and state active | Small or no drift on managed devices |
| Sleep password enforcement | Idle lock behavior | Devices lock immediately after sleep or screen saver |

---

## Practical Notes

- For a 25-device design fleet, use smart groups aggressively; they make drift visible without forcing unnecessary profile complexity.
- Treat minimum macOS version as a control that needs monthly review, not a set-and-forget checkbox.
- If your JAMF instance shows the controls under different headings, prefer the live tenant label over this document.
- When a control is implemented partly through inventory rather than a profile payload, document that clearly so the support team knows where to verify it.