# Chained Prompt - Finance Mapped Drives (Post-Win11 Migration)

## Step 1 - Ticket
After Win11 migration, a Finance user's mapped drives (S: and P:) are missing every morning and must be remapped by hand. Logon script exists but seems not to run reliably post-upgrade.

## Step 2 - Triage Summary

**Summary:** Finance user's mapped drives (S: and P:) do not persist after Win11 migration and require manual remapping each morning; logon script appears unreliable post-upgrade.

**Impact:**
- Who is affected: One Finance user reported (to confirm if others affected).
- How many are affected: Single known report; broader Finance/team impact unknown (to confirm).
- Business urgency: Medium to High (to confirm) — daily manual remapping disrupts Finance workflows and risks delayed access to shared resources.

**Known facts:**
- Migration context: Issue began after Win11 upgrade.
- Symptom: Mapped drives S: and P: are missing at each morning logon.
- Workaround in use: User manually remaps drives daily.
- Logon script exists but is suspected to not run reliably since the upgrade.

**Missing info to gather:**
- User identifier/device name and whether issue occurs on one machine or multiple (to confirm).
- Exact logon script name/location and deployment method (GPO logon script, mapped drive via GPP, login script via Group Policy, etc.) (to confirm).
- Whether the script runs at all (check event logs/GPResult) or runs but fails partway (to confirm).
- Any error messages, event log entries, or script output captured at logon (to confirm).
- Network location paths for S: and P: and whether they're reachable manually after logon (to confirm).
- Whether Group Policy is applying correctly post-upgrade (gpresult /r or /h) (to confirm).
- Whether this affects only this user or other Win11-migrated Finance users (to confirm).
- Timing: does remapping fail every day or intermittently (to confirm).

**Likely category:** Post-Migration Logon Script / Group Policy - Mapped Drive Persistence Issue (to confirm).

**First diagnostic step:** Run `gpresult /r` (or `/h` for detailed HTML report) on the affected machine to confirm whether the relevant Group Policy/logon script is applying successfully post-upgrade, isolating a policy-application failure from a script execution failure.

## Step 3 - Likely Fixes (ranked)

### 1. Logon script not executing due to Group Policy timing/processing change on Win11
**Why likely:** Win11 upgrades commonly change GPO client-side extension behavior or introduce faster boot/async logon processing, which can cause logon scripts to run before network/drive resources are available, or to be skipped ("run once" caching, background refresh timing).
**Check to confirm:** Run `gpresult /r` (or `/h` for full report) on the affected machine after a normal morning logon and confirm whether the logon script GPO shows as applied; also check Event Viewer (Group Policy operational log) for script execution success/failure around logon time.
**Action if confirmed:** Adjust GPO settings to force synchronous logon script processing (e.g., enable "Always wait for the network at computer startup and logon") — to confirm this is the correct policy path for the environment before applying.

### 2. Network/profile not ready when script attempts to map drives (slow network provider ordering)
**Why likely:** Manual remapping works later in the session, suggesting connectivity exists but isn't ready at the exact moment the script runs — a common side effect of Win11's faster startup combined with unchanged network wait settings.
**Check to confirm:** Compare logon script timestamp (from GPO/script logging, if any, or Task Scheduler history) against network availability timestamp in Event Viewer (NETLOGON/DNS Client events) for the same login (to confirm logging exists to do this).
**Action if confirmed:** Add a delay or "wait for network" condition before the drive-mapping commands run — to confirm exact implementation once script content is reviewed.

### 3. Script itself is intact but its trigger (logon script path/GPO link) was altered or lost during migration
**Why likely:** Migrations that rebuild or re-image devices can disconnect a machine/user from a previously linked GPO, OU, or logon script path, especially if the device landed in a different OU post-Win11 upgrade.
**Check to confirm:** Verify in Active Directory Users and Computers (or Entra/Intune, to confirm which is authoritative) that the affected user/device object is in the expected OU and that the logon script GPO is still linked and scoped to that OU/security group.
**Action if confirmed:** Re-link the GPO or move the device/user object to the correct OU/group — to confirm exact remediation once AD structure is reviewed.

### 4. Persistent drive mappings not re-established because "Reconnect at sign-in" is not set for these drives
**Why likely:** If drives were originally mapped manually (not solely via script) prior to migration, a profile reset/new profile creation during Win11 upgrade could have dropped the "reconnect at logon" flag, leaving the logon script as the only mapping mechanism — and if that script has any partial failure, there's no fallback.
**Check to confirm:** Check the user's profile (old vs. new profile folder, e.g., `C:\Users\<user>.000`) to confirm whether a new profile was created during migration (to confirm profile type/version).
**Action if confirmed:** Ensure drives are mapped with persistence enabled and confirm profile migration didn't create a fresh profile losing prior settings — to confirm profile remediation approach once profile state is verified.

### 5. Script relies on a mapped drive letter/path conflict introduced by new device or OneDrive Known Folder Move changes
**Why likely:** Least probable given no reported errors pointing this way, but Win11 migrations sometimes bundle OneDrive KFM or storage sense changes that can interfere with drive letter assignment (to confirm if OneDrive/KFM was part of this migration).
**Check to confirm:** Check for drive letter conflicts or errors referencing S:/P: in OneDrive sync client logs or Disk Management (to confirm OneDrive is even in scope for this user).
**Action if confirmed:** Resolve conflicting drive letter/path assignment — to confirm exact fix once conflict source is verified.

## Step 4 - Closure Note

Resolved. Cause: Win11 upgrade changed Group Policy logon processing to asynchronous/fast startup, so the logon script attempted to map drives S: and P: before the network was ready, causing the mappings to fail silently each morning. Action: Modified Group Policy to enforce synchronous processing ("Always wait for the network at computer startup and logon"), ensuring the logon script runs only after network availability is confirmed. Preventive: Apply this GPO setting as standard baseline for all Win11-migrated devices to prevent recurrence of logon-script/drive-mapping failures caused by faster startup timing. User confirmed working.
