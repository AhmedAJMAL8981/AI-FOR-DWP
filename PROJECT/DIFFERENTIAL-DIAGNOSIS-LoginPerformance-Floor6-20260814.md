# DIFFERENTIAL DIAGNOSIS: LOGIN & PERFORMANCE ISSUE
## FinBridge Floor 6 – Windows 11 Migration Cohort
**Date:** 2026-08-14 (Monday morning, first business day post-migration)  
**Affected Cohort:** ~45 Legal department users, Floor 6  
**Symptoms:** Slow login (prolonged wait time) OR login failure (cannot authenticate)  
**Scope:** Multiple users on same floor  
**Timeline:** Windows 11 migration completed week of 2026-08-06; app deployed Friday 2026-08-11; incident discovered Monday 2026-08-14 09:14

---

## EXECUTIVE SUMMARY

**Situation:** Multiple users on Floor 6 cannot log in or experience extremely slow login times on Monday morning following a weekend after Windows 11 migration and Friday document management app deployment.

**Critical Distinction:** This is a **login/authentication issue**, not a post-login productivity issue. The scope (multiple users, same floor, same cohort) suggests **systemic/infrastructure cause** rather than user-specific problem.

**Approach:** Ranked differential diagnosis using enterprise troubleshooting methodology. Root cause will be identified through systematic evidence collection, not temporal proximity to Friday deployment.

---

## RANKED DIFFERENTIAL DIAGNOSIS (HIGHEST TO LOWEST PROBABILITY)

### **RANK 1: Intune Policy Enforcement / Device Compliance Failure**
**Probability: 40–45%** | **Confidence Level: HIGH** | **Time to Validate: 5 minutes**

#### Plausibility Explanation
- **Timing:** Intune policies deploy overnight or at device startup; Windows 11 migration cohort likely received new baseline policies
- **Scope:** Affects cohort uniformly (all Floor 6 users experiencing same issue)
- **Mechanism:** Intune policy could enforce:
  - MFA requirement that wasn't needed pre-migration
  - Conditional access rule requiring device compliance check
  - New certificate requirement for network access
  - BitLocker or other encryption requirement preventing boot
  - Network adapter driver policy conflict
  - VPN requirement before authentication
- **Evidence:** Policies deployed to this cohort during migration week or over weekend would affect all users equally
- **Why First:** Most common cause of cohort-wide login delays post-migration

#### Fastest Validation Check
```
Action 1: Check Intune Portal
→ Intune > Devices > Windows 11 devices (Floor 6)
→ Filter by device name pattern (LEGAL*, FIN*, LF*)
→ Check "Enrollment Status"
   • If "Compliant" = policy processed OK
   • If "Non-compliant" = policy blocking login
   • If "Pending compliance" = policy still evaluating
→ Time required: 3 minutes

Action 2: Check Policy Delivery Status
→ Intune > Devices > Compliance
→ Filter to Floor 6 device group
→ Check "Compliance status" column
   • If red/failing = policy is blocking access
   • If green = policy enforcement succeeded
→ Time required: 2 minutes
```

#### Evidence That CONFIRMS This Cause
- [ ] Intune portal shows Floor 6 devices marked "Non-compliant" as of Monday morning
- [ ] Compliance failure started 08:00 Monday (device boot time)
- [ ] Specific policy (e.g., "MFA enforcement", "BitLocker required", "Certificate required") is listed as non-compliant
- [ ] Azure AD conditional access rules show policy blocking sign-in
- [ ] All affected users' devices show same compliance failure
- [ ] Disabling the offending policy immediately restores login
- [ ] Event Viewer on affected machines shows policy evaluation errors at boot time

#### Evidence That RULES OUT This Cause
- [ ] Intune portal shows all Floor 6 devices as "Compliant" at time of incident
- [ ] No policy changes in last 48 hours (Intune audit log)
- [ ] Some Floor 6 devices logging in successfully (indicates policy not uniformly blocking)
- [ ] Users can log in via alternative method (e.g., PIN instead of password, VPN instead of corporate network)
- [ ] Non-Floor 6 users with same Intune policy logging in normally (indicates policy not broken globally)

---

### **RANK 2: Azure AD / Conditional Access Authentication Policy Block**
**Probability: 25–30%** | **Confidence Level: HIGH** | **Time to Validate: 5 minutes**

#### Plausibility Explanation
- **Timing:** Conditional access (CA) policies can be pushed overnight or activated on a schedule
- **Scope:** CA policy can be applied to all users in a floor/department location or device group
- **Mechanism:** Conditional access rule could suddenly require:
  - MFA from corporate network (not required before)
  - Specific IP range / location (Floor 6 moved to different VPN gateway?)
  - Compliant device (Windows 11 device not yet marked compliant in Azure AD)
  - Specific browser or OS version
  - Device must be Azure AD joined (not domain-joined only)
- **Evidence:** CA policies are evaluated at logon; if rule blocks, user cannot authenticate
- **Why Second:** Very common post-migration; easily overlooked because policies apply transparently

