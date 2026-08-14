# L2/L3 KB: Copilot Unauthorized Data Access - Floor 6 Legal
**v 1.0, 07/08/2026, status : Draft**

## Background
Microsoft 365 Copilot is used by Floor 6 Legal to search, summarize, and surface content from approved enterprise data sources such as SharePoint, Exchange, Teams, and any connected document management or case management system. In a legal environment, this matters because the platform must respect matter-level and document-level permissions at all times; if Copilot returns content outside a user's assigned matter scope, the firm may have exposed confidential client data, privileged material, or work product.

This incident stream is security-related, not a normal Copilot support issue. Treat it separately from login, performance, desktop, or profile incidents.

## Symptom
The user report is typically: "Copilot showed me client matter content I should not be able to see," or "Copilot returned information from a matter I am not assigned to." The engineer may observe one or more of the following:

- A Floor 6 Legal user can describe a matter, client name, file title, or document excerpt that should not be visible to them.
- The same user may report the issue appeared in Copilot chat, Copilot search, or a Copilot-generated summary.
- Other Floor 6 users may or may not report the same behavior, but one confirmed report is enough to treat the issue as a potential disclosure event.
- The user may be able to access Copilot normally, so the issue is not a login failure or device problem.

## Root Cause
The technical root cause is an access-control failure in the Copilot data path: Copilot returned content from a source the user was not authorized to read. In practice, this is usually one of these failure modes:

1. The underlying matter folder, SharePoint site, or case management record has overly permissive ACLs or inherited permissions.
2. The Copilot connector or service account is over-privileged and can query content beyond the user's matter assignment.
3. Row-level security or document-level filtering is missing, disabled, or bypassed in the connected data source.
4. A recent document management deployment changed permissions or reindexed content in a way that exposed restricted matter data.

The confirming evidence is the combination of:

- The user report naming a specific confidential matter.
- Microsoft 365 / Purview audit records showing the user queried Copilot at the same time.
- Entra and group membership evidence showing the user was not assigned to that matter.
- Document repository or case management audit logs showing the exposed item was not meant for that user.
- If present, a connector/service-account audit trail showing the connector had broader access than the user.

If those records line up, the issue is not "Copilot being wrong"; it is a permissions or connector configuration failure that allowed restricted data to be returned.

## Detection
Confirm this is the issue before making changes. Do not rely on the user story alone.

### 1. Preserve the user evidence first
Path: affected device and user Copilot session

What to look for:
- Copilot chat history or browser history showing the exact prompt and response.
- Document names, file paths, matter names, or client names in the returned content.
- Timestamp of the disclosure.

Expected result:
- You have a timestamped record of what the user saw before any containment action changes the state.

### 2. Check Microsoft Purview Unified Audit Log
Path: Microsoft Purview portal > Audit > Search

What to search:
- User = affected Floor 6 user.
- Time range = reported time plus at least 24 hours.
- Workloads = Copilot, SharePoint, Exchange, Teams, and any connected app used by the firm.

What to look for:
- Copilot interaction records around the reported time.
- File accessed, file previewed, file downloaded, search, or message read actions tied to the same matter.
- The source system that Copilot queried.

Important note:
- There is no single Windows Event ID for a Copilot disclosure. The primary evidence lives in Microsoft 365 audit data, not Event Viewer.

### 3. Check Entra sign-in and audit logs
Path: Entra admin center > Monitoring & health > Sign-in logs
Path: Entra admin center > Monitoring & health > Audit logs

What to look for:
- Sign-in logs for the user and for the Copilot-related app around the reported time.
- Unexpected device, IP, geo, or conditional access behavior.
- Audit log operations such as Add member to group, Remove member from group, Update user, Update application, Add app role assignment, or service principal changes.

Expected result:
- No evidence of a compromised account is required to confirm this incident, but you should confirm whether the user identity was normal and whether any permission change happened near the incident window.

### 4. Check matter permissions in the source system
Path: SharePoint admin center, document repository admin portal, or case management console used by Floor 6 Legal

What to look for:
- Folder/site/library ACLs for the exposed matter.
- Inherited permissions that include broad groups such as Everyone, Authenticated Users, Domain Users, or an overly broad legal cohort.
- Recent permission changes, especially on or after Friday's document management deployment.
- Service account or connector account membership that grants broader access than the user should have.

Expected result:
- The exposed matter should only be accessible to the authorized legal team. If the reporting user appears in the ACLs or if broad inheritance is present, you have identified the control failure.

### 5. Check the Copilot connector or document management integration
Path: Microsoft 365 admin center / Copilot settings, plus the document management app console or vendor admin portal

What to look for:
- Which data sources Copilot is connected to.
- Whether the connector uses user impersonation or a service account.
- Whether row-level security or matter-level filtering is enabled.
- Whether the Friday app deployment changed permissions, reindexed data, or changed the connector configuration.

Expected result:
- You can explain whether Copilot should have been constrained by user permissions. If it was querying through a broad service account or failed RLS, the incident is confirmed.

### 6. Endpoint corroboration only if needed
Path: affected workstation > Event Viewer

What to look for:
- Windows Security log Event ID 4624 for the user sign-in time.
- Windows Security log Event ID 4634 for logoff timing.
- Windows Security log Event ID 4688 if process auditing is enabled and you need to confirm browser or app launch around the Copilot session.

