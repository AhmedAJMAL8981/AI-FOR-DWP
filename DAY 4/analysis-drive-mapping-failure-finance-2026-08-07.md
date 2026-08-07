# Analysis with Solutions - Finance Shared Drive Mapping Failure (2026-08-07)

## 1) Symptom and Affected Scope
- **Symptom:** Finance team cannot access shared drives.
- **Affected users/devices:** 45 users, all Finance users on `DESKTOP-FB*` devices in `OU=Finance`.
- **Start time:** 08:00 today.
- **Evidence sources:** Intune Management Extension Log and System Log.
- **Pattern confirmation:** Same failure pattern observed on `DESKTOP-FB041` and `DESKTOP-FB022`.

## 2) Ranked Probable Causes (Most Likely First)

### Cause 1 (Most likely): Drive-mapping script now runs in SYSTEM context, but mapping requires USER context/session credentials
**Why it is probable (scope evidence):**
- `08:00:02` Intune log explicitly states script context is **SYSTEM**.
- `08:00:03` warning states UNC path is not accessible **from SYSTEM context** at execution time.
- Prior change note confirms migration from GPO logon script (USER) to Intune script (SYSTEM) on `2024-03-14 23:30`.
- Prior change note also states script was **not updated** for SYSTEM context constraints.
- Broad impact across Finance endpoints is consistent with a deployment/context design issue.

**Fastest check to confirm/eliminate:**
- Execute the same mapping logic once as an affected Finance user and once as Local SYSTEM on the same endpoint; if USER succeeds and SYSTEM fails, this cause is confirmed.

---

### Cause 2: Script executes before required network/SMB client readiness at startup in SYSTEM context
**Why it is probable (scope evidence):**
- Script failure occurs at `08:00:03`.
- Workstation service enters running state at `08:00:05` (after the failure timestamp).
- UNC mapping dependency timing mismatch can cause immediate startup-time failures.

**Fastest check to confirm/eliminate:**
- Re-run the script in SYSTEM context a few minutes after startup on an affected device; if delayed run succeeds while startup run fails, timing dependency is confirmed.

---

### Cause 3: No retry configured, so a transient startup failure becomes a persistent access issue
**Why it is probable (scope evidence):**
- `08:00:04` Intune log: **No retry configured**.
- If first attempt happens during a non-ready state, absence of retry preserves failure for users.

**Fastest check to confirm/eliminate:**
- Add a controlled delayed second attempt in pilot scope; if second attempt maps successfully, no-retry behavior is a confirmed contributor.

---

### Cause 4: User-visible S: drive is not assigned because mapping attempt is not occurring in the interactive user context
**Why it is probable (scope evidence):**
- `Ntfs Event 98` at `08:00:07`: drive letter S: has not been assigned.
- Script is running as SYSTEM, not user logon context, following the migration model change.

**Fastest check to confirm/eliminate:**
- Compare drive mappings/session visibility between SYSTEM context and logged-on user context on an affected endpoint.

---

### Cause 5: UNC path name/reachability issue to `\\finbridge-fs01\Finance` at execution moment
**Why it is probable (scope evidence):**
- Error includes “Network name cannot be found.”
- Could indicate name/path reachability issues at the exact execution moment.
- Lower rank because migration/context evidence more directly explains observed behavior.

**Fastest check to confirm/eliminate:**
- Test DNS resolution and SMB port 445 reachability to `finbridge-fs01` at failure window under SYSTEM context.

## 3) Confirmed Root Cause
**Confirmed root cause (from scope facts):**
- The drive-mapping script was migrated from USER-context GPO logon execution to SYSTEM-context Intune execution (`2024-03-14 23:30`) and was not updated to handle SYSTEM context requirements. As a result, UNC mapping to `\\finbridge-fs01\Finance` fails at execution time, and S: is not assigned.

**Supporting confirmation in scope:**
- Intune log explicitly identifies SYSTEM context and explicitly states UNC path is not accessible from SYSTEM context.
- Change note explicitly documents that this migration/context mismatch exists.
- Group Policy processing is successful, ruling out GP processing fault as primary cause.

## 4) Recommended Solutions

### Immediate fix
- Move drive mapping execution back to USER context (or deploy equivalent user-context mechanism) for Finance users so UNC mapping uses user session credentials.
- Add a startup delay/retry guard in the mapping logic to avoid pre-network timing failures.

### Longer-term fix
- Refactor mapping approach for Intune-managed endpoints to a user-targeted method with explicit context handling and retry logic.
- Add rollout controls: pilot ring in Finance subset, logging for context/timing outcomes, and documented rollback path.
- Update change standards to require execution-context validation (USER vs SYSTEM) before production migration.

## 5) Workaround While Fix Rolls Out
- Provide users with direct UNC access attempt to `\\finbridge-fs01\Finance` from their logged-in session as a temporary access path.
- If needed, perform manual user-session drive mapping on critical users/devices pending confirmation of central fix deployment.

## 6) Validation Status
- Root cause statement is based on explicit scope evidence and change-note documentation.
- Any environment-specific dependency checks (for example DNS/SMB timing variability) remain **pending confirmation** until executed in live validation.