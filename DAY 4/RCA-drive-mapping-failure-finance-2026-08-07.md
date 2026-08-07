# Root Cause Analysis (RCA) - Finance Shared Drive Mapping Failure

## 1) Incident Details
- **Incident ID:** pending confirmation
- **Detected:** 2026-08-07 08:00 (scope states "Since: 08:00, today")
- **Escalated:** pending confirmation
- **Resolved:** pending confirmation

## 2) Scope and Affected/Unaffected Population
### Affected
- **Users:** 45 users
- **Business group:** Finance team
- **Devices:** `DESKTOP-FB*`
- **Directory scope:** `OU=Finance`
- **Symptom:** Unable to access shared drives (including failed assignment of drive letter `S:`)

### Unaffected
- **Confirmed unaffected users/devices:** pending confirmation (not provided in scope facts)

### Key comparison that isolated the cause
- **Comparison 1 (runtime context):** Historical model = GPO logon script in **USER** context; current model (after migration) = Intune script in **SYSTEM** context.
- **Comparison 2 (log evidence):** Group Policy processed successfully at `08:00:06`, while script execution failed at `08:00:03` in SYSTEM context.
- **Comparison 3 (cross-endpoint reproducibility):** `DESKTOP-FB041` and `DESKTOP-FB022` show the same failure pattern.

## 3) Detailed Timeline (Chronological)
- **2024-03-14 23:30** - Change implemented: drive mapping moved from GPO logon script (USER context) to Intune PowerShell script (SYSTEM context); script not updated for SYSTEM-context behavior (per migration change log).
- **2026-08-07 08:00** - Incident symptom active: Finance users cannot access shared drives.
- **2026-08-07 08:00:01** (`DESKTOP-FB041`, Intune Management Extension Log) - `ScriptRunner (Info)`: Executing `Map-FinBridgeDrives.ps1`.
- **2026-08-07 08:00:02** (`DESKTOP-FB041`, Intune Management Extension Log) - `ScriptRunner (Info)`: Script context is `SYSTEM account`.
- **2026-08-07 08:00:03** (`DESKTOP-FB041`, Intune Management Extension Log) - `ScriptRunner (Warning)`: Network path `\\finbridge-fs01\Finance` not accessible from SYSTEM context at execution time.
- **2026-08-07 08:00:03** (`DESKTOP-FB041`, Intune Management Extension Log) - `ScriptRunner (Error)`: Script failed, exit code `1`, error `Network name cannot be found`.
- **2026-08-07 08:00:04** (`DESKTOP-FB041`, Intune Management Extension Log) - `ScriptRunner (Info)`: No retry configured.
- **2026-08-07 08:00:05** (`DESKTOP-FB041`, System Log) - `Service Control Manager Event 7036`: Workstation service entered running state.
- **2026-08-07 08:00:06** (`DESKTOP-FB041`, System Log) - `GroupPolicy Event 1500`: Group Policy processed successfully.
- **2026-08-07 08:00:07** (`DESKTOP-FB041`, System Log) - `Ntfs Event 98 (Warning)`: Could not map drive letter `S:`; letter not assigned.
- **2026-08-07 (time not provided)** - Additional endpoint `DESKTOP-FB022` observed with same pattern.

## 4) Root Cause Statement (Single Sentence)
The incident was caused by migrating drive mapping execution from USER-context GPO logon processing to SYSTEM-context Intune script execution without updating the script/assignment for SYSTEM-context UNC access and timing requirements, resulting in failed access to `\\finbridge-fs01\Finance` and unassigned user drive mappings.

## 5) Technical Root Cause Explanation
The prior implementation executed during user logon in USER context, where user session credentials and user-scoped drive mapping behavior were available. After migration, `Map-FinBridgeDrives.ps1` executed in SYSTEM context (confirmed at `08:00:02`), and the log explicitly states the UNC path was not accessible from SYSTEM context at execution time (`08:00:03`). The script then failed with `Network name cannot be found` and exit code `1`, and because no retry was configured (`08:00:04`), the initial failure persisted rather than self-correcting later in the boot/login sequence. Supporting timing evidence shows Workstation service readiness (`08:00:05`) occurred after the failure event, reinforcing that execution context and startup timing together caused mapping failure and left `S:` unassigned (`08:00:07`).

## 6) Contributing Factors
- Script executed in SYSTEM context rather than USER context after migration.
- Script/solution not updated to account for SYSTEM-context limitations for UNC drive mapping at login time.
- No retry logic configured after first failure.
- Execution occurred before Workstation service running state in observed sequence.
- Broad targeting to Finance scope (`DESKTOP-FB*`, `OU=Finance`) amplified impact.

## 7) Impact Summary
- **User impact:** 45 Finance users unable to access required shared drives.
- **Business impact:** Finance operations relying on shared drive access were disrupted (specific process-level impacts pending confirmation).
- **Geographic/site impact:** pending confirmation (not provided in scope facts).
- **Duration to resolution:** pending confirmation.

## 8) Corrective Actions Taken
- **Evidence review completed:** Intune Management Extension and System logs reviewed for `DESKTOP-FB041`; same pattern validated on `DESKTOP-FB022`.
- **Cause isolation completed:** GP processing fault excluded via Event 1500 success; migration context mismatch identified as primary cause chain.
- **Implementation/execution of remediation:** pending confirmation (not provided in scope facts).

## 9) Preventive Actions (Owner and Target Date)
> Note: Owners and dates are not present in scope facts and are marked pending confirmation.

1. **Action:** Re-implement drive mapping in USER context (or equivalent user-session-targeted method) for Finance devices.
   - **Owner:** pending confirmation
   - **Target date:** pending confirmation

2. **Action:** Add retry/delay logic to avoid startup race conditions for network-dependent mapping.
   - **Owner:** pending confirmation
   - **Target date:** pending confirmation

3. **Action:** Add pre-deployment validation checklist for execution context (USER vs SYSTEM) for endpoint script migrations.
   - **Owner:** pending confirmation
   - **Target date:** pending confirmation

4. **Action:** Add pilot/ring deployment and rollback criteria for future drive-mapping changes.
   - **Owner:** pending confirmation
   - **Target date:** pending confirmation

## 10) Lessons Learned
- Execution context changes (USER to SYSTEM) are a high-risk design change for logon-dependent resource access and must be explicitly tested.
- Successful Group Policy processing does not validate success of separately managed Intune SYSTEM-context scripts.
- For network-dependent startup automation, first-attempt-only logic is fragile; retry strategy is necessary.
- Cross-endpoint pattern checking (`DESKTOP-FB041`, `DESKTOP-FB022`) quickly distinguishes isolated device issues from scope-wide deployment defects.

## 11) Confirmation Status
- Root cause is supported by direct scope evidence and change history.
- Resolution status, final mitigation owner, and completion dates remain **pending confirmation**.