#### Fastest Validation Check
```
Action 1: Check Azure AD Conditional Access
→ Azure AD > Security > Conditional Access Policies
→ Filter by recently modified (last 48 hours)
→ Check which policies apply to "Floor 6" or "Legal" or "Migrated Users"
→ For each policy, check:
   • Is it enabled?
   • What condition triggers the block? (location, device, user risk, etc.)
   • Does it match Floor 6's characteristics?
→ Time required: 3 minutes

Action 2: Check Sign-In Logs
→ Azure AD > Sign-in logs
→ Filter: Status = "Failure", User location = "Floor 6" or Floor 6 IP range
→ Look for column "Conditional Access Status"
   • If "Block" = CA policy is blocking
   • If "Not Applied" = CA not the cause
→ Time required: 2 minutes
```

#### Evidence That CONFIRMS This Cause
- [ ] Azure AD sign-in logs show status "Conditional Access" → "Block" for Floor 6 users
- [ ] Specific CA policy is listed as the blocker (e.g., "Require MFA for migrated users")
- [ ] CA policy was activated or modified between Friday and Monday
- [ ] All affected users' sign-in attempts fail at CA stage (not at password validation)
- [ ] Temporarily disabling the CA policy allows users to log in
- [ ] Users can log in from VPN or with different device (outside CA policy scope)
- [ ] Non-Floor 6 users exempt from this CA policy logging in successfully

#### Evidence That RULES OUT This Cause
- [ ] Azure AD sign-in logs show failure reason = "Invalid password" or "Account locked" (not CA block)
- [ ] No CA policies modified in last 48 hours
- [ ] No CA policies apply to Floor 6 or device group
- [ ] All CA policies show "Not Applied" in sign-in logs
- [ ] All Floor 6 users meet CA policy requirements (compliant device, correct location, etc.)
- [ ] Some Floor 6 users logging in successfully (indicates CA not uniformly blocking)

---

### **RANK 3: Network Connectivity / VPN Gateway Issue**
**Probability: 15–20%** | **Confidence Level: MEDIUM** | **Time to Validate: 3 minutes**

#### Plausibility Explanation
- **Timing:** Network issue could be overnight maintenance, VPN concentrator restart, or routing change
- **Scope:** Affects all Floor 6 users if they share a VPN gateway or network segment
- **Mechanism:** 
  - Domain controller unreachable (users cannot authenticate against AD)
  - VPN gateway down or misconfigured (login attempts timeout)
  - Network path to Azure AD service blocked (cloud authentication fails)
  - DNS resolution failure (cannot find domain controller or cloud endpoints)
  - Proxy or firewall rule blocks authentication traffic
- **Evidence:** Users would see timeout or "cannot reach server" errors, not permission denied
- **Why Third:** Less likely because single network segment shouldn't go completely offline; but possible if Floor 6 is on isolated VLAN

#### Fastest Validation Check
```
Action 1: Ping Domain Controller
→ From affected machine or help desk system:
   ping [domain_controller_name]
   ping [domain_controller_IP]
→ If responses received = network connectivity OK
→ If timeouts or "unreachable" = network issue present
→ Time required: 1 minute

Action 2: Test Azure AD Connectivity
→ From affected machine:
   nslookup login.microsoftonline.com
   nslookup device.login.microsoftonline.com
→ If IP addresses returned = DNS resolution OK
→ If "NXDOMAIN" or timeout = Azure AD unreachable
→ Time required: 1 minute

Action 3: Check Network Team / Monitoring
→ Contact network team directly
→ Ask: "Any maintenance on Floor 6 network, VPN, or domain controller Saturday-Monday?"
→ Check network monitoring tool (Nagios, PRTG, etc.) for Floor 6 segment uptime
→ Time required: 1–2 minutes
```

#### Evidence That CONFIRMS This Cause
- [ ] Ping to domain controller shows timeout or "unreachable" from Floor 6
- [ ] Azure AD endpoints (login.microsoftonline.com) unreachable from Floor 6
- [ ] Network team confirms maintenance or outage on Floor 6 segment over weekend
- [ ] VPN concentrator logs show connection failures from Floor 6 subnet
- [ ] Non-Floor 6 users can log in normally (indicates AD and cloud services OK)
- [ ] Floor 6 users can log in from home (VPN) or different building (different network path)
- [ ] Tracert / pathping shows network path blocked at specific hop

#### Evidence That RULES OUT This Cause
- [ ] Ping to domain controller responds normally from Floor 6
- [ ] Azure AD endpoints (login.microsoftonline.com) resolve and respond
- [ ] Network team confirms no maintenance or issues on Floor 6 network
- [ ] VPN concentrator logs show no connection errors
- [ ] Some Floor 6 users logging in successfully (indicates network OK for at least some traffic)
- [ ] Users report they receive specific error message (e.g., "password invalid") rather than timeout

---

