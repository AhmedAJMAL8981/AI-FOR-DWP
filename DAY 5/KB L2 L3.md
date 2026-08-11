# KB: AVD Black Screen Post-Login on POOL-FIN-01 (L2/L3)

Version: v 1.0  
Date: 07/08/2026  
Status : Draft

## Background
Azure Virtual Desktop (AVD) delivers Finance desktops through host pools. During this incident pattern, POOL-FIN-01 hosts can accept user sign-in but fail during desktop rendering.

Why this matters:
- Users can authenticate but still cannot work because the desktop remains black.
- Impact can spread quickly when brokers continue placing sessions on affected hosts.
- Fast pool differential checks (POOL-FIN-01 vs POOL-FIN-02) are required to avoid misdiagnosing as generic client/network latency.

## Symptom
What the engineer observes:
- Sessions on POOL-FIN-01 show black screen after sign-in.
- Some sessions recover after about 30 seconds; others disconnect or remain unusable.
- Control pool (POOL-FIN-02) does not show the same crash pattern in the same time window.

What users report:
- "I sign in and only see a black screen."
- "Sometimes it reconnects, sometimes it disconnects."
- "This started after the overnight update window."

## Root Cause
Specific technical cause:
- Desktop Window Manager crash on POOL-FIN-01 session hosts: `dwm.exe` faulting in `igdumd64.dll` with exception `0xc0000005`.

Evidence that confirms root cause:
- Application log Event ID `1000` with `Faulting application name: dwm.exe` and `Faulting module name: igdumd64.dll`.
- Desktop Window Manager Operational log Event ID `9009` in same incident window.
- TerminalServices-LocalSessionManager Operational Event ID `40` occurring after Event ID `21`.
- Differential comparison: matching signature present on POOL-FIN-01 and absent on POOL-FIN-02 control host in the same window.

## Detection
Objective: confirm this exact incident in under 3 minutes before remediation.

1. Identify one affected host and one control host.
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts` and `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`.
- Record: affected POOL-FIN-01 host, control POOL-FIN-02 host, incident time window.

2. On affected POOL-FIN-01 host, confirm Application Event ID 1000 signature.
- Exact log location: `Event Viewer > Windows Logs > Application`.
- Filter: Event ID `1000`.
- Required fields:
  - `Faulting application name = dwm.exe`
  - `Faulting module name = igdumd64.dll`
  - `Exception code = 0xc0000005`
- Quick command:
```powershell
$start=(Get-Date).AddHours(-6)
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$start} |
Where-Object { $_.Message -match 'Faulting application name:\s*dwm.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64.dll' } |
Select-Object -First 10 TimeCreated, MachineName, Id, Message
```

3. On affected POOL-FIN-01 host, confirm DWM operational correlation.
- Exact log location: `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational`.
- Filter: Event ID `9009`.
- Required fields: `TimeCreated`, `MachineName`, `Id`, `Message` aligned with Event 1000 timeframe.
- Quick command:
```powershell
$start=(Get-Date).AddHours(-6)
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$start} |
Select-Object -First 20 TimeCreated, MachineName, Id, Message
```

4. On affected host, confirm logon-to-disconnect pattern.
- Exact log location: `Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`.
- Filter: Event IDs `21` and `40`.
- Required pattern: Event `21` followed by Event `40` in same user/session timeframe.
- Quick command:
```powershell
$start=(Get-Date).AddHours(-6)
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=@(21,40); StartTime=$start} |
Select-Object -First 40 TimeCreated, Id, MachineName, Message
```

5. Comparison check (mandatory): POOL-FIN-01 vs POOL-FIN-02.
- On POOL-FIN-02 control host, validate absence of the same Event 1000 (`dwm.exe` + `igdumd64.dll`) signature in same time window.
- Optional baseline indicator on control host: Event ID `9011` present in DWM operational log with no repeating crash pattern.
- Decision to proceed: remediate only when signature is present on POOL-FIN-01 and absent on POOL-FIN-02.

## Resolution
Target time: 5-10 minutes for containment and first recovery validation.

1. Put affected POOL-FIN-01 host(s) in drain mode.
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <host> > Allow new sessions = No`.
- Expected result: no new user sessions land on affected host(s).

