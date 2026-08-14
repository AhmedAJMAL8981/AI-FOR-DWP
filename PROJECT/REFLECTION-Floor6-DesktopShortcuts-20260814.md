# Reflection: Floor 6 Desktop Shortcuts / Profile Incident
Date: 2026-08-14
Scope: Floor 6 Legal

## Initial Hypothesis
The first working assumption was that the Friday document management app deployment directly removed user desktop shortcuts across Floor 6.

## Evidence That Disproved It
- No installation or deployment evidence was provided that proved the app deleted or modified desktop shortcuts.
- No profile service event evidence was initially provided to confirm a profile corruption path.
- Only one direct user report was confirmed at the start, which was insufficient to prove a floor-wide app-caused failure.
- Because the sign-in and Copilot incidents were occurring in parallel, timing overlap alone could not establish causation.

## New Evidence Discovered
- The incident was isolated as a post-login desktop state symptom, separate from authentication failure and separate from the Copilot security stream.
- The investigation established the key diagnostic branches: profile load failure (Event IDs 1509/1516), policy or app impact, and migration artifact.
- Evidence requirements were clarified: compare user desktop vs Public desktop shortcut state, check Start Menu shortcut presence, and validate profile path for temporary profile indicators.
- The runbook introduced explicit decision gates to prevent premature app rollback without confirming evidence.

This evidence was significant because it changed the investigation from assumption-driven rollback to branch-based diagnosis with objective go/no-go criteria.

## Correct Conclusion
The exact root cause could not be conclusively proven from the initial evidence set. The most likely explanation is a post-change profile or policy side effect in the Windows 11/Intune cohort, with app contribution remaining a conditional hypothesis that requires corroborating logs before action.

## Lesson Learned
- Enforce evidence gates before remediation: do not roll back app assignments unless profile, policy, and deployment evidence supports the app path.
- Separate concurrent incidents early to avoid cross-stream bias and false causality.
- Require post-migration desktop baseline validation (user desktop, Public desktop, and Start Menu comparison) before full cohort release.
- Capture profile and policy telemetry first, then act; this reduces unnecessary change risk and improves RCA quality.
- Use pilot-first remediation and wave-based rollout to limit impact if the initial fix is incorrect.