### **RANK 4: Windows 11 User Profile Corruption / Migration Issue**
**Probability: 12–15%** | **Confidence Level: MEDIUM** | **Time to Validate: 5 minutes**

#### Plausibility Explanation
- **Timing:** Profile corruption can manifest at first boot post-migration
- **Scope:** Could affect multiple users if migration process has systematic flaw
- **Mechanism:**
  - User profile failed to migrate from Windows 10 → temporary profile created
  - Roaming profile server unreachable (user cannot load profile)
  - Profile corruption prevents user data load during login process
  - ntuser.dat file locked or inaccessible
  - Cached credentials not migrated correctly
- **Evidence:** Users in temporary profiles (.000) or profile load errors in Event Viewer
- **Why Fourth:** Less likely as first hypothesis because temporary profiles usually allow login (slow but functional); rules out Windows 11 itself as culprit

#### Fastest Validation Check
```
Action 1: Check for Temporary Profiles
→ Remote into affected machine (if possible)
→ Run: dir C:\Users | findstr /R "\.000"
→ If results show [username].000 files = user in temporary profile
→ Time required: 2 minutes

Action 2: Check Event Viewer for Profile Errors
→ Remote into affected machine
→ Event Viewer > Windows Logs > System
→ Look for Event ID 1509 (user profile failed to load)
→ Look for Event ID 1516 (cannot create directory for profile)
→ Time required: 2 minutes

Action 3: Query Roaming Profile Server
→ Ask: "Is roaming profile server accessible from Floor 6?"
→ Run: net use \\[profile_server]\profiles (test share access)
→ Check server logs for connection errors
→ Time required: 2 minutes
```

#### Evidence That CONFIRMS This Cause
- [ ] Event Viewer shows Event ID 1509/1516 (profile load failure) on affected machines
- [ ] Users are logged in using temporary profiles ([username].000)
- [ ] Roaming profile server is offline or unreachable
- [ ] Profile migration logs show failures for Floor 6 cohort
- [ ] ntuser.dat file is locked or corrupted on affected machines
- [ ] Deleting corrupted profile and forcing profile rebuild restores normal login
- [ ] Other cohorts' profiles loaded correctly (indicates issue specific to Floor 6 migration)

#### Evidence That RULES OUT This Cause
- [ ] No temporary profiles found on any affected machine
- [ ] Event Viewer shows no profile-related errors (no Event ID 1509/1516)
- [ ] Roaming profile server is online and accessible
- [ ] Users successfully log in after deleting corrupted profile and forcing rebuild
- [ ] Some Floor 6 users logging in with normal (non-temporary) profiles

---

### **RANK 5: Document Management App Deployment – Direct Impact**
**Probability: 10–12%** | **Confidence Level: MEDIUM-LOW** | **Time to Validate: 5 minutes**

#### Plausibility Explanation
- **Timing:** App deployed Friday afternoon; first login opportunity is Monday morning
- **Scope:** App deployed to all Floor 6 machines, affecting all users equally
- **Mechanism:**
  - App installation included a logon script that fails or times out
  - App installer ran with elevated privileges, modified authentication registry keys
  - App installer created a service that must start before login can proceed (but service is broken)
  - App installer modified network driver or proxy settings, breaking authentication
  - App is attempting to index or sync data on first logon, causing 10+ minute startup delay
  - App's post-installation job runs at startup and crashes, preventing user logon
