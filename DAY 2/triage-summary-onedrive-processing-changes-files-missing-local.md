# Triage Summary - T-1007

## Summary (one line)
OneDrive is stuck on "processing changes" after migration, with files missing locally.

## Impact (who/how many/business urgency)
- Who is affected: At least one reported user post-migration (to-verify).
- How many are affected: Single known report currently; wider migration cohort impact unknown (to-verify).
- Business urgency: High (to-verify) due to potential loss of local file availability and workflow disruption.

## Known Facts
- Ticket reference: T-1007.
- Symptom: OneDrive status remains "processing changes".
- Additional symptom: Files are missing locally.
- Timing/context: Issue reported after migration.

## Missing Information to Gather
- Whether files are visible in OneDrive on the web versus missing only on local device (to-verify).
- Approximate count/types of missing files and affected folders (to-verify).
- Whether issue affects one device/profile only or multiple endpoints for the same user (to-verify).
- Current OneDrive client status/sign-in state and last successful sync time (to-verify).
- Available local disk space and Files On-Demand behavior for affected folders (to-verify).
- Whether Known Folder Move or library path changes occurred during migration (to-verify).
- Whether there are concurrent migration incidents with similar OneDrive sync symptoms (to-verify).
- Exact time issue started and any user actions immediately before symptom began (to-verify).

## Likely Category
M365/OneDrive - Post-Migration Sync and Local File Availability Issue (to-verify).

## First Diagnostic Step
Determine data location first by confirming whether missing files are present in OneDrive web; this separates sync/client issues from potential data migration issues before remediation steps.