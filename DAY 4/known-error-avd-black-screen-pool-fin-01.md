Symptom     : Users in POOL-FIN-01 see a black screen after login. Some sessions recover after about 30 seconds, while others disconnect or remain unusable.

Cause       : A graphics/display stack regression was introduced by the 02:00 image update applied to POOL-FIN-01. On affected hosts, Desktop Window Manager (dwm.exe) repeatedly faulted in Intel graphics module igdumd64.dll.

Scope       : The impact was limited to POOL-FIN-01, with approximately 40 percent of users affected during the incident window. POOL-FIN-02 was unaffected.

Workaround  : Prioritize user access through the unaffected pool (POOL-FIN-02) where possible to contain impact. For affected POOL-FIN-01 hosts, execute the approved graphics/image remediation path used in the incident runbook.

Permanent fix: Apply the approved POOL-FIN-01 graphics/image remediation (driver/acceleration path correction) and revalidate host/session behavior. Recovery was verified at 10:00 with successful user logins and no new reports.

How to spot it: On affected hosts, look for repeated Application Error Event ID 1000 showing dwm.exe faulting in igdumd64.dll (exception 0xc0000005), followed by Desktop Window Manager Event ID 9009 and LocalSessionManager Event ID 40 disconnects after Event ID 21 logons. A supporting discriminator is pool differential: POOL-FIN-01 (updated at 02:00) shows failures while POOL-FIN-02 does not.
