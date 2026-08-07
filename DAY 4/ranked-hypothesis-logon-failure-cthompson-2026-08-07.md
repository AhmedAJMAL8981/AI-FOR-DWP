# Ranked Hypothesis - User Logon Failure (cthompson)

Date: 2026-08-07  
Analyst: DWP Engineer

## Scope Facts Used (Only)
- Symptom: user `cthompson` not able to login
- Affected users: `cthompson` only
- Start time: around 08:40 this morning
- Known change: none reported

## Top 5 Most Likely Causes (Most Probable First)

### 1) Account lockout triggered by bad/old cached credentials on another device or service
Why this fits scope facts:
- Single-user impact strongly points to an account-specific issue, not a broad platform outage.
- Sudden start time (~08:40) matches a lockout threshold being reached after repeated bad attempts.
- No known change is consistent with background retries from a stale credential source (phone mail app, mapped drive, scheduled task, saved VPN credential).

Single fastest check:
- In AD/Azure identity admin view, check whether `cthompson` is currently locked and review the latest lockout event timestamp/source host.

### 2) Password expired or account forced to change password, but user cannot complete the flow
Why this fits scope facts:
- Affects one user only and can begin at a specific time when policy thresholds are reached.
- "No change" still fits because expiration is policy-driven, not a newly introduced change.

Single fastest check:
- Check `cthompson` account password status (expired / must change at next logon) in identity directory.

### 3) Account disabled/restricted (manual or automated security action)
Why this fits scope facts:
- Purely user-specific symptom.
- Can appear suddenly in the morning if an automated protection rule or admin action occurred.
- No broad impact or change required.

Single fastest check:
- Verify `cthompson` account enabled state and sign-in block status in identity admin portal.

### 4) MFA/Conditional Access challenge failure specific to user factors
Why this fits scope facts:
- One-user-only failures commonly occur with per-user MFA method issues (lost device, app desync, number matching failure).
- Sudden onset can happen without infrastructure change (token/session invalidation, phone time drift, denied prompt).

Single fastest check:
- Review `cthompson` latest sign-in logs for failure reason code tied to MFA/Conditional Access.

### 5) Endpoint-specific local sign-in issue (credential provider, cached profile, local policy on user device)
Why this fits scope facts:
- Single-user impact can still be endpoint-bound if issue reproduces only on one machine.
- Start time aligns with a reboot/start-of-day local condition.
- No environment-wide change needed.

Single fastest check:
- Test `cthompson` sign-in on a known-good alternate endpoint (or test a known-good user on cthompson's device) to split account vs device cause immediately.

## Note
This is a ranked hypothesis based only on provided scope facts; no single root cause is confirmed yet.

## Evidence Assessment Against Each Hypothesis

Evidence set assessed: Security log on DESKTOP-FB022, incident window 08:44-09:12.

### 1) Account lockout triggered by bad/old cached credentials on another device or service
Judgement: Supports.

Why:
- Event 4740 at 08:44:56 confirms the account was locked out.
- Event 4776 at 08:44:01 shows wrong password (0xC000006A) for FINBRIDGE\cthompson.
- Events 4771 at 08:45:44, 08:46:01, and 08:46:33 show continued wrong-password Kerberos pre-auth (0x18) from source IP 10.10.8.112, which differs from DESKTOP-FB022 (10.10.1.88), supporting a secondary credential source.

Determinative citations:
- 4740 at 08:44:56
- 4776 at 08:44:01
- 4771 at 08:45:44, 08:46:01, 08:46:33

### 2) Password expired or account forced to change password, but user cannot complete the flow
Judgement: Contradicts.

Why:
- Observed failures are explicit wrong-password failures, not expiry/change-required indicators.
- Event 4776 reports 0xC000006A (wrong password), and Event 4771 reports 0x18 (wrong password).

Determinative citations:
- 4776 at 08:44:01 (0xC000006A)
- 4771 at 08:45:44, 08:46:01, 08:46:33 (0x18)

### 3) Account disabled/restricted (manual or automated security action)
Judgement: Contradicts.

Why:
- Failure reason is bad password followed by lockout, not disabled/restricted state.
- Event 4740 indicates a lockout transition happened after repeated bad-password attempts, which is a different failure mode from an already-disabled account.

Determinative citations:
- 4625 at 08:44:03, 08:44:28, 08:44:55 (bad password)
- 4740 at 08:44:56 (account locked out)

### 4) MFA/Conditional Access challenge failure specific to user factors
Judgement: Contradicts.

Why:
- Security events show authentication failing at password/pre-auth stage before MFA challenge success could matter.
- Wrong-password indicators dominate the sequence.

Determinative citations:
- 4776 at 08:44:01 (0xC000006A wrong password)
- 4771 at 08:45:44, 08:46:01, 08:46:33 (0x18 wrong password)

### 5) Endpoint-specific local sign-in issue (credential provider, cached profile, local policy on user device)
Judgement: Contradicts (for an endpoint-only explanation).

Why:
- Initial interactive failures on DESKTOP-FB022 are present, but subsequent wrong-password Kerberos attempts come from a different source IP (10.10.8.112).
- Multi-source bad credentials points to account credential misuse/stale secret replay beyond a single local endpoint condition.

Determinative citations:
- 4625 at 08:44:03, 08:44:28, 08:44:55 from DESKTOP-FB022
- 4771 at 08:45:44, 08:46:01, 08:46:33 from 10.10.8.112
