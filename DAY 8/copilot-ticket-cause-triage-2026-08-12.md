# Copilot Support Ticket Triage (DWP Training)
Date: 2026-08-12

Scope rule applied: defaulted to non-Copilot causes unless evidence strongly suggests otherwise.

## Ticket 1
Ticket: Finance lead cannot summarise Q3 board pack in SharePoint though they can see it.

Likely cause (ranked):
1. Sensitivity label restriction
2. Data indexing lag
3. Permissions/access boundary
4. License/client prerequisite issue
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check: Open the board pack and check its sensitivity label/encryption settings first.

Is this actually a Copilot bug?: No (likely). Seeing a file does not guarantee Copilot can process labeled/restricted content.

## Ticket 2
Ticket: New hire (started yesterday): Copilot in Outlook knows nothing about recent emails.

Likely cause (ranked):
1. Data indexing lag
2. License/client prerequisite issue
3. Permissions/access boundary
4. Sensitivity label restriction
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check: Confirm how recently the mailbox was provisioned and whether the user is still within expected indexing warm-up time.

Is this actually a Copilot bug?: No (likely). New-starter timing strongly points to ingestion/indexing delay before personalized grounding is complete.

## Ticket 3
Ticket: HR manager in Word gets "I don't have access to that content" for sensitive salary spreadsheet.

Likely cause (ranked):
1. Permissions/access boundary
2. Sensitivity label restriction
3. Data indexing lag
4. License/client prerequisite issue
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check: Verify the HR manager's direct access to that exact spreadsheet path/file in M365 first.

Is this actually a Copilot bug?: No. The error explicitly indicates access boundary, with label policy as a close secondary factor.

## Ticket 4
Ticket: Sales rep in Teams cannot find client contract shared by guest link from another org.

Likely cause (ranked):
1. Guest/external sharing limitation
2. Permissions/access boundary
3. Data indexing lag
4. Sensitivity label restriction
5. License/client prerequisite issue
6. Genuine Copilot fault

Fastest check: Check whether the contract is only accessible via cross-tenant guest link (not internal indexed content).

Is this actually a Copilot bug?: No (likely). Cross-tenant guest sharing is a known limitation pattern for Copilot grounding.

## Ticket 5
Ticket: IT admin says Copilot stopped for the whole Finance team this morning and was fine yesterday.

Likely cause (ranked):
1. License/client prerequisite issue
2. Permissions/access boundary
3. Data indexing lag
4. Sensitivity label restriction
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check: In M365 admin, confirm Finance users still have active Copilot licenses/service plans assigned.

Is this actually a Copilot bug?: Unclear. Team-wide impact can be licensing/configuration drift; escalate to product fault only if licensing and config checks pass.

## Ticket 6
Ticket: Manager says Copilot summarised a file from a folder they forgot they could access.

Likely cause (ranked):
1. Permissions/access boundary
2. Data indexing lag
3. Sensitivity label restriction
4. License/client prerequisite issue
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check: Check effective permissions on that folder/file for the manager account.

Is this actually a Copilot bug?: No. This behavior matches expected grounding within the user's existing permissions, even if they forgot access existed.

## Ticket 7
Ticket: Analyst gets generic answers and Copilot seems not to use internal SharePoint content at all.

Likely cause (ranked):
1. License/client prerequisite issue
2. Permissions/access boundary
3. Data indexing lag
4. Sensitivity label restriction
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check: Confirm the analyst is signed into the correct work tenant/account with Copilot entitlement enabled.

Is this actually a Copilot bug?: Unclear. Generic-only responses usually indicate entitlement/account context or access scope issues before product fault.

## Ticket 8
Ticket: Executive assistant in Outlook cannot see a shared mailbox calendar managed for their director.

Likely cause (ranked):
1. Permissions/access boundary
2. License/client prerequisite issue
3. Data indexing lag
4. Sensitivity label restriction
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check: Verify delegate/calendar permissions on the shared mailbox for the assistant account.

Is this actually a Copilot bug?: No (likely). Shared mailbox delegate access boundaries commonly limit what Copilot can use.

## Triage note
Use “genuine Copilot fault” only after confirming entitlement, account context, permission scope, and indexing state.
