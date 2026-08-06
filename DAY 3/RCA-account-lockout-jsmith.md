# Root Cause Analysis (RCA): Account Lockout — jsmith

## Incident Summary
On 2026-08-06, user **jsmith** was locked out of their machine (DESKTOP-FB001) for approximately 16 minutes (08:06:01–08:22:10) following repeated failed logon attempts. The account was re-enabled by helpdesk-admin and the user successfully logged on at 08:23:44.

## Event ID Reference

| Event ID | Meaning |
|---|---|
| **4625** | An account failed to log on. Logged on the machine where the logon attempt was made; includes failure reason (e.g., bad password, account locked out) and logon type. |
| **4740** | A user account was locked out. Logged (typically on the Domain Controller) when the failed-logon threshold defined in the account lockout policy is reached; identifies the account and the source ("Called from") workstation that caused the lockout. |
| **4722** | A user account was enabled. Logged when an administrator re-enables/activates a disabled or locked account object; includes the identity of the admin who performed the action. |
| **4624** | An account was successfully logged on. Confirms the account authenticated and includes the logon type used. |

**Logon types referenced:**
- **Type 2 – Interactive**: Logon at the local keyboard/console (e.g., typing credentials at the Windows sign-in screen).
- **Type 7 – Unlock**: Logon attempt made by unlocking an already-in-session, locked workstation (Ctrl+Alt+Del "unlock" screen).

## Reconstructed Sequence of Events (Plain English)

1. **08:02:14** – jsmith attempted to sign in at the keyboard of DESKTOP-FB001 and entered incorrect credentials; the logon failed with "Unknown username or bad password."
2. **08:04:22** – Two minutes later, jsmith tried again at the same machine and failed a second time with the same reason.
3. **08:06:01** – The account's failed-logon count reached the domain lockout threshold, and the account was automatically locked out. The lockout was attributed to activity originating from DESKTOP-FB001.
4. **08:07:45** – jsmith attempted to unlock their (already in-session) workstation; this attempt also failed, but this time because the account was locked out — not because of a bad password.
5. **08:22:10** – Approximately 16 minutes later, a helpdesk administrator (FINBRIDGE\helpdesk-admin) re-enabled/unlocked the jsmith account.
6. **08:23:44** – jsmith successfully logged on interactively, confirming the account and credentials were working normally.

## Most Likely Cause (with Evidence)

**Most likely cause:** jsmith entered an incorrect password twice in quick succession at the local console of DESKTOP-FB001, tripping the account lockout policy. The most probable underlying reason is that jsmith was using a stale/incorrect password (e.g., recently changed password not yet updated by the user, or a simple mistype), rather than an external/malicious actor.

**Supporting evidence:**
- Both failures (08:02:14, 08:04:22) are **Logon type 2 (Interactive)** from the **same source machine (DESKTOP-FB001)** — consistent with the same person typing credentials at the console, not a remote or automated/brute-force attempt from another host.
- The two failures are only ~2 minutes apart with the same failure reason ("Unknown username or bad password"), consistent with a user retrying after a typo rather than a scripted attack (no high-volume/rapid-fire attempts seen).
- The **4740** lockout event is attributed to the same workstation (DESKTOP-FB001), confirming the lockout originated from this user's own repeated attempts, not a separate device.
- The **08:07:45** failure is a **Type 7 (Unlock)** attempt with failure reason "Account locked out" — this is the expected/benign result of trying to unlock a session after a lockout has already occurred, not a new cause.
- Resolution required manual helpdesk action (**4722**) rather than an automatic timeout, and the subsequent logon (**4624**) succeeded on the first attempt — consistent with the credential itself being fine once the lockout was cleared (i.e., not a broader account/identity problem).

There is no evidence in this log window of a compromise attempt (e.g., logons from unfamiliar hosts/IPs, high attempt volume, or use of unusual logon types), but this should be confirmed against a wider log window before being fully ruled out.

## 5 Whys Analysis

1. **Why was jsmith's account locked out?**
   Because two consecutive failed interactive logon attempts on DESKTOP-FB001 (08:02:14 and 08:04:22) exceeded the account lockout threshold, triggering an automatic lockout at 08:06:01.

2. **Why were there two consecutive failed logon attempts?**
   Because jsmith entered an incorrect password both times when signing in at the console (*to confirm*: exact reason for the incorrect entries).

3. **Why was an incorrect password entered on both attempts?**
   Most likely because jsmith was using an outdated/stale password (e.g., following a recent password change or expiry) or simply mistyped it under time pressure (*to confirm* with jsmith directly — no corroborating event, such as a password-change event, is present in this log window).

4. **Why did jsmith not realize the password was incorrect/outdated before repeating the same attempt?**
   Because the standard Windows logon failure message ("Unknown username or bad password") does not distinguish between a mistyped password and an expired/changed credential, so the user had no clear signal to stop and use a different recovery path (e.g., self-service password reset) before retrying with the same credential.

5. **Why is there no safeguard to prevent a user from being locked out before they can self-correct or get help?**
   Because the environment relies on a hard lockout policy with no intermediate warning (e.g., "1 attempt remaining before lockout") and no readily available self-service unlock/reset option at the point of failure, meaning any short run of incorrect attempts — regardless of intent — results in a full lockout requiring helpdesk intervention.

**Root cause:** Lack of user-facing signal distinguishing "bad password" from "credential needs resetting," combined with an account lockout policy that has no interim warning or self-service recovery step, allowed a routine credential mistake to escalate into a ~16-minute lockout requiring manual helpdesk remediation.

## Recommendations / Corrective Actions

- Enable self-service password reset (SSPR) so users can resolve bad/expired credentials without waiting for helpdesk.
- Configure a lockout warning threshold (e.g., "Windows Hello"/logon banner or NetWrix-style alert) so users are notified after 1 failed attempt with guidance before the lockout threshold is reached.
- Confirm with jsmith whether a recent password change occurred; if so, review the communication process for notifying users of password expiry ahead of time.
- Review whether devices/services with cached credentials (mapped drives, mobile mail profiles, scheduled tasks) under jsmith's account could contribute to repeated auth failures in future incidents.
- Track average time-to-remediate for lockout tickets; 16 minutes from lockout to helpdesk action should be benchmarked against SLA to identify staffing/process improvements.

## Assumptions / Open Items (to confirm)
- Exact reason for incorrect password entries (mistype vs. stale/expired credential vs. recent password change) — not confirmable from log data alone; recommend a brief interview with jsmith.
- Whether the organization's lockout threshold is set to 2 failed attempts (implied by this sequence) — to confirm against domain Group Policy.
- Whether any other sign-in activity for jsmith (e.g., mobile device, VPN, other endpoints) occurred in this window that could also be contributing factors — not present in the provided log excerpt.
