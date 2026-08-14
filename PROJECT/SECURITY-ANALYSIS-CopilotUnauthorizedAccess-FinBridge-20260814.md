# SECURITY INCIDENT ANALYSIS
## Copilot Unauthorized Data Access – FinBridge Legal Department
**Incident Identifier:** SEC-2026-0814-001  
**Reported:** 2026-08-14 09:14 (Monday)  
**Location:** Floor 6, Legal Department, FinBridge  
**Reporter:** IT Operations Lead (via Paralegal)  
**Classification:** POTENTIAL UNAUTHORIZED DATA DISCLOSURE / PRIVILEGE ESCALATION  
**Threat Level:** CRITICAL

---

## WHY THIS IS A SECURITY INCIDENT, NOT A STANDARD SUPPORT TICKET

### The Critical Distinction

This is **NOT** a Copilot malfunction or "AI weirdness." This is a **data access control failure** with legal, compliance, and regulatory implications.

### Standard Support Ticket Definition
A standard support ticket addresses a **user-facing feature problem**:
- "Copilot gave me the wrong answer"
- "Copilot crashed"
- "Copilot is slow"
- "I can't figure out how to use Copilot"

**Response:** Restart app, provide training, contact vendor support.

### Security Incident Definition
A security incident represents a **violation of data confidentiality, integrity, or access control**:
- "Copilot showed me data I don't have permission to access"
- "I saw information about a client matter I'm not assigned to"
- "Confidential information appeared that violates my role/privilege"

**Response:** Preserve evidence, isolate systems, investigate access controls, assess breach status, notify leadership and compliance.

---

## WHY THIS CANNOT BE DISMISSED AS A "COPILOT BUG" OR "AI WEIRDNESS"

### Why "AI Hallucination" Doesn't Explain This

**Misconception:** "Copilot sometimes makes things up. This user probably misidentified the information, or Copilot confabulated something."

**Reality:** Copilot is not generating or hallucinating legal information. Copilot is a **search and summarization tool** that retrieves data from configured data sources:

| Data Source | Copilot Role | Access Control Requirement |
|---|---|---|
| **Document Repository** | Retrieves and summarizes documents | Must respect document-level permissions |
| **SharePoint** | Indexes and searches files | Must filter results by user's SharePoint access |
| **Email** | Searches mailbox content | Must only return emails from user's mailbox |
| **Teams** | Searches conversations | Must only return conversations user is member of |
| **Case Management** | Searches matter data | Must respect matter assignment and role |

**Critical Point:** Copilot is **not creating** the data. It is **retrieving and displaying** information from one of these sources. If a paralegal saw client matter information, it came from a real data source, and Copilot failed to enforce access control.

### The Access Control Failure Chain

```
┌─────────────────────────────────────────────────────────┐
│  1. DATA SOURCE                                         │
│  (Document Repo, SharePoint, Email, Teams, etc.)       │
│  ├─ Should have permission controls at document/file   │
│  │  level (row-level security, document ACLs)          │
│  └─ Paralegal SHOULD NOT have read access to matter    │
├─────────────────────────────────────────────────────────┤
│  2. COPILOT CONNECTOR                                   │
│  (Data integration layer)                               │
│  ├─ Should query data source using user's permissions  │
│  │  (impersonate user, apply user's access token)      │
│  └─ Should filter results: ONLY show data user can     │
│     access                                              │
├─────────────────────────────────────────────────────────┤
│  3. COPILOT RESULT DISPLAY                              │
│  (What user sees)                                       │
│  ├─ FAILURE: Paralegal saw matter they don't have      │
│  │  access to                                           │
│  └─ This indicates a break in the chain (steps 1 or 2) │
└─────────────────────────────────────────────────────────┘

FAILURE POINTS (Most Likely):
A) Document permissions were reset (Friday app deployment)
B) Copilot using service account with overly broad access
C) Copilot not applying row-level security (RLS) filtering
D) User's permissions were accidentally granted (wrong group)
E) New document management app bypassed access controls
```

### Why This Matters: The Difference Between Bug and Breach

| Copilot Bug | Security Incident |
|---|---|
| Copilot crashes → User loses productivity | Copilot displays confidential data → Legal/compliance liability |
| Copilot returns wrong search results → User confusion | Copilot bypasses access control → Unauthorized disclosure |
| Copilot performance is slow → User frustration | Copilot reveals attorney-client privilege → Bar violation |
| Vendor issue, standard fix | **Potential breach, regulatory notification required** |

---

## INCIDENT SEVERITY CLASSIFICATION

### Severity Level: **CRITICAL (P0)**

| Dimension | Assessment | Justification |
|---|---|---|
| **Data Sensitivity** | **CRITICAL** | Legal matters = attorney-client privileged communication + confidential client information |
| **Regulatory Impact** | **CRITICAL** | Bar association rules require protection of confidential info; breach may trigger notification |
| **Breach Likelihood** | **HIGH** | Unauthorized access confirmed; exfiltration status unknown but likely |
| **Compliance Risk** | **CRITICAL** | Client contracts likely require data protection; breach could trigger damages |
| **Exposure Scope** | **UNKNOWN** | Affects 1 confirmed user; unknown if others affected; unknown how many matters exposed |
| **Access Control Failure** | **SYSTEMIC** | Points to configuration error affecting potentially many users, not isolated user error |
| **Business Impact** | **CRITICAL** | If public, severe reputational damage; if regulatory, fines; if civil, liability |
| **Time Sensitivity** | **IMMEDIATE** | Every minute increases risk of evidence loss, data exfiltration, log overwrite |

