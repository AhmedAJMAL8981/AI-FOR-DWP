# Microsoft 365 Copilot Readiness Checklist - Finance

Department: Finance  
User count: ~200  
Data sensitivity: High - payroll, board packs, M&A documents, client financial data  
Current state: M365 E5 licensed for all users; Copilot add-on not yet assigned; SharePoint permissions inherited from a 2019 migration and never fully audited

## Priority 1 - Permissions and Oversharing Review

Because this department holds highly sensitive financial and client data, these checks must be completed first.

- [ ] Identify every SharePoint site, Teams-connected site, and document library used by Finance.
- [ ] Review who can access each site, library, and folder.
- [ ] Remove any access that is not clearly needed for current job roles.
- [ ] Check for broad access such as "Everyone", "All authenticated users", large mail-enabled groups, or old project groups.
- [ ] Confirm inherited permissions from the 2019 migration are still valid.
- [ ] Review shared links to Finance documents and remove open or overly broad links.
- [ ] Check for any board pack, payroll, M&A, or client financial files stored in locations that are open to too many people.
- [ ] Confirm external sharing is disabled or tightly controlled for Finance locations.
- [ ] Record who approved each access change and keep an audit trail.
- [ ] Recheck the highest-risk locations after changes to confirm access is now appropriate.

## Priority 2 - Licensing Prerequisites

- [ ] Confirm all 200 users have active Microsoft 365 E5 licenses.
- [ ] Confirm the Copilot add-on is assigned only to approved pilot or rollout users.
- [ ] Validate licensing for any shared mailboxes, service accounts, or support users involved in testing.
- [ ] Confirm the license assignment process is documented for future rollout.

## Priority 3 - Microsoft 365 Apps Client Version

- [ ] Confirm users are on a supported Microsoft 365 Apps build for Copilot.
- [ ] Check that desktop apps are up to date on Windows devices.
- [ ] Confirm update channels are aligned across the Finance estate.
- [ ] Validate Office apps open and sign in correctly before enabling Copilot.
- [ ] Test Word, Excel, Outlook, and Teams with the target client build.

## Priority 4 - Identity and MFA Readiness

- [ ] Confirm every user has a working Entra ID sign-in.
- [ ] Verify MFA is enabled and working for all Finance users.
- [ ] Check for accounts with old authentication methods that may fail during Copilot use.
- [ ] Confirm conditional access policies do not block normal work after sign-in.
- [ ] Test sign-in from a standard user device, not only admin machines.
- [ ] Make sure support can quickly reset MFA or unlock accounts during rollout.

## Priority 5 - Sensitivity Labelling and Data Protection

- [ ] Confirm sensitivity labels are in use for Finance content.
- [ ] Check that payroll, board packs, M&A, and client financial files are labelled correctly.
- [ ] Verify labels are applied consistently in SharePoint, OneDrive, and Office apps.
- [ ] Confirm labels and protection settings behave as expected when users share files.
- [ ] Review whether the most sensitive content has the right protection before Copilot is enabled.

## Priority 6 - End-User Comms and Enablement

- [ ] Prepare a simple message explaining what Copilot is, what it is for, and what it is not for.
- [ ] Tell users which files and data they should not paste into Copilot unless approved.
- [ ] Give 3 to 5 safe use examples relevant to Finance work.
- [ ] Explain how to report bad answers, missing content, or access problems.
- [ ] Brief managers and super users before wider rollout.
- [ ] Provide a short FAQ and support route for first-week issues.

## Go-Live Readiness Check

- [ ] High-risk SharePoint and OneDrive permissions have been reviewed and corrected.
- [ ] Oversharing risks have been reduced.
- [ ] E5 licensing is confirmed.
- [ ] Copilot add-on is assigned only to approved users.
- [ ] Microsoft 365 Apps are on a supported version.
- [ ] Identity and MFA are working.
- [ ] Sensitivity labelling is in place for sensitive Finance content.
- [ ] Users have received clear guidance before enablement.

## Decision

- [ ] Ready to pilot Copilot in Finance
- [ ] Not ready - fix permissions and oversharing first
