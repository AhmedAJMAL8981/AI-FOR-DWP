# Known Error Record — Floor 3 Finance Domain Login Failure
**KEDB ID:** KEDB-2024-03-15-FINFLOOR3  
**Date raised:** 2024-03-15  
**Related incident:** INC-2024-03-15-FINFLOOR3  

---

**Symptom**  
Users on Windows 11 machines in the Finance OU, Floor 3 see a blank or failed logon screen at startup and cannot log in. The issue affects machines that received their network settings automatically (via DHCP) and does not affect machines that were manually configured with the correct network settings before the overnight migration.

**Cause**  
The DHCP scope for the Floor 3 subnet was not updated when the old DNS servers (10.10.3.250 and 172.16.5.5) were decommissioned at 02:00 on 2024-03-15 and replaced by 10.10.0.10. Affected machines received the decommissioned DNS server address via their DHCP lease, could not resolve the domain controller FINBRIDGE-DC01.finbridge.local, and therefore could not establish a domain secure channel or process Group Policy at startup.

**Scope**  
Windows 11 machines on Floor 3, Finance OU (DESKTOP-FB031, FB055, FB056, FB057) that rely on DHCP-assigned DNS settings. Machines manually pre-configured with DNS server 10.10.0.10 (DESKTOP-FB029, FB058) are not affected.

**Workaround**  
Manually set DNS server to 10.10.0.10 on the affected adapter, then run `ipconfig /flushdns`, `nltest /sc_reset:finbridge.local`, and `gpupdate /force` to restore domain connectivity without a reboot. Revert the static override (`Set-DnsClientServerAddress -ResetServerAddresses`) once the DHCP scope is permanently corrected and the lease renews.

**Permanent fix**  
Update DHCP scope option 6 for the Floor 3 subnet to hand out DNS server 10.10.0.10 in place of the decommissioned addresses. Audit all other subnets in the migration wave to confirm no remaining DHCP scopes still reference 10.10.3.250 or 172.16.5.5. Status: pending confirmation.

**How to spot it**  
Check the System Event Log on the affected machine for Netlogon Event ID **5719** (secure channel to FINBRIDGE failed — no domain controller available) and DNS Client Event ID **1014** (name resolution timeout for `FINBRIDGE-DC01.finbridge.local`), followed by GroupPolicy Event IDs **1058**, **1030**, and **1129** (GPO processing failed — no DC connectivity). Confirm the DNS server assigned by DHCP via `ipconfig /all` — if it shows 10.10.3.250 or 172.16.5.5, the DHCP scope has not been updated.
