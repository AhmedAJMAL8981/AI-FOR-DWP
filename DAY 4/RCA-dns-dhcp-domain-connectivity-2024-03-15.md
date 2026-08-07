# Root Cause Analysis — Secure Channel / Group Policy Failure
**Incident ID:** INC-2024-03-15-FINFLOOR3  
**Document status:** Confirmed  
**Author role:** DWP Service Desk Engineer  

---

## 1. Incident Overview

| Field | Detail |
|-------|--------|
| **Incident ID** | INC-2024-03-15-FINFLOOR3 |
| **Detected** | 2024-03-15, 07:40 (first Netlogon 5719 error at 07:40:08) |
| **Escalated** | Pending confirmation |
| **Resolved** | Pending confirmation |
| **Symptom** | Blank/failed logon experience on startup tied to secure channel and Group Policy errors |
| **Affected OU** | OU=Finance, Floor 3 |

---

## 2. Affected vs Unaffected Systems

### Affected

| Machine | DNS assigned (DHCP) | Impact |
|---------|---------------------|--------|
| DESKTOP-FB031 | 10.10.3.250 (decommissioned) | Failed logon — secure channel broken, GPO failed |
| DESKTOP-FB055 | 172.16.5.5 (decommissioned) | Failed logon — secure channel broken, GPO failed |
| DESKTOP-FB056 | 172.16.5.5 (decommissioned) | Failed logon — secure channel broken, GPO failed |
| DESKTOP-FB057 | 172.16.5.5 (decommissioned) | Failed logon — secure channel broken, GPO failed |

### Unaffected

| Machine | DNS assigned | Reason unaffected |
|---------|-------------|-------------------|
| DESKTOP-FB029 | 10.10.0.10 (correct) | Manually pre-configured before migration wave |
| DESKTOP-FB058 | 10.10.0.10 (correct) | Manually pre-configured before migration wave |

### Key isolating comparison

DESKTOP-FB029 is in the same OU (OU=Finance, Floor 3) as DESKTOP-FB031. At 07:40:05 FB029 received DNS 10.10.0.10 and successfully processed Group Policy at 07:40:11 (Event 1500). FB031, relying on DHCP, received DNS 10.10.3.250 (decommissioned) and failed. The only variable distinguishing the two machines was the DNS server assigned. This comparison confirmed the DHCP scope gap as the root cause.

---

## 3. Timeline of Events

| Timestamp | Event | Detail |
|-----------|-------|--------|
| 2024-03-14 overnight | DNS decommission — 172.16.5.5 | Old DNS server 172.16.5.5 decommissioned. DHCP scope for affected Floor 3 subnet not updated. FB055–FB057 will receive this address on next lease. |
| 2024-03-15 02:00 | DNS decommission — 10.10.3.250 | Old DNS server 10.10.3.250 decommissioned as part of migration wave. Replacement: 10.10.0.10. DHCP scope for Floor 3 subnet not updated. |
| 2024-03-15 07:40:02 | SCM Event 7036 | Network Location Awareness service entered running state on FB031 — machine starting network-dependent startup tasks. |
| 2024-03-15 07:40:05 | FB029 — DNS assigned | DESKTOP-FB029 (manually pre-configured) using DNS 10.10.0.10. Baseline: correct DNS in place. |
| 2024-03-15 07:40:08 | **Netlogon Event 5719 (Error)** | FB031: Unable to establish secure channel to domain FINBRIDGE — no domain controller available. DNS query for FINBRIDGE-DC01.finbridge.local returned no response. |
| 2024-03-15 07:40:09 | GroupPolicy Event 1058 (Error) | FB031: GPO processing failed — cannot access SYSVOL path. |
| 2024-03-15 07:40:10 | GroupPolicy Event 1030 (Warning) | FB031: Cannot query list of Group Policy Objects. |
| 2024-03-15 07:40:11 | GroupPolicy Event 1058 (Error) | FB031: GPO processing failed — second occurrence. |
| 2024-03-15 07:40:11 | **FB029 — GPO success** | DESKTOP-FB029: Group Policy Event 1500 — GPO processing completed successfully. Confirms 10.10.0.10 resolves DC and domain is reachable. |
| 2024-03-15 07:40:12 | GroupPolicy Event 1129 (Error) | FB031: GPO failed — no network connectivity to a domain controller. |
| 2024-03-15 07:41:05 | DNS Client Event 1014 (Warning) | FB031: Name resolution for FINBRIDGE-DC01.finbridge.local timed out — confirms DNS server is unreachable, not returning NXDOMAIN. |
| 2024-03-15 07:42:18 | DHCP Client Event 50036 (Information) | FB031: IP address 10.10.3.144 leased. DNS servers assigned by DHCP: **10.10.3.250** (old, decommissioned at 02:00). Confirms DHCP scope was not updated. |
| 2024-03-15 07:44:01 | GroupPolicy Event 1129 (Error) | FB031: GPO processing failed again — DC connectivity still unavailable. Machine remains in failed logon state. |
| 2024-03-15 07:40–07:55 | Startup window | All affected machines (FB031, FB055–FB057) experienced the failed logon state during this window. |

