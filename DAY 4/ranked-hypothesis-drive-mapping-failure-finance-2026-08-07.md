# Ranked Hypothesis - Finance Shared Drive Mapping Failure (2026-08-07)

## Scope-Limited Assessment
This ranking uses only the provided scope facts and weights heavily the timing/change clue:
- 2024-03-14 23:30 migration from GPO logon script (USER context) to Intune PowerShell script (SYSTEM context)
- Script was not updated for SYSTEM context
- Reproducible pattern on multiple Finance endpoints
- Group Policy processed successfully (not a GP processing failure)

## Ranked Top 5 Likely Causes (Most Probable First)

### 1) Script is running in SYSTEM context and trying to access a user-scoped UNC/mapping path without user credentials
**Why this fits the scope facts**
- Intune log explicitly shows: "Script context: SYSTEM account" at 08:00:02.
- Immediate warning/error: UNC path not accessible from SYSTEM; "Network name cannot be found"; exit code 1.
- Change note states script moved from USER to SYSTEM and was not updated.
- Blast radius (all Finance users) matches a common deployment-context defect.

**Single fastest check**
- On one impacted device, run `whoami` and re-run the script once as logged-on Finance user vs Local SYSTEM (`psexec -s`). If USER succeeds and SYSTEM fails, this cause is confirmed.

### 2) Script executes too early in boot/login sequence, before network provider pathing is usable in SYSTEM context
**Why this fits the scope facts**
- Failure at 08:00:03 occurs before Workstation service "entered running state" at 08:00:05.
- UNC access depends on SMB client stack and network readiness; timing mismatch explains immediate failure.
- Same timestamp pattern on multiple desktops supports deterministic race condition.

**Single fastest check**
- On one affected endpoint, trigger the same SYSTEM script manually 2-3 minutes after startup. If it succeeds later but fails at startup, early-execution timing is confirmed.

### 3) No retry logic in Intune script assignment causes transient startup failure to become persistent user impact
**Why this fits the scope facts**
- Log states "No retry configured" immediately after failure.
- Even brief startup unavailability (service/network) would self-heal with retry, but current design guarantees first-failure stickiness.
- Explains why many users are affected at the same start-of-day window.

**Single fastest check**
- Review Intune assignment/run configuration and script body for retry loop. Add a temporary delayed second attempt on a pilot endpoint; if second attempt maps successfully, this cause is validated.

### 4) Drive mapping is being created in the wrong security/session context (SYSTEM session), so users do not receive usable S: mapping
**Why this fits the scope facts**
- Script executes in SYSTEM, not interactive user session.
- `Ntfs Event 98` indicates S: not assigned; this is consistent with mapping not being established where user session expects it.
- Migration from USER-context GPO script to SYSTEM-context Intune is directly aligned with this behavior shift.

**Single fastest check**
- Compare `net use` output under SYSTEM and under impacted user on the same machine. If SYSTEM has/no-attempts while user has no S: mapping, context separation is confirmed.

### 5) Name/path reachability issue to `\\finbridge-fs01\Finance` from endpoint network context (DNS/smb routing), amplified by SYSTEM execution timing
**Why this fits the scope facts**
- Error string includes "Network name cannot be found," which can indicate name resolution/reachability failures.
- Could be contributory, but lower probability because the migration/timing evidence explains causality more directly.
- Cross-device occurrence means it could still be an environment-level dependency issue at startup.

**Single fastest check**
- From one impacted endpoint at failure time, test `Resolve-DnsName finbridge-fs01` and `Test-NetConnection finbridge-fs01 -Port 445` under SYSTEM context.

## Chained Prompt Response (Explicit Timing-Clue Re-rank)
Question: Which cause is most consistent with (a) GP processed successfully and (b) behavior changed only after migration to SYSTEM on 2024-03-14 23:30?

**Most consistent cause: #1 (SYSTEM context cannot perform user-intended UNC mapping with required credentials/session context).**

### Why this is most consistent
- GP processed successfully at 08:00:06, so a GP-processing fault is explicitly ruled out.
- The behavioral inflection point is the migration from USER to SYSTEM context; previously working behavior changed after that deployment model switch.
- The Intune log directly names SYSTEM context and immediate UNC access failure, matching the documented known limitation in the change note.

### Explicit re-rank with that reasoning weighted
1. SYSTEM-context execution cannot satisfy user-context UNC mapping requirements (credentials/session scope mismatch)
2. Script timing at startup precedes full network/Workstation readiness for UNC access in SYSTEM context
3. Missing retry logic converts transient startup unavailability into a sustained outage symptom
4. Mapping occurs (or attempts occur) outside interactive user context, leaving user-visible S: unassigned
5. Underlying DNS/SMB path reachability issue to `\\finbridge-fs01\Finance` (possible but less likely than migration-context causes)

## Current Position
No single root cause is asserted yet. This is a ranked hypothesis list based on available evidence and the migration timing clue.
