# INCIDENT TRIAGE REPORT
## HIGH: Desktop Profile Corruption – Missing Shortcuts & Desktop Settings
**Date:** 2026-08-14 | **Time Reported:** 09:14 | **Location:** Floor 6 (Legal)  
**Reported By:** IT Operations Lead (via user report) | **Affected Users:** 1+ (escalating)  
**Status:** ACTIVE INVESTIGATION | **Severity:** HIGH | **Priority:** P2

---

## INCIDENT BREAKDOWN

### Summary
At least one user on Floor 6 reported that **desktop shortcuts and customized desktop settings have vanished** after login. This suggests **user profile corruption or misconfiguration** related to the recent Windows 11 migration and/or Intune enrollment.

### Why This is a Separate Incident
- **Scope:** This is a **post-login profile/configuration issue**, not an authentication problem
- **Technical Root Cause:** Distinct from login failures (users CAN log in) and from data access issues (not a security/permissions problem)
- **Investigation Path:** Focuses on user profile loading, group policy, Windows 11 default profiles, Intune configuration, and document app configuration
- **Business Impact:** Medium—users can work but with degraded productivity; manually re-creating shortcuts and desktop layout is time-consuming
- **Containment Strategy:** Independent from the other two incidents; can be addressed in parallel or after authentication/security issues are resolved

### Severity Context
This is the **LEAST CRITICAL** of the three incidents because:
1. **Not Blocking:** Users CAN log in and access systems
2. **Not Security:** No confidentiality, integrity, or availability risk
3. **Productivity Loss:** Moderate (re-creating shortcuts, desktop layout) rather than complete (no work)
4. **Reversible:** Desktop settings are easily restored with user control and without major data risk
5. **Likely Cause:** Configuration issue (not random failure) related to known changes (migration, app deployment)

---

## PRIORITY ASSESSMENT

| Factor | Assessment |
|--------|------------|
| **Severity** | **HIGH** – Degrades user productivity; likely affects multiple users |
| **Business Impact** | **MEDIUM** – Users can work but with manual workarounds; reduces efficiency |
| **Number of Users Affected** | 1 confirmed, likely many more (common symptom post-migration) |
| **Security Risk** | **LOW** – No security or data exposure concern |
| **Operational Risk** | **MEDIUM** – Points to possible post-migration validation failure |
| **Urgency** | **DEFERRED (after P1 incidents resolved)** – Can proceed parallel but not blocking |
| **Time Sensitivity** | Low – No time-critical business impact |

**Recommended Action Level:** Investigate in parallel with P1 incidents; escalate to Desktop/Imaging team if affecting many users.

---

## FACTS vs ASSUMPTIONS vs UNKNOWNS

### VERIFIED FACTS
1. At least one user on Floor 6 is missing desktop shortcuts
2. The user recently underwent Windows 11 migration and Intune enrollment (last week)
3. A new document management application was deployed Friday afternoon
4. This is being reported at the same time as login/Copilot issues (Monday morning)
5. The same floor (Floor 6, Legal) is reporting all three issues

### REASONABLE ASSUMPTIONS
1. **Assumption:** Desktop shortcuts were present before the weekend or Windows 11 migration
   - **Confidence:** HIGH – User would have had shortcuts from previous Windows 10 setup

2. **Assumption:** Multiple users may have the same problem (typical of profile/policy issues)
   - **Confidence:** HIGH – Desktop and profile corruption usually affects cohorts, not individuals

3. **Assumption:** This could be related to Windows 11 profile migration or new policy application
   - **Confidence:** MEDIUM–HIGH – Common post-migration symptom

4. **Assumption:** The new document management app or Intune policy may have reset user profiles
   - **Confidence:** MEDIUM – App installations or policy updates can trigger profile resets

### UNKNOWNS (CRITICAL TO DETERMINE)

1. **How many users are affected by missing shortcuts?**
   - Just one? A few? All of Floor 6?
   - WHERE TO CHECK: Direct outreach to Floor 6 helpdesk queue; ask for reports of "missing shortcuts" or "empty desktop"

2. **Which specific shortcuts are missing?**
   - Application shortcuts (Outlook, Teams, Word)?
   - Folder shortcuts (Documents, Downloads, file shares)?
   - Custom shortcuts created by users?
   - WHERE TO CHECK: Ask affected user; check desktop comparison (before/after if screenshots exist)

