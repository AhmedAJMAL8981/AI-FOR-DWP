## Incident Triage

**Likely cause (ranked):**
1. permissions/access boundary
2. sensitivity label restriction
3. guest/external sharing limitation
4. data indexing lag
5. license/client prerequisite issue
6. genuine Copilot fault

**Fastest check:**
Verify whether the paralegal currently has direct read access to the exact SharePoint folder/file containing the NDA.

**Triage outcome:**
Resolved by configuration/access check

**Is this actually a Copilot bug?:**
No. The error explicitly indicates access is not available, and the user states the folder was previously unknown and unopened.

## End User Communication

Thanks for raising this. The most likely reason is that the NDA is stored in a location your account does not currently have permission to open.

We are checking access to that specific SharePoint folder and, if needed, requesting the correct access path from the matter owner. Once your access is in place, Copilot should be able to work with that document.

We will update you as soon as the access check is completed.