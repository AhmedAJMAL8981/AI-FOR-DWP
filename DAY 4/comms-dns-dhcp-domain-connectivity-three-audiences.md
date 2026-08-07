# End-User Communications — Floor 3 Finance Domain Login Failure
**Incident ID:** INC-2024-03-15-FINFLOOR3  
**Date:** 2024-03-15  

---

## Audience 1 — Non-Technical Executive

**Subject: Brief IT update — Finance Floor 3 login issue this morning**

Your team's access and data are safe and have not been compromised. This morning, four computers on Floor 3 were temporarily unable to display the login screen following a planned overnight IT migration. The cause has been identified — a network setting was not updated as part of the migration. A fix is being applied. No action is required from you.

---

## Audience 2 — Affected End-User Team (Finance, Floor 3)

**Subject: Update on the login issue this morning — what happened and what to do**

Hi team,

This morning some computers on Floor 3 showed a blank or failed login screen because an overnight IT change didn't update one of the background network settings the computers need to log in correctly. The issue has been identified and a fix is being applied now.

If you see this problem again before the fix is fully rolled out, please **do not restart your machine repeatedly** — contact the IT Service Desk straight away and let them know you are seeing a blank login screen.

**Contact:** IT Service Desk — pending confirmation.

Thanks for your patience.

---

## Audience 3 — Engineer-to-Engineer Internal Note

**Subject: INC-2024-03-15-FINFLOOR3 — DHCP scope DNS option not updated post-migration, Floor 3 Finance OU**

---

### Root Cause

DNS migration wave decommissioned 10.10.3.250 (02:00, 2024-03-15) and 172.16.5.5 (overnight, 2024-03-14). New authoritative DNS: 10.10.0.10. DHCP scope for the Floor 3 subnet was not updated — option 6 still handed out the old decommissioned IPs. Machines booting after 02:00 received dead DNS via DHCP lease, could not resolve `FINBRIDGE-DC01.finbridge.local`, Netlogon DC Locator failed (SRV `_ldap._tcp.finbridge.local` unresolvable), secure channel never established (Event 5719), GPO processing failed at every retry (Events 1058, 1030, 1129).

Control machines FB029 and FB058 had been manually pre-configured with static DNS 10.10.0.10 before the migration wave — both resolved the DC immediately and processed GPO successfully (Event 1500 at 07:40:11 on FB029). This isolates the DHCP scope gap as the sole root cause.

---

### Affected Machines and DNS Assignment

| Machine | DHCP-assigned DNS | Affected |
|---------|-------------------|----------|
| DESKTOP-FB031 | 10.10.3.250 (decommissioned 02:00) | Yes |
| DESKTOP-FB055 | 172.16.5.5 (decommissioned overnight 2024-03-14) | Yes |
| DESKTOP-FB056 | 172.16.5.5 (decommissioned overnight 2024-03-14) | Yes |
| DESKTOP-FB057 | 172.16.5.5 (decommissioned overnight 2024-03-14) | Yes |
| DESKTOP-FB029 | 10.10.0.10 (manually pre-configured) | No |
| DESKTOP-FB058 | 10.10.0.10 (manually pre-configured) | No |

---

### Key Events (FB031 — representative affected machine)

| Timestamp | Event | Detail |
|-----------|-------|--------|
| 07:40:08 | Netlogon 5719 | Secure channel to FINBRIDGE failed — no DC available |
| 07:40:09–12 | GroupPolicy 1058/1030/1129 | GPO failed — no DC connectivity |
| 07:41:05 | DNS Client 1014 | Name resolution timeout for FINBRIDGE-DC01.finbridge.local — timeout, not NXDOMAIN; confirms host unreachable |
| 07:42:18 | DHCP 50036 | IP 10.10.3.144 leased; DNS assigned: 10.10.3.250 — confirms stale scope |
| 07:44:01 | GroupPolicy 1129 | Retry failed — DC still unreachable |

---

### Action Taken

Pending confirmation. Expected:

1. Update DHCP scope option 6 on Floor 3 subnet → `10.10.0.10`
2. `ipconfig /release && ipconfig /renew` on FB031, FB055–FB057
3. `ipconfig /flushdns`
4. `nltest /sc_reset:finbridge.local`
5. `gpupdate /force` — verify Event 1500 fires cleanly

---

### Verification Step

On each previously affected machine post-fix:

```powershell
# Confirm DNS assignment is now correct
ipconfig /all  # DNS Servers should show 10.10.0.10

# Confirm secure channel is healthy
nltest /sc_verify:finbridge.local  # Expect: "Flags: b0 WRITABLE DC"

# Confirm GPO applied
gpresult /r  # Expect: policy list populated, no errors
```

Check Event Viewer → System: confirm no new Netlogon 5719 or GroupPolicy 1058/1030/1129 events post-fix. GroupPolicy Event 1500 should be present.

---

### Preventive Actions Required

| Action | Detail | Owner |
|--------|--------|-------|
| Update decommission runbook | Add mandatory step: validate and update DHCP scope option 6 on all affected subnets before or simultaneously with DNS server decommission. Must be signed off before the change window closes | Infrastructure / Change Management |
| Post-migration DHCP audit | Script to query all DHCP scopes and alert where option 6 references a decommissioned IP | Infrastructure Engineering |
| Consistent pre-configuration tracking | Where manual DNS pre-configuration is used ahead of a migration wave, maintain a complete machine list and confirm all machines are covered — not a sample | Desktop Engineering / Project Lead |

---

### If This Recurs Before Permanent Fix

Static DNS override on affected adapter:

```powershell
Set-DnsClientServerAddress -InterfaceAlias "<AdapterName>" -ServerAddresses 10.10.0.10
ipconfig /flushdns
nltest /sc_reset:finbridge.local
gpupdate /force
```

Revert after DHCP scope is fixed and lease renews:

```powershell
Set-DnsClientServerAddress -InterfaceAlias "<AdapterName>" -ResetServerAddresses
```

---

*Related incident: INC-2024-03-15-FINFLOOR3 — pending formal closure confirmation*