3. **When did shortcuts disappear?**
   - After first login on Friday (day of app deployment)?
   - After login Monday morning?
   - Gradually over the weekend?
   - WHERE TO CHECK: Ask user directly; check Windows Event Viewer for profile load errors

4. **Is this a user profile corruption or a default profile issue?**
   - Did the user's profile fail to load and a new/default profile was created instead?
   - Did the user's profile load but shortcuts were not migrated from Windows 10 to Windows 11?
   - Is this a GPO issue where policy is hiding/removing shortcuts?
   - WHERE TO CHECK: Check user profile directory (`C:\Users\[username]`); check desktop folder for actual .lnk files

5. **Are other user profile customizations missing (besides shortcuts)?**
   - Wallpaper/theme customization?
   - Saved credentials (cached passwords)?
   - User-installed applications?
   - Taskbar customization?
   - WHERE TO CHECK: Interview user about other missing settings

6. **Is the document management app responsible?**
   - Did the app installation reset profiles?
   - Did the app delete/rename shortcuts on purpose?
   - WHERE TO CHECK: App installation log, app settings/configuration

7. **Is this related to Intune policy or Group Policy?**
   - Did a new GPO remove or hide desktop shortcuts?
   - Did an Intune policy override user desktop settings?
   - WHERE TO CHECK: Intune policy report, Group Policy audit log on affected machines

---

## FIRST 30-MINUTE TRIAGE PLAN

### **MINUTE 0–5: DISCOVERY & SCOPE ASSESSMENT**
**Goal:** Determine affected user count; establish whether this is widespread or isolated

- [ ] **Contact Floor 6 / Helpdesk Queue**
  - "Are other users reporting missing desktop shortcuts or vanished desktop settings?"
  - Capture count of reports
  - Ask: When did they first notice? (Friday? Monday morning?)
  - Assess: Is this escalating (more reports coming in)?

- [ ] **Interview Reported User**
  - "When did you last see the shortcuts on your desktop?"
  - "After which event did they disappear?" (Friday app deployment? Weekend? Monday login?)
  - "Which shortcuts are missing?" (List them)
  - "Are other desktop settings missing too?" (Wallpaper, taskbar, credentials?)
  - "Did you intentionally delete them, or did they just vanish?"

- [ ] **Determine if This is Post-Migration Expected Behavior**
  - Did the Windows 11 migration team expect some desktop customization loss?
  - Did migration documentation mention shortcuts might need to be re-created?
  - If YES: This may be expected; document as "post-migration user re-customization needed"
  - If NO: This is unexpected; needs investigation

### **MINUTE 5–15: NARROW ROOT CAUSE**
**Goal:** Determine whether shortcuts were lost due to profile issue, policy issue, or app issue

