# INCIDENT TRIAGE REPORT
## CRITICAL: Copilot Unauthorized Data Access – Client Matter Disclosure
**Date:** 2026-08-14 | **Time Reported:** 09:14 | **Location:** Floor 6 (Legal)  
**Reported By:** IT Operations Lead (via Paralegal user report) | **Affected User:** 1 (confirmed), likely more  
**Status:** ACTIVE INVESTIGATION | **Severity:** CRITICAL | **Priority:** P1-SECURITY

---

## INCIDENT BREAKDOWN

### Summary
A paralegal on Floor 6 reported that **Copilot displayed confidential client matter information that the user explicitly states they have never had access to**. This represents a potential **data exposure / privilege escalation incident** with significant legal, compliance, and contractual implications.

### Why This is a Separate Incident (Not a General Login Issue)
- **Scope:** This is a **data access control problem**, not an authentication/connectivity problem
- **Technical Root Cause:** Independent from login failures (users may not be able to log in, but someone COULD access Copilot and see privileged data)
- **Security Classification:** **POTENTIAL BREACH / UNAUTHORIZED DISCLOSURE** – requires immediate isolation and evidence preservation
- **Investigation Path:** Focuses on data access permissions, Copilot configuration, document management app integration, and user profile/role settings
- **Regulatory Risk:** High – legal work involves confidential client data; unauthorized access may trigger breach notification, compliance reporting, and contractual obligations
- **Containment Strategy:** Independent from login/shortcut issues—may require immediate isolation of Copilot, document repository, and affected user accounts

### Severity Context
This is the **MOST CRITICAL** of the three incidents because:
1. **Legal/Compliance Risk:** Unauthorized access to client data in a legal firm could trigger regulatory notification, bar association complaints, and civil liability
2. **Contractual Risk:** Client contracts likely require data protection assurances; breach could result in contract violations and damages
3. **Trust Impact:** If confirmed, indicates a systemic failure in data governance or access control
4. **Evidence Risk:** Every minute of delay increases risk of evidence tampering, data exfiltration, or log overwrite

---

## PRIORITY ASSESSMENT

| Factor | Assessment |
|--------|------------|
| **Severity** | **CRITICAL** – Potential unauthorized data access / breach |
| **Business Impact** | **CRITICAL** – Reputation, compliance, contractual liability |
| **Number of Users Affected** | 1 confirmed (paralegal), unknown if others affected |
| **Security Risk** | **CRITICAL** – Indicates possible privilege escalation, data exposure, or configuration error |
| **Regulatory/Legal Risk** | **CRITICAL** – Potential breach notification requirement; bar association obligation; client notification |
| **Urgency** | **IMMEDIATE (0–5 min)** – Requires emergency response; potential evidence preservation |
| **Time Sensitivity** | **Critical** – Every minute data remains accessible increases exposure; logs may be overwritten |

**Recommended Action Level:** EMERGENCY ESCALATION to Security Team + Legal + Compliance + CIO (now). Consider incident commander activation.

---

## FACTS vs ASSUMPTIONS vs UNKNOWNS

### VERIFIED FACTS
1. One paralegal on Floor 6 reported seeing client matter information in Copilot
2. The paralegal explicitly states they have never been assigned to work on that client matter
3. This suggests an access control failure (paralegal should not have view/read access to that matter)
4. The incident was reported during Monday morning's incident wave (09:14), not an isolated incident reported separately
5. Copilot was recently enabled/deployed as part of Microsoft 365 rollout to this cohort
6. A new document management application was deployed Friday afternoon to Floor 6
7. Copilot may be integrated with the document management system (acting as an AI search/summarization layer)

### REASONABLE ASSUMPTIONS
1. **Assumption:** This is not user confusion or misreporting
   - **Confidence:** MEDIUM – Paralegal is a legal professional, likely understands matter assignment; but verify by asking specific questions (e.g., "How do you know this is a client matter you shouldn't see?")

2. **Assumption:** Copilot displayed information from a data source (document repository, email, SharePoint, etc.)
   - **Confidence:** HIGH – Copilot does not generate confidential legal information; it must source it from somewhere

3. **Assumption:** If one user saw unauthorized data, others may have as well
   - **Confidence:** MEDIUM–HIGH – If the access control failure is systemic (wrong permissions applied to many users), it's likely others are affected but haven't reported yet

4. **Assumption:** The document management application deployment Friday may have reset/misconfigured access controls
   - **Confidence:** MEDIUM – New apps sometimes reset or override permissions during installation; timing is suspicious

