# Personal AI Usage Charter (DWP Desktop/Endpoint Engineering)

Owner: [Name]  
Role: DWP Engineer (Desktop/Endpoint)  
Version/Date: 1.0 / 03 Aug 2026

## Purpose
Use public AI assistants to improve speed and quality for low-risk engineering work while protecting DWP users, systems, and data.

## Scope
This charter applies when using public LLM tools that are not DWP-hosted or DWP-approved secure internal AI services.

## Core Principle
Public AI can help me think and draft, but I remain accountable for security, accuracy, change control, and outcomes.

## 1) Tasks Appropriate for Public LLM Help
I may use public AI for generic, non-sensitive endpoint engineering activities, including:

1. Drafting PowerShell or batch script skeletons using dummy values.
2. Explaining Windows/endpoint concepts (services, event logs, registry structure, certificate basics).
3. Creating troubleshooting checklists for common desktop issues.
4. Drafting command syntax examples for known public tools and Windows features.
5. Generating template documentation (runbooks, handover notes, change summaries) with no DWP data.
6. Converting technical notes into clearer plain English for colleague communication.
7. Producing test ideas for script validation in a lab/sandbox environment.
8. Reviewing generic code quality issues (error handling, logging, idempotency) using sanitized snippets.

## 2) Tasks Not Appropriate for Public LLM Help
I will not use public AI for any task involving protected DWP information, privileged operations, or production decisioning, including:

1. Any user-specific incident details containing personal, health, benefits, or case-related information.
2. Production hostnames, domain/internal network details, architecture diagrams, security tooling config, or vulnerability details.
3. Credentials or secrets of any kind: passwords, tokens, API keys, certificates/private keys, recovery codes.
4. Full production scripts, configs, logs, or ticket exports that reveal internal context.
5. Security incident response content, forensic evidence, or active threat investigation details.
6. Decisions that require authoritative DWP policy interpretation (security, legal, HR, casework).
7. Any action that bypasses formal CAB/change control, approval paths, or least-privilege controls.
8. Direct copy/paste execution of AI-generated system changes on live endpoints.

## 3) Data-Handling Rule (PII and Credentials)
I follow this non-negotiable rule:

1. Never paste end-user PII or credentials into public AI tools.
2. Treat all user identifiers and internal system identifiers as sensitive unless proven otherwise.
3. Redact before prompting: names, NI numbers, emails, phone numbers, usernames, device IDs, ticket IDs, IPs, hostnames, and location data.
4. Use placeholders only, for example USER_A, DEVICE_X, DOMAIN_Y.
5. If a prompt needs real data to be useful, stop and use approved internal channels/tools instead.
6. If accidental disclosure occurs, report immediately via DWP security process and rotate exposed secrets at once.

## 4) Personal "Generate Then Verify" Rule (Scripts and System Changes)
I use AI output only as a first draft and always run this verification sequence:

1. Generate: ask AI for a minimal, commented draft with safe defaults and rollback steps.
2. Review: line-by-line check for destructive commands, privilege misuse, hardcoded paths, and hidden assumptions.
3. Validate: confirm against official Microsoft/vendor docs and DWP standards.
4. Test: run in isolated lab/sandbox on representative endpoint builds.
5. Peer check: get a colleague review for medium/high-impact changes.
6. Control: raise change record, approvals, and implementation plan before production use.
7. Deploy safely: pilot to limited cohort, monitor logs/telemetry, then phase rollout.
8. Record: document what AI generated, what I changed, what I verified, and final evidence.

## Personal Operating Rules
1. If unsure whether content is safe for public AI, treat it as not safe.
2. Keep prompts factual, minimal, and sanitized.
3. Do not present AI output as authoritative without verification.
4. Remain responsible for every command run and every change approved.

## Commitment Statement
I will use public AI assistants to accelerate low-risk engineering tasks, never to expose DWP data or replace professional judgment, security policy, or change governance.

Signed: ____________________  
Date: ____________________