---

## 4. Root Cause Statement

The DHCP scope for the Floor 3 subnet was not updated to replace the decommissioned DNS server addresses (10.10.3.250 and 172.16.5.5) with the new DNS server (10.10.0.10), causing all machines that relied on DHCP-assigned DNS to receive an unreachable DNS server at boot, which prevented resolution of the domain controller FQDN and broke the Netlogon secure channel and Group Policy processing.

---

## 5. Contributing Factors

- **No validation step in the decommission runbook** — the migration wave runbook did not include a requirement to update and verify DHCP scope DNS options before or alongside DNS server decommission.
- **Staggered decommission across subnets** — 172.16.5.5 was decommissioned the night before (2024-03-14); 10.10.3.250 was decommissioned at 02:00 on 2024-03-15. The split timeline increased the window during which multiple subnets held stale DHCP scope entries.
- **Manual pre-configuration not applied consistently** — FB029 and FB058 were remediated before the migration wave, but the remaining machines in the same OU and floor were not, indicating the pre-configuration process was incomplete or not tracked.
- **No automated DHCP scope audit** — there was no mechanism to detect that DHCP scope option 6 still referenced a decommissioned IP after the migration wave completed.

---

## 6. Corrective Actions Taken

> Actions below are based on the confirmed root cause. Completion status is pending confirmation where not explicitly stated in scope facts.

| # | Action | Status |
|---|--------|--------|
| 1 | Update DHCP scope option 6 for the Floor 3 subnet to 10.10.0.10 | Pending confirmation |
| 2 | Force DHCP lease renewal on affected machines (`ipconfig /release` → `ipconfig /renew`) | Pending confirmation |
| 3 | Flush DNS resolver cache on affected machines (`ipconfig /flushdns`) | Pending confirmation |
| 4 | Reset Netlogon secure channel (`nltest /sc_reset:finbridge.local`) or reboot affected machines | Pending confirmation |
| 5 | Verify Group Policy applies cleanly (`gpupdate /force`) on all affected machines | Pending confirmation |
| 6 | Audit all other subnets in the migration wave to confirm no remaining DHCP scopes reference 10.10.3.250 or 172.16.5.5 | Pending confirmation |

---

## 7. Preventive Actions

| # | Action | Owner | Target date |
|---|--------|-------|-------------|
| 1 | Add a mandatory DHCP scope DNS option validation step to the DNS migration / decommission runbook — must be completed and signed off before any DNS server is decommissioned | Infrastructure / Change Management | Pending confirmation |
| 2 | Implement a post-migration DHCP audit script to alert on any scope still referencing a decommissioned DNS IP | Infrastructure Engineering | Pending confirmation |
| 3 | Require a full scope-level check (not just sample machines) when manually pre-configuring DNS before a migration wave — track all machines remediated vs outstanding | Desktop Engineering / Project lead | Pending confirmation |
| 4 | Add a pre-flight validation check to the migration wave checklist: query each affected DHCP scope's DNS option and confirm the new server IP is in place before the change window closes | Change Management | Pending confirmation |

---

*Document status: Root cause confirmed. Corrective and preventive action completion pending confirmation.*