### UNKNOWNS (CRITICAL TO DETERMINE FIRST)

1. **What exactly did the paralegal see, and how did they identify it as client matter?**
   - Did they see client name? Matter number? Confidential content?
   - Is it possible they're confusing this with a matter they ARE assigned to?
   - WHERE TO CHECK: Ask the paralegal directly; preserve their device / Copilot chat history

2. **Which client matter was disclosed?**
   - Client name, matter ID, type of data (email, document, contract, strategy memo?)
   - When was this matter's information last accessed or modified?
   - WHERE TO CHECK: Case management system, document repository, audit log

3. **How is Copilot configured to access data?**
   - Is Copilot searching the document management system, SharePoint, email, or all of the above?
   - Does Copilot respect row-level security (RLS) or document-level access controls?
   - Is Copilot using the logged-in user's permissions, or a service account with broad access?
   - WHERE TO CHECK: Copilot configuration in Microsoft 365, document management app settings, data integration logs

4. **What access control permissions does this paralegal have?**
   - Which client matters are they assigned to in the case management system?
   - What SharePoint/document repository permissions do they have?
   - Was their access recently modified by the Windows 11 migration or Intune enrollment?
   - WHERE TO CHECK: Active Directory group membership, document repository permissions, case management system role assignments

5. **When did the access control failure occur?**
   - Did the paralegal see this information in Copilot on Friday (after app deployment)? This morning? Just now?
   - Was it a one-time glimpse or repeated access?
   - WHERE TO CHECK: Copilot chat history, audit logs, Copilot interaction logs

6. **Is this specific to Copilot, or can the user access the underlying data directly?**
   - Can the paralegal open the document repository and see the confidential client matter directly (without Copilot)?
   - Is Copilot amplifying an existing access control failure, or creating a new one?
   - WHERE TO CHECK: Have the paralegal attempt direct access (with oversight); check document repository permissions

7. **Are there other users affected?**
   - Have other staff members reported similar issues?
   - Can we proactively scan for unauthorized Copilot queries or data access?
   - WHERE TO CHECK: Copilot usage logs, helpdesk ticket queue, direct outreach to Floor 6 staff

8. **Is this related to the new document management app?**
   - Did the app's deployment enable Copilot integration without proper access control?
   - Did the app reset document-level permissions?
   - WHERE TO CHECK: App deployment logs, document repository permissions audit trail, app vendor documentation

---

## FIRST 30-MINUTE TRIAGE PLAN

### **MINUTE 0–3: EMERGENCY ISOLATION & EVIDENCE PRESERVATION**
**Goal:** Prevent further exposure; preserve evidence; establish incident command

- [ ] **IMMEDIATELY:** Do NOT touch affected user's machine (preserve logs and chat history)
  - Do NOT reboot or restart
  - Do NOT clear Copilot history
  - Do NOT modify document repository permissions yet

- [ ] **Page Security Team Lead + Chief Compliance Officer + General Counsel**
  - Notify: "Potential unauthorized data access incident in Legal department. Paralegal reports Copilot displayed confidential client matter they should not access. Investigating now. May require breach notification."
  - Request: Guidance on evidence preservation, legal hold, breach notification timeline

- [ ] **Notify CIO / Incident Commander**
  - Activate incident response protocol
  - Assign dedicated incident commander for coordination

- [ ] **ISOLATION DECISION POINT (Minute 2):**
  - Do we immediately disable Copilot for Floor 6?
  - Do we immediately disable the document management app?
  - **Decision:** Isolate suspected data sources; do not cut off all access (Legal department still needs to work)
  - **Action:** Take affected user's machine offline (preserve logs); disable Copilot access for Floor 6 temporarily

### **MINUTE 3–10: INITIAL FACT-FINDING & SCOPE ASSESSMENT**
**Goal:** Confirm incident validity; determine scope; identify affected data

**Initial Interview with Affected User (Paralegal):**
- [ ] **Do NOT confront or accusatory; frame as fact-finding**
  - "We received a report that you saw information in Copilot that you weren't expecting. Can you walk us through what happened?"
  - "When did this occur? (Friday? This morning? Just now?)"
  - "What exactly did you see? (Client name, matter ID, type of content?)"
  - "How do you know it's a matter you shouldn't have access to?"
  - "Can you describe where you were in Copilot when this appeared?"
  - "Did you share this information with anyone else?"

- [ ] **Preserve Interview Notes**
  - Document verbatim responses
  - Request permission to preserve Copilot chat history and browser history

