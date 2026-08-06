# VPN / Windows 11 Upgrade — Engineer Note

**Ref:** T-1008 (VPN connects, no internal access after Win11 upgrade)

**Engineer note:**

**Root cause:** Win11 upgrade removed the legacy VPN client and did not trigger the Intune re-deployment of the new client, due to a detection-rule gap in the app deployment policy.

**Action taken:**
- Manually removed stale VPN registry entries under `HKLM\SOFTWARE\<vendor>`.
- Force-triggered Intune sync on the affected device.
- New VPN client deployed via Intune.
- Split-tunnel config applied.

**Config detail:** Split-tunnel VPN profile pushed as part of the new client install (standard profile); registry cleanup targeted stale `<vendor>` keys left behind by the legacy client uninstall.

**Verification:** Connectivity confirmed to all internal subnets post-fix; VPN connects and internal resources reachable.

**Preventive action needed:** Fix/tighten the Intune detection rule for the VPN client deployment so an in-place Win11 upgrade correctly triggers re-deployment of the new client (don't rely on legacy-client artifacts as detection logic). Consider adding a post-upgrade compliance check/remediation script to catch this scenario proactively.

**Data loss:** None.
