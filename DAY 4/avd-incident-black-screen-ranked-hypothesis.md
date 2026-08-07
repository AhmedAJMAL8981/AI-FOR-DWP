# AVD Incident Black Screen - Ranked Hypotheses

Date: 2026-08-06
Scope baseline: POOL-FIN-01 impacted after 02:00 image update; POOL-FIN-02 not updated and unaffected.

## Scope Facts
- Symptom: blank screen post-login; clears after ~30s for some users, persists for others.
- Who: ~40% of users on POOL-FIN-01.
- Since: ~07:00 this morning.
- Change: overnight image update to POOL-FIN-01 at 02:00; POOL-FIN-02 was not updated.

## Weighting Logic
Primary weight is the control signal: POOL-FIN-02 was not updated and is fully unaffected. Therefore, causes that depend on the POOL-FIN-01 image delta rank above tenant-wide/shared causes.

## Most Consistent With POOL-FIN-02 Unaffected
1. Image-level regression introduced by the POOL-FIN-01 golden image update.

Why this is most consistent:
- Directly matches the only known change boundary (updated pool affected, non-updated pool healthy).
- Explains mixed symptom duration via startup timing/race conditions.

Single fastest check:
- Boot one POOL-FIN-01 session host from the previous known-good image and test affected user logon. If black screen disappears, image regression is strongly supported.

## Re-ranked Top 5 Causes (Most Probable First)

1. Image-level regression in POOL-FIN-01 golden image (logon shell/GPU/display stack component changed overnight)
- Why this fits: strongest timing and blast-radius match to the 02:00 one-pool-only update.
- Single fastest check: A/B test current image host vs one rollback host in POOL-FIN-01.

2. FSLogix/profile container attach regression triggered by new image build
- Why this fits: image-coupled change with user-variable impact and ~30s delay pattern.
- Single fastest check: inspect FSLogix logon-time attach duration/errors for one affected user.

3. Logon policy/script behavior change activated by new image baseline
- Why this fits: can block shell completion post-auth; user targeting explains partial impact.
- Single fastest check: run one affected test login with scripts/policy bypassed and compare time-to-desktop.

4. Graphics acceleration/driver mismatch introduced in updated image
- Why this fits: black screen post-login is a known display stack failure mode; pool-local timing aligns.
- Single fastest check: toggle to known-stable graphics/acceleration setting on one affected host and retest.

5. Shell/AppX provisioning/startup dependency issue in updated image
- Why this fits: can produce delayed or persistent black desktop depending on user/session state.
- Single fastest check: compare Explorer/shell component startup sequence between affected POOL-FIN-01 and healthy POOL-FIN-02 sessions.

## Note
This is a ranked hypothesis set based on scope facts and timing, not a final root cause declaration.

## Incident Evidence Review Addendum (Appended)

Date reviewed: 2026-08-06
Reviewed host evidence window: 07:00-07:30

### Event Details (Affected vs Unaffected)

Affected host: SHFIN-01-A
- 07:02:10 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21: Session logon succeeded.
- 07:02:14 - Microsoft-Windows-Kernel-General, Event 1: Boot time 02:03:11 (post overnight image update restart).
- 07:02:16 - Application Error, Event 1000: dwm.exe faulting in igdumd64.dll, exception 0xc0000005.
- 07:02:17 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 40: Session disconnected.
- 07:02:18 - Desktop Window Manager, Event 9009: DWM exited with code 0x40010004.
- 07:02:44 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21: Reconnect logon succeeded.
- 07:02:46 - Application Error, Event 1000: repeated dwm.exe fault in igdumd64.dll.
- 07:02:47 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 40: Session disconnected.
- 07:03:01 - Desktop Window Manager, Event 9009: DWM exited with code 0x40010004.
- 07:03:10 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21: second reconnect logon succeeded.
- 07:08:22 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21: Session logon succeeded for another user.
- 07:08:24 - Application Error, Event 1000: repeated dwm.exe fault in igdumd64.dll.

Comparison host: SHFIN-02-A (POOL-FIN-02 unaffected, pre-update image)
- 07:01:44 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21: Session logon succeeded.
- 07:01:46 - Desktop Window Manager, Event 9011: DWM started successfully.
- No Application Error Event 1000 entries in the same window.

### Reviewed Hypotheses Against Evidence

1. Image-level regression in POOL-FIN-01 golden image
- Judgement: Supported.
- Determining evidence: Event 1 at 07:02:14 plus repeated Event 1000 at 07:02:16/07:02:46/07:08:24 only on affected host; unaffected host shows Event 9011 at 07:01:46 and no Event 1000.

2. FSLogix/profile container attach regression
- Judgement: Contradicted by current evidence.
- Determining evidence: immediate DWM crash chain Event 1000 (07:02:16) followed by Event 9009 (07:02:18), repeated at 07:02:46/07:03:01; no FSLogix-specific errors in provided log set.

3. Logon policy or script regression
- Judgement: Contradicted by current evidence.
- Determining evidence: Event 21 logon success at 07:02:10 then rapid DWM/driver failure Event 1000 at 07:02:16 and Event 9009 at 07:02:18.

4. Graphics acceleration or driver mismatch introduced by updated image
- Judgement: Supported.
- Determining evidence: Event 1000 explicitly identifies dwm.exe faulting in igdumd64.dll at 07:02:16, 07:02:46, 07:08:24, with matching Event 9009 DWM exits.

5. Shell/AppX provisioning or startup dependency issue
- Judgement: Neutral to contradicted.
- Determining evidence: no direct shell/AppX failures in provided entries; repeated graphics-module DWM faults are a more direct mechanism.

### Surviving Working Hypothesis

Graphics acceleration or display driver regression introduced by the updated POOL-FIN-01 image, causing DWM crashes in igdumd64.dll and session disconnect or black-screen loops.

### Resolution Steps (Detailed)

1. Contain impact immediately
- Stop new session placement on POOL-FIN-01 (drain mode).
- Redirect users to POOL-FIN-02 where capacity allows.
- Notify service desk with user workaround and incident reference.

2. Validate with one-host A/B mitigation
- Select one affected POOL-FIN-01 host and place in maintenance.
- Apply one temporary mitigation: disable acceleration path or roll back Intel graphics driver to known-good version.
- Reboot and perform 3 to 5 controlled logons.
- Success criteria: no new Event 1000 (dwm.exe/igdumd64.dll), no Event 9009 spike, no immediate Event 21 to Event 40 loop.

3. Remediate at image level
- Open the POOL-FIN-01 golden image used for the 02:00 rollout.
- Remove or roll back Intel display driver package version linked to failures.
- Install approved stable driver version validated previously.
- Prevent automatic reintroduction of the bad package during image build/update.
- Publish a fixed image version with explicit driver change notes.

4. Roll out safely
- Deploy fixed image to canary subset of POOL-FIN-01 hosts first.
- Monitor logon reliability, reconnect behavior, and event signatures for 30 to 60 minutes.
- Promote in waves only if Event 1000/9009 return to baseline.

5. Validate closure
- Compare pre-fix and post-fix error rates for Event 1000 and Event 9009.
- Confirm black-screen reports return to baseline.
- Verify POOL-FIN-02 remains unaffected as control.

6. Backout and escalation criteria
- If canary still reproduces Event 1000 igdumd64.dll faults, halt rollout.
- Revert canary hosts to prior known-good image.
- Escalate with crash dumps, driver inventory, and host comparison bundle.

7. Prevent recurrence
- Add pre-release image soak test for repeated AVD logon/reconnect behavior.
- Add release gate that blocks image promotion on DWM crash signatures.
- Pin graphics driver versions until validated in canary.