2. Execute approved graphics/image remediation runbook on affected POOL-FIN-01 host(s).
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <host> > Virtual machine > Run command`.
- Action: run the approved enterprise remediation package exactly as documented in platform runbook.
- Expected result: remediation completes with no task errors.

3. Restart remediated host(s) if required by approved remediation.
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <host> > Virtual machine > Restart`.
- Expected result: host returns to healthy running state.

4. Re-enable session placement on remediated host(s).
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <host> > Allow new sessions = Yes`.
- Expected result: host is available for controlled test sign-ins.

5. Perform controlled user sign-in test.
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <host> > Sessions`.
- Expected result: user reaches desktop without black-screen loop.

6. Expand to additional POOL-FIN-01 hosts only after successful pilot host outcome.
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`.
- Expected result: no immediate recurrence during staged return.

## Verification
1. Validate AVD host status and session behavior.
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`.
- Pass criteria:
  - Remediated hosts show available state.
  - Session count is stable and not disconnect-looping.

2. Validate user experience outcome.
- Action: affected test user signs in and lands on desktop.
- Pass criteria: no black screen, no immediate disconnect.

3. Validate post-fix Event ID 1000 status on remediated host.
- Exact log location: `Event Viewer > Windows Logs > Application`.
- Filter: Event ID `1000` in post-fix window.
- Pass criteria: no new entries matching `dwm.exe` + `igdumd64.dll` after remediation timestamp.

4. Validate post-fix Event ID 9009 status.
- Exact log location: `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational`.
- Filter: Event ID `9009` in post-fix window.
- Pass criteria: no repeating 9009 crash pattern after fix.

5. Validate disconnect-loop suppression.
- Exact log location: `Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`.
- Filter: Event ID `40` in post-fix window.
- Pass criteria: no recurring disconnect loop after successful logons.

6. Record closure evidence.
- Required evidence: host names, timestamps, before/after event checks, user test outcome.
- Pass criteria: incident ticket contains audit-ready validation data.

## Rollback
Use rollback if remediation worsens impact or fails.

1. Immediate containment: drain all POOL-FIN-01 hosts.
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select all > Allow new sessions = No`.
- Expected result: new sessions are blocked from POOL-FIN-01.

2. Confirm POOL-FIN-02 can receive users.
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`.
- Expected result: at least one POOL-FIN-02 host available for redirected sign-ins.

3. Instruct users to reconnect for broker redirection.
- Action text: `Please reconnect now. New sessions are being routed to POOL-FIN-02.`
- Expected result: user impact is reduced by avoiding POOL-FIN-01.

4. Validate containment effectiveness.
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Sessions`.
- Expected result: no increase in new POOL-FIN-01 sessions after drain mode.

5. If required, execute approved pre-update graphics/image rollback.
- Azure portal path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <host> > Virtual machine > Run command`.
- Expected result: platform rollback begins under controlled conditions.

## Preventive
1. Enforce canary-first rollout sequence.
- Require phased deployment: canary host(s) -> POOL-FIN-02 -> POOL-FIN-01.
- Promote only when no matching Event 1000 (`dwm.exe` + `igdumd64.dll`) and no repeating Event 9009 for 30 minutes.

2. Add automated crash-signature correlation alert.
- Alert when same host shows Event 1000 (`dwm.exe`/`igdumd64.dll`) plus Event 9009 and Event 40 after Event 21 in a short window.
- Trigger Sev2 when threshold is met on 2 or more hosts.

3. Add pool differential monitoring dashboard.
- Compare POOL-FIN-01 vs POOL-FIN-02 for Event 1000, Event 9009, and Event 40 rates in change windows.
- Freeze rollout if POOL-FIN-01 exceeds control threshold.

4. Require post-change validation script attachment.
- Within 15 minutes of rollout, run scripted event checks on at least 2 hosts and attach output to change ticket.
- Do not close change until L3 review completes.

5. Standardize fast containment trigger.
- If black-screen signature appears on 2 or more POOL-FIN-01 hosts within 20 minutes, set Allow new sessions to No for affected hosts.
- Redirect new sign-ins to POOL-FIN-02 until remediation is complete.

## Related
- `runbook-avd-black-screen-pool-fin-01.md`
- `RCA-AVD-BlackScreen-POOL-FIN-01-2026-08-06`
- `known-error-avd-black-screen-pool-fin-01`
- `closure-note-avd-black-screen-2026-08-06.md`
- `comms-avd-black-screen-three-audiences.md`
