# Analysis with Solutions - Intune Win32 App Install Failure (Adobe Acrobat Pro v23.6)

## 1) Symptom and Affected Scope
- **Symptom:** Intune Win32 app install for **Adobe Acrobat Pro v23.6** fails with return code **1603**.
- **Install context:** `SYSTEM`.
- **Install command:** `msiexec /i AcrobatPro.msi /quiet`.
- **Observed pattern:** Initial install failed, then retry after 60 minutes failed with the same code.
- **Evidence source:** Intune Management Extension / AgentExecutor log excerpt provided.

## 2) Reconstructed Timeline
- `10:01:00` Agent starts app install for Adobe Acrobat Pro v23.6.
- `10:01:01` Install context confirmed as SYSTEM.
- `10:01:03` Install command executed: `msiexec /i AcrobatPro.msi /quiet`.
- `10:01:44` Installer returns `1603` (fatal install failure).
- `10:01:45` Detection rule checks `HKLM\\SOFTWARE\\Adobe\\Acrobat Reader\\23.0` and returns not found.
- `10:01:47` App result marked failed; retry scheduled in 60 minutes.
- `11:01:48` Retry attempt 1 starts with same command.
- `11:02:31` Retry attempt 1 returns `1603` again.

## 3) Ranked Probable Causes (Most Likely First)

### Cause 1 (Most likely): Packaging/detection mismatch between "Acrobat Pro" app and "Acrobat Reader" detection key
**Why it is probable:**
- App is named **Adobe Acrobat Pro v23.6**, but detection checks **Acrobat Reader** path (`HKLM\\SOFTWARE\\Adobe\\Acrobat Reader\\23.0`).
- This mismatch strongly indicates the Win32 app package may have been cloned or misconfigured.
- Even if installation succeeds, this detection rule can still mark app as failed and trigger repeated retries.

**Fastest check to confirm/eliminate:**
- In Intune app config, compare product intent (Acrobat Pro) vs detection rule path/value.
- Validate registry footprint expected for Acrobat Pro on a known-good reference machine.

---

### Cause 2: Existing Adobe product/version conflict causes MSI 1603
**Why it is probable:**
- `1603` commonly occurs when installing an MSI over incompatible/superseded Adobe components without proper uninstall/supersedence logic.
- Acrobat family products (Reader/Standard/Pro) often conflict if major versions or channels overlap.

**Fastest check to confirm/eliminate:**
- Review endpoint for existing Adobe Reader/Acrobat products and versions before install.
- Re-run installer with verbose logging (`/L*v`) and inspect for product code conflict/custom action failure.

---

### Cause 3: Required reboot or pending installer transaction blocks MSI execution
**Why it is probable:**
- Repeated 1603 exactly one hour apart can indicate unresolved system installer state.
- Pending reboot or in-progress MSI transaction frequently surfaces as generic 1603 in Intune logs.

**Fastest check to confirm/eliminate:**
- Check reboot-pending indicators and Windows Installer service state.
- Reboot test endpoint and retry deployment once before broad rollout.

---

### Cause 4: Installer command is incomplete for vendor prerequisites/transforms
**Why it is probable:**
- Command uses only `/i ... /quiet` with no transform (`TRANSFORMS=`), language, serial/licensing, or vendor bootstrap sequence.
- Acrobat enterprise packages often require Adobe Customization Wizard output or specific deployment switches.

**Fastest check to confirm/eliminate:**
- Validate package deployment guide used to build `AcrobatPro.msi`.
- Test full vendor-recommended silent command line locally in SYSTEM context.

---

### Cause 5: Content/package integrity issue in `AdobeAcrobatPro.intunewin`
**Why it is probable:**
- If MSI path/content extraction is malformed, install can fail quickly with 1603.
- Lower rank because command appears to find MSI and runs for ~40 seconds, suggesting execution started.

**Fastest check to confirm/eliminate:**
- Rebuild `.intunewin` from clean source and verify `install/uninstall` command paths.
- Compare hash/source consistency between packaging machine and uploaded content.

## 4) Root Cause Position
**Primary issue indicated by current evidence:**
- The deployment configuration shows a **high-probability app-definition mismatch**: Acrobat Pro deployment paired with Acrobat Reader detection logic.

**Important note:**
- Provided log excerpt **proves install-time failure 1603**, but does not include MSI verbose logs required to name the exact failing custom action. Therefore, installer-level root cause remains **pending confirmation**.

## 5) Recommended Solutions

### Immediate corrective actions
1. Correct detection rule to Acrobat Pro-specific registry/file evidence.
2. Create a pilot assignment to 1-3 test devices before broad rollout.
3. Capture MSI verbose log in SYSTEM context:
   `msiexec /i AcrobatPro.msi /quiet /L*v C:\\ProgramData\\Microsoft\\IntuneManagementExtension\\Logs\\AcrobatPro-install.log`
4. Remove conflicting Adobe products or configure proper supersedence/uninstall behavior.
5. Retry install after reboot on pilot device to clear pending transaction state.

### Medium-term hardening
- Standardize Win32 packaging checklist:
  - App identity matches install payload.
  - Detection rule aligns to installed product (not sibling product family).
  - Supersedence defined for previous Adobe channels/editions.
  - SYSTEM-context validation completed pre-production.
  - Verbose log capture baked into pilot phase.

## 6) Workaround While Fix Rolls Out
- For high-priority users, deploy Adobe Reader separately (if business-acceptable) while Acrobat Pro package is remediated.
- Alternatively, perform controlled manual installation on a small critical cohort with validated command line, then onboard corrected Intune package.

## 7) Validation Criteria (Exit Conditions)
- Intune install status shows success on pilot devices.
- Detection rule returns detected for Acrobat Pro.
- No repeat 1603 in AgentExecutor logs across two policy cycles.
- No retry loop observed after first successful install.
