# Prevention Note: Floor 6 Copilot Unauthorized Data Access

## Process change
**Matter Permission Attestation Before Copilot Enablement**

## What it is
Before Copilot is enabled for any legal group, the matter owner must sign off that the group has no access to restricted client matter folders, and the Copilot connector must be checked against the approved access list. This is a required release gate, not a post-incident review.

## Why this would have caught it
The incident involved Copilot showing content from a matter the user should not have been able to see. A permission attestation step would have forced a direct check of the source folders, group membership, and connector scope before Copilot was available to the floor.

## How to run it
1. Review the current access list for the legal matter sources.
2. Confirm the target legal group is not granted broader access than intended.
3. Confirm the Copilot connector uses only the approved source systems and least-privilege access.
4. Require Security and Legal approval before Copilot is enabled for the floor.

## Owner
Security / Legal / M365 release owner
