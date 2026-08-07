# Root Cause Analysis (RCA): RDP Connection Failure and Account Lockout - FINBRIDGE\\bwalker

## Incident Summary
- **Incident type:** Remote Desktop connection failure followed by account lockout
- **Affected account:** FINBRIDGE\\bwalker
- **Primary client/source:** 10.10.5.44
- **Event window:** 2024-03-15 14:01:02 to 14:22:09
- **Observed impact:** User could not establish RDP session; account became locked out; access restored later with successful RemoteInteractive logon.

## Event ID Reference (What Each Event Records)

| Log | Source | Event ID | What it records |
|---|---|---|---|
| System | TermDD | 56 | RDP transport/security protocol stream error detected by Terminal Services; server disconnects the RDP client session. Often appears when security negotiation fails or session setup is aborted after authentication issues. |
| System | RemoteDesktopServices-RdpCoreTS | 140 | RDP connection attempt failed because provided username/password was not accepted during authentication. |
| Security | Microsoft-Windows-Security-Auditing | 4625 | Failed logon attempt. Includes failure reason, account, logon type, and source IP/computer. Here, Logon Type 10 means RemoteInteractive (RDP). |
| Security | Microsoft-Windows-Security-Auditing | 4740 | User account lockout event. Triggered when failed attempts reach domain/local lockout threshold. Includes locked account and calling/source computer. |
| System | RemoteDesktopServices-RdpCoreTS | 131 | TCP connection accepted from an RDP client. This confirms network-level reachability and successful socket establishment (not full authentication by itself). |
| Security | Microsoft-Windows-Security-Auditing | 4624 | Successful logon event. Here, Logon Type 10 confirms a successful RDP sign-in for FINBRIDGE\\bwalker. |

## Reconstructed Sequence of Events (Plain English)
1. At **14:01:02**, client **10.10.5.44** attempted RDP to the server.
2. At the same second, **Event 140** logged that credentials were incorrect, and **TermDD 56** recorded protocol/security stream disconnect for the same client. This indicates RDP setup failed during/after authentication.
3. At **14:01:04**, a **4625** failure for **FINBRIDGE\\bwalker** (Logon Type 10, source 10.10.5.44) confirms the first failed RDP sign-in due to bad credentials.
4. Additional failed RDP logons occurred at **14:03:18** and **14:05:33** (both **4625**, same account/source/failure reason).
5. At **14:05:34**, **4740** recorded account lockout for **FINBRIDGE\\bwalker**, called from **10.10.5.44**, immediately after repeated bad-password attempts.
6. At **14:22:07**, **Event 131** shows the server accepted a new TCP RDP connection from **10.10.5.44**.
7. At **14:22:09**, **4624** shows successful RemoteInteractive logon for **FINBRIDGE\\bwalker**, confirming restored access and valid authentication at that point.

## Most Likely Cause of the RDP Connection Failure

### Conclusion
The RDP connection failures were most likely caused by **repeated invalid credentials (wrong password and/or outdated cached password) from client 10.10.5.44**, which then triggered account lockout policy enforcement.

### Evidence from events
- **RdpCoreTS 140** explicitly states username or password was not correct.
- Three separate **4625** failures (14:01:04, 14:03:18, 14:05:33) show consistent failure reason: **Unknown username or bad password**, all with **Logon Type 10** and same source **10.10.5.44**.
- **4740** occurs one second after the third 4625, linking lockout directly to those failed RDP attempts from the same client.
- Later **131 + 4624** from the same source/account show network path and account were functional once valid authentication succeeded (or lockout was cleared).

### Why Event 56 appears here
**TermDD 56** is often a secondary symptom in this pattern: once authentication/security negotiation fails, the RDP protocol stream is terminated and the session is disconnected.

## 5 Whys Analysis

### Problem statement
User could not connect via RDP and account FINBRIDGE\\bwalker became locked out.

1. **Why did the RDP connection fail?**
   Because authentication failed during RemoteInteractive logon attempts.

2. **Why did authentication fail?**
   Because the username/password presented by client 10.10.5.44 was rejected (Event 140, Event 4625).

3. **Why was the rejected credential retried multiple times?**
   Because additional RDP sign-in attempts were made with the same bad credential pattern over several minutes (three 4625 events).

4. **Why did this become a bigger outage rather than just a single failed login?**
   Because lockout policy threshold was reached, causing account lockout (Event 4740).

5. **Why did lockout policy trigger in this scenario?**
   Because the environment correctly enforced brute-force protection rules, but the user/client kept submitting invalid credentials (manual retries or cached credential replay), exhausting allowed attempts.

### Root Cause
Incorrect credentials were repeatedly submitted for RDP from 10.10.5.44, leading to authentication failure and account lockout according to policy.

### Contributing Factors
- Possible stale cached password in RDP client profile or saved credential store.
- User may not have recognized first failure as credential-related and retried quickly.
- No immediate user-visible warning before final lockout threshold was crossed.

## Corrective and Preventive Actions

### Immediate corrective actions
1. Unlock account and validate current password with user.
2. Remove saved/cached RDP credentials on client 10.10.5.44 (Credential Manager and .rdp saved creds if applicable).
3. Retry RDP with explicit domain-qualified username format (for example, FINBRIDGE\\bwalker).
4. Confirm no background process/service on client is repeatedly attempting old credentials.

### Preventive actions
1. User guidance: after first bad-password RDP failure, stop retrying and verify/reset password before additional attempts.
2. Endpoint hardening: periodically clear obsolete saved credentials on shared/admin endpoints.
3. Monitoring: alert on pattern of repeated 4625 (Logon Type 10) followed by 4740 from same source host.
4. Policy review: ensure lockout thresholds balance security and operational usability.
5. Documentation: add runbook step to check RdpCoreTS 140 + Security 4625/4740 correlation before deeper network troubleshooting.

## Confidence and Assumptions
- **Confidence:** High that credential failure caused the incident, based on direct event messages and sequence.
- **Assumption:** The provided logs are representative of the full incident window. If broader SIEM logs show other source hosts, additional contributors may exist.

## Timeline Appendix (Raw Chronology)
- **14:01:02** - System, TermDD, **56** (protocol/security stream error; disconnect), client 10.10.5.44
- **14:01:02** - System, RdpCoreTS, **140** (username/password incorrect), client 10.10.5.44
- **14:01:04** - Security, **4625** (failed RemoteInteractive logon), FINBRIDGE\\bwalker, source 10.10.5.44
- **14:03:18** - Security, **4625** (failed RemoteInteractive logon), FINBRIDGE\\bwalker, source 10.10.5.44
- **14:05:33** - Security, **4625** (failed RemoteInteractive logon), FINBRIDGE\\bwalker, source 10.10.5.44
- **14:05:34** - Security, **4740** (account locked out), FINBRIDGE\\bwalker, caller 10.10.5.44
- **14:22:07** - System, RdpCoreTS, **131** (new TCP RDP connection accepted), client 10.10.5.44:52341
- **14:22:09** - Security, **4624** (successful RemoteInteractive logon), FINBRIDGE\\bwalker, source 10.10.5.44
