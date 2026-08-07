# Root Cause Analysis (RCA): Repeated Microsoft Outlook Crash (OUTLOOK.EXE)

## Incident Summary
On 2024-03-15 between 09:14 and 09:18, Microsoft Outlook (OUTLOOK.EXE v16.0.17126.20132) crashed repeatedly. The crashes were recorded as application faults (Event ID 1000), followed by Windows Error Reporting telemetry (Event ID 1001), and a .NET runtime termination due to an unhandled access violation (Event ID 1026).

## Event ID Reference

| Event ID | Source | What it records |
|---|---|---|
| **1000** | Application Error | A process crash/fault. Captures faulting app, faulting module, exception code, fault offset, process details, and report ID. In this incident it shows OUTLOOK.EXE faulting in KERNELBASE.dll with exception **0xc0000005** (access violation). |
| **1001** | Windows Error Reporting | Post-crash WER submission metadata (fault bucket, event type such as APPCRASH, response/cab info). It indicates Windows classified and attempted to report the crash signature. |
| **1026** | .NET Runtime | .NET process termination due to an unhandled managed exception. Here it records **System.AccessViolationException**, confirming the process ended because invalid memory access was not handled. |

## Reconstructed Sequence of Events (Plain English)

1. **09:13:44** - Outlook started (from the first Event 1000 details: faulting app start time).
2. **09:14:22** - Outlook crashed. Event ID 1000 logged: OUTLOOK.EXE faulted in KERNELBASE.dll with exception code 0xc0000005 at offset 0x000000000003a4b2.
3. **09:17:45** - Outlook crashed again. A second Event ID 1000 logged with the same app version, same faulting module, same exception code, and same offset, showing repeatability of the failure signature.
4. **09:18:01** - Windows Error Reporting Event ID 1001 logged APPCRASH metadata (fault bucket/type), indicating Windows categorized the failure and prepared report data.
5. **09:18:05** - .NET Runtime Event ID 1026 logged that OUTLOOK.EXE terminated due to an unhandled System.AccessViolationException.

## Most Likely Cause (with Evidence)

**Most likely cause:** A deterministic access violation in Outlook's runtime path, most likely triggered by an unstable or incompatible extension/component (commonly a COM/.NET add-in or integration module) interacting with Outlook, resulting in invalid memory access and process termination.

**Why this is most likely based on evidence:**
- The crash signature is repeated: same executable version, same faulting module (KERNELBASE.dll), same exception code (0xc0000005), and same fault offset (0x3a4b2) across multiple crashes.
- Exception **0xc0000005** is an access violation (read/write/execute on invalid memory), matching Event 1026's **System.AccessViolationException**.
- KERNELBASE.dll is frequently where the exception is surfaced/raised; it is often the crash surface, not necessarily the true origin component.
- Short interval repeat crash pattern (~3 minutes) indicates a reproducible trigger (for example: startup action, mailbox/profile object load, or add-in initialization) rather than a one-off transient error.

**Confidence level:** Medium.

**Why not High:**
- Provided logs confirm the crash mechanics but do not include module load/add-in inventory, stack trace, Outlook safe-mode comparison, or dump analysis needed to name a single exact binary with certainty.

## 5 Whys Analysis

1. **Why did Outlook keep crashing?**
   Because OUTLOOK.EXE hit an access violation (0xc0000005) and terminated (Event 1000), and this happened repeatedly with the same crash signature.

2. **Why did the process terminate instead of recovering?**
   Because the memory access violation surfaced as an unhandled exception in the runtime path (Event 1026: System.AccessViolationException), so the process was forcibly ended.

3. **Why was there an access violation in Outlook's execution path?**
   Most likely because a loaded component path (such as add-in/integration code or mailbox-processing hook) attempted invalid memory access during Outlook operations.

4. **Why would a component perform invalid memory access in this context?**
   Typical contributors are incompatibility after updates, defects in add-in code, corrupted state/profile data passed into the component path, or boundary issues between managed and unmanaged code.

5. **Why was this allowed to impact user availability repeatedly?**
   Because the environment lacked immediate isolation controls at first crash (for example automated add-in disable on repeated APPCRASH, rapid crash triage workflow, or guardrails to force safe mode during repeated faults), allowing the same trigger condition to recur.

**Root cause statement:**
A reproducible access-violation fault path in Outlook (manifesting in KERNELBASE.dll and .NET as System.AccessViolationException), most likely driven by an unstable/incompatible extension or integration path, caused repeated process termination.

## Supporting Evidence Table

| Evidence | Observation | RCA significance |
|---|---|---|
| Event 1000 @ 09:14:22 | OUTLOOK.EXE crash; module KERNELBASE.dll; code 0xc0000005; offset 0x3a4b2 | Confirms first hard crash and memory-access fault type |
| Event 1000 @ 09:17:45 | Same crash signature repeats | Indicates deterministic/reproducible failure path |
| Event 1001 @ 09:18:01 | APPCRASH bucket captured | Confirms WER classification and crash reporting |
| Event 1026 @ 09:18:05 | Unhandled System.AccessViolationException | Confirms fatal unhandled exception behavior |

## Corrective and Preventive Actions

- Run Outlook in safe mode and compare behavior to isolate add-in influence.
- Disable all COM add-ins, then re-enable one at a time to identify offending component.
- Update Office channel/build and all Outlook-integrated add-ins to latest compatible versions.
- Create a fresh Outlook profile and test against same mailbox to rule out profile corruption.
- Collect and analyze crash dumps (WER/local dumps) to identify the precise call stack and offending module.
- If enterprise-managed, deploy policy to temporarily block known-bad add-in versions.
- Add incident runbook step: after second identical Event 1000 within 15 minutes, auto-trigger add-in isolation workflow.

## Assumptions / Open Items

- No call stack or dump was provided; exact offending DLL/function cannot be named from these events alone.
- No add-in inventory was provided; suspected component type is evidence-based but not yet proven.
- No correlation logs (Office telemetry, ProcMon, Reliability Monitor details) were provided for deeper attribution.

## Analyst Conclusion
The provided events strongly indicate repeated, deterministic Outlook termination due to memory access violation. The highest-probability technical origin is an Outlook extension/integration path (often add-in related) rather than random OS instability, with KERNELBASE.dll acting as the exception surface and not necessarily the root faulty binary.