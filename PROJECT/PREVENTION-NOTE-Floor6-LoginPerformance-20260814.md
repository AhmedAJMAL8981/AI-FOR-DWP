# Prevention Note: Floor 6 Login / Performance

## Process change
**Friday Floor 6 Sign-In Canary**

## What it is
Before any Windows 11, Intune, or floor-specific app change is released to the full Floor 6 Legal group, one pilot user must complete a successful sign-in on a pilot device after the change is applied. The pilot check must include a normal login, a policy refresh, and confirmation that the device reaches the desktop within the expected time.

## Why this would have caught it
The incident affected many users at once and appeared after a shared floor-wide change. A pilot sign-in check on Friday afternoon would have shown the login failure or severe delay before the change reached the whole floor, allowing the rollout to stop before Monday morning.

## How to run it
1. Apply the change only to the pilot ring first.
2. Have the pilot user sign in on a pilot device the same day.
3. Confirm the user can reach the desktop and open core apps.
4. If the pilot user fails or signs in slowly, block the rollout and investigate before wider release.

## Owner
Desktop / Intune release owner
