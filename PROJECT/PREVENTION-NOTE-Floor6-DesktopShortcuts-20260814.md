# Prevention Note: Floor 6 Desktop Shortcuts / Profile Symptom

## Process change
**Post-Migration Desktop Baseline Check**

## What it is
After Windows 11 migration or Intune enrollment, the desktop state for one pilot user must be compared with the saved baseline for that user before the rollout is approved for the rest of Floor 6. The check must confirm the user profile loads normally and the expected desktop shortcut set is still present.

## Why this would have caught it
This incident showed up as missing shortcuts after recent platform changes. A post-migration baseline check would have flagged the missing desktop items, a temporary profile, or a policy-driven desktop reset before the change reached Monday morning use.

## How to run it
1. Keep a known-good shortcut baseline for a pilot user.
2. After migration or enrollment, compare the user desktop, Public desktop, and Start Menu shortcut list to that baseline.
3. Check for profile errors during the first post-change sign-in.
4. Do not release the change to the wider floor until the pilot desktop matches the baseline.

## Owner
Desktop engineering / imaging owner
