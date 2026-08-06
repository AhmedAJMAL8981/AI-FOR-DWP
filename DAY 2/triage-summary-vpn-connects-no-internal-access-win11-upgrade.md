# Triage Summary - T-1008

## Summary (one line)
VPN connects, but internal resources are unreachable after Windows 11 upgrade.

## Impact (who/how many/business urgency)
- Who is affected: At least one upgraded Win11 user (to-verify).
- How many are affected: Single known report currently; broader post-upgrade VPN impact unknown (to-verify).
- Business urgency: High (to-verify) because user has remote connectivity but cannot access internal business services.

## Known Facts
- Ticket reference: T-1008.
- Symptom: VPN connection succeeds.
- Additional symptom: Internal resources are not reachable.
- Timing/context: Issue reported after Windows 11 upgrade.

## Missing Information to Gather
- User/device identifiers and current network location (home/office/hotspot) (to-verify).
- Which internal resources fail (file shares, intranet, line-of-business apps, remote management endpoints) (to-verify).
- Whether any internal resource is reachable by name or by direct address (to-verify).
- Whether issue reproduces across different networks for the same device/user (to-verify).
- VPN client version/profile details and whether policy/profile changed during upgrade (to-verify).
- Whether split/full tunnel behavior is expected for this user profile (to-verify).
- Whether similar post-upgrade VPN routing/name-resolution issues are reported by other users (to-verify).
- Exact timestamp of failed access attempts for log correlation (to-verify).

## Likely Category
Remote Access - VPN Post-Windows 11 Upgrade Connectivity/Routing Issue (to-verify).

## First Diagnostic Step
Validate path and scope by testing access to a known internal resource using both hostname and direct address immediately after VPN connection, then compare results to determine whether the primary break is name resolution or network routing.