Expected result:
- Endpoint logs should only corroborate the timeline. They do not confirm the disclosure by themselves.

## Resolution
Follow this order so you preserve evidence while containing exposure.

### 1. Open or upgrade the ticket to P1-SECURITY
Path: ticketing system / incident queue

Expected result:
- Incident is tracked as a security event, and Security, Compliance, and Legal are attached as responders.

### 2. Disable Copilot for the Floor 6 Legal cohort
Path: Microsoft 365 admin center > Billing / Licenses or Entra admin center > Groups > Floor 6 Legal > Licenses

Action:
- Remove the Copilot SKU or Copilot service plan from the Floor 6 Legal group, or block the group through your tenant's approved licensing workflow.

Expected result:
- Floor 6 Legal users can no longer query Copilot while investigation continues.

### 3. Preserve the affected user session
Path: affected endpoint and browser session

Action:
- Export Copilot chat history, screenshots, and browser history.
- Do not clear caches, sign the user out of the browser, or reboot the device until evidence is captured.

Expected result:
- The report is preserved for audit and legal review.

### 4. Validate and narrow permissions in the source data system
Path: SharePoint admin center, document repository admin portal, or case management console

Action:
- Review the exposed matter ACL.
- Revert any overly broad folder or document permissions to the documented baseline.
- Remove unexpected group membership from the reporting user if they were added incorrectly.

Expected result:
- Only the authorized matter team retains access to the exposed content.

### 5. Review and remediate the Copilot connector
Path: Microsoft 365 admin center > Copilot settings / connectors, plus the document management app vendor console

Action:
- Confirm the connector uses least privilege.
- If the connector uses a service account, reduce its access to the minimum required.
- Disable or isolate the connector if it cannot enforce matter-level filtering.

Expected result:
- Copilot can only return content that the user is already allowed to see.

### 6. Re-scan the affected cohort
Path: Microsoft Purview portal > Audit > Search and the document repository audit console

Action:
- Search for other Floor 6 users with similar Copilot queries or access to the same matter.
- Review any other exposed matter folders for permission drift.

Expected result:
- You can confirm whether the issue is isolated to one matter or affects the wider Floor 6 Legal cohort.

## Verification
Use these checks to prove the fix worked.

1. Re-run the original Copilot query as a test account with no access to the exposed matter.
Expected result: Copilot does not return the confidential matter content.

2. Confirm the reporting user no longer has Copilot access if containment is still active.
Expected result: The user cannot launch or query Copilot for Floor 6 data while the hold remains in place.

3. Review Purview audit logs for the post-fix window.
Expected result: No new unauthorized Copilot returns, downloads, or file previews appear for the exposed matter.

4. Review the source system ACLs and audit trail.
Expected result: Only approved users and groups have access to the matter, and no recent unexpected permission changes remain.

5. Confirm Security and Legal sign off on containment.
Expected result: The incident remains open for investigation until Security approves closure of the containment action.

## Rollback
Only roll back if the containment action causes a worse business or security impact, and only with Security and Legal approval.

1. Restore Copilot access for a single pilot user only.
Path: Microsoft 365 admin center > Licenses / Entra group-based licensing

Action:
- Reassign the Copilot SKU to one approved pilot user in Floor 6 Legal.

Expected result:
- The pilot user can launch Copilot again.

2. Re-test the original query.
Expected result:
- If the unauthorized matter reappears, stop rollback immediately and keep Copilot disabled.

3. If the pilot is clean and approved, restore Copilot to the remaining Floor 6 Legal users in a controlled batch.
Expected result:
- Users regain Copilot access only after the source permissions and connector state are verified.

4. If the permission rollback worsens access scope, restore the previous ACL baseline from the exported evidence.
Path: SharePoint / document repository permission console

Expected result:
- The source system returns to the last known good access state.

## Preventive
Put the following controls in place so this does not recur:

- Require a permission-drift check after any document management deployment that touches Floor 6 Legal content.
- Require a Copilot connector review before enabling Copilot for any legal cohort.
- Enforce least privilege for any service account used by Copilot or the document management app.
- Add an audit rule for unexpected matter access, Copilot query spikes, and group membership changes in Entra and Purview.
- Maintain a known-good ACL export for each high-risk matter library so rollback is immediate.
- Use a small pilot group and a test matter before broad Copilot rollout to Legal.

## Related
- [Runbook: Floor 6 Copilot Unauthorized Data Access Concern](RUNBOOK-Floor6-Copilot-UnauthorizedAccess-20260814.md)
- [RCA - Floor 6 Copilot Unauthorized Data Access Concern](RCA-Floor6-Copilot-UnauthorizedAccess-20260814.md)
- [SECURITY ANALYSIS - Copilot Unauthorized Data Access – FinBridge Legal Department](SECURITY-ANALYSIS-CopilotUnauthorizedAccess-FinBridge-20260814.md)
- [INCIDENT TRIAGE REPORT - CRITICAL: Copilot Unauthorized Data Access – Client Matter Disclosure](INCIDENT-CRITICAL-CopilotDataAccess-UnauthorizedClientMatter-Floor6-20260814.md)
- [L1 Self-Service KB: Unexpected Copilot Content (Floor 6)](L1-KB-Copilot-Access-Concern-Floor6-20260807.md)