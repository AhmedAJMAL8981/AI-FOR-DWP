# Microsoft 365 Copilot Readiness Tiers - Finance

Department: Finance  
Context: ~200 users, M365 E5 in place, Copilot add-on not yet assigned, SharePoint permissions inherited from a 2019 migration and never fully audited, sensitive data includes payroll, board packs, M&A documents, and client financial data.

## MUST complete before rollout (blocking)

- [ ] Review and fix SharePoint and OneDrive permissions.
- [ ] Remove oversharing and broad access to sensitive Finance content.
- [ ] Confirm external sharing is controlled for Finance locations.
- [ ] Verify sensitivity labels for high-risk Finance documents and sites.
- [ ] Confirm identity and MFA are working for all users.

## SHOULD complete before rollout (high risk if skipped)

- [ ] Confirm Microsoft 365 E5 licensing for all users.
- [ ] Assign the Copilot add-on only to approved pilot or rollout users.
- [ ] Check Microsoft 365 Apps are on a supported version.
- [ ] Align Office update channels across the Finance estate.
- [ ] Test Word, Excel, Outlook, and Teams on the target client build.
- [ ] Prepare end-user comms, safe-use guidance, and support contacts.

## CAN complete during/after rollout (lower risk)

- [ ] Validate licensing process for future rollout waves.
- [ ] Check shared mailboxes, service accounts, and support users used in testing.
- [ ] Fine-tune the FAQ and manager briefing after pilot feedback.
- [ ] Expand safe-use examples based on first-week user questions.
- [ ] Update documentation and training material after rollout.

## Why the permissions and oversharing audit is MUST

Even though licensing and client version checks are easier to confirm, they do not address the biggest Finance risk: giving Copilot access to the wrong content. This department holds payroll, board packs, M&A documents, and client financial data, and the current SharePoint permissions were inherited from a 2019 migration that was never fully audited. If access is too broad, Copilot could surface sensitive information to users who should not see it. That is a business risk, a confidentiality risk, and a governance risk, so the permissions and oversharing audit must be completed before rollout.

## Rollout decision

- [ ] Ready for limited pilot only after MUST items are complete
- [ ] Not ready for rollout until permissions and oversharing are remediated