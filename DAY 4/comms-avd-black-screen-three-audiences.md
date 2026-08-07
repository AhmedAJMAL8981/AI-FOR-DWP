# End-User Communication: AVD Black Screen Incident (Three Audiences)

## Audience 1 - Non-technical executive
Your access is restored, and data remained safe. On 2026-08-06, from 07:00 to 10:00, only POOL-FIN-01 was affected; POOL-FIN-02 was unaffected. 40% of POOL-FIN-01 users saw a black screen after sign-in, with some recovering in 30 seconds and others disconnecting. The 02:00 overnight image update in POOL-FIN-01 caused a display-component failure. We applied the approved image/graphics correction and verified normal logins by 10:00. Future updates will use small pilot rollout and stability checks first. Action: none unless it reappears.

## Audience 2 - Affected end-user team (10 people, non-technical)
Hi team, your access is back and your data stayed safe. On 2026-08-06, an overnight 02:00 update in POOL-FIN-01 caused a display problem, so from about 07:00 to 10:00 around 40% of users in that pool saw a black screen after sign-in; some recovered in about 30 seconds, others were disconnected, and POOL-FIN-02 was unaffected. We applied the approved image/graphics correction and verified normal logins by 10:00. Future updates will use small pilot rollout and stability checks first. If you see this again, contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note
Incident facts (same scope as user comms):
- Date/time window: 2026-08-06, approximately 07:00 to 10:00.
- Blast radius: POOL-FIN-01 only (~40% impacted); POOL-FIN-02 unaffected.
- User symptom: black screen post-logon; partial self-recovery for some (~30s), disconnects for others.

Root cause:
- Overnight 02:00 image update on POOL-FIN-01 introduced a graphics/display regression.
- Failure signature observed during incident analysis: repeated DWM failure path tied to Intel graphics user-mode module igdumd64.dll, producing session instability/disconnect loops.

Exact action taken:
- Applied approved POOL-FIN-01 graphics/image remediation (driver/acceleration path correction) on affected pool path.

Config detail:
- Change discriminator remained pool-specific: updated image on POOL-FIN-01 vs no update on POOL-FIN-02.
- Relevant update time anchor: 02:00 image update; impact visible starting ~07:00.

Verification step:
- At 10:00, post-remediation validation confirmed successful POOL-FIN-01 logons and no new issue reports.

Preventive action needed:
- Keep future image releases on small pilot rollout first, then require stability checks before full promotion (logon success and disconnect behavior gates).
