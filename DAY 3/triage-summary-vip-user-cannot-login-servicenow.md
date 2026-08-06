# Triage Summary

## Summary (one line)
VIP, non-technical user is unable to log into ServiceNow (to confirm exact symptom — login failure, error message, or access issue).

## Impact (who/how many/business urgency)
- Who is affected: Single user, flagged as VIP (to confirm VIP designation and reason).
- How many are affected: Unknown whether this is isolated to this user or affects others (to confirm).
- Business urgency: High (to confirm) — VIP status typically drives expedited handling, but no confirmed business-critical deadline stated.

## Known Facts
- User is described as non-technical.
- User cannot log in to ServiceNow.
- User is flagged as VIP.

## Missing Information to Gather
- Exact error message or behaviour observed when attempting to log in (to confirm).
- Login method used — SSO, direct ServiceNow credentials, MFA prompt, etc. (to confirm).
- Whether this is a new issue or has occurred before (to confirm).
- Device and location being used (corporate laptop, VPN/remote, on-site) (to confirm).
- Time the issue started and whether it correlates with a password expiry, account lockout, or recent change (to confirm).
- Whether the user's account is active, unlocked, and correctly licensed/provisioned in ServiceNow (to confirm).
- Whether other users are experiencing the same issue (to confirm).
- Any recent changes to identity provider, MFA, or ServiceNow configuration (to confirm).

## Likely Category
Access/Account — Application Login Issue (ServiceNow) (to confirm).

## First Diagnostic Step
Contact the user (or have desk-side support assist, given non-technical status) to capture the exact error message and login method, then check the user's account status (locked/disabled/password expiry) and MFA/SSO logs in the identity provider and ServiceNow admin console.
