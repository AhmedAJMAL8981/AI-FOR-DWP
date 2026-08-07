# Analysis with Solutions — Secure Channel / Group Policy Failure
**Incident date:** 2024-03-15  
**Affected site:** OU=Finance, Floor 3  
**Author role:** DWP Service Desk Engineer  
**Status:** Root cause confirmed  

---

## 1. Symptom and Affected Scope

Users on three Windows 11 machines in OU=Finance, Floor 3 experienced a blank or failed logon at startup between 07:40 and 07:55 on 2024-03-15. The failure was tied to the machine being unable to establish a Netlogon secure channel or apply Group Policy at boot. A fourth machine in the same OU (DESKTOP-FB029) was unaffected.

| Machine | Subnet DNS assigned | Affected |
|---------|---------------------|----------|
| DESKTOP-FB031 | 10.10.3.250 (decommissioned) | Yes |
| DESKTOP-FB055 | 172.16.5.5 (decommissioned) | Yes |
| DESKTOP-FB056 | 172.16.5.5 (decommissioned) | Yes |
| DESKTOP-FB057 | 172.16.5.5 (decommissioned) | Yes |
| DESKTOP-FB029 | 10.10.0.10 (correct) | No — manually pre-configured |
| DESKTOP-FB058 | 10.10.0.10 (correct) | No — manually pre-configured |

---

## 2. Key Error Events

| Event ID | Source | Message |
|----------|--------|---------|
| 5719 | Netlogon | Secure channel to FINBRIDGE failed — no DC available |
| 1014 | DNS Client | Name resolution timeout for FINBRIDGE-DC01.finbridge.local |
| 1058 / 1030 / 1129 | GroupPolicy | GPO processing failed — no DC connectivity |

---

## 3. Ranked Probable Causes

### Cause 1 — DHCP scope not updated to new DNS server *(most likely)*

**Supporting evidence:**  
- DHCP scope for the Floor 3 subnet was explicitly not updated after the migration wave  
- FB031 DHCP lease confirms assignment of 10.10.3.250 (decommissioned at 02:00)  
- FB055–FB057 confirm assignment of 172.16.5.5 (decommissioned 2024-03-14)  
- All machines assigned the old DNS via DHCP are affected; all machines with manually-assigned correct DNS are unaffected  

**Fastest check:** `ipconfig /all` on affected machine — confirm DNS Server field shows a decommissioned IP (10.10.3.250 or 172.16.5.5).

---

### Cause 2 — Decommissioned DNS host unreachable at network layer

**Supporting evidence:**  
- DNS Client event 1014 records a *timeout*, not NXDOMAIN — consistent with querying a powered-off or network-removed host  
- Old DNS servers were decommissioned at 02:00; no route or listener remains  

**Fastest check:** `Test-NetConnection 10.10.3.250 -Port 53` from an affected machine — TCP timeout or `TcpTestSucceeded: False` confirms host is unreachable.

---

### Cause 3 — Netlogon secure channel unable to self-heal without DNS

**Supporting evidence:**  
- Netlogon 5719 fires because DC Locator cannot resolve `_ldap._tcp.finbridge.local` SRV records without a working DNS server  
- Secure channel cannot be re-established at startup  

**Fastest check:** `nltest /sc_verify:finbridge.local` — `ERROR_NO_LOGON_SERVERS` confirms DNS is still the blocker.

---

### Cause 4 — GPO client cache expired with no DC reachable

**Supporting evidence:**  
- GroupPolicy events 1058/1030/1129 are downstream of the Netlogon failure  
- With no DC reachable and no valid cached policy, GPO processing fails entirely  

**Fastest check:** Presence of GroupPolicy events 1058/1030/1129 in Event Viewer following Netlogon 5719 confirms this is a consequence, not an independent cause.

---

### Cause 5 — New DNS server (10.10.0.10) missing records *(low probability)*

**Supporting evidence:**  
- FB029 and FB058, both using 10.10.0.10, resolved FINBRIDGE-DC01.finbridge.local and processed GPO successfully  
- This effectively eliminates a record gap on the new DNS server as a contributing cause  

**Fastest check:** `nslookup FINBRIDGE-DC01.finbridge.local 10.10.0.10` — successful resolution eliminates this cause. *Pending confirmation as a precautionary step.*

---

## 4. Confirmed Root Cause

**The DHCP scope for the Floor 3 subnet was not updated to reference the new DNS server (10.10.0.10) when the old DNS servers were decommissioned at 02:00 on 2024-03-15.**

Affected machines powered on between 07:40 and 07:55 holding DHCP leases that assigned a decommissioned DNS server. With no working DNS, `FINBRIDGE-DC01.finbridge.local` could not be resolved, Netlogon could not locate a domain controller, the secure channel could not be established, and Group Policy processing failed — producing the blank/failed logon experience.

Machines manually pre-configured with the correct DNS server (10.10.0.10) before the migration wave were entirely unaffected, as they bypassed the stale DHCP scope.

---

## 5. Recommended Solutions

### Immediate fix

1. Update the DHCP scope option 6 (DNS Servers) for the Floor 3 subnet to `10.10.0.10`
2. Force a DHCP lease renewal on all affected machines:
   ```
   ipconfig /release
   ipconfig /renew
   ```
3. Flush the DNS resolver cache:
   ```
   ipconfig /flushdns
   ```
4. Reset the Netlogon secure channel:
   ```
   nltest /sc_reset:finbridge.local
   ```
   Or reboot the affected machine — a clean boot will re-run DC Locator with the corrected DNS assignment
5. Confirm Group Policy applies cleanly:
   ```
   gpupdate /force
   ```

### Longer-term fix

- **Include DHCP scope updates in the migration wave checklist.** The decommission runbook should require DHCP scope option 6 to be updated and verified on all affected subnets before or simultaneously with DNS server decommission, not as a separate follow-up step.
- **Audit all remaining subnets** in the migration wave to confirm no other DHCP scopes still reference 10.10.3.250 or 172.16.5.5.
- **Consider DHCP scope-level validation** as a pre-flight check: query each scope's DNS option and alert where a decommissioned IP is still listed.

---

## 6. Workaround (while fix is rolled out)

Manually set the DNS server to `10.10.0.10` on each affected machine while the DHCP scope update is pending:

```powershell
# Replace <InterfaceAlias> with the correct adapter name from ipconfig /all
Set-DnsClientServerAddress -InterfaceAlias "<InterfaceAlias>" -ServerAddresses 10.10.0.10
```

Then run steps 3–5 from the immediate fix above to restore domain connectivity without a full reboot.

> **Note:** This workaround sets a static DNS override. Once the DHCP scope is corrected and the lease renews, the machine will revert to DHCP-assigned DNS. Remove the static override if needed: `Set-DnsClientServerAddress -InterfaceAlias "<InterfaceAlias>" -ResetServerAddresses`

---

*Document status: Root cause confirmed. Remediation pending.*