**Parallel Investigation Track 1: Data Source Identification**
- [ ] Identify which case/matter the user saw
  - Look it up in the case management system
  - Confirm the paralegal is NOT assigned to this matter
  - Identify who IS assigned (legal team members, attorneys, authorized staff)

- [ ] Determine where that matter's information is stored
  - Document repository folder / SharePoint site
  - Email (attorney or staff mailboxes)
  - Case management system (matter record, attachments)
  - Backup/archive systems

**Parallel Investigation Track 2: Copilot Configuration & Access**
- [ ] Query Copilot configuration
  - Does Copilot have access to document repository? Email? SharePoint?
  - What service account or permissions does Copilot use to query data?
  - Is row-level security (RLS) enforced? Document-level access control?
  
- [ ] Check Copilot usage logs
  - When was this Copilot instance accessed by this user?
  - What queries were executed?
  - What documents/data were returned?

**Parallel Investigation Track 3: Document Management App**
- [ ] Identify the new app deployed Friday
  - Name, vendor, version
  - Does it integrate with Copilot?
  - What permissions did it request during installation?
  - Did it modify document repository access controls?

### **MINUTE 10–20: ROOT CAUSE HYPOTHESIS & EVIDENCE COLLECTION**
**Goal:** Form root cause hypothesis; collect evidence to confirm/refute

**Hypothesis Testing:**

**Hypothesis A: Document Permissions Were Reset by New App**
- [ ] Check document repository permission audit trail for Friday afternoon changes
  - Did the new app deployment modify folder permissions?
  - Were permissions set to overly permissive? (Everyone, Domain Users, Authenticated Users?)
  - ACTION: Export permission history for the matter's folder; compare before/after app deployment

**Hypothesis B: Copilot is Using a Service Account with Broad Access**
- [ ] Check Copilot's data connector configuration
  - Service account identity (if one is used)
  - Service account permissions in document repository
  - Does service account bypass document-level access control?
  - ACTION: Query Active Directory for service account group memberships; check document repository permissions

**Hypothesis C: User's Access Permissions Were Unexpectedly Modified**
- [ ] Check the paralegal's Active Directory and document repository permissions
  - Group memberships (current and history)
  - Did Windows 11 migration or Intune enrollment modify group membership?
  - Did the new app add the user to an overly permissive group?
  - ACTION: Compare user's group memberships before/after migration; check Intune policy for any group assignment changes

**Hypothesis D: Copilot Search Algorithm is Returning Results Beyond User's Permissions**
- [ ] Check Copilot's query logic and result filtering
  - Does Copilot apply row-level security when returning search results?
  - Is there a known issue with Copilot's document filtering?
  - ACTION: Test Copilot as the affected user; search for the same matter; observe if unauthorized results appear

**Evidence Collection:**
- [ ] **Export Copilot Chat History**
  - User ID, timestamps, exact queries, results returned
- [ ] **Export Document Repository Permissions**
  - Folder and document levels
  - Group and individual permissions
  - Permission change audit trail (last 48 hours minimum)
- [ ] **Export Service Account Permissions**
  - If Copilot uses a service account, identify it and export its permissions
- [ ] **Query Active Directory Group Membership Audit Log**
  - Changes to user's group membership (last 48 hours)
- [ ] **Retrieve Application Deployment Logs**
  - Document management app installation log
  - Any permission modifications, service accounts created, registry changes

### **MINUTE 20–30: IMMEDIATE CONTAINMENT & ESCALATION**
**Goal:** Prevent further unauthorized access; prepare for potential breach notification

**Containment Actions:**
- [ ] **Tier 1: Immediate Isolation**
  - [ ] Take affected user's machine offline (preserve evidence)
  - [ ] Disable Copilot access for all Floor 6 users (temporary precaution)
  - [ ] Disable or isolate the new document management app (if suspected)

- [ ] **Tier 2: Access Control Remediation**
  - [ ] Reset document repository permissions for the affected matter to documented access control list (ACL)
  - [ ] Verify no other users have unexpected access
  - [ ] Audit all matter folders for permission drift

- [ ] **Tier 3: Scope Assessment**
  - [ ] Search Copilot chat history for other users on Floor 6
  - [ ] Look for queries that returned documents outside their normal access
  - [ ] Identify any other potentially affected users

- [ ] **Tier 4: Breach Assessment & Notification Preparation**
  - [ ] Convene Security + Compliance + Legal team
  - [ ] Determine: Is this a breach? Did unauthorized data leave the system?
  - [ ] Prepare breach notification timeline and client notification (if required)

**Escalation Summary (Minute 28):**
- [ ] Prepare incident summary for incident commander:
  - Confirmed unauthorized access (YES/MAYBE/NO)
  - Scope (1 user, multiple users, multiple matters)
  - Data exposure (confidential client information confirmed)
  - Immediate containment (Copilot disabled, permissions reset, app isolated)
  - Next steps (full investigation, breach assessment, client notification planning)

---

## EVIDENCE REQUIRED (BEFORE CONFIRMING ROOT CAUSE & BREACH STATUS)

### Evidence Set 1: User Access History (REQUIRED – URGENT)
- **Copilot Chat History Export**
  - User ID, session timestamps, queries, results
  - File names and document titles returned
  - Any indication of data exfiltration (download, share, forward)

- **Document Repository Access Log**
  - User's document view/open events (last 48 hours)
  - Files accessed by this user
  - Timestamp of unauthorized access

- **Active Directory Group Membership History**
  - User's current and previous group memberships
  - Changes in last 48 hours, especially groups with matter access

### Evidence Set 2: Copilot Configuration & Integration (REQUIRED)
- **Copilot Data Connector Configuration**
  - Which systems does Copilot query? (SharePoint, document repo, email?)
  - Service account identity (if applicable)
  - Authentication method and permission model
  - Export of Copilot's recent queries and filtering logic

- **Copilot Audit Log**
  - All data sources queried by Copilot
  - Results returned (and to whom)
  - Any anomalies in result filtering

### Evidence Set 3: Document Permissions (REQUIRED)
- **Document Repository Permission Audit Trail**
  - Complete history of permissions for the confidential matter folder (last 48 hours minimum)
  - Permission changes by timestamp and admin identity
  - Current vs. baseline ACL

- **Current Permissions Export**
  - Folder-level and document-level permissions
  - User/group access
  - Inherited vs. explicit permissions

### Evidence Set 4: Application Deployment (REQUIRED)
- **Document Management App Deployment Log**
  - Vendor, version, deployment timestamp (Friday 2026-08-11)
  - Installation script, post-deployment tasks
  - Any permission modifications, registry changes, service accounts created
  - Vendor security advisories or known issues

- **Application Vendor Documentation**
  - Copilot integration points
  - Permission model and RLS implementation
  - Known security issues with Windows 11 or Intune

### Evidence Set 5: Broader Exposure Assessment (REQUIRED)
- **Copilot Usage Audit for All Floor 6 Users**
  - Chat history exports for all users
  - Queries and results (searching for patterns of unauthorized access)
  
- **Document Repository Permission Audit for All Matters**
  - Scan for any folders with overly permissive access
  - Identify any users with access they shouldn't have

---

## SYSTEMS & LOGS TO CHECK

| System | Log/Data Location | What to Look For | Priority |
|--------|------------------|-----------------|----------|
| **Copilot** | Microsoft 365 audit log, Copilot chat history export | Queries, results, user identity, timestamp | IMMEDIATE |
| **Document Repository** | Permission audit trail, access log | Who accessed what, when, permissions state | IMMEDIATE |
| **Active Directory** | Group membership history, audit log | User's group membership changes | IMMEDIATE |
| **Document Mgmt App** | Deployment log, installer, vendor KB | Permission changes, known issues, Copilot integration | IMMEDIATE |
| **SharePoint/OneDrive** | Access log, audit trail (if used by Copilot) | User access, document view events | HIGH |
| **Case Management System** | Matter assignment, user roles, access log | Is user assigned to this matter? Who is? | HIGH |
| **Email Archive** | If Copilot searches email, audit trail | User access to matter-related emails | MEDIUM |
| **Windows Event Viewer** | Application log (on affected machine, if accessible) | Application errors, permission-related events | MEDIUM |
| **Intune** | Policy delivery log, device enrollment status | Were any policies applied that modify permissions? | MEDIUM |
| **Microsoft 365 Audit Log** | Activity log, report, export | Broader view of permission changes, app integrations | HIGH |

---

## INVESTIGATION APPROACH

### Step 1: Validate the Report (Minute 0–5)
**Why:** Confirm this is a real access control failure, not user confusion or misunderstanding
```
Action:
1. Interview the paralegal directly
   → What exactly did you see?
   → How do you know it's confidential?
   → When did you see it?
   → Did anyone else see it?

2. Preserve Copilot chat history immediately (do not let it expire/auto-delete)

3. Look up the matter in case management system
   → Confirm the paralegal is NOT assigned
   → Identify who IS assigned
```