### Why This is P0 / CRITICAL (Not P1/P2)

**P0 = Security/Compliance Incident**
- Unauthorized access to confidential data ✓
- Attorney-client privilege potentially violated ✓
- Regulatory breach notification threshold likely met ✓
- Chain of evidence must be preserved immediately ✓
- Requires immediate incident commander activation ✓
- Requires immediate Legal/Compliance/Security involvement ✓

**Not P1 (Business Impact) because:** While business-blocking incidents are P1, security incidents supersede business priority when they involve data exposure, regulatory risk, or breach potential.

**Not P2 (Standard Support) because:** This is not a feature request or configuration preference.

---

## FACTS vs ASSUMPTIONS vs UNKNOWNS

### VERIFIED FACTS (100% Confidence)

1. **One paralegal on Floor 6 reported** seeing client matter information in Copilot
2. **The paralegal explicitly states** they have never been assigned to work on that matter
3. **The paralegal is a legal professional** (understands matter assignment and data classification)
4. **This is a real data source** (Copilot retrieved the information from somewhere: document repo, SharePoint, email, Teams, or case management system)
5. **Copilot was recently deployed** as part of Microsoft 365 rollout to this cohort
6. **A new document management application was deployed Friday afternoon** to Floor 6
7. **Windows 11 migration and Intune enrollment completed** for this cohort last week
8. **No logs, forensics, or initial investigation** have been completed yet

### REASONABLE ASSUMPTIONS (HIGH Confidence – >80%)

**Assumption 1: This is not user misunderstanding**
- **Confidence:** 85%
- **Rationale:** Paralegal is trained legal professional; understands client matters, case assignment, and data classification
- **Weakness:** Possible confusion with different matter or similar client name
- **Test:** Ask paralegal for specific identifiers (matter number, client name, specific content)

**Assumption 2: The data exists and came from a configured data source**
- **Confidence:** 95%
- **Rationale:** Copilot does not generate legal data; it must retrieve from document repo, SharePoint, email, Teams, or case management system
- **Weakness:** User could have misread or misinterpreted information displayed
- **Test:** Ask Copilot to reproduce the same query; check if data appears again

**Assumption 3: If one user saw unauthorized data, others likely have as well**
- **Confidence:** 70%
- **Rationale:** Access control failures are usually systemic (wrong group, wrong policy, wrong permissions) affecting cohorts, not individual users
- **Weakness:** Could be isolated to this user's account or this user's interaction
- **Test:** Audit other users' Copilot chat history; scan for patterns of unauthorized queries

**Assumption 4: The Friday document management app deployment may have triggered the access control failure**
- **Confidence:** 60%
- **Rationale:** Timing is suspicious; app deployments often reset permissions or modify access controls
- **Weakness:** Could be unrelated; could be Windows 11 migration or Intune policy side effect
- **Test:** Compare document permissions before/after app deployment; check app installation logs

