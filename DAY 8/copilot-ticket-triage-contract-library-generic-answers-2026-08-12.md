## Incident Triage

**Likely cause (ranked):**
1. data indexing lag
2. sensitivity label restriction
3. permissions/access boundary
4. license/client prerequisite issue
5. guest/external sharing limitation
6. genuine Copilot fault

**Fastest check:**
Verify that a known contract template from the library appears in the user's Microsoft 365 search results and is readable by the user.

**Triage outcome:**
Under investigation

**Is this actually a Copilot bug?:**
Unclear. Generic responses often indicate missing retrievable context (indexing or policy/access constraints) rather than a Copilot defect.

## End User Communication

Thanks for the detail. The most likely reason is that Copilot is not yet fully pulling context from the templates library, which can happen when document context is still syncing or restricted.

We are checking whether those templates are currently discoverable and available for Copilot to reference for your account.

We will update you once that check completes and confirm any required follow-up actions.