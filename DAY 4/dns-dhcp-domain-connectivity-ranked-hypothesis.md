# Ranked Hypothesis — Secure Channel / Group Policy Failure
**Incident:** Domain connectivity failure on startup  
**Affected:** DESKTOP-FB031 + FB055, FB056, FB057 (OU=Finance, Floor 3)  
**Date/Window:** 2024-03-15, 07:40–07:55  
**Analyst:** Windows/AD Engineering  

---

## Scope Facts

| Item | Detail |
|------|--------|
| Symptom | Blank/failed logon; secure channel and Group Policy errors on startup |
| Affected machines | DESKTOP-FB031, FB055, FB056, FB057 (3 of 4 on Floor 3) |
| Unaffected machines | DESKTOP-FB029 (same OU); FB058 (Floor 3) |
| Change at 02:00 | Old DNS servers decommissioned: 10.10.3.250 (Floor 3 subnet), 172.16.5.5 (secondary). Replaced by 10.10.0.10 |
| DHCP gap | DHCP scope for Floor 3 subnet NOT updated to hand out new DNS server |
| FB031 DHCP lease | DNS assigned: 10.10.3.250 (decommissioned) |
| FB029 DNS | 10.10.0.10 (correct) — manually pre-configured before migration wave |
| FB058 DNS | 10.10.0.10 (correct) — manually pre-configured before migration wave |
| Key errors | Netlogon 5719, DNS Client 1014, GroupPolicy 1058 / 1030 / 1129 |

---

## Initial Ranked List — 5 Most Likely Causes

### 1. DHCP scope not updated → affected machines assigned decommissioned DNS server

**Why it fits:**  
FB031 is confirmed to hold DNS 10.10.3.250 (decommissioned at 02:00). The DHCP scope for the Floor 3 subnet was explicitly not updated. Every machine relying on DHCP-assigned DNS is pointing at a server that no longer exists. DNS Client event 1014 records a *timeout* (not NXDOMAIN), consistent with querying a host that is powered off or unreachable. Without DNS, `FINBRIDGE-DC01.finbridge.local` is unresolvable, which kills Netlogon (5719), which kills GPO (1058/1030/1129). The entire error chain flows from this single upstream failure.

**Fastest check:** `ipconfig /all` on each affected machine — confirm the DNS server field shows 10.10.3.250 or 172.16.5.5.

---

### 2. Decommissioned DNS host unreachable at the network layer

**Why it fits:**  
A DNS server that is powered off or has had its NIC/route removed causes queries to time out at the socket level rather than returning errors. DNS Client 1014 explicitly records a *name resolution timeout* — this matches a dead host rather than a misconfigured one. Even if a machine retained a cached pointer to the old DNS IP, the host is gone, so every query stalls until timeout.

**Fastest check:** `Test-NetConnection 10.10.3.250 -Port 53` from an affected machine — a TCP timeout or `TcpTestSucceeded: False` confirms the host is unreachable.

---

### 3. Netlogon secure channel to FINBRIDGE broken and unable to self-heal

**Why it fits:**  
Netlogon 5719 fires when the secure channel is severed or cannot be established at startup because no DC is locatable. Once DNS resolution fails, Netlogon cannot run DC Locator to find a replacement DC. The secure channel cannot be re-established without a working DNS lookup for `_ldap._tcp.finbridge.local` SRV records. This is a consequence of cause 1 but can persist even after DNS is fixed unless explicitly reset.

**Fastest check:** `nltest /sc_verify:finbridge.local` — if it returns `ERROR_NO_LOGON_SERVERS`, the channel is broken and DNS is still the blocker.

---

### 4. New DNS server (10.10.0.10) missing or incomplete SRV / A records for FINBRIDGE-DC01

**Why it fits:**  
If the new DNS server was stood up but zone replication or manual record entry was incomplete, even correctly-pointed machines would fail to resolve the DC. However, FB029 and FB058 — both using 10.10.0.10 — resolved successfully and processed GPO without issue. This makes a new-DNS record gap much less probable. Remains on the list as a low-probability check to eliminate during remediation.

**Fastest check:** `nslookup FINBRIDGE-DC01.finbridge.local 10.10.0.10` and `nslookup -type=SRV _ldap._tcp.finbridge.local 10.10.0.10` — successful resolution eliminates this cause.

---

### 5. DNS suffix search list absent or incorrect

**Why it fits:**  
If the DNS suffix search list does not include `finbridge.local`, machines may query bare hostnames and fail to resolve the FQDN. DNS Client 1014 does reference the FQDN explicitly, weakening this hypothesis, but DHCP options 15 (domain name) and 119 (domain search list) would also be inherited from the same stale scope that hands out the wrong DNS server — both could be stale simultaneously.

**Fastest check:** `ipconfig /all` — confirm `finbridge.local` appears in the DNS Suffix Search List and Connection-specific DNS Suffix fields.

---

## Re-Rank: Timing Clue Applied

> **The two unaffected machines (FB029, FB058) were manually pre-configured with 10.10.0.10 before the migration wave. They did not rely on DHCP for DNS. Every affected machine did. The DHCP scope was not updated. Therefore, the DHCP scope gap is not one cause among five — it is the root cause that activates all other entries on the list.**

The boundary between affected and unaffected maps *exactly* onto the boundary between DHCP-assigned DNS and manually-assigned DNS.

| Rank | Cause | Timing clue alignment |
|------|-------|-----------------------|
| **1** | DHCP scope not updated → decommissioned DNS assigned | FB029 and FB058 bypass DHCP DNS entirely. They work. Every DHCP-dependent machine on the same subnet gets the dead DNS IP and fails. This is the root cause. |
| **2** | Decommissioned DNS host unreachable at network layer | Directly downstream of cause 1. The old server is gone; every query to it times out. Confirms mechanism of cause 1. |
| **3** | Netlogon secure channel broken / unable to self-heal | Consequence of cause 2. DC Locator cannot run without DNS; secure channel cannot be established or repaired. Persists after DNS is fixed until reset or reboot. |
| **4** | GPO client cache expired with no DC reachable | Consequence of cause 3. Without the secure channel, the Group Policy client has no DC to pull policy from. Produces events 1058/1030/1129. |
| **5** | New DNS server record gaps (missing SRV/A records) | Eliminated as a primary cause by the FB029/FB058 control data — both use 10.10.0.10 and work correctly. Low-probability secondary check only. |

---

## One-Sentence Root Cause Statement

The decommissioned DNS servers were removed at 02:00, the DHCP scope was not updated, and at 07:40–07:55 affected machines powered on and received stale DHCP leases pointing at dead DNS hosts — every downstream error (Netlogon 5719, DNS 1014, GPO 1058/1030/1129) is a consequence of that single gap, which the two pre-configured machines were immune to by design.

---

## Recommended Remediation Sequence

1. Update DHCP scope option 6 to hand out `10.10.0.10`
2. Force DHCP lease renewal on affected machines (`ipconfig /release` → `ipconfig /renew`)
3. Flush DNS cache (`ipconfig /flushdns`)
4. Reset Netlogon secure channel (`nltest /sc_reset:finbridge.local`) or reboot
5. Trigger GPO refresh (`gpupdate /force`) to confirm policy applies cleanly

---

*Status: Hypothesis — not yet confirmed. Pending checks listed above.*