### Step 2: Identify the Data Source (Minute 5–10)
**Why:** Understand which system failed to enforce access control
```
Action:
1. Determine where the matter's data is stored
   → Document repository? SharePoint? Email? All?
   
2. Check that location's permission audit trail
   → Are permissions what they should be?
   → Did permissions change recently? (Friday afternoon?)
   
3. Determine Copilot's integration with that location
   → Does Copilot query it?
   → Using what account? What permissions?
```

### Step 3: Trace the Access Control Failure (Minute 10–20)
**Why:** Pinpoint the exact component that allowed unauthorized access
```
Action:
1. Hypothesis: Document Permissions Wrong
   → Export permission history
   → Compare Friday before-app vs. after-app
   → ACTION: If app reset permissions, contact vendor

2. Hypothesis: Service Account Over-Privileged
   → Identify Copilot's service account
   → Export its permissions
   → Compare to documented baseline

3. Hypothesis: User Permissions Accidentally Granted
   → Check user's group membership changes
   → Correlate with Intune policy changes or migration
   → Check if app added user to wrong group

4. Hypothesis: Copilot Filtering Logic Broken
   → Test Copilot as this user
   → Search for the same matter
   → Observe whether unauthorized results appear
```

### Step 4: Assess Scope & Exposure (Minute 15–25)
**Why:** Determine if one user's problem or systemic issue; identify other affected parties
```
Action:
1. Scan all Floor 6 users' Copilot chat history
   → Are others seeing unauthorized data?
   → Pattern of unauthorized queries?

2. Audit all matter folders
   → Check permissions for ALL matters (not just the one reported)
   → Are other matters also over-permissioned?

3. Interview IT Operations Lead
   → Was this report isolated, or part of a pattern?
   → Have other users complained?
```

### Step 5: Escalate & Prepare Breach Assessment (Minute 25–30)
**Why:** Trigger legal/compliance escalation; prepare for potential breach notification
```
Action:
1. Escalate to:
   → Chief Compliance Officer
   → General Counsel
   → CIO / Incident Commander
   → Security Lead

2. Prepare incident summary:
   → What data was exposed?
   → To whom? For how long?
   → Was it exfiltrated (downloaded, shared, forwarded)?
   → Is this a reportable breach?

3. Begin breach notification preparation:
   → Client notification template
   → Regulatory notification (if required)
   → Timeline (if required by law)
```

---

## RISK ASSESSMENT

### Severity Breakdown

| Risk Category | Current Assessment | Likelihood | Impact | Notes |
|---|---|---|---|---|
| **Data Exposure** | **CRITICAL** | High | Confidential client information may be visible to unauthorized user | If true, violates attorney-client privilege, bar rules, and contractual obligations |
| **Breach** | **HIGH** | Medium–High | Unauthorized access may constitute a reportable breach | Depends on data sensitivity and disclosure timeline |
| **Privilege Violation** | **CRITICAL** | High | Unauthorized access to privileged attorney-client communications | Bar disciplinary risk; malpractice liability |
| **Compliance/Regulatory** | **CRITICAL** | High | Potential notification requirement (GDPR, state breach laws, contract terms) | Each hour of delay increases liability |
| **Contractual Liability** | **CRITICAL** | High | Client contracts likely require data protection assurances | Breach could trigger contract termination, damages |
| **Reputational** | **CRITICAL** | High | If public, serious damage to firm's reputation | Legal market highly reputation-sensitive |
| **Operational** | **HIGH** | Medium | Other users may have discovered similar access; unknown breadth | Need rapid audit of all users and permissions |

### Indicators of Potential Breach
1. **Confirmed:** Unauthorized user saw confidential information
2. **Suspected:** Copilot displayed matter information not accessible to user's role
3. **Suspected:** New app deployment may have reset access controls
4. **Unknown:** Was information downloaded, shared, or forwarded?
5. **Unknown:** How many other users are affected?

### Escalation Triggers
- **IMMEDIATE:** Confirmed unauthorized data access (already triggered)
- **IMMEDIATE:** If multiple users affected
- **HIGH:** If data left the system (download, share, forward)
- **HIGH:** If matter involves sensitive client (public company, governmental, media)
- **CRITICAL:** If client contacts firm reporting privacy concerns

---

## IMMEDIATE CONTAINMENT ACTIONS

