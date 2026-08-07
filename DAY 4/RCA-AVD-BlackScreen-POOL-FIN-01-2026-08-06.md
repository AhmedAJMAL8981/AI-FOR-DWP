# Root Cause Analysis (RCA)

## Incident Title
AVD Black Screen Post-Login on POOL-FIN-01 After Overnight Image Update

## Document Control
- Date: 2026-08-06
- Prepared by: DWWP Engineering
- Severity: High (user productivity impact)
- Status: Resolved
- Resolution verified at: 10:00

## Executive Summary
At approximately 07:00, users in POOL-FIN-01 began experiencing a black screen after login. Some sessions recovered after about 30 seconds while others disconnected or remained unusable. POOL-FIN-02 was fully unaffected. Investigation correlated the issue to the overnight 02:00 image update applied only to POOL-FIN-01. Event evidence from affected hosts showed repeated Desktop Window Manager (dwm.exe) crashes in Intel graphics module igdumd64.dll, followed by session disconnect behavior. The recommended graphics/image remediation was implemented, and service was verified restored at 10:00 with successful user logins and no new user reports.

## Scope and Impact
- Symptom: Blank screen after login.
- User impact pattern: Intermittent recovery for some users (~30 seconds), persistent for others.
- Affected population: Approximately 40 percent of users on POOL-FIN-01.
- Unaffected population: POOL-FIN-02 (100 percent unaffected).
- Service impact window: Approximately 07:00 to 10:00.

## Environment and Change Context
- Host pool A (affected): POOL-FIN-01
- Host pool B (control, unaffected): POOL-FIN-02
- Relevant change: Overnight image update at 02:00 applied to POOL-FIN-01 only.
- Control condition: POOL-FIN-02 did not receive the update and had no symptoms.

## Supporting Evidence

### Evidence Set A: Affected host SHFIN-01-A (07:00-07:30)
- 07:02:10 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21
  - Session logon succeeded (user FINBRIDGE\\mlopez, Session ID 3).
- 07:02:14 - Microsoft-Windows-Kernel-General, Event 1
  - Boot time was 02:03:11 (post-update restart alignment).
- 07:02:16 - Application Error, Event 1000 (Error)
  - Faulting app: dwm.exe
  - Faulting module: igdumd64.dll
  - Exception: 0xc0000005
- 07:02:17 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 40
  - Session disconnected (Session ID 3).
- 07:02:18 - Desktop Window Manager, Event 9009 (Error)
  - DWM exited with code 0x40010004.
- 07:02:44 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21
  - Reconnect logon succeeded.
- 07:02:46 - Application Error, Event 1000
  - Repeat dwm.exe fault in igdumd64.dll.
- 07:02:47 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 40
  - Session disconnected.
- 07:03:01 - Desktop Window Manager, Event 9009
  - Repeat DWM exit.
- 07:03:10 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21
  - Second reconnect logon succeeded.
- 07:08:22 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21
  - Session logon succeeded (user FINBRIDGE\\akapoor).
- 07:08:24 - Application Error, Event 1000
  - Repeat dwm.exe fault in igdumd64.dll.

### Evidence Set B: Unaffected comparison host SHFIN-02-A (POOL-FIN-02)
- 07:01:44 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21
  - Session logon succeeded.
- 07:01:46 - Desktop Window Manager, Event 9011 (Information)
  - DWM started successfully.
- No Application Error Event 1000 entries in same window.

### Evidence Interpretation
- Repeating DWM crashes tied to Intel graphics user-mode module on affected host.
- Disconnection loop follows DWM crashes.
- Clean control host (pre-update image) without corresponding failures.
- Strongest causal discriminator: only updated pool failed.

