# End-User Communications for Copilot Tickets
Date: 2026-08-12

Use these messages as ready-to-send user updates in plain English.

## Ticket 1 - Finance lead cannot summarise Q3 board pack in SharePoint
Hello,

Thanks for reporting this. You can open the Q3 board pack, but Copilot may still be blocked from using it if the file has protection settings (for example, a sensitivity label or encryption) that limit AI processing.

### Next steps
1. Open the board pack in SharePoint and check whether a sensitivity label is applied.
2. If labeled/restricted, confirm with your information protection owner whether Copilot usage is allowed for that label.
3. Retry the same prompt after any label/policy update.
4. If it still fails, share the exact error text and file URL with IT for deeper review.

## Ticket 2 - New hire in Outlook sees no recent email context
Hello,

Thanks for flagging this. Since the account was created very recently, Copilot may not have finished indexing your mailbox context yet. This is common for new starters.

### Next steps
1. Confirm your mailbox and Copilot license are active in your work account.
2. Wait for indexing to complete, then try again later the same day.
3. Test with a simple prompt like "Summarize my latest unread emails".
4. If there is no improvement after the expected onboarding window, contact IT with screenshots.

## Ticket 3 - HR manager gets "I don't have access to that content"
Hello,

The message usually means Copilot cannot use that spreadsheet with your current access path, even if someone expects you to have access.

### Next steps
1. Open the exact salary review spreadsheet directly and confirm you can view it with your own account.
2. Ask the file owner to re-check your permissions on that specific file/folder.
3. Confirm whether a sensitivity label/policy is preventing Copilot from using that content.
4. Retry in Word after access/policy changes.

## Ticket 4 - Sales rep cannot find guest-shared contract from another org
Hello,

Thanks for reporting this. Content shared via guest links from another organization is often outside normal Copilot grounding scope.

### Next steps
1. Confirm the file is from an external tenant and only shared via guest link.
2. Ask the owner for an approved internal sharing path if business policy allows.
3. Open the file directly to confirm manual access still works.
4. If Copilot use is required, involve IT to review cross-tenant sharing design and policy options.

## Ticket 5 - Copilot stopped for whole Finance team this morning
Hello,

Thanks for raising this quickly. Because this affects a whole team and worked yesterday, the most likely cause is a licensing or service configuration change rather than a user mistake.

### Next steps
1. IT will first confirm all Finance users still have active Copilot licenses and enabled service plans.
2. IT will validate account sign-in state and client prerequisites.
3. Please share 2-3 impacted user examples, app names, and timestamps to speed diagnosis.
4. If licensing/config checks pass, IT will escalate to Microsoft support as a potential product issue.

## Ticket 6 - Copilot summarized a file user forgot they could access
Hello,

What you saw is usually expected behavior. Copilot can use content you already have permission to access, even if you forgot that access existed.

### Next steps
1. Review your permissions for that folder/file with IT or the content owner.
2. If access is no longer needed, request permission removal.
3. Re-test Copilot after permission changes.
4. If needed, ask IT for guidance on least-privilege access cleanup.

## Ticket 7 - Analyst gets generic answers, no internal SharePoint grounding
Hello,

Thanks for reporting this. Generic responses usually happen when account context, entitlement, or content access scope is not fully aligned.

### Next steps
1. Confirm you are signed into the correct work tenant/account.
2. Confirm your Copilot license is active.
3. Verify you can manually open the expected SharePoint sites/files.
4. Retry with a specific prompt that names a known accessible internal file or site.
5. If still generic, send prompt examples and timestamps to IT for targeted checks.

## Ticket 8 - Executive assistant cannot see shared mailbox calendar in Outlook Copilot
Hello,

Thanks for reporting this. Shared mailbox and delegate scenarios can have access boundaries that differ from your normal mailbox experience.

### Next steps
1. Confirm your delegate/calendar permissions on the shared mailbox are correctly assigned.
2. Verify the shared mailbox opens normally in Outlook with your current account.
3. Retry Copilot with clear context (for example, mention the director/shared mailbox in prompt wording).
4. If unresolved, IT will review shared mailbox policy and Copilot support limits for delegated calendars.

## Closing note for users
If you contact IT, include:
1. Exact Copilot prompt used.
2. Exact error message text.
3. App used (Word, Outlook, Teams, etc.).
4. Time of test and affected file/mailbox URL.

This shortens resolution time significantly.
