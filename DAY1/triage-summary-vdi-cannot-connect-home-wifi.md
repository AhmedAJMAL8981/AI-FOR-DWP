# Structured Triage Summary

## Summary (one line)
User cannot connect to VDI today; connection attempt returns "cannot connect" despite working on Friday, from home Wi-Fi.

## Impact (who/how many/business urgency)
- Affected user(s): 1 reported user (to confirm).
- Scope: Single-user access issue based on current report (to confirm).
- Business urgency: User cannot access VDI, which may block normal work activity (to confirm).

## known facts
- User reports inability to access "the vdi thing" today.
- Error shown is "cannot connect".
- User reports it worked on Friday.
- User is working from home on Wi-Fi.

## Missing information to gather
- Exact error wording/screenshot and where in the connection flow it appears (to confirm).
- Whether internet access is otherwise working on the same device (to confirm).
- Whether VPN is required for this VDI path and current VPN status (to confirm).
- Whether issue occurs on only one device/user profile (to confirm).
- Whether any recent password change/account lockout occurred (to confirm).
- Current date/time on endpoint and whether system clock is correct (to confirm).
- Whether user can reach the VDI portal URL in browser (to confirm).
- Any recent changes since Friday (client update, home router changes, endpoint restart status) (to confirm).

## likely catagory
- Remote access / VDI connectivity issue (to confirm).

## Suggest first diagnostic step
- Confirm basic connectivity path: ask user to verify internet is working, then retry VDI after confirming required VPN state; capture exact error text or screenshot at failure point (to confirm).