**Assumption 5: This is a configuration error, not a malicious insider attack**
- **Confidence:** 75%
- **Rationale:** Paralegal reported it (didn't hide it); reported at routine incident time (not after hours); no evidence of data exfiltration
- **Weakness:** Could be social engineering test or cover for data theft
- **Test:** Check for unusual access patterns, data downloads, external shares

### UNKNOWNS (CRITICAL TO CLARIFY)

#### **IMMEDIATE (0–5 minutes)**

1. **Which specific client matter was exposed?**
   - Matter name/number
   - Client identity
   - Type of information (emails, documents, strategy memos, financial data)
   - Confidentiality level (public, internal, attorney-client privileged, work product)
   - WHERE TO CHECK: Interview paralegal; query case management system

2. **What exactly did the paralegal see in Copilot?**
   - Was it a document title? Content preview? Full document?
   - How many documents or emails?
   - Did they see it once, or repeated access?
   - WHERE TO CHECK: Copilot chat history (PRESERVE IMMEDIATELY)

3. **Is the paralegal's statement accurate (not a misunderstanding)?**
   - Are they 100% certain it's a matter they're not assigned to?
   - Could they be confusing it with a matter they ARE assigned to?
   - WHERE TO CHECK: Verify paralegal's actual case assignment in case management system

4. **Did the paralegal attempt to access the underlying data directly?**
   - Can they open the document repository and access that matter's files?
   - Or can they ONLY see it through Copilot?
   - WHERE TO CHECK: Have paralegal attempt direct access (with oversight)

5. **How did the paralegal discover this (what was their search query)?**
   - What did they ask Copilot?
   - Was it an intentional search or accidental discovery?
   - WHERE TO CHECK: Copilot chat history

#### **URGENT (5–15 minutes)**

6. **How many other users might be affected?**
   - Are other Floor 6 users reporting similar unauthorized access?
   - Can we proactively scan Copilot history for patterns?
   - WHERE TO CHECK: Helpdesk queue, direct outreach to Floor 6 staff, Copilot audit logs

7. **Which data source contained the exposed information?**
   - Document repository? SharePoint? Email? Teams? Case management?
   - Different sources have different access control mechanisms
   - WHERE TO CHECK: Copilot chat log shows which source; query each source's access logs

8. **What are the paralegal's actual permissions?**
   - Active Directory groups and roles
   - Document repository permissions
   - Case management system access level
   - SharePoint and Teams memberships
   - WHERE TO CHECK: Active Directory, case management system, document repo admin panel

9. **Was the data downloaded, shared, or forwarded?**
   - If Copilot showed information in chat, did user copy/paste it?
   - Did user take screenshot?
   - Did user share with colleagues?
   - This determines breach vs. contained incident
   - WHERE TO CHECK: Copilot audit log, email search, chat history

10. **When did this occur?**
    - Friday afternoon (after app deployment)?
    - Monday morning (this morning)?
    - When was it discovered (just now)?
    - WHERE TO CHECK: Copilot timestamp, interview paralegal

#### **HIGH PRIORITY (15–25 minutes)**

11. **Is Copilot using a service account with overly broad permissions?**
    - Service account identity
    - Service account group memberships
    - Does service account bypass document-level access controls?
    - WHERE TO CHECK: Copilot connector configuration, Active Directory service account audit

12. **Did document management app deployment reset permissions?**
    - Permission state before Friday deployment
    - Permission state after Friday deployment
    - Did app installer have permission to change document ACLs?
    - WHERE TO CHECK: Document repository audit trail, app installation logs

13. **Is row-level security (RLS) enforced in Copilot?**
    - Does Copilot filter results based on user's permissions?
    - Is RLS configured and enabled?
    - Known issues with RLS in this Copilot version?
    - WHERE TO CHECK: Copilot configuration, Microsoft documentation, vendor testing

14. **Was the user accidentally added to a group with document access?**
    - Group membership changes in last 48 hours
    - Did Windows 11 migration or Intune enrollment add user to unexpected groups?
    - WHERE TO CHECK: Active Directory group membership history, Intune policy audit

15. **Are other matters also over-permissioned?**
    - Scan all matter folders for unauthorized user access
    - Identify systemic permission drift
    - WHERE TO CHECK: Document repository permission audit, bulk scan script

---

## EVIDENCE COLLECTION (IMMEDIATE – DO NOT DELAY)

### **CRITICAL PATH: Preserve Digital Evidence (0–5 minutes)**

#### **Evidence Set 1: Copilot Interaction Record**
**Why:** Copilot chat history is ephemeral and may auto-delete or be cleared by user. This is the primary evidence of unauthorized data access.

**What to Collect:**
- [ ] **Copilot Chat History Export (JSON/CSV)**
  - User ID, session ID
  - Timestamp of interaction
  - Exact queries executed
  - Results returned (document titles, file paths, content preview)
  - Data source queried (document repo, SharePoint, email, etc.)
  - Document identifiers (matter number, file name, file path)

- [ ] **Browser History & Cache** (if Copilot accessed via web)
  - Web browser history for Copilot portal access
  - Cache files (may contain preview of returned documents)
  - Cookies and session tokens

- [ ] **Copilot Audit Log Export**
  - From Microsoft 365 audit log: Copilot interactions by this user
  - Search query details
  - Data sources accessed
  - Results returned

**Collection Method:**
```
1. Do NOT ask user to export (they may clear history)
2. Export directly from admin console:
   → Microsoft 365 admin center > Reports > Audit logs
   → Filter: User = paralegal, Service = Copilot
   → Time range: Last 48 hours
3. Export from Copilot service directly:
   → Microsoft 365 Copilot > Settings > Audit
4. Preserve chain of custody (document who collected, when, method)
```

#### **Evidence Set 2: User Account Access State**
**Why:** Determine what permissions the user actually has; confirm they should NOT have access.

**What to Collect:**
- [ ] **Active Directory User Object Audit**
  - Current group memberships
  - Group membership history (changes in last 48 hours)
  - Manager assignment
  - Department / organizational unit
  - Account flags (disabled, locked, etc.)

- [ ] **Case Management System Access Verification**
  - Matter assignments for this user (list all matters)
  - User role (attorney, paralegal, admin)
  - Access level per matter
  - Confirm: User is NOT assigned to the exposed matter

- [ ] **Document Repository Permissions Audit**
  - User's direct file/folder permissions
  - User's permissions via group membership
  - Confirm: User should NOT have access to the exposed matter's folder

**Collection Method:**
```powershell
# Active Directory group membership
Get-ADUser -Identity [paralegal_username] -Properties MemberOf | Select-Object -ExpandProperty MemberOf

# Group membership history (if audit log available)
Get-ADUser -Identity [paralegal_username] | Get-ADGroup -Server [DC] | Get-ADObjectAudit
```

#### **Evidence Set 3: Exposed Data Identification**
**Why:** Determine exactly what was exposed; critical for breach assessment and regulatory notification.

**What to Collect:**
- [ ] **Matter Identification**
  - Matter name / number
  - Client name
  - Matter type (litigation, transaction, advisory)
  - Data classification (public, internal, confidential, attorney-client privileged)
  
- [ ] **Content Exposed**
  - Document titles returned by Copilot
  - File types (emails, Word docs, PDFs, spreadsheets)
  - Content classification (financial data, legal strategy, client communications)
  - Date range of documents (current matters, completed matters, archived)

- [ ] **Scope of Exposure**
  - How many documents from this matter were displayed in Copilot?
  - Were all matter files exposed or subset?
  - Were other matters' files also exposed?

**Collection Method:**
```
1. Interview paralegal:
   "Can you tell me the client name and matter number you saw in Copilot?"
   "What type of documents or information did you see?"
   "Do you remember any specific file names or email subjects?"

2. Query case management system:
   Matter [number] → Current authorized access list
   Confirm paralegal is NOT on the list

3. Query document repository:
   Matter [number] folder → Current permissions ACL
   Identify which users have access (should match authorized list)
```

---

## CRITICAL CHECKS REQUIRED (EVIDENCE COLLECTION PHASE)

### **1. PERMISSION STRUCTURE VERIFICATION**

#### **Active Directory & Group Policy**

| Check | What to Look For | Why It Matters | Command/Location |
|---|---|---|---|
| **User Group Membership (Current)** | Is user in any group with document access? | Establishes baseline permissions | `Get-ADUser -Identity [user] -Properties MemberOf` |
| **Group Membership Changes (Last 48h)** | Was user added to or removed from groups? | Identifies recent permission changes | Active Directory audit log, `Get-ADGroupMember` history |
| **Group Nesting** | Is user indirectly in a group via nested group? | Transitive permissions; harder to audit | Recursive group membership analysis |
| **Dynamic Groups** | Is user in Azure AD dynamic groups? | May be automatically added based on criteria | Azure AD > Groups > Dynamic membership rules |
| **Service Principal Accounts** | What service accounts have access to matter data? | Copilot may use service account | Active Directory > Service Accounts |

#### **Document Repository Permissions**

| Check | What to Look For | Why It Matters | Command/Location |
|---|---|---|---|
| **Folder-Level ACLs** | Who has read/write on matter folder? | Establishes allowed access | `Get-Item -Path [folder] \| Get-Acl` |
| **Document-Level ACLs** | Are individual documents restricted? | Some repos allow fine-grained access | Document repo admin panel |
| **Inherited vs. Explicit** | Is permission inherited from parent or explicit? | Inherited permissions easier to accidentally grant | ACL audit trail |
| **Permission Change History** | When did permissions last change? | Identify trigger event (app deployment, migration) | Document repo audit log, permission change log |
| **Shared Links & Anonymous Access** | Are documents shared externally or publicly? | Could explain unauthorized access | Document repo > Sharing settings |
| **Public or "Everyone" Permissions** | Is matter folder accessible to "Everyone" or "Authenticated Users"? | Most common permission overage | ACL review for overly permissive groups |

#### **Row-Level Security (RLS) Configuration**

| Check | What to Look For | Why It Matters | Command/Location |
|---|---|---|---|
| **RLS Enabled in Copilot** | Is RLS feature turned on? | Without RLS, service account bypasses user permissions | Copilot settings, Microsoft 365 admin center |
| **RLS Applied to Data Source** | Which data sources have RLS configured? | May be enabled for some but not others | Copilot connector settings for each source |
| **RLS Test** | Query as authorized user vs. unauthorized user; compare results | Confirms RLS is working | Copilot chat query comparison |
| **RLS Known Issues** | Any CVEs or known RLS bypass issues? | May be vendor issue, not configuration | Microsoft security advisories, vendor KB |

---

### **2. MICROSOFT 365 & AZURE AD CHECKS**

#### **Azure AD Sign-In & Authentication**

| Check | What to Look For | Why It Matters | Location |
|---|---|---|---|
| **User Sign-In Activity** | When did paralegal last sign in? When did they access Copilot? | Establishes timeline | Azure AD > Sign-in logs, filter by user |
| **Conditional Access Policies** | Are any CA policies applied to user? | May prevent access or require MFA | Azure AD > Conditional Access |
| **Audit Log for User** | What M365 services has user accessed? | May reveal unusual access patterns | M365 admin center > Audit logs, filter by user |
| **Session Tokens** | What authentication method was used? | Establishes user identity; rules out compromise | Sign-in log details |

#### **Microsoft 365 Audit Trail**

| Check | What to Look For | Why It Matters | Location |
|---|---|---|---|
| **Copilot Audit Log** | All Copilot interactions by user | Primary evidence of Copilot access | M365 admin center > Audit > Copilot activity |
| **SharePoint Access** | Did user access matter files via SharePoint? | RLS may be bypassed at SharePoint level | M365 audit > SharePoint activities |
| **Teams Access** | Did user access matter information via Teams channels? | Teams may not enforce RLS correctly | M365 audit > Teams activities |
| **Email Access** | Did user access privileged emails? | May indicate broader access control failure | M365 audit > Exchange activities |
| **Document Download** | Did user download exposed matter documents? | Escalates from viewing to possession | File download events in audit log |

#### **Service Principal & Connector Identity**

| Check | What to Look For | Why It Matters | Location |
|---|---|---|---|
| **Copilot Service Principal** | What account does Copilot use to query data? | Service principal's permissions applied to all queries | Azure AD > App registrations > Copilot |
| **Data Connector Service Account** | What account does the connector (to doc repo, SharePoint, etc.) use? | This account's permissions determine access | Azure AD > Service accounts; Copilot connector config |
| **Service Account Permissions** | What groups/roles does the service account have? | Determines data access scope | Active Directory > Service account groups |
| **Service Account Audit** | Has service account been granted excessive permissions? | Most common cause of RLS bypass | Active Directory audit log, permission history |

---

### **3. SHAREPOINT & TEAMS CHECKS**

#### **SharePoint Site & Library Security**

| Check | What to Look For | Why It Matters | Location |
|---|---|---|---|
| **Site Permissions** | Who has access to the SharePoint site hosting matter docs? | Document-level access depends on site access | SharePoint > Site permissions |
| **Library Permissions** | Who has access to the document library? | Broader than folder-level access | SharePoint > Library > Permissions |
| **Folder Permissions** | Who has read access to matter folder? | Specific to this matter | SharePoint > Folder > Permissions |
| **Document Sharing** | Are any documents shared externally or with unexpected users? | May explain unauthorized access | SharePoint > Document > Sharing |
| **Shared Links** | Are there any "Anyone" links to matter documents? | Could allow unauthorized access | SharePoint > Manage access > Shared links |
| **Inheritance Settings** | Is folder inheriting permissions from parent? | Unintended inheritance is common source of access drift | SharePoint folder settings > Permissions > Inheritance |

#### **Teams Channels & Conversations**

| Check | What to Look For | Why It Matters | Location |
|---|---|---|---|
| **Team Membership** | Is paralegal a member of matter-specific Teams? | Team members can access channel conversations | Teams > Members |
| **Channel Membership** | Is paralegal a member of the matter channel? | Channel access grants message visibility | Teams > Channel > Members |
| **Message Search** | Did Copilot retrieve matter information from Teams messages? | Indicates Teams channel access or Copilot indexing | Teams > Search; M365 audit > Teams activity |
| **Pinned Messages** | Are confidential documents pinned in channels? | More visible to Copilot indexing | Teams > Channel > Pinned messages |
| **External Sharing** | Have any matter-related Teams files been shared externally? | May indicate permission misconfiguration | Teams > Files > Sharing settings |

---

### **4. DOCUMENT MANAGEMENT APP CHECKS (Friday Deployment)**

#### **Application Deployment & Configuration**

| Check | What to Look For | Why It Matters | Location |
|---|---|---|---|
| **Deployment Timestamp** | When exactly was app deployed? | Friday afternoon timing is suspicious | App deployment log, ticket creation timestamp |
| **Deployment Scope** | Which users/devices received the app? | Helps identify who could be affected | App deployment log, Intune policy assignment |
| **Installation Account** | What account ran the app installation? | May be elevated/over-privileged | App installation log, MSI log |
| **Permissions Requested** | What permissions did app request during install? | May have requested document repo access | App installer log, UAC prompts captured |

#### **Application Behavior & Access Control**

| Check | What to Look For | Why It Matters | Location |
|---|---|---|---|
| **Data Source Integration** | Which data sources does the app query? (document repo, SharePoint, email, etc.) | Determines what data the app can access | App configuration, connector settings |
| **Authentication Method** | How does app authenticate to data sources? (service account, user impersonation, API key) | Service account = bypass of user permissions | App settings, authentication config |
| **Permission Handling** | Does app enforce row-level security? | RLS bypass = unauthorized access | App documentation, vendor testing |
| **Default Permissions** | What default permissions did app grant during installation? | May have accidentally granted folder access | App installation log, registry changes |
| **Copilot Integration** | Does app integrate with Copilot? Does it register as a data source? | App may expose data to Copilot without RLS | App documentation, Copilot connectors |

#### **Application Vendor Security**

| Check | What to Look For | Why It Matters | Location |
|---|---|---|---|
| **Known Vulnerabilities** | CVEs affecting this app version? | May be exploited vulnerability | Vendor KB, CVE database, vendor security page |
| **Permission Bypass Issues** | Known issues with RLS or access control? | Vendor may have acknowledged issue | Vendor release notes, security advisories |
| **Windows 11 Compatibility** | Is there a known issue with Windows 11 + app interaction? | Could affect permission application | Vendor documentation, forum posts |
| **Intune Enrollment Compatibility** | Does app work correctly with Intune-enrolled devices? | Could be policy/permissions issue specific to Intune | Vendor KB, support tickets |

---

### **5. WINDOWS 11 MIGRATION & INTUNE CHECKS**

#### **Migration Impact on Permissions**

| Check | What to Look For | Why It Matters | Location |
|---|---|---|---|
| **Migration Timing** | When was this user's device migrated to Windows 11? | Post-migration changes could have triggered access shifts | Migration ticket, device inventory |
| **User Profile Migration** | Was user profile migrated from Windows 10? | Profile migration can reset or modify cached credentials | Migration log, profile creation timestamp |
| **Group Policy Application** | Were new GPOs applied during migration? | GPO can restrict or grant access | GPO audit log, gpresult.html on device |
| **Credential Caching** | Was credential caching state changed? | Could affect how system authenticates to document repo | GPO settings, migration documentation |

#### **Intune Enrollment Impact**

| Check | What to Look For | Why It Matters | Location |
|---|---|---|---|
| **Enrollment Status** | Is device successfully enrolled in Intune? | Failed enrollment can cause access issues | Intune > Devices > Enrollment status |
| **Intune Policies Applied** | Which policies were assigned to this user/device? | Policies can modify permissions, group membership, or access | Intune > Policies > Assigned policies |
| **Compliance Baseline** | Is any security baseline applied? | Security baseline may grant or restrict access | Intune > Security baselines |
| **Group Assignment via Intune** | Was user added to any dynamic groups via Intune? | Can grant unexpected permissions | Intune > Groups > Dynamic membership |
| **Certificate or Credential Push** | Did Intune push any certificates or credentials? | Could grant access to data sources | Intune > Certificates; device certificate store |

---

## IMMEDIATE CONTAINMENT ACTIONS

### **TIER 0: EMERGENCY ISOLATION (0–2 minutes)**
**Goal:** Stop further unauthorized access; preserve evidence

**Action 0.1: Freeze Affected User's Account**
```powershell
# Option A: Disable account (most conservative)
Disable-ADAccount -Identity [paralegal_username]

# Option B: Reset session (less disruptive)
Revoke-AzureADUserAllRefreshToken -ObjectId [user_ObjectId]
```
**Rationale:** Prevents further Copilot queries; stops any data exfiltration if in progress  
**Risk:** User cannot work until account re-enabled; must communicate with Legal/Compliance first

**Action 0.2: Disable Copilot Access Immediately**
```
Method 1: Intune Policy
→ Create emergency policy: "Copilot disabled"
→ Assign to affected user
→ Takes effect at next policy refresh (5–15 minutes)

Method 2: Conditional Access (Azure AD)
→ Create emergency CA rule: "Block Copilot for this user"
→ Takes effect immediately

Method 3: Microsoft 365 Admin Center
→ Disable Copilot tenant-wide or for this user
→ Takes effect immediately
```
**Rationale:** Prevents further unauthorized queries while investigation proceeds  
**Impact:** Floor 6 users (and others) lose Copilot; justified by security hold

**Action 0.3: Isolate Affected Machine (If Feasible)**
```
Method 1: Network isolation (preferred)
→ Disconnect from network switch or VLAN
→ Physical machine remains powered on (to preserve evidence)

Method 2: Remote lock
→ Use Intune remote lock or RDP to lock machine
→ Prevents further access while preserving state
```
**Rationale:** Preserves logs, cache, and Copilot chat history on device  
**Impact:** User cannot work until machine re-connected; justified by security preservation

**Action 0.4: Enable Audit Logging (Immediate)**
```powershell
# Enable comprehensive auditing for document repository
Enable-AuditLog -Source "DocumentRepository" -EventType "Read,Write,Delete,PermissionChange"

# Enable audit for case management system access
Enable-AuditLog -Source "CaseManagementSystem" -EventType "Matter Access,Document View"

# Enable audit for Copilot interactions
Enable-AuditLog -Source "Copilot" -EventType "Query,ResultReturn,DataAccess"
```
**Rationale:** Captures any ongoing suspicious activity; essential for forensics  
**Impact:** Minor performance impact on systems; justified by security need

### **TIER 1: EVIDENCE PRESERVATION (2–5 minutes)**

**Action 1.1: Preserve Copilot Chat History**
```
1. Export user's Copilot chat history immediately
   → M365 admin center > Reports > Audit logs
   → Filter: User = [paralegal], Service = Copilot
   → Export to JSON (not deletable once exported)

2. Capture browser cache (if Copilot accessed via web)
   → Export browser cache directory
   → Preserve with chain of custody documentation
```

**Action 1.2: Capture Active Directory State**
```powershell
# Snapshot user's current state
$user = Get-ADUser -Identity [paralegal_username] -Properties * | ConvertTo-Json | Out-File -FilePath "C:\Evidence\$([DateTime]::Now.Ticks)_ADUser.json"

# Snapshot group memberships
Get-ADUser -Identity [paralegal_username] -Properties MemberOf | Select-Object -ExpandProperty MemberOf | Out-File -FilePath "C:\Evidence\$([DateTime]::Now.Ticks)_Groups.txt"

# Snapshot case management system access
# (export from case mgmt system directly)
```

**Action 1.3: Preserve Document Repository Permissions**
```
1. Capture permission state for the exposed matter folder
   → Export ACL for matter folder and all documents
   → Export permission change history (last 48 hours)
   → Include who made changes and when

2. Backup the document folder
   → Preserve current state for forensics
   → Do NOT restore or modify
```

**Action 1.4: Capture System Logs**
```powershell
# On affected machine (if accessible):
Get-EventLog -LogName Security -After (Get-Date).AddHours(-48) | Out-File "C:\Evidence\Security_EventLog_48h.txt"
Get-EventLog -LogName Application -After (Get-Date).AddHours(-48) | Out-File "C:\Evidence\Application_EventLog_48h.txt"
Get-EventLog -LogName System -After (Get-Date).AddHours(-48) | Out-File "C:\Evidence\System_EventLog_48h.txt"
```

**Action 1.5: Legal Hold Notice**
```
Send to: IT, Document Management, SharePoint Team, Copilot Team, Case Management Team
Subject: LEGAL HOLD – Preservation Notice

"A data security incident has been identified. Preserve all evidence related to:
- User: [paralegal name/ID]
- Date range: 2026-08-11 (app deployment) to 2026-08-14 (discovery)
- Systems: Copilot, Document Repository, SharePoint, Case Management, Active Directory

Do not delete, modify, or destroy any logs, audit trails, permissions records, or data.
Compliance with this notice is mandatory.
Contact: [Chief Counsel] for questions."
```

### **TIER 2: ESCALATION & DECISION MAKING (5–15 minutes)**

**Action 2.1: Emergency Escalation Call**
```
Participants (IMMEDIATE CONFERENCE CALL):
- Chief Information Security Officer (CISO)
- Chief Compliance Officer
- General Counsel / Chief Counsel
- Chief Information Officer (CIO)
- IT Operations Director
- Incident Commander (if activated)

Talking Points:
1. "Paralegal reports Copilot displayed confidential client matter info (matter name: [X]) that they were never authorized to access."
2. "Initial assessment: This is not a Copilot bug. This indicates an access control failure in our data governance."
3. "Immediate actions: Disabled Copilot, isolated user account, preserved evidence."
4. "Decision required: Is this a breach? Do we need to notify clients?"
5. "Scope unknown: May affect multiple users; investigation ongoing."
```

**Action 2.2: Activate Incident Response Protocol**
- [ ] Assign Incident Commander
- [ ] Open Security Incident Ticket (SIEM system)
- [ ] Activate on-call security team
- [ ] Convene investigation team (Security + Compliance + Legal)
- [ ] Begin evidence chain of custody documentation
- [ ] Notify cyber insurance carrier (if applicable)

**Action 2.3: Determine Breach Notification Timeline**
```
Decision Gate: Is this a "breach" requiring notification?

If YES (data left the system, exfiltrated, or shared):
→ State laws: 30–60 days to notify affected parties
→ EU GDPR: 72 hours to notify authorities
→ Professional obligations: Immediate (bar association, clients)

If MAYBE (authorized access but via unauthorized vector):
→ Requires Legal/Compliance assessment
→ May need notification anyway (contractual obligation)

If NO (contained within system, no exfiltration, not reportable):
→ Internal RCA only (but still CISO-level incident)

ACTION: Legal team begins breach notification assessment immediately
```

### **TIER 3: PARALLEL INVESTIGATION (15–25 minutes)**

**Track 1: Permission Audit (Forensics Team)**
- [ ] Export document repository permissions for exposed matter
- [ ] Identify all users with access (should match authorized list)
- [ ] Identify discrepancies
- [ ] Check permission change history (last 48 hours)
- [ ] Identify trigger: App deployment? Policy change? User group change?

**Track 2: Copilot Configuration Review (Security Team + Microsoft)**
- [ ] Verify Copilot RLS configuration
- [ ] Verify Copilot service account permissions
- [ ] Test Copilot query as authorized vs. unauthorized user
- [ ] Determine if RLS is being bypassed
- [ ] Request Microsoft support for any known RLS issues

**Track 3: Application Vendor Assessment (IT Operations)**
- [ ] Contact document management app vendor IMMEDIATELY
- [ ] "App deployed Friday to Floor 6. User now seeing unauthorized data in Copilot. Possible app or integration issue. Please advise immediately."
- [ ] Request: Known issues, security advisories, Windows 11 compatibility, RLS bypass issues
- [ ] Request: Access logs from app installation

**Track 4: Scope Expansion (Security Team)**
- [ ] Poll Floor 6 staff: "Have others seen similar unauthorized data?"
- [ ] Scan all Floor 6 users' Copilot history for unauthorized queries
- [ ] Audit all matter permissions for access drift
- [ ] Identify other potentially affected users

### **TIER 4: SECONDARY CONTAINMENT (If Scope Expands)**

**If Multiple Users Affected:**
- [ ] Disable Copilot for entire Floor 6 (precaution)
- [ ] Begin mass permission audit for all matter folders
- [ ] Prepare communication to Legal department
- [ ] Begin notification planning (if breach confirmed)

**If Other Matters Also Exposed:**
- [ ] Identify all affected client matters
- [ ] Assess sensitivity of each matter
- [ ] Prepare individual client notification (if required)
- [ ] Escalate scope to executives and insurers

**If Data Exfiltration Confirmed:**
- [ ] Activate full incident response protocol
- [ ] Notify cybersecurity incident response team
- [ ] Begin forensic imaging of affected machines
- [ ] Prepare breach notification letters
- [ ] Activate communication/PR team

---

## TWO-SENTENCE ESCALATION TO SECURITY TEAM

**IMMEDIATE ESCALATION (Send Now):**

> "SECURITY ALERT: A paralegal in FinBridge Legal reported that Copilot displayed confidential client matter information they were never authorized to access, indicating an access control failure in our data governance infrastructure. We have immediately disabled Copilot, isolated the user, and preserved evidence; this requires emergency security investigation to determine if unauthorized access is systemic, whether data was exfiltrated, and whether breach notification is legally required."

---

## ROOT CAUSE HYPOTHESIS FRAMEWORK

### **Why This Matters**
The root cause determines the remediation strategy. Each hypothesis requires different evidence and different fixes.

### **Hypothesis Priority & Likelihood**

| Rank | Hypothesis | Likelihood | Investigation | Remediation | Timeline |
|---|---|---|---|---|---|
| **1** | **App deployment reset document permissions** | 40% | Check permission audit trail for Friday changes | Restore permissions to baseline; app vendor assessment | 1–2 hours |
| **2** | **Copilot service account over-privileged** | 30% | Audit service account group membership and permissions | Reduce service account permissions; implement RLS | 2–4 hours |
| **3** | **Copilot RLS not configured or bypassed** | 15% | Test RLS functionality; check Copilot settings | Configure RLS; test functionality; vendor support | 4–8 hours |
| **4** | **User accidentally added to wrong group** | 10% | Check user's group membership changes (last 48h) | Remove user from inappropriate group | 30 minutes |
| **5** | **Intune policy grants unexpected access** | 5% | Audit Intune policies applied to user/device | Modify or roll back policy | 1–2 hours |

### **Evidence-Driven Hypothesis Testing**

```
HYPOTHESIS 1: Document Permissions Were Reset (40% likely)
│
├─ EVIDENCE TO COLLECT:
│  ├─ Permission audit trail for exposed matter (last 48 hours)
│  ├─ Permission change log for Friday afternoon (app deployment time)
│  ├─ ACL before vs. after app deployment
│  └─ Identify who/what changed permissions
│
├─ TEST:
│  └─ Compare current permissions to documented baseline
│     → If permissions are overly permissive → HYPOTHESIS CONFIRMED
│     → If permissions match baseline → HYPOTHESIS REJECTED
│
└─ REMEDIATION (If Confirmed):
   ├─ Restore permissions to documented baseline
   ├─ Contact app vendor: "Did your Friday deployment modify document permissions?"
   ├─ If YES → Demand app hotfix or rollback
   └─ If NO → Continue with other hypotheses

────────────────────────────────────────────────────────────────

HYPOTHESIS 2: Copilot Service Account Over-Privileged (30% likely)
│
├─ EVIDENCE TO COLLECT:
│  ├─ Copilot service account identity (Azure AD app registration)
│  ├─ Service account group memberships
│  ├─ Service account explicit permissions on document repository
│  ├─ Service account permissions history (when was it granted?)
│  └─ Comparison to documented baseline
│
├─ TEST:
│  └─ Query: Does Copilot use user's identity or service account identity?
│     → If service account → Check its permissions
│     → If user's identity → HYPOTHESIS REJECTED
│
│  └─ Query: Can service account access all matters?
│     → If YES → HYPOTHESIS CONFIRMED
│     → If NO → HYPOTHESIS REJECTED
│
└─ REMEDIATION (If Confirmed):
   ├─ Reduce service account to minimum necessary permissions
   ├─ Implement RLS at application level
   ├─ Test: Service account can query, but RLS filters results
   └─ Document new baseline

────────────────────────────────────────────────────────────────

HYPOTHESIS 3: Copilot RLS Not Working (15% likely)
│
├─ EVIDENCE TO COLLECT:
│  ├─ Copilot RLS configuration (enabled? disabled?)
│  ├─ RLS applied to which data sources?
│  ├─ Any known issues with this Copilot version?
│  ├─ RLS bypass CVEs or vulnerabilities?
│  └─ Copilot version and patch level
│
├─ TEST:
│  └─ Query Copilot as [authorized user] vs. [unauthorized user]
│     → Same results = HYPOTHESIS CONFIRMED (RLS not filtering)
│     → Different results = HYPOTHESIS REJECTED (RLS is working)
│
└─ REMEDIATION (If Confirmed):
   ├─ Enable RLS in Copilot settings
   ├─ Configure RLS for all data sources
   ├─ Test functionality
   ├─ Update Microsoft support (if it's a known issue)
   └─ Apply patches if available

────────────────────────────────────────────────────────────────

HYPOTHESIS 4: User Accidentally in Wrong Group (10% likely)
│
├─ EVIDENCE TO COLLECT:
│  ├─ Current group membership for paralegal
│  ├─ Group membership history (changes last 48 hours)
│  ├─ Group membership before/after migration or enrollment
│  └─ Identify any unexpected groups
│
├─ TEST:
│  └─ Is user a member of a group with matter access?
│     → If YES (and shouldn't be) → HYPOTHESIS CONFIRMED
│     → If NO → HYPOTHESIS REJECTED
│
└─ REMEDIATION (If Confirmed):
   ├─ Remove user from inappropriate group
   ├─ Verify user is only in authorized groups
   ├─ Test: Re-query Copilot (should not see matter now)
   └─ Identify how user was added (Windows 11 migration? Intune policy?)

────────────────────────────────────────────────────────────────

HYPOTHESIS 5: Intune Policy Grants Unexpected Access (5% likely)
│
├─ EVIDENCE TO COLLECT:
│  ├─ All Intune policies assigned to user or device
│  ├─ Policy details: Does any policy modify group membership?
│  ├─ Policy deployment history (when applied?)
│  ├─ Security baselines applied
│  └─ Certificate or credential policies
│
├─ TEST:
│  └─ Does any Intune policy dynamically add user to a group?
│     → If YES → HYPOTHESIS CONFIRMED
│     → If NO → HYPOTHESIS REJECTED
│
└─ REMEDIATION (If Confirmed):
   ├─ Identify the problematic policy
   ├─ Modify policy to exclude this user (or remove policy)
   ├─ Sync policy changes to device
   ├─ User loses group membership (and access)
   └─ Document policy change for future reference
```

---

## CRITICAL SUCCESS FACTORS FOR THIS INVESTIGATION

### **What Makes This Investigation Succeed (What NOT to Do)**

| ✅ DO | ❌ DON'T |
|---|---|
| **Preserve all evidence immediately** – Don't wait for formal request | **Don't touch affected machine** – Preserves logs and cache |
| **Separate investigation from remediation** – Fix comes after root cause | **Don't fix the problem immediately** – May destroy evidence needed to understand what happened |
| **Treat as potential breach until proven otherwise** | **Don't assume "Copilot bug"** – Dangerous underestimation |
| **Involve Legal/Compliance from minute 0** | **Don't try to contain this quietly** – Will be discovered; better to be transparent |
| **Document chain of custody for all evidence** | **Don't let anyone "clean up" systems** – Cleanup destroys evidence |
| **Escalate to CIO/CISO immediately** | **Don't treat this as IT helpdesk issue** – Requires security expertise |
| **Scope the impact (is it 1 user or many?)** | **Don't assume it's isolated to this user** – Common access control failures affect cohorts |
| **Test hypotheses with data before acting** | **Don't rely on guesses** – Data-driven investigation only |

---

## SUMMARY & NEXT STEPS

### **What We Know (100% Confirmed)**
- A paralegal reported seeing unauthorized client matter information in Copilot
- This indicates an access control failure (not a Copilot bug)
- Evidence must be preserved immediately

### **What We Don't Know (Must Investigate)**
- Root cause (app, permissions, policy, RLS)
- Scope (1 user or many?)
- Whether data was exfiltrated
- Whether this is a reportable breach

### **Immediate Actions (Next 30 Minutes)**
1. Disable Copilot access for affected user
2. Preserve Copilot chat history and evidence
3. Escalate to Security, Compliance, Legal
4. Begin parallel investigation on 5 hypotheses
5. Activate incident response protocol

### **Investigation Milestones**
- **5 min:** Evidence preserved; user isolated
- **15 min:** Root cause hypothesis identified
- **30 min:** Preliminary investigation underway
- **2 hours:** Root cause confirmed
- **4 hours:** Remediation plan approved
- **EOD:** Remediation completed and validated

---

**Prepared by:** DWP Service Desk Engineer  
**Classification:** CONFIDENTIAL – Security/Legal Use Only  
**Next Review:** Every 30 minutes until resolved  
**Escalation Contact:** [CISO/Security Lead] [Phone/Email]