### **TIER 1: Emergency Isolation (0–5 minutes)**

**Action 1.1: Preserve Evidence**
- [ ] **DO NOT REBOOT** affected user's machine (preserve Copilot chat history and browser cache)
- [ ] **Export Copilot chat history** immediately before auto-delete or user clearing
- [ ] **Screenshot** the exact data/matter displayed in Copilot (to document what was exposed)
- [ ] **Document the paralegal's statement** verbatim

**Action 1.2: Disable Access Vectors**
- [ ] **Disable Copilot access** for affected user immediately
- [ ] **Disable Copilot access** for entire Floor 6 (precautionary, while investigating)
- [ ] **Take affected user's machine offline** (physically or via remote lock)
- [ ] **Do NOT delete** user's chat history, browser cache, or local files

**Action 1.3: Notify Leadership Immediately**
```
Notification Template:
"INCIDENT: Potential unauthorized data access detected in Legal department.
One paralegal reported Copilot displaying confidential client matter information 
they should not have access to. Immediate containment in place (Copilot disabled, 
user isolated). Investigating now. Breach assessment underway. Chief Counsel and 
Compliance have been paged. Updates every 15 minutes."
```

### **TIER 2: Access Control Remediation (5–15 minutes)**

**Action 2.1: Reset Document Permissions to Baseline**
- [ ] Identify the matter that was exposed
- [ ] Retrieve documented access control list (ACL) for that matter
- [ ] Reset folder and document-level permissions to match baseline
- [ ] Add audit trail note: "Permissions reset after unauthorized access incident"

**Action 2.2: Audit & Reset New App's Permissions**
- [ ] If document management app deployment is suspected:
  - Identify the app's installation account and any service accounts created
  - Review permissions this account was granted
  - Remove any over-privileged permissions
  - Contact vendor for security guidance

**Action 2.3: Scan for Systemic Permission Drift**
- [ ] Query document repository for any matters with overly permissive access (Everyone, Domain Users, Authenticated Users)
- [ ] Generate report of permission anomalies
- [ ] Prepare corrective actions

### **TIER 3: Scope Assessment (10–20 minutes)**

**Action 3.1: Identify Other Potentially Affected Users**
- [ ] Export Copilot chat history for **all Floor 6 users** (last 48 hours)
- [ ] Search for:
  - Queries that return documents outside normal role access
  - Downloads or shares of matter documents
  - Unusual query patterns

- [ ] Interview IT Ops Lead
  - Have other users reported similar issues?
  - Are there other reports we should follow up on?

**Action 3.2: Audit All Matter Permissions**
- [ ] Generate a complete audit report of ALL matter folder permissions
- [ ] Identify any matters with unauthorized user access
- [ ] Flag matters with sensitive clients (public companies, government, media)

### **TIER 4: Breach Assessment & Preparation (20–30 minutes)**

**Action 4.1: Convene Incident Response Team**
- [ ] Chief Compliance Officer
- [ ] General Counsel
- [ ] Chief Information Security Officer
- [ ] HR / Communications (for breach notification preparation)

**Action 4.2: Assess Breach Criteria**
- [ ] Did unauthorized user VIEW the data? (YES – confirmed)
- [ ] Did unauthorized user DOWNLOAD the data? (Unknown – need to check logs)
- [ ] Did unauthorized user SHARE the data? (Unknown – need to check logs)
- [ ] Is the data sensitive enough to require notification? (Likely YES for legal matter)
- [ ] Does applicable law require notification? (Check: GDPR, state breach laws, contract terms)

**Action 4.3: Begin Breach Notification Preparation**
- [ ] Draft client notification email (do NOT send without Legal/Compliance approval)
- [ ] Prepare regulatory notification (if required)
- [ ] Prepare timeline for notification (legal deadline: usually 30–60 days)
- [ ] Determine scope: One client or multiple?

**Action 4.4: Document Initial Findings**
- [ ] Record exact unauthorized information exposed
- [ ] Timeline of access
- [ ] Number of users potentially affected
- [ ] Containment actions taken
- [ ] Preliminary root cause hypothesis

### **TIER 5: Ongoing Investigation & Recovery (30+ minutes)**

**Action 5.1: Full Forensic Analysis**
- [ ] Detailed analysis of Copilot query logs
- [ ] Complete audit of document repository access logs
- [ ] Analysis of Active Directory and Intune changes (Windows 11 migration)
- [ ] Vendor assessment of new document management app