## Incident Timeline
- 02:00 - Overnight image update applied to POOL-FIN-01.
- 02:03:11 - Affected host reboot time recorded (Event 1 observed at 07:02:14).
- Approximately 07:00 - User impact begins (black screen post-login) in POOL-FIN-01.
- 07:02:10 to 07:08:24 - Repeated Event 1000 (dwm.exe fault in igdumd64.dll) and Event 9009 on affected host.
- During investigation - Hypothesis elimination confirms graphics/image-linked failure as surviving cause.
- Remediation applied - Recommended graphics/image resolution executed on affected pool path.
- 10:00 - Resolution verified: users logging in to POOL-FIN-01 successfully; no issues reported.

## Root Cause Statement
A graphics/display stack regression was introduced through the POOL-FIN-01 image update, resulting in repeated Desktop Window Manager (dwm.exe) failures in Intel graphics module igdumd64.dll. This caused black-screen behavior and session instability/disconnect loops after user logon.

## Why Other Hypotheses Were Eliminated
- FSLogix profile attach regression: no direct FSLogix error evidence in provided window; observed failure signature is explicit DWM graphics crash.
- Logon policy/script regression: logon succeeds, then fails in graphics stack within seconds; not a generic script latency signature.
- Shell/AppX startup issue: possible in general black-screen incidents, but no direct shell/AppX error entries and evidence is dominated by DWM/driver faulting.

## 5-Whys Analysis
1. Why did users see a black screen after login?
   - Because DWM crashed repeatedly during session initialization.
2. Why did DWM crash?
   - Because dwm.exe faulted in igdumd64.dll (Intel graphics user-mode driver), Event 1000.
3. Why was the unstable graphics module active on affected hosts?
   - Because the updated POOL-FIN-01 image introduced or activated a graphics component/version path that was unstable in this AVD workload.
4. Why did this reach production users?
   - Because image promotion controls did not block rollout based on AVD-specific logon/reconnect and DWM stability validation.
5. Why were controls insufficient?
   - Because pre-release testing and quality gates for graphics stack reliability in pooled AVD sessions were not strict enough to detect this failure mode before deployment.

## Resolution Actions Implemented
- Contained impact by prioritizing unaffected pool usage where possible.
- Applied approved graphics/image remediation for POOL-FIN-01 hosts (driver/acceleration path correction per incident runbook).
- Revalidated host/session behavior post-change.
- Confirmed service restoration at 10:00 with successful user access and no new issue reports.

## Preventive and Corrective Actions (CAPA)

### Immediate (completed or in progress)
- Add active monitoring alert for Event 1000 where faulting app is dwm.exe and module is igdumd64.dll.
- Add alert for DWM Event 9009 spikes per host pool.
- Attach pool-level health dashboard for login success, disconnect rate, and black-screen incidents.

### Short term (next release cycle)
- Introduce canary rollout for all AVD image changes (10 to 20 percent hosts first).
- Add release gate: block promotion if repeated DWM crash signatures appear in soak tests.
- Lock graphics driver versions in image pipeline until explicitly validated.

### Medium term (process hardening)
- Build automated pre-production AVD soak tests:
  - Multiple concurrent user logins.
  - Reconnect cycles.
  - Validation of desktop readiness time.
  - Event log quality checks for Event 1000 and Event 9009.
- Formalize rollback trigger thresholds and decision matrix in change procedure.

### Ownership and Tracking
- DWWP Engineering: image pipeline gates, soak automation.
- EUC/Platform Team: driver governance and validation matrix.
- Operations: monitoring rules and incident playbook update.

## Verification of Recovery
- Verification time: 10:00.
- Verification criteria met:
  - Users logging in successfully to POOL-FIN-01.
  - No active black-screen reports after fix.
  - No continuing session disconnect pattern reported.

## Residual Risk
- Moderate until next full image cycle proves sustained stability.
- Mitigated by canary-first rollout, event-based gates, and driver pinning.

## Lessons Learned
- Pool-differential impact plus change timing is a high-confidence directional signal and should trigger immediate image regression checks.
- DWM and graphics-module crash signatures must be first-class release blockers in AVD environments.
- Control pools (non-updated) provide decisive evidence and should be embedded in standard triage workflow.