- **Evidence:** App uninstallation or rollback immediately restores login
- **Why Fifth:** Plausible but less likely as PRIMARY cause because:
  - Logon scripts typically fail gracefully (don't block login)
  - App deployed only to Floor 6; if it broke logon scripts, deployment would have caught it
  - Most apps don't run during authentication phase (too early to affect login)
  - If app broke authentication, it would likely be detected Friday before EOD

#### Fastest Validation Check
```
Action 1: Check App Installation Log
→ On affected machine (if accessible):
   %AppData%\[DocumentManagementApp]\Installation.log
   C:\Program Files\[DocumentManagementApp]\Install.log
→ Look for errors or crashes during installation
→ Look for post-installation tasks that failed
→ Time required: 2 minutes

Action 2: Check Startup Services
→ On affected machine:
   Services.msc → Look for [DocumentManagementApp] services
   Check if any are:
   • Disabled or failing to start
   • Marked "Manual" but starting automatically
   • Showing error state
→ Time required: 2 minutes

Action 3: Test Rollback
→ Uninstall [DocumentManagementApp] from one test machine
→ Restart machine
→ Attempt login
→ If login succeeds quickly → App is likely cause
→ Time required: 5 minutes
```

#### Evidence That CONFIRMS This Cause
- [ ] App installation log shows errors or failed post-installation tasks
- [ ] App logon script is timing out (taking 5+ minutes)
- [ ] App service is marked as startup but failing to start
- [ ] Uninstalling app from test machine immediately restores normal login speed
- [ ] All affected machines have the app installed
- [ ] App was not deployed to non-Floor 6 machines (and they log in normally)
- [ ] App vendor releases hotfix or rollback guide for Windows 11 / Intune compatibility
- [ ] Registry or network settings modified by app are causing authentication delays

#### Evidence That RULES OUT This Cause
- [ ] App installation completed successfully with no errors in log
- [ ] App's logon script completes in <1 second or is disabled
- [ ] App service is running without errors
- [ ] Uninstalling app from test machine does NOT restore normal login speed
- [ ] Some Floor 6 users can log in normally (indicates app not universally blocking)
- [ ] Non-Floor 6 users not experiencing login issues (and don't have app)
- [ ] Event Viewer shows no errors from app-related services or processes

---

### **RANK 6: Windows 11 Driver or Hardware Compatibility Issue**
**Probability: 8–10%** | **Confidence Level: MEDIUM-LOW** | **Time to Validate: 5 minutes**

#### Plausibility Explanation
- **Timing:** Windows 11 migration first boot occurs; driver conflicts can cause login delays
- **Scope:** Affects all Floor 6 machines if they're the same hardware model
- **Mechanism:**
  - Network adapter driver missing or incompatible → cannot reach domain controller
  - Storage controller driver issue → disk extremely slow, delays profile load
  - Chipset driver incompatibility → CPU throttling or I/O delays during boot
  - BIOS/firmware update required for Windows 11 causes hardware malfunction
  - Printer or peripheral driver crashes during logon script execution
- **Evidence:** Event Viewer shows driver errors; Device Manager shows devices with warnings
- **Why Sixth:** Less likely because:
  - Driver issues usually caught in pre-deployment testing
  - Would more likely cause boot failure than login delay
  - Individual machines would fail independently, not cohort-wide

#### Fastest Validation Check
```
Action 1: Check Device Manager for Errors
→ On affected machine (if accessible):
   Device Manager → Look for devices with warning (yellow exclamation)
   Note any:
   • Network adapters with warnings
   • Storage controllers with warnings
   • Unknown devices
→ Time required: 1 minute

Action 2: Check Event Viewer for Driver Errors
→ On affected machine:
   Event Viewer > System log
   Search for error events related to drivers
   Look for: "driver failed to load", "not compatible", "hardware error"
→ Time required: 2 minutes

Action 3: Check BIOS/Firmware Version
→ On affected machine:
   System Information → BIOS version
   Compare to Windows 11 support matrix
   Check if BIOS update available
→ Time required: 1 minute
```

#### Evidence That CONFIRMS This Cause
- [ ] Device Manager shows network adapter or storage controller with warning
- [ ] Event Viewer shows driver error events at boot time
- [ ] All affected machines same hardware model
- [ ] BIOS version not compatible with Windows 11
- [ ] Updating drivers restores normal login speed
- [ ] Non-Floor 6 machines (different hardware) logging in normally
- [ ] Vendor (Dell, HP, Lenovo) releases Windows 11 driver pack for this model

#### Evidence That RULES OUT This Cause
- [ ] Device Manager shows all devices functioning normally (no warnings)
- [ ] Event Viewer shows no driver-related errors
- [ ] Different hardware models on Floor 6 all experiencing same issue (not model-specific)
- [ ] BIOS version is current and compatible with Windows 11
- [ ] Updating drivers does NOT improve login speed

---

### **RANK 7: Domain Controller or Active Directory Replication Issue**
**Probability: 5–8%** | **Confidence Level: LOW-MEDIUM** | **Time to Validate: 3 minutes**

#### Plausibility Explanation
- **Timing:** AD replication could have failed overnight or during weekend maintenance
- **Scope:** All users on a particular domain controller or replication site experiencing delays
- **Mechanism:**
  - Domain controller offline or responding slowly
  - Active Directory replication broken → logon scripts, group policies not updated
  - Global Catalog server slow or unreachable
  - LDAP queries timing out during authentication
- **Evidence:** Network monitoring shows DC response time degraded; AD replication status shows errors
- **Why Seventh:** Less likely because:
  - AD DC issues usually affect all users org-wide, not just Floor 6
  - Would show as network latency, not login failure
  - DC redundancy should prevent single DC failure from blocking all logins

#### Fastest Validation Check
```
Action 1: Query Domain Controller Status
→ From helpdesk system:
   nltest /dclist:[domain]
   dcdiag /v (to check DC health)
→ Look for slow response times or errors
→ Time required: 2 minutes

Action 2: Check Active Directory Replication
→ From AD admin console:
   Active Directory Sites and Services
   Check replication status between DCs
   Look for replication failures or delays
→ Time required: 2 minutes

Action 3: Ping Domain Controller
→ ping [DC_name] and note response time
→ If >50ms consistently = possible DC performance issue
→ Time required: 1 minute
```

#### Evidence That CONFIRMS This Cause
- [ ] dcdiag reports errors on domain controller
- [ ] AD replication monitor shows replication failures
- [ ] Domain controller response time is slow (>100ms)
- [ ] Global Catalog server is offline or unresponsive
- [ ] Directing users to alternate domain controller restores normal login
- [ ] Server monitoring shows CPU or memory exhaustion on DC

#### Evidence That RULES OUT This Cause
- [ ] dcdiag reports all DCs healthy
- [ ] AD replication status is normal
- [ ] Domain controller response time is normal (<20ms)
- [ ] Non-Floor 6 users logging in with no delays (indicates AD functioning normally)

---

### **RANK 8: Friday App Deployment – Indirect Impact via Group Policy / Configuration**
**Probability: 3–5%** | **Confidence Level: LOW** | **Time to Validate: 10 minutes**

#### Plausibility Explanation
- **Timing:** App deployment could have triggered group policy update or created new GPO
- **Scope:** If app created group policy that applies to all Floor 6 users, affects everyone
- **Mechanism:**
  - App installer created GPO with logon script that now runs at every login
  - App deployment triggered Windows Group Policy refresh that updated authentication settings
  - App installation modified registry in a way that affects group policy evaluation
  - App deployment created startup script that interferes with authentication
- **Evidence:** Group policy audit log shows new policies created Friday afternoon
- **Why Eighth:** Unlikely because:
  - App installers typically don't create group policies
  - Would require domain admin privileges and domain coordination
  - If app affected GPO, would likely be detected in testing before Friday deployment
  - Separable from direct app cause (Rank 5)

#### Fastest Validation Check
```
Action 1: Check Group Policy Modification Time
→ From DC or admin console:
   Group Policy Management Console
   Filter by modified date: 2026-08-11 (Friday)
   Check for any new policies created on that date
→ Time required: 2 minutes

Action 2: Check Group Policy Audit Log
→ On DC:
   Event Viewer > Windows Logs > Security
   Search for Event ID 5136 (object changed) with Friday timestamp
   Check if any GPO modifications related to logon
→ Time required: 2 minutes

Action 3: Run gpupdate on Test Machine
→ On a Floor 6 machine:
   gpupdate /force
   Immediately attempt to log out/in
→ If forces normal login → not policy issue
→ Time required: 3 minutes
```

#### Evidence That CONFIRMS This Cause
- [ ] New group policy created Friday afternoon related to logon or authentication
- [ ] Group Policy audit log shows Friday modifications by app deployment account
- [ ] Running gpupdate manually on test machine shows policy application succeeds but login still slow
- [ ] Removing the Friday policy immediately restores normal login

#### Evidence That RULES OUT This Cause
- [ ] No group policy modifications on Friday
- [ ] Group Policy audit log shows no Friday changes
- [ ] gpupdate runs successfully and login speed is not affected

---

## DEPLOYMENT IMPACT ASSESSMENT

### Critical Question: Is the Friday Document Management Application Deployment the Root Cause?

This section specifically examines what evidence would prove OR disprove the Friday app deployment as the root cause of Monday login issues.

---

### **EVIDENCE THAT WOULD PROVE Friday App Deployment IS THE CAUSE**

#### Category 1: Application Installation Errors (Direct Impact)
- [ ] **App installation log shows critical error or crash**
  - Error occurs during installation
  - Post-installation script fails with exit code ≠ 0
  - Evidence: %appdata%\[AppName]\Install.log or C:\Program Files\[AppName]\Setup_Error.log
  - **Severity:** HIGH confidence if found

- [ ] **App logon script times out or crashes during login attempt**
  - Script execution time: >30 seconds (causing login delay)
  - Script error event in Event Viewer
  - Evidence: Event Viewer > Application log; cmd.exe crash during logon
  - **Severity:** HIGH confidence if found; would directly explain slow login

- [ ] **App's auto-start service is broken or causes crash at logon**
  - Service set to "Automatic" but fails to start
  - Service crash dump shows app error
  - Evidence: Services.msc; Event Viewer > System log; WER (Windows Error Reporting) logs
  - **Severity:** HIGH confidence if found

- [ ] **Uninstalling app from test machine immediately restores normal login speed**
  - Test procedure:
    1. Pick one Floor 6 machine with slow login
    2. Uninstall [DocumentManagementApp]
    3. Restart
    4. Attempt login and measure time
  - **Severity:** CRITICAL; would directly confirm or rule out app as cause

#### Category 2: App Modification of Authentication Components (Indirect Impact)
- [ ] **App installer modified Windows authentication registry keys**
  - Evidence: Registry change audit log shows Friday modifications to:
    - HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer
    - HKLM\SECURITY\Policy\*
    - HKCU\Software\Microsoft\Windows\CurrentVersion\Run
  - **Severity:** HIGH confidence if authentication-critical keys modified

- [ ] **App created new group policy object (GPO) at Friday deployment**
  - Evidence: Group Policy Management Console shows new GPO created 2026-08-11
  - New GPO applies logon script or authentication-related settings
  - **Severity:** MEDIUM-HIGH confidence

- [ ] **App modified network adapter or proxy settings affecting Azure AD connectivity**
  - Evidence: ipconfig /all shows unexpected proxy settings
  - Network trace shows auth traffic routed differently than expected
  - **Severity:** MEDIUM confidence if connectivity actually broken

- [ ] **App's data indexing process runs at logon and causes delays**
  - Evidence: Task Manager shows app process consuming CPU/disk at logon
  - App's initialization can be seen in Event Viewer > Application log as "slow operation"
  - **Severity:** MEDIUM confidence; would cause slow login (not failure) but not prevent login

#### Category 3: Vendor Confirmation (External Validation)
- [ ] **Vendor releases security advisory about Windows 11 / Intune compatibility issue**
  - "Known issue: Application causes logon delays on Windows 11 Intune-enrolled devices"
  - **Severity:** HIGH confidence if issue directly matches

- [ ] **Vendor confirms app installation can modify authentication settings**
  - Vendor documentation acknowledges app touches authentication or networking
  - Vendor provides rollback guide
  - **Severity:** MEDIUM-HIGH confidence

---

### **EVIDENCE THAT WOULD PROVE Friday App Deployment IS NOT THE CAUSE (Disproof)**

#### Category 1: App Installation Success
- [ ] **App installation log shows clean, successful completion**
  - No errors, exit code = 0
  - All files installed correctly
  - Registry entries added without issues
  - Evidence: Installation log timestamp Friday 14:30–15:00 with "Installation successful" message
  - **Severity:** HIGH confidence in disproving direct install failure

- [ ] **Uninstalling app from test machine does NOT restore normal login speed**
  - Test procedure:
    1. Pick Floor 6 machine with slow login
    2. Uninstall [DocumentManagementApp]
    3. Restart and test login
    4. If login still slow → app not cause
  - **Severity:** CRITICAL disproving evidence

- [ ] **App service/processes show no errors in logs**
  - Services.msc shows app services running normally
  - Event Viewer shows no errors from app-related processes
  - Task Scheduler shows no failed scheduled tasks from app
  - **Severity:** HIGH confidence

#### Category 2: Scope Mismatch (If App Not Deployed to All Users)
- [ ] **App was deployed only to SOME Floor 6 users, but ALL Floor 6 users experiencing login issues**
  - Evidence: Deployment log shows app installed to machines [A, B, C] only
  - But affected users include machines [D, E, F] (without app)
  - **Severity:** CRITICAL disproving evidence

- [ ] **App was deployed to NON-Floor 6 machines, but they are NOT experiencing login issues**
  - Evidence: App deployed to floors 3 and 4 as well
  - Floors 3 and 4 users logging in normally Monday morning
  - **Severity:** HIGH confidence that app is not cause

- [ ] **App deployment rollback was tested Friday EOD, and login was normal**
  - Evidence: Friday afternoon after deployment, one test machine was rolled back
  - Test machine logged in successfully Friday evening
  - **Severity:** MEDIUM-HIGH confidence

#### Category 3: Login Issue Characteristics Don't Match App Behavior
- [ ] **Some Floor 6 users can log in successfully (not all affected)**
  - If app deployment universally broke authentication, ALL would fail
  - Selective failure indicates system/infrastructure issue, not app
  - Evidence: Helpdesk reports indicate subset of Floor 6 affected
  - **Severity:** CRITICAL disproving evidence

- [ ] **Users receive error message indicating authentication failure, not timeout**
  - Users report: "Invalid password" or "Account locked" or "Cannot reach server"
  - Users do NOT report: "Taking very long time" or "Hanging on login"
  - **Severity:** HIGH confidence; app causing delay would show timeout behavior

- [ ] **Restarting machine restores login speed (app already loaded, shouldn't affect restart)**
  - If app caused logon script failure, restart should NOT fix (script still broken)
  - If restart fixes it, likely temporary cache/policy issue, not app
  - **Severity:** MEDIUM-HIGH confidence

#### Category 4: External Validation
- [ ] **Vendor denies any known Windows 11 or Intune compatibility issues**
  - Vendor statement: "Application is fully compatible and tested on Windows 11 + Intune"
  - Vendor KB or release notes mention no logon-related issues
  - **Severity:** MEDIUM confidence in disproving; absence of evidence isn't definitive

- [ ] **No third-party reports of app causing logon issues**
  - Search vendor forums, GitHub issues, community reports
  - No other organizations report logon delays after deploying this app
  - **Severity:** LOW-MEDIUM confidence; lack of reports could indicate rarity rather than absence

---

### **KEY DISTINGUISHING FACTORS: App-Related vs. Independent Issue**

| Finding | Suggests App IS Cause | Suggests App Is NOT Cause |
|---------|---|---|
| **Logon time:** >5 minutes | App indexing or script timeout | Policy evaluation or network latency |
| **Logon time:** <30 seconds but consistent delay | App logon script running slowly | Policy delays or credential caching |
| **Login failure (cannot authenticate)** | App modified auth registry | Policy/compliance block, network issue, or credential problem |
| **All Floor 6 affected uniformly** | Suggests app deployed to all; but could be policy/network | Policy, network, or compliance issue affecting cohort |
| **Only some Floor 6 affected** | Suggests app-related (different hardware/install state) | User-specific issue (credentials, group membership) |
| **Non-Floor 6 users unaffected** | Suggests Floor 6-specific (app? network? policy?) | App is likely cause (only deployed to Floor 6) |
| **Uninstall app → login works** | DEFINITIVE: App is cause | N/A |
| **Uninstall app → login still slow** | DEFINITIVE: App is NOT cause | Confirms app not cause |

---

### **DIFFERENTIAL DIAGNOSIS WORKFLOW FOR APP DEPLOYMENT CAUSE**

```
START: Is Friday app deployment the root cause?
│
├─→ FIRST FAST TEST: Uninstall app from one Floor 6 machine
│   │
│   ├─→ Result: Login now normal and fast
│   │   └─→ CONCLUSION: App IS the cause
│   │       ACTION: Prepare rollback for all Floor 6
│   │
│   └─→ Result: Login still slow / still fails
│       └─→ CONCLUSION: App is NOT the cause
│           ACTION: Continue with other hypotheses (network, policy, etc.)
│
├─→ IF FAST TEST NOT POSSIBLE: Check installation log and app configuration
│   │
│   ├─→ App installation log shows errors or crashes
│   │   ├─→ Confidence: App may be cause (medium-high)
│   │   └─→ ACTION: Prioritize app-related hypothesis; test removal
│   │
│   └─→ App installation log shows success
│       ├─→ Confidence: App probably NOT cause (medium-high)
│       └─→ ACTION: Deprioritize app; test network/policy/compliance first
│
├─→ SECONDARY CHECK: Compare affected vs. unaffected users/machines
│   │
│   ├─→ ALL Floor 6 affected; NONE of other floors affected
│   │   └─→ Suggests: Floor 6-specific cause (could be app, could be network, could be policy)
│   │
│   └─→ SOME Floor 6 affected; SOME of other floors affected
│       └─→ Suggests: Org-wide cause (unlikely to be Friday app specific)
│
└─→ FINAL DETERMINATION: Based on evidence, classify as:
    ├─→ "App deployment highly likely to be cause" → Remediation: Rollback/fix app
    ├─→ "App deployment possible but not definitive" → Remediation: Test removal first
    ├─→ "App deployment unlikely to be cause" → Remediation: Focus on other hypotheses
    └─→ "App deployment ruled out" → Remediation: Independent of app
```

---

## FINAL RANKED DIFFERENTIAL DIAGNOSIS (Summary)

### Probability Rankings with Confidence Levels

| Rank | Hypothesis | Probability | Confidence | Time to Validate | Primary Evidence |
|---|---|---|---|---|---|
| **1** | Intune policy enforcement / compliance failure | 40–45% | HIGH | 5 min | Intune portal shows non-compliant devices; Azure AD conditional access blocks logon |
| **2** | Azure AD conditional access block | 25–30% | HIGH | 5 min | Sign-in logs show "Conditional Access" → "Block"; CA policy recently modified |
| **3** | Network connectivity / VPN issue | 15–20% | MEDIUM | 3 min | Domain controller unreachable; Azure AD endpoints not responding; network maintenance occurred |
| **4** | Windows 11 profile corruption | 12–15% | MEDIUM | 5 min | Temporary profiles (.000) found; Event ID 1509 in Event Viewer; roaming profile server offline |
| **5** | Document management app deployment (direct) | 10–12% | MEDIUM-LOW | 5 min | App installation log shows errors; logon script times out; uninstall restores login |
| **6** | Windows 11 driver/hardware issue | 8–10% | MEDIUM-LOW | 5 min | Device Manager shows driver warnings; Event Viewer shows driver errors; BIOS incompatible |
| **7** | Domain controller/AD replication issue | 5–8% | LOW-MEDIUM | 3 min | dcdiag reports errors; AD replication failures; DC response time slow |
| **8** | App deployment (indirect via GPO) | 3–5% | LOW | 10 min | New GPO created Friday; group policy audit log shows modifications; logon script failure |

---

## RECOMMENDED INVESTIGATION SEQUENCE (First 30 Minutes)

### **Minute 0–5: Rapid Triage (Parallel)**
- [ ] **Track A:** Check Intune portal for non-compliant Floor 6 devices
- [ ] **Track B:** Check Azure AD sign-in logs for conditional access blocks
- [ ] **Track C:** Contact network team: "Any maintenance on Floor 6 network over weekend?"
- [ ] **Track D:** Test network connectivity (ping DC, nslookup Azure AD)

### **Minute 5–10: Evidence Collection (Based on Track A–D Results)**
- [ ] If Intune shows non-compliant → Investigate which policy is failing
- [ ] If CA shows block → Identify which CA rule is blocking and when it was activated
- [ ] If network team reports maintenance → Test connectivity immediately
- [ ] If network tests fail → Escalate to network team for emergency restoration

### **Minute 10–15: Hypothesis Refinement**
- [ ] Narrow down to most likely cause from evidence collected
- [ ] If Intune/CA appears to be cause → Proceed to TIER 2 containment
- [ ] If network/profile appears to be cause → Proceed with targeted fix
- [ ] If app deployment suspected → Prepare test rollback

### **Minute 15–30: Fast Validation Test**
- [ ] **Test rollback:** Uninstall app from one test Floor 6 machine; restart; attempt login
- [ ] **Test policy:** Temporarily modify offending Intune policy; see if login succeeds
- [ ] **Test network:** Restore connectivity to domain controller; measure login time
- [ ] **Test profile:** Force profile rebuild on one affected machine; measure login time

---

## OCCAM'S RAZOR APPLICATION

**Principle:** Entities should not be multiplied without necessity. The simplest explanation requiring fewest assumptions is usually correct.

### **Simplest Explanations (Require Fewest Components)**

1. **Intune Policy Enforcement:** One policy created during migration; affects all cohort uniformly; simple to test (check portal)
2. **Conditional Access Rule:** One CA rule block; affects authentication uniformly; testable in minutes
3. **Network Issue:** Single network segment down; affects all users on that segment uniformly; testable with ping
4. **App Uninstall Test:** Single app deployed Friday; single uninstall test proves/disproves; most direct causation test

### **Complex Explanations (Require Multiple Assumptions)**

- "App deployment caused GPO creation AND DC replication failure AND user profile corruption" (requires 3+ simultaneous failures)
- "Windows 11 driver issue AND Intune policy conflict AND network latency" (requires 3+ independent issues)
- "App modified authentication registry AND created logon script AND triggered policy update" (requires multiple coordinated changes)

### **Application to FinBridge Case:**

**Most Likely Causes (by Occam's Razor):**
1. One Intune policy deployed during migration now blocking or requiring validation
2. One Azure AD conditional access rule activated and blocking Floor 6 users
3. One network segment experiencing connectivity issue

**Less Likely Causes (require multiple assumptions):**
- App deployment causing problems (requires assumption: app touches authentication, assumption: deployment wasn't tested, assumption: failure wasn't caught Friday)
- Windows 11 driver issue (requires assumption: thousands of machines with same driver, assumption: driver wasn't in migration test, assumption: issue only manifests Monday)

---

## FACTS vs ASSUMPTIONS vs UNKNOWNS (Summary)

### VERIFIED FACTS (100% Confidence)
1. Floor 6 has ~45 legal users recently migrated to Windows 11
2. Windows 11 migration completed week of 2026-08-06
3. Intune enrollment completed during same migration
4. Document management application deployed Friday 2026-08-11 (afternoon)
5. Multiple users reporting login issues Monday 2026-08-14 (09:14)
6. Login issues manifest as either slow login or login failure
7. No diagnostic logs or reports have been collected yet

### REASONABLE ASSUMPTIONS (80–95% Confidence)
1. Migration included deployment of new Intune policies to cohort
2. Azure AD was configured for cloud authentication during migration
3. Application deployment was tested before release (standard practice)
4. Network infrastructure (domain controllers, VPN) functioning (would be noticed if completely down)
5. At least some users can log in (wouldn't report "multiple affected" if 100% lockout)

### CRITICAL UNKNOWNS (Must Clarify Immediately)
1. Can ANY Floor 6 user log in successfully?
2. What is the exact error message users are receiving?
3. How long does a login attempt take before timing out or failing?
4. Were any policies deployed to this cohort between Friday and Monday?
5. Was app deployment tested on Windows 11 + Intune before Friday release?
6. Has any network maintenance or service outage been performed?
7. Are only Floor 6 users affected, or other floors/cohorts also affected?

---

## METHODOLOGY APPLIED

### **Enterprise Troubleshooting Framework Used**

1. **Scope Analysis:** Multiple users → Systemic cause (not user-specific)
2. **Timeline Analysis:** Issue manifests Monday after Friday deployment and weekend → Root cause likely from migration or Friday event
3. **Cohort Analysis:** All Floor 6 affected similarly → Suggests shared infrastructure/policy/network, not individual variation
4. **Prioritization:** Authentication > Productivity; Multiple users > Single user; Immediate impact > Latent issues
5. **Occam's Razor:** Simplest explanation first (one policy, one rule, one network issue) before complex multi-factor causes
6. **Evidence Hierarchy:** Positive evidence (logs show failure) > Absence of evidence; Objective tests (uninstall) > Assumptions
7. **Rapid Validation:** 5-minute checks to narrow hypothesis before deep dives
8. **Parallel Investigation:** Check multiple hypotheses simultaneously to save time

---

**Prepared by:** DWP Service Desk Engineer  
**Date:** 2026-08-14  
**Classification:** TECHNICAL ANALYSIS  
**Next Review:** After initial evidence collection (within 30 minutes)  
**Escalation:** To Infrastructure/Intune team if not resolved within first 15 minutes of triage