**Investigation Path A: If One User Reports Missing Shortcuts**
- [ ] **Check User's Profile Directory**
  - Remote into affected user's machine (if possible; may be blocked if they can't log in)
  - Navigate to `C:\Users\[username]\Desktop\`
  - Are there .lnk files? (hidden files?)
  - Compare to known shortcut locations: `C:\Users\Public\Desktop\`, Start Menu folder
  
- [ ] **Check Windows Event Viewer (on affected machine)**
  - System log: Any profile-related errors during login?
  - Application log: Any issues reported by Windows Shell, File Explorer, or Intune agent?
  - Check for Event ID 1509 (user profile service), 1516 (profile loading errors)

- [ ] **Determine if This is a User Profile Corruption**
  - Ask: Can you log in successfully? (YES? → Profile loaded OK; shortcuts just missing)
  - Ask: Are you logged in using a default/temporary profile, or your own profile?
  - WHERE TO CHECK: User's profile path should be `C:\Users\[username]\`, not `C:\Users\[username].000` (temp profile indicator)

**Investigation Path B: If Multiple Users Report Missing Shortcuts**
- [ ] **Escalate to Desktop/Imaging Team**
  - This is likely a post-migration issue affecting the cohort
  - Query: Did migration process restore all shortcuts?
  - Action: May need to re-apply base profile or re-run migration validation

- [ ] **Check Intune Policy Applied to Floor 6**
  - Did a policy deploy that hides or removes desktop shortcuts?
  - Query Intune console for Desktop Management / Default Devices / policies affecting Floor 6
  - Look for: "Remove shortcuts", "Lock desktop", "Disable user customization", etc.

- [ ] **Check Group Policy Applied Post-Migration**
  - Query domain controller for any new GPOs applied to Floor 6 OU
  - Look for: "Desktop settings", "Start Menu", "Taskbar" policies

**Investigation Path C: If New Document Management App is Suspected**
- [ ] **Check Application Installation Log**
  - Did the app installation delete or modify desktop shortcuts?
  - Did the app reset user profile or temp files?
  - ACTION: Query app vendor documentation or run diagnostic on app installer

### **MINUTE 15–30: CORRECTIVE ACTION & ESCALATION DECISION**
**Goal:** Determine if this is a quick-fix (user re-creates shortcuts) or requires admin remediation

**If Investigation Shows: Profile Corruption (Profile Failed to Load)**
- [ ] **ACTION: Attempt Profile Repair**
  - Remote into machine as admin
  - Delete the corrupted profile: `Remove-Item "C:\Users\[username]" -Recurse` (may need to back up user data first)
  - User logs out and back in (new clean profile is created)
  - User's data (Documents, Downloads) should roam via OneDrive or folder redirection
  - Shortcuts will be re-created from default profile or Start Menu

- [ ] **If Profile Repair Fails:**
  - Escalate to Desktop Support for deeper investigation
  - May require imaging or manual restoration from backup

**If Investigation Shows: Post-Migration Expected Loss**
- [ ] **ACTION: User Self-Service Workaround**
  - Provide instructions for user to re-create shortcuts
  - Shortcuts can be quickly created by pinning applications to taskbar or Start Menu
  - Link user to shortcut templates or batch creation script (if available)
  - Provide ETA: "Most users re-created desktop in 5–10 minutes"

- [ ] **Document as Post-Migration Item**
  - Log ticket as "Post-migration shortcut restoration (expected)"
  - Update migration documentation for next cohort

**If Investigation Shows: Policy or App Removed Shortcuts**
- [ ] **ACTION: Policy Remediation**
  - If GPO or Intune policy is hiding shortcuts:
    - Modify or roll back the policy
    - Re-enable user desktop customization
    - Users log off and back on (shortcuts reappear)

- [ ] **ACTION: Application Remediation**
  - If app deleted shortcuts:
    - Contact app vendor
    - Prepare rollback plan or app configuration fix
    - Consider temporarily uninstalling app for Floor 6 until resolved

**If Investigation Shows: Widespread Issue (Many Users Affected)**
- [ ] **ESCALATE to Desktop/Imaging Team**
  - Prepare escalation summary:
    - Scope: X users affected
    - Cause: Profile corruption / Policy issue / App issue
    - Recommendation: Bulk profile repair / Policy rollback / App remediation
  - Request: ETA for resolution

---

## EVIDENCE REQUIRED (BEFORE CONFIRMING ROOT CAUSE)

### Evidence Set 1: Profile State (REQUIRED)
- **User Profile Directory Contents**
  - Path: `C:\Users\[username]\`
  - File: Desktop shortcut files (.lnk)
  - File: AppData\Roaming (user customizations)
  - Confirmation: Is this the user's profile or a temporary profile (.000)?

- **User Profile Service Event Logs**
  - Event Viewer → System log → Event ID 1509, 1516 (profile loading errors)
  - Timestamp of profile load attempts

- **Desktop Folder Contents**
  - List of actual files on desktop
  - Comparison to expected shortcuts (if known/documented)

### Evidence Set 2: Policy Configuration (REQUIRED)
- **Intune Policies Applied to Floor 6 / User**
  - Export of all policies assigned to affected user or device
  - Check for "Desktop", "Shortcuts", "Start Menu" related policies

- **Group Policy Audit Trail**
  - Domain controller: Any new GPOs applied to Legal department OU
  - Timestamp and content of policy changes

- **Group Policy Results (on affected machine)**
  - `gpresult /h report.html` (generate Group Policy results report)
  - Check applied policies for desktop/shortcut restrictions

### Evidence Set 3: Application Logs (REQUIRED)
- **Document Management App Installation Log**
  - Timestamp of Friday deployment
  - Did app install touch user profiles or desktop?
  - Any known issues with user profile handling?

### Evidence Set 4: Windows 11 Migration Validation (CONDITIONAL)
- **Migration Report**
  - Were desktop shortcuts migrated from Windows 10?
  - Did migration account for user customizations?
  - Known issues in post-migration validation?

- **Post-Migration Checklist**
  - Was a desktop/profile validation step included?
  - Were shortcuts expected to be restored or recreated?

---

## SYSTEMS & LOGS TO CHECK

| System | Log/Data Location | What to Look For | Priority |
|--------|------------------|-----------------|----------|
| **User's Machine** | `C:\Users\[username]\Desktop\` | Desktop shortcut files (.lnk) | IMMEDIATE |
| **Windows Event Log** | System → Event ID 1509, 1516 | Profile loading failures | IMMEDIATE |
| **Intune Console** | Policies assigned to user/device | Desktop/shortcut restrictions | HIGH |
| **Group Policy** | GPO audit log (DC), gpresult.html | Applied policies affecting desktop | HIGH |
| **Document Mgmt App** | Installation log, app configuration | Profile/shortcut modification | MEDIUM |
| **Windows 11 Migration** | Migration report, validation logs | Shortcut restoration process | MEDIUM |
| **Roaming Profiles** | If enabled: network share | User profile backup, shortcut history | MEDIUM |
| **Start Menu** | `C:\Users\[username]\AppData\Roaming\Microsoft\Windows\Start Menu` | Start Menu shortcuts (may be backed up) | LOW |

---

## INVESTIGATION APPROACH

### Step 1: Determine Scope (Minute 0–5)
**Why:** If one user, troubleshoot individually; if many, likely cohort/policy issue
```
Action:
1. Poll helpdesk: "How many Floor 6 users have reported missing shortcuts?"
2. Get exact count or percentage
3. If >5 users: Escalate to Desktop/Imaging team (policy/migration issue likely)
4. If 1–2 users: Troubleshoot as isolated profile issue
```

### Step 2: Capture Exact Shortcut Loss (Minute 5–10)
**Why:** Understand scope of impact (all shortcuts? Some? Which ones?)
```
Action:
1. Interview affected user:
   → "Which shortcuts did you have before?" (list them)
   → "Which are missing now?" (list them)
   → "Do you see a Desktop folder at all?" (empty? Just some shortcuts?)
   → "Are other customizations gone?" (wallpaper, theme, taskbar?)

