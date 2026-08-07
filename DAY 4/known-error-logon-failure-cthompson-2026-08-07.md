Symptom     : User FINBRIDGE\cthompson cannot log in. During the incident window, interactive sign-in attempts failed with bad password and then account locked out messages.

Cause       : Repeated invalid credential submissions for FINBRIDGE\cthompson triggered account lockout policy at 08:44:56. The failures were seen from DESKTOP-FB022 and continued from a second source (10.10.8.112), consistent with stale/incorrect credentials being retried.

Scope       : Impact was limited to one user account (FINBRIDGE\cthompson) in the observed incident window (08:44-09:12). No other affected users were in scope facts.

Workaround  : Restore access by unlocking FINBRIDGE\cthompson, then stop further bad-password retries before the next sign-in attempt. Immediate containment is to update or remove saved credentials on DESKTOP-FB022 and on the source at 10.10.8.112.

Permanent fix: Identify the process/device at 10.10.8.112 submitting Kerberos pre-auth with wrong password and correct its stored credential. Keep credentials aligned across all user endpoints/services so lockout threshold is not retriggered.

How to spot it: Look for this sequence: Event 4776 (08:44:01, 0xC000006A wrong password) and repeated Event 4625 interactive failures (08:44:03, 08:44:28, 08:44:55), followed by Event 4740 lockout at 08:44:56 and Event 4625 type 7 unlock failure at 08:45:10 (account locked out). Confirm secondary source behavior with Event 4771 at 08:45:44, 08:46:01, and 08:46:33 showing 0x18 wrong password from 10.10.8.112.
