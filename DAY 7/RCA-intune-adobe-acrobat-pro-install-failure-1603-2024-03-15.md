# Root Cause Analysis (RCA): Intune Adobe Acrobat Pro v23.6 Install Failure (Return Code 1603)

## Incident Summary
On 2024-03-15, an Intune Win32 deployment for **Adobe Acrobat Pro v23.6** failed during installation in `SYSTEM` context. The initial attempt and the first scheduled retry both failed with MSI return code **1603**. Post-install detection also failed because the configured registry path was not found.

## Evidence Extract (Provided)
- Install package: `AdobeAcrobatPro.intunewin`
- Install command: `msiexec /i AcrobatPro.msi /quiet`
- Return code: `1603` (initial and retry)
- Detection key queried: `HKLM\\SOFTWARE\\Adobe\\Acrobat Reader\\23.0`
- Detection result: `Not detected`

## Sequence of Events (Plain English)
1. `10:01:00` - Intune agent started Adobe Acrobat Pro install.
2. `10:01:01` - Install context confirmed as SYSTEM.
3. `10:01:03` - MSI silent install command launched.
4. `10:01:44` - Installer returned 1603, app marked failed.
5. `10:01:45` - Detection checked Acrobat Reader registry path; value not found.
6. `10:01:47` - Retry scheduled for 60 minutes.
7. `11:01:48` - Retry attempt 1 started with same command.
8. `11:02:31` - Retry failed again with 1603.

## What 1603 Means in This Context
MSI error `1603` is a generic fatal failure indicating installation did not complete successfully. It does not by itself identify the precise failing custom action. Additional MSI verbose logs are required for definitive installer-level attribution.

## Most Likely Root Cause
**Most likely root cause:** Misaligned Win32 app configuration (Acrobat Pro payload paired with Acrobat Reader detection definition), combined with an unresolved MSI execution failure surfaced as code 1603.

### Why this is the leading conclusion
- The app identity is **Acrobat Pro**, but detection rule checks **Acrobat Reader** registry path.
- This mismatch is direct evidence of packaging/configuration inconsistency.
- Repeated 1603 across retries indicates an unaddressed installer precondition/conflict rather than transient network delay.

**Confidence:** Medium.

### Why confidence is not high
- No MSI verbose log (`/L*v`) or endpoint-side installer trace was provided.
- Without custom action details, exact installer fault (conflict, pending reboot, transform/license prerequisite, permissions edge case) cannot be singled out with certainty.

## 5 Whys
1. Why did Acrobat Pro deployment fail in Intune?
Because MSI returned fatal code 1603 and app detection did not pass.

2. Why did detection not pass?
Because detection checked `Acrobat Reader` registry path, which was not present.

3. Why was detection targeting Reader for a Pro deployment?
Because the Win32 app definition appears to be misconfigured or reused from a different Adobe package template.

4. Why did retries continue to fail?
Because the same install command/configuration was retried without correcting underlying installer or detection issues.

5. Why did this reach active deployment?
Because pre-production packaging validation likely did not fully verify alignment between payload, silent command, and detection rule in SYSTEM context.

## Impact
- Application remained unavailable for targeted devices/users.
- Intune agent entered retry cycle, increasing deployment noise and delaying remediation.

## Corrective Actions
1. Update detection to Acrobat Pro-specific evidence (validated on reference endpoint).
2. Rebuild/revalidate Intune package metadata and command line from Adobe enterprise packaging guidance.
3. Add supersedence or pre-uninstall logic for conflicting Adobe editions/versions.
4. Run pilot deployment with MSI verbose logging enabled and review failure detail before broad assignment.
5. Add packaging quality gate: payload-detection-context triad validation required before production publish.

## Preventive Controls
- Maintain Adobe app packaging baseline templates separated by product family (Reader vs Pro vs Standard).
- Require peer review checklist for Win32 apps:
  - Product name matches installer payload.
  - Detection path matches intended product.
  - SYSTEM-context install test completed.
  - Rollback and supersedence defined.
- Keep first-wave assignment limited to pilot ring with success threshold before expansion.

## Open Items
- Collect and review MSI verbose log from failing endpoint(s).
- Confirm whether conflicting Adobe products were present before install.
- Confirm whether pending reboot state existed at failure time.

## Final RCA Statement
The incident was most likely caused by a Win32 app packaging/configuration defect in Intune, evidenced by mismatch between Acrobat Pro deployment intent and Acrobat Reader detection logic, with concurrent unresolved MSI fatal failure (1603). The exact installer custom action failure remains pending until verbose MSI logs are analyzed.