2. Remote into machine and check:
   → C:\Users\[username]\Desktop\ directory (any .lnk files?)
   → C:\ProgramData\Microsoft\Windows\Start Menu\ (shortcut backup location)
   → Recycle Bin (were they deleted? still recoverable?)
```

### Step 3: Determine Root Cause (Minute 10–20)
**Why:** Directs remediation strategy
```
Action:
1. Test Hypothesis A: Profile Corruption
   → Check Event Viewer for profile loading errors
   → Confirm user is in their own profile (not temp .000 profile)
   → If corrupted: Consider profile rebuild

2. Test Hypothesis B: Policy Removed Shortcuts
   → Run gpresult /h on affected machine
   → Check for policies restricting desktop customization
   → Query Intune for desktop/shortcut-related policies

3. Test Hypothesis C: Post-Migration Expected Loss
   → Check migration documentation
   → Was shortcut restoration part of migration process?
   → If expected: User re-creates shortcuts (quick workaround)

4. Test Hypothesis D: App Deleted Shortcuts
   → Check document management app installation log
   → Check if app has profile reset/reset settings option
   → Test: Uninstall app; check if shortcuts reappear
```

### Step 4: Implement Corrective Action (Minute 20–30)
**Why:** Restore user productivity quickly
```
Action:
1. If Isolated Profile Corruption:
   → Attempt profile rebuild (delete and recreate)
   → Restore shortcuts from default profile
   → Test: User logs in, shortcuts present

2. If Policy Issue:
   → Modify or roll back policy
   → Reapply policy to desktop
   → Test: User logs in, shortcuts present

3. If Post-Migration Expected:
   → Provide user with shortcut recovery tool or manual instructions
   → Estimate time to recovery: 5–10 minutes user effort

4. If App Issue:
   → Escalate to app vendor
   → Consider temporary app removal
   → Prepare rollback plan
```

---

## RISK ASSESSMENT

### Severity Breakdown

| Risk Category | Current Assessment | Likelihood | Impact |
|---|---|---|---|
| **User Productivity** | **MEDIUM** | High | Users must manually recreate desktop customizations; 5–15 min per user |
| **Data Loss** | **LOW** | Low | Shortcuts are just links; user data (files, etc.) not at risk |
| **System Integrity** | **LOW** | Low | No indication of system corruption or malware |
| **Security** | **LOW** | Low | No security or data exposure concern |
| **Operational** | **MEDIUM** | Medium | Points to possible post-migration validation gap; if affecting many users, indicates process failure |

### Escalation Triggers
- If more than 5 users affected → Escalate to Desktop/Imaging (cohort issue)
- If user cannot access critical applications due to missing shortcuts → Provide workarounds (Start Menu, taskbar)
- If shortcuts mysteriously reappear and disappear → Indicate unstable profile or policy conflict

---

## IMMEDIATE CONTAINMENT ACTIONS

### **TIER 1: Quick Assessment (0–5 minutes)**

**Action 1.1: Establish Scope**
- [ ] Poll Floor 6 helpdesk for number of users reporting missing shortcuts
- [ ] Determine: Isolated issue or widespread?

**Action 1.2: Communicate with Affected User**
- [ ] "We're aware of missing desktop shortcuts on Floor 6. We're investigating. In the meantime, you can access applications from the Start Menu or taskbar shortcuts."
- [ ] "We expect to have this resolved or provide a workaround within 30 minutes."

### **TIER 2: Isolated Issue Remediation (5–20 minutes)**

**Action 2.1: If One User Affected**
```powershell
# Check if user profile is corrupted (run on affected machine as admin)
Get-ChildItem "C:\Users" | Where-Object {$_.Name -like "*\.000"} | Select-Object Name
# If result shows [username].000, user is in temp profile — profile is corrupted