**Action 5.2: Root Cause Determination & Corrective Actions**
- [ ] Identify systemic failure (permissions, app, Copilot configuration)
- [ ] Prepare corrective actions to prevent recurrence
- [ ] Determine if issue affects other floors/departments

**Action 5.3: Communication & Client Notification (Decision Gate)**
- [ ] If breach confirmed: Client notification by [timeline per law/contract]
- [ ] If not breach: Internal RCA and corrective actions

---

## DECISION TREE

```
START: Copilot Unauthorized Data Access Investigation (09:14)
│
├─→ Q1: Did the user actually see confidential data?
│   │
│   ├─→ A: NO (misunderstanding, wrong matter, etc.)
│   │   └─→ ACTION: Document as false alarm; no further escalation
│   │       → Log incident as resolved; monitor for recurrence
│   │
│   └─→ A: YES (confirmed unauthorized access)
│       └─→ PROCEED: This is a real incident
│           → GOTO PATH A (Breach Confirmation & Evidence Preservation)
│
├─→ PATH A: Confirmed Unauthorized Access Incident (09:14–09:20)
│   │
│   ├─→ ACTION: Emergency isolation
│   │   ├─→ Disable Copilot access for affected user
│   │   ├─→ Disable Copilot access for Floor 6 (precautionary)
│   │   ├─→ Export Copilot chat history before auto-delete
│   │   └─→ Preserve affected user's machine (no reboot)
│   │
│   ├─→ ACTION: Notify leadership
│   │   ├─→ Chief Counsel (IMMEDIATE)
│   │   ├─→ Compliance Officer (IMMEDIATE)
│   │   ├─→ CIO (IMMEDIATE)
│   │   └─→ Activate incident commander
│   │
│   ├─→ Q2: Was the data DOWNLOADED, SHARED, or FORWARDED?
│   │   │
│   │   ├─→ A: YES (confirmed exfiltration)
│   │   │   └─→ SEVERITY: CRITICAL BREACH
│   │   │       → Breach notification required (likely)
│   │   │       → Client notification (likely)
│   │   │       → Regulatory notification (maybe)
│   │   │       → GOTO PATH A1 (Breach Escalation)
│   │   │
│   │   └─→ A: NO or UNKNOWN (contained viewing only)
│   │       └─→ SEVERITY: HIGH (Unauthorized access, containable)
│   │           → Breach notification may not be required (depends on law)
│   │           → Client notification (maybe)
│   │           → GOTO PATH A2 (Contained Incident Assessment)
│   │
│   ├─→ PATH A1: Confirmed Breach / Data Exfiltration
│   │   │
│   │   ├─→ ACTION: Immediate escalation
│   │   │   ├─→ Convene legal/compliance/IR team
│   │   │   ├─→ Begin breach notification procedure
│   │   │   ├─→ Prepare client contact
│   │   │   ├─→ Document all evidence
│   │   │   └─→ Preserve chain of custody
│   │   │
│   │   ├─→ ACTION: Scope & impact assessment
│   │   │   ├─→ Which client matters affected?
│   │   │   ├─→ How much data? (file count, data size)
│   │   │   ├─→ Who had access? (single user or many?)
│   │   │   └─→ How long exposed? (hours? days?)
│   │   │
│   │   ├─→ ACTION: Contain further exposure
│   │   │   ├─→ Reset all matter permissions
│   │   │   ├─→ Audit for other unauthorized access
│   │   │   ├─→ Disable document management app (if culprit)
│   │   │   └─→ Apply controls to Copilot (RLS, access control)
│   │   │
│   │   └─→ OUTCOME: Breach response protocol activated; client notification prepared
│   │
│   └─→ PATH A2: Unauthorized Access (Contained Viewing)
│       │
│       ├─→ ACTION: Root cause investigation
│       │   ├─→ Q: What caused the access failure?
│       │   │   │
│       │   │   ├─→ A: Document permissions reset by app → Vendor remediation
│       │   │   ├─→ A: Service account over-privileged → Permission reduction
│       │   │   ├─→ A: User accidentally granted access → Group cleanup
│       │   │   └─→ A: Copilot RLS not working → Microsoft escalation
│       │   │
│       │   └─→ ACTION: Implement corrective action (per root cause)
│       │
│       ├─→ ACTION: Scope assessment
│       │   ├─→ How many other users affected?
│       │   ├─→ How many other matters exposed?
│       │   └─→ Are there patterns of unauthorized access?
│       │
│       ├─→ DECISION: Is this a reportable breach?
│       │   │
│       │   ├─→ A: YES (law, contract, or sensitivity requires notification)
│       │   │   └─→ Begin breach notification (see PATH A1)
│       │   │
│       │   └─→ A: NO (contained, no exfiltration, not reportable)
│       │       └─→ OUTCOME: Internal RCA; corrective actions; monitor for recurrence
│       │
│       └─→ OUTCOME: Incident contained; communication prepared
│
├─→ PATH B: Unknown / Investigation Stalled (if at 15-minute mark)
│   │
│   ├─→ ACTION: Escalate to Security Team + Microsoft support
│   │   ├─→ Request forensic analysis
│   │   ├─→ Request Microsoft Copilot/M365 security investigation
│   │   └─→ Prepare legal hold (preserve all evidence)
│   │
│   └─→ OUTCOME: Continued investigation with external resources
│
└─→ END: Continue investigation in parallel; prepare communication & remediation
```

