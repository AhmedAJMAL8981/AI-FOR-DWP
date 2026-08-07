# Title: Runbook - AVD Black Screen Post-Login on POOL-FIN-01
# Version: 1.0
# Date: 07/08/2026
# Author: Sathishbabu
# Reviewed: self
# Status: draft
# Change: initial version from RCA

# Runbook: AVD Black Screen Post-Login on POOL-FIN-01

## 1. Prerequisites
- [ ] Access check: You can sign in to Azure portal and open Azure Virtual Desktop host pools. [ELEVATED]
- [ ] Access check: You can view and edit session host settings for POOL-FIN-01 and POOL-FIN-02. [ELEVATED]
- [ ] Access check: You can connect to at least one affected session host in POOL-FIN-01 and one control host in POOL-FIN-02.
- [ ] Access check: You can open Event Viewer on both hosts and read Windows logs.
- [ ] Access check: You can execute the approved graphics/image remediation runbook for POOL-FIN-01. [ELEVATED]
- [ ] Tool check: Azure portal in browser.
- [ ] Tool check: Remote connection method to session hosts (RDP or approved admin access path).
- [ ] Tool check: Event Viewer on Windows session hosts.
- [ ] Mandatory end-user information captured: affected username(s).
- [ ] Mandatory end-user information captured: first seen time of black screen.
- [ ] Mandatory end-user information captured: host pool shown in AVD client at failure time.
- [ ] Mandatory end-user information captured: whether session recovered after about 30 seconds or disconnected.
- [ ] Mandatory end-user information captured: one screenshot or exact on-screen symptom wording if available.
- [ ] Mandatory ticket information captured: incident window start and latest occurrence time.

## 2. Procedure
1. Action: Open Azure portal, go to Azure Virtual Desktop > Host pools, and select POOL-FIN-01. [ELEVATED]
   Expected result: You are on the POOL-FIN-01 host pool overview page.

2. Action: In POOL-FIN-01, open Session hosts and record one host that currently or recently showed black-screen behavior.
   Expected result: One affected session host name is recorded in the ticket.

3. Action: Open a remote admin session to the recorded affected host.
   Expected result: You are signed in to the affected Windows session host desktop.

4. Action: Open Event Viewer at Event Viewer > Windows Logs > Application, then use Filter Current Log and set Event IDs to 1000.
   Expected result: Application Error Event 1000 entries are listed for the incident window.

5. Action: In the filtered Application log, open the event details and confirm Faulting application name is dwm.exe and Faulting module name is igdumd64.dll.
   Expected result: At least one Event 1000 entry matches dwm.exe faulting in igdumd64.dll.

6. Action: Open Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational, then filter Event ID 9009.
   Expected result: Event 9009 entries are visible in the same time window as Event 1000.

7. Action: Open Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational, then filter Event IDs 21 and 40.
   Expected result: Event 21 logons and Event 40 disconnects are visible in the incident window.

8. Action: Compare timestamps across Event 1000, Event 9009, and Event 40 for the same affected host.
   Expected result: The sequence shows Event 1000 and Event 9009 around the same period as disconnect behavior.

9. Action: In Azure portal, open Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts, then select one control host.
   Expected result: One POOL-FIN-02 control host is selected for comparison.

10. Action: Open a remote admin session to the selected POOL-FIN-02 control host.
    Expected result: You are signed in to the control host desktop.

11. Action: On the control host, open Event Viewer > Windows Logs > Application, filter Event ID 1000, and check for dwm.exe plus igdumd64.dll in the same incident window.
    Expected result: The matching crash signature is absent on the control host.

12. Action: Execute the approved graphics/image remediation runbook for POOL-FIN-01 hosts exactly as documented. [ELEVATED]
    Expected result: Remediation completes on targeted POOL-FIN-01 hosts with no task errors.

13. Action: In Azure portal, return users to remediated POOL-FIN-01 hosts and observe new sign-ins for immediate black-screen recurrence. [ELEVATED]
    Expected result: New sign-ins complete without black-screen loop or immediate disconnect pattern.

## 3. Verification
1. Action: Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, then select one remediated host and open Sessions.
   Expected result: You can see active/new sessions on the remediated host.

2. Action: Ask one affected user to sign in to AVD and record success or failure in the incident ticket.
   Expected result: User reaches desktop without black screen.

3. Action: On the same remediated host, open Event Viewer > Windows Logs > Application, filter Event ID 1000, and set Logged to the post-fix window.
   Expected result: No new Event 1000 entries for dwm.exe faulting in igdumd64.dll after remediation time.

4. Action: On the same host, open Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational, filter Event ID 9009 in the post-fix window.
   Expected result: No repeating Event 9009 crash pattern is present after remediation time.

5. Action: On the same host, open Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational, filter Event ID 40 in the post-fix window.
   Expected result: No recurring disconnect loop appears after successful logon events.

6. Action: Update the incident ticket with verification timestamp and the exact host checked.
   Expected result: Closure evidence is recorded with host name, time, and outcome.

## 4. Rollback
Target: Execute in under 3 minutes to stop user impact.

1. Action: Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts. [ELEVATED]
   Expected result: Session host list for POOL-FIN-01 is visible.

2. Action: Select all POOL-FIN-01 session hosts and set Allow new sessions to No (drain mode). [ELEVATED]
   Expected result: No new user sessions can land on POOL-FIN-01.

3. Action: Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts and confirm at least one host is Available. [ELEVATED]
   Expected result: POOL-FIN-02 can accept redirected users.

4. Action: Send incident update instructing users to reconnect so broker places new sessions on POOL-FIN-02.
   Expected result: New connection attempts move away from POOL-FIN-01.

5. Action: Validate containment by opening Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Sessions and refreshing twice over 60 seconds. [ELEVATED]
   Expected result: No increase in new sessions on POOL-FIN-01.

6. Action: On one affected POOL-FIN-01 host, open Event Viewer > Windows Logs > Application and confirm Event ID 1000 (dwm.exe/igdumd64.dll) is no longer affecting new user sign-ins because no new sessions are arriving.
   Expected result: User impact is immediately reduced while deeper remediation is prepared.

7. Action: If POOL-FIN-02 cannot absorb load, execute the approved pre-update graphics/image rollback for POOL-FIN-01 from the platform change runbook. [ELEVATED]
   Expected result: Platform rollback work starts under controlled conditions after impact containment.

## 5. Notes
- The defining signature in this incident is the sequence of Event 1000 (dwm.exe faulting in igdumd64.dll, exception 0xc0000005), Event 9009, and Event 40 shortly after Event 21 logon.
- Pool differential is a key discriminator: POOL-FIN-01 (updated at 02:00) showed failures while POOL-FIN-02 did not.
- User experience may be mixed, with some sessions recovering after about 30 seconds and others disconnecting or remaining unusable.
- Related records: RCA-AVD-BlackScreen-POOL-FIN-01-2026-08-06 and known-error-avd-black-screen-pool-fin-01.