# If corrupted, consider profile rebuild:
# 1. Backup user data from C:\Users\[username]\
# 2. Delete profile: Remove-Item "C:\Users\[username]" -Recurse -Force
# 3. User logs off and back on (new clean profile created)
# 4. Roaming data restored (OneDrive, folder redirection)
# 5. Shortcuts regenerated from default profile
```

**Action 2.2: Provide Quick Workaround**
- [ ] "Your applications are available in the Start Menu. Press [Windows] key and search for the app name."
- [ ] "If you need desktop shortcuts, you can right-click and create new shortcuts, or use this guide: [link to shortcut creation steps]"
- [ ] Estimated user effort: 5–10 minutes

### **TIER 3: Widespread Issue Escalation (10–20 minutes)**

**Action 3.1: If Multiple Users Affected**
- [ ] Escalate to Desktop/Imaging team with summary:
  - Number of users affected: X
  - Timing: Missing after Friday app deployment? Monday login?
  - Scope: All of Floor 6 or subset?
  - Likely cause: Post-migration issue / Policy issue / App issue

**Action 3.2: Temporary Workaround for Many Users**
- [ ] Provide all affected users with:
  - Instructions for pinning applications to taskbar (quick access)
  - Instructions for accessing applications from Start Menu
  - Batch script (if available) to create common shortcuts
  - ETA for permanent fix: "By end of day" or "By tomorrow morning"

**Action 3.3: Investigate Root Cause in Parallel**
- [ ] Check Intune policies for desktop restrictions
- [ ] Check Group Policy changes
- [ ] Check document management app installation effects
- [ ] Query Windows 11 migration team: Was shortcut restoration validated?

### **TIER 4: Policy/App Issue Remediation (15–25 minutes)**

**If Policy is Culprit:**
- [ ] Identify the specific policy restricting shortcuts
- [ ] Modify policy or roll back
- [ ] Re-apply to affected users/devices
- [ ] Users log off and back on (shortcuts reappear)

**If App is Culprit:**
- [ ] Quarantine the app (uninstall or disable for Floor 6)
- [ ] Contact app vendor: "App deployment Friday appears to have deleted user desktop shortcuts. Can you advise?"
- [ ] Prepare rollback or remediation plan
- [ ] Consider re-deploying app after fix is confirmed

### **TIER 5: Long-Term Fix (Post-30 minutes)**

**Action 5.1: Profile Rebuild at Scale** (if needed)
- [ ] For affected users:
  - Backup user data
  - Delete corrupted profiles
  - Re-provision new profiles
  - Restore roaming data (OneDrive, folder redirects)

**Action 5.2: Preventive Measures**
- [ ] Post-migration: Add desktop/shortcut validation step
- [ ] Before deploying apps: Test for profile/shortcut impact
- [ ] Document expected post-migration behavior (if shortcuts are intentionally removed)
- [ ] Provide users with shortcut recovery tool or template

---

## DECISION TREE

```
START: Floor 6 Desktop Profile Corruption Investigation (09:14)
│
├─→ Q1: How many users are affected by missing shortcuts?
│   │
│   ├─→ A: 1–2 users
│   │   └─→ GOTO PATH A (Isolated Profile Issue)
│   │
│   ├─→ A: 3–10 users
│   │   └─→ GOTO PATH B (Cohort Issue – Likely Policy or Migration)
│   │
│   └─→ A: 11+ users (majority of floor)
│       └─→ GOTO PATH C (Systemic Issue – Urgent Escalation)
│
├─→ PATH A: Isolated User Issue (1–2 users)
│   │
│   ├─→ Q: Is user's profile corrupted (temp .000 profile)?
│   │   │
│   │   ├─→ YES
│   │   │   ├─→ ACTION: Profile rebuild
│   │   │   ├─→ Backup data → Delete profile → User re-logs in → Test
│   │   │   └─→ OUTCOME: Shortcuts restored (from default profile)
│   │   │
│   │   └─→ NO (user in normal profile)
│   │       └─→ Q: Are shortcuts missing from disk (C:\Users\[username]\Desktop\)?
│   │           │
│   │           ├─→ YES (shortcuts deleted)
│   │           │   ├─→ ACTION: Check Recycle Bin (recover shortcuts?)
│   │           │   ├─→ ACTION: Check Intune/GPO for deletion policy
│   │           │   └─→ ACTION: If app-related, escalate to vendor
│   │           │
│   │           └─→ NO (shortcuts should be there but hidden?)
│   │               ├─→ ACTION: Check GPO for "hide shortcuts" policy
│   │               ├─→ ACTION: Modify policy to re-enable
│   │               └─→ ACTION: User logs off/on to refresh
│   │
│   └─→ OUTCOME: Isolated issue resolved; user back to normal in <15 min
│
├─→ PATH B: Cohort Issue (3–10 users)
│   │
│   ├─→ ACTION: Escalate to Desktop/Imaging team
│   │   └─→ "Multiple Floor 6 users missing desktop shortcuts post-migration/post-app-deployment. Requesting investigation."
│   │
│   ├─→ Q: Is this expected post-migration behavior?
│   │   │
│   │   ├─→ YES
│   │   │   ├─→ ACTION: Provide users with shortcut recovery tool/guide
│   │   │   ├─→ ACTION: Update migration documentation
│   │   │   └─→ OUTCOME: User self-service recovery (5–10 min per user)
│   │   │
│   │   └─→ NO (unexpected)
│   │       └─→ Q: Root cause?
│   │           ├─→ A: Policy restricting shortcuts
│   │           │   ├─→ ACTION: Modify/roll back policy
│   │           │   └─→ OUTCOME: Shortcuts reappear after policy refresh
│   │           │
│   │           ├─→ A: App deleted shortcuts
│   │           │   ├─→ ACTION: Escalate to app vendor
│   │           │   └─→ ACTION: Prepare remediation or rollback
│   │           │
│   │           └─→ A: Profile migration incomplete
│   │               ├─→ ACTION: Bulk profile rebuild
│   │               └─→ ACTION: Coordinate with Imaging team
│   │
│   └─→ OUTCOME: Cohort issue identified and escalated; remediation underway
│
├─→ PATH C: Systemic Issue (11+ users / Entire Floor)
│   │
│   ├─→ ACTION: IMMEDIATE escalation to Desktop/Imaging + CIO
│   │   └─→ "Entire Floor 6 appears to have lost desktop shortcuts. Suggests post-migration issue or system-wide policy change."
│   │
│   ├─→ ACTION: Assess business impact
│   │   ├─→ Can users access applications? (Yes, via Start Menu or taskbar)
│   │   ├─→ Is this causing work stoppage? (No — workarounds available)
│   │   └─→ Estimated time to fix: 1–4 hours (policy rollback or profile rebuild at scale)
│   │
│   ├─→ Q: Root cause assessment
│   │   │
│   │   ├─→ A: Windows 11 migration process (shortcuts not migrated)
│   │   │   ├─→ ACTION: Confirm with migration team
│   │   │   ├─→ ACTION: Prepare bulk shortcut restoration (script)
│   │   │   └─→ OUTCOME: Can restore via script; 30–60 minutes at scale
│   │   │
│   │   ├─→ A: Intune policy (enforced after migration)
│   │   │   ├─→ ACTION: Identify the policy
│   │   │   ├─→ ACTION: Rollback or modify
│   │   │   └─→ OUTCOME: Shortcuts reappear; 5–15 minutes per user
│   │   │
│   │   └─→ A: Document management app deployment
│   │   │   ├─→ ACTION: Quarantine app
│   │   │   ├─→ ACTION: Contact vendor for emergency fix
│   │   │   └─→ OUTCOME: Uninstall app, restore from backup; 30–45 minutes
│   │
│   ├─→ ACTION: Provide business continuity workaround
│   │   ├─→ Announce: "All applications accessible via Start Menu"
│   │   ├─→ Provide: Batch shortcut creation script or tool
│   │   └─→ ETA: "Full resolution by EOD"
│   │
│   └─→ OUTCOME: Systemic issue identified; escalated; workaround active; permanent fix in progress
│
└─→ END: Continue investigation; implement fix; validate resolution
```

---

## EXECUTIVE UPDATE FOR LEADERSHIP
*(Non-Technical, Suitable for Partners & Senior Leadership – Target delivery: After P1 Incidents Resolved)*

---

### **Status Update: Desktop Profile Issue – Floor 6 (LOW PRIORITY)**

**Situation:** Some staff members on Floor 6 are reporting missing desktop shortcuts and customized settings after the recent Windows 11 upgrade. This is a **low-priority issue** because all work can continue — applications are still accessible through the Start Menu.

**What We Know:**
- Desktop shortcuts and customizations have disappeared following the Windows 11 migration
- This is a common post-migration issue that can be quickly resolved
- All applications and files remain accessible; no data loss

**What We're Doing:**
- Investigating whether this is expected post-migration behavior or a configuration issue
- Providing staff with quick workarounds (Start Menu access, taskbar shortcuts)
- Coordinating with our Desktop Support team for remediation

**Impact:**
- Staff can continue working without delay
- Desktop customization will take 5–15 minutes per user to restore once root cause is identified
- No security or data concerns

**Resolution Timeline:**
- **Diagnosis:** Next 1–2 hours (in parallel with P1 incidents)
- **Remediation:** By end of business day
- **Options:**
  - If post-migration expected: User re-customization (5–10 min each) OR
  - If configuration error: Automated restoration script (15–30 min for all users)

---

**Prepared by:** Service Desk Lead  
**Classification:** INTERNAL  
**Next Review:** EOD, 2026-08-14

---

## OPEN ITEMS / NEXT STEPS

- [ ] Confirm exact number of users affected with missing shortcuts
- [ ] Determine when shortcuts disappeared (Friday? Monday morning? Timeline)
- [ ] Check if user profiles are corrupted (temp .000 profiles?)
- [ ] Audit Intune policies for any desktop/shortcut restrictions
- [ ] Review document management app installation effects on user profiles
- [ ] Verify Windows 11 migration post-validation process
- [ ] Determine if this is expected post-migration behavior or configuration error
- [ ] Implement remediation (profile rebuild, policy rollback, or user self-service)
- [ ] Validate that shortcuts are restored
- [ ] Document post-migration shortcut handling for future cohorts