---

## EXECUTIVE UPDATE FOR LEADERSHIP
*(Non-Technical, Suitable for Partners & Senior Leadership – Target delivery: Before Noon on 2026-08-14)*

---

### **ALERT: Potential Data Security Incident Reported – Legal Department**

**Situation:** During routine Monday morning incident response, we received a report that a staff member in the Legal department was able to access confidential client matter information through Copilot (our new AI assistant) that they should not have had access to.

**What We Know:**
- One paralegal reported seeing a client matter in Copilot that they are not assigned to work on
- This appears to be a systems access control failure, not user error or policy violation
- We have immediately disabled Copilot access for that user and the entire Floor 6 Legal department as a precautionary measure
- We are investigating whether other users may have had similar unauthorized access

**What We're Doing Right Now:**
1. **Immediate Containment:** Isolated Copilot access; preserved all evidence; took affected user's machine offline
2. **Scope Assessment:** Checking whether other staff members had similar access; auditing all confidential matter permissions
3. **Root Cause Investigation:** Investigating whether the issue is related to a new document management system deployed Friday, the recent Windows 11 upgrade, or the Copilot configuration

**Initial Assessment:**
- This appears to be a configuration error related to recent system changes (Windows 11 migration, Copilot deployment, or new document management app) rather than a malicious attack
- We currently have no indication that confidential information left the firm (no evidence of downloads or external sharing)
- This is being treated as a potential breach and we are following our incident response protocol

**Compliance & Client Notification:**
- Our Chief Counsel and Compliance Officer have been notified and are guiding next steps
- If we determine this meets the threshold for client notification (based on applicable law and contract terms), clients will be contacted within the required timeframe
- We are preserving all evidence for legal hold and investigation

**Impact on Business:**
- Legal department staff will have Copilot temporarily disabled while we investigate
- All other systems (email, files, case management) remain operational
- Staff can continue their work without Copilot

**Next Steps & Timeline:**
- **By 11:00 AM:** Root cause determination and scope confirmation
- **By 12:00 PM:** Breach notification decision (whether client notification is required)
- **By EOD:** Corrective actions implemented and Copilot re-enabled with proper access controls
- **By EOW:** Full investigation report and security improvements implemented

**For Partners:**
- We are actively investigating and taking all appropriate containment and remediation steps
- We will update you immediately if there is any indication that your confidential information was accessed or left our systems
- Our security and legal teams are fully engaged

---

**Prepared by:** [Service Desk Lead + Security Lead]  
**Classification:** CONFIDENTIAL – Executive/Legal Use Only  
**Next Update:** 11:00 AM, 2026-08-14  
**Escalation Contact:** [CIO] [Phone/Email] for urgent questions

---

## OPEN ITEMS / CRITICAL PATH

- [ ] Immediate: Export Copilot chat history and preserve evidence
- [ ] Immediate: Confirm which client matter was exposed
- [ ] Immediate: Determine if data was downloaded/shared (critical for breach determination)
- [ ] First 10 min: Complete paralegal interview and capture exact details
- [ ] First 15 min: Audit document repository permissions for all matters
- [ ] First 20 min: Scan all Floor 6 users' Copilot history for unauthorized access patterns
- [ ] First 25 min: Convene legal/compliance/security team for breach assessment
- [ ] First 30 min: Issue preliminary breach notification recommendation to leadership
- [ ] Post-30 min: Root cause analysis (app, Copilot config, permissions, Azure AD/Intune changes)
- [ ] Post-30 min: Client notification preparation (if required)
- [ ] Post-investigation: Corrective actions (RLS, access control, app remediation, M365 configuration)
