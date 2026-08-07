# RCA - Print Spooler Repeated Crash and Failed Recovery

## Incident Summary
- **Service:** Print Spooler (`Spooler`)
- **Log Source:** System log, Service Control Manager
- **Incident Window:** 2024-03-15 10:01:14 to 10:03:50
- **Observed Impact:** Print services repeatedly unavailable due to service termination and unsuccessful recovery.

## Event ID Meaning (What Each Event Records)

| Event ID | Meaning | What it tells us here |
|---|---|---|
| 7034 | A service terminated unexpectedly. Usually logged when a service exits abnormally and no custom recovery detail is included in this specific event. | Print Spooler crashed unexpectedly at least three times in quick succession (10:01:14, 10:01:45, 10:02:16). |
| 7031 | A service terminated unexpectedly and SCM is applying a configured recovery action. | On the fourth crash (10:02:47), SCM confirms recovery policy and schedules restart in 60,000 ms. |
| 7023 | A service terminated with a specific Win32 error text. | At 10:03:49, Spooler terminated with: "The specified module could not be found." This points to a missing dependency (often DLL/module linked to print drivers, print processors, or monitors). |
| 7038 | Service could not log on using configured account due to logon rights/auth failure. | At 10:03:50, Spooler could not log on as `NT AUTHORITY\\SYSTEM` because requested logon type was not granted on this computer. This indicates service-logon-right policy misconfiguration. |

## Reconstructed Sequence of Events (Plain English)
1. At 10:01:14, Print Spooler crashes for the first time.
2. It starts again, but crashes again at 10:01:45.
3. It restarts and crashes a third time at 10:02:16.
4. It crashes a fourth time at 10:02:47. This time SCM explicitly logs that it will attempt recovery by restarting the service after 60 seconds.
5. Around one minute later, at 10:03:49, Spooler terminates with a concrete error: a required module cannot be found.
6. One second later, at 10:03:50, SCM logs that Spooler cannot log on as Local System because the logon type right is not granted.
7. Result: the service is stuck in an outage state. Even when SCM tries to recover, startup is blocked by both dependency failure and account-rights misconfiguration.

## Most Likely Cause of the Crash Loop

### Root Cause (Most likely)
Missing or broken print subsystem dependency (module/DLL) loaded by Print Spooler, most likely from a printer driver, print processor, language monitor, or port monitor component.

### Supporting Evidence
- Repeated unexpected terminations (`7034`) indicate real service instability, not an intentional stop.
- `7023` provides direct error text: "The specified module could not be found."
- Timing pattern (~31 seconds between early crashes, then recovery attempt) fits a service repeatedly starting and failing during initialization/loading.

### Contributing Cause (Recovery Failure Amplifier)
Service logon rights for `NT AUTHORITY\\SYSTEM` are misconfigured/denied for service logon on the machine (`7038`).

### Supporting Evidence
- `7038` explicitly states logon type not granted for Local System.
- This blocks restart/recovery attempts, prolonging outage even if the missing module issue is later corrected.

## Five Whys Analysis

### Problem Statement
Print Spooler repeatedly crashed and failed to recover, causing sustained print outage.

1. **Why did users lose print service?**  
   Because the Print Spooler service stopped repeatedly and did not stay running.

2. **Why did the service stop repeatedly?**  
   Because it terminated unexpectedly multiple times (`7034`, `7031`).

3. **Why did it terminate unexpectedly?**  
   Because during startup/runtime it encountered a missing required module (`7023`: "The specified module could not be found").

4. **Why was the required module missing?**  
   Most likely due to incomplete driver/package installation, partial uninstall, file removal/corruption, or orphaned print component registration still referenced by Spooler.

5. **Why did automatic recovery not restore service quickly?**  
   Because service logon rights were misconfigured: `NT AUTHORITY\\SYSTEM` lacked required service logon type rights (`7038`), so restart attempts were blocked.

### 5 Whys Conclusion
- **Primary technical root cause:** Missing print-related module dependency causing Spooler crash.
- **Secondary governance/config root cause:** Incorrect local/domain security policy assignment for service logon rights affecting Local System.

## Corrective and Preventive Actions (CAPA)

### Immediate Corrective Actions
1. Validate and repair Print Spooler dependencies:
   - Inspect print drivers/processors/monitors for missing DLL references.
   - Remove orphaned driver packages and reinstall known-good signed drivers.
2. Verify service account and rights:
   - Confirm Spooler `Log On` account is Local System.
   - Restore required service logon rights via local security policy or GPO baseline.
3. Restart Spooler and confirm stable runtime for at least 15-30 minutes under print load.

### Preventive Actions
1. Enforce controlled printer driver lifecycle:
   - Centralized approved driver repository.
   - Change control for print driver updates/removals.
2. Add configuration drift monitoring:
   - Alert on changes to user rights assignments affecting services.
3. Add event correlation alerting:
   - Trigger incident when `7034/7031` repeats and escalate immediately if followed by `7023` or `7038`.
4. Include spooler health checks in endpoint monitoring:
   - Service state + startup failures + module load failures.

## Confidence Assessment
- **Confidence in primary cause (missing module):** High, due to explicit `7023` error string.
- **Confidence in contributing cause (logon rights misconfiguration):** High, due to explicit `7038` message naming Local System and missing logon type rights.

## Appendix - Raw Timeline
- 10:01:14 - Event 7034 - Spooler terminated unexpectedly (count 1)
- 10:01:45 - Event 7034 - Spooler terminated unexpectedly (count 2)
- 10:02:16 - Event 7034 - Spooler terminated unexpectedly (count 3)
- 10:02:47 - Event 7031 - Spooler terminated unexpectedly (count 4), restart scheduled in 60000 ms
- 10:03:49 - Event 7023 - Spooler terminated: "The specified module could not be found"
- 10:03:50 - Event 7038 - Spooler unable to log on as `NT AUTHORITY\\SYSTEM` (logon type not granted)
