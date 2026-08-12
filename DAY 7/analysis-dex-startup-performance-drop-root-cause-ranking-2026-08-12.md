# DEX Startup Performance Drop: Ranked Likely Causes

Date: 2026-08-12  
Scope fact basis: Finance-Win11 (215 devices) startup score dropped sharply on 2026-08-04 immediately after a new security baseline profile was deployed at 02:00. IT-Win11 (40 devices) was not in scope for the change and stayed stable.

## Ranked Most Likely Causes

### 1. Startup script added for compliance logging is slowing logon/startup
Why it fits the evidence: This is the most direct new behavior introduced at the exact time the Finance-Win11 drop starts. A startup script runs on every affected device, so it can create a broad, immediate slowdown. The clean IT-Win11 comparison group had no config change and did not show the drop, which strongly points to the Finance-only startup script path.

Fastest check: Temporarily disable or bypass the startup script for a small Finance-Win11 pilot group and compare startup time against unchanged devices the same day.

### 2. Additional Defender scan policy is extending startup time
Why it fits the evidence: The Defender policy was added in the same Finance-only rollout window as the drop, so it matches the timing precisely. Security scanning can add work at startup across all affected devices, which fits the broad score drop seen only in the configured group. IT-Win11 stayed stable without the policy change, which supports the policy as a likely contributor.

Fastest check: Compare startup performance on a subset with the new Defender policy disabled versus a matched subset still using the policy.

### 3. The new security baseline is triggering heavier policy processing at startup
Why it fits the evidence: The drop appears immediately after the baseline deployment and remains low on the following days, which is consistent with a new baseline adding repeated startup processing overhead. Because IT-Win11 had no config change and remained steady, the problem is more likely tied to Finance-Win11 policy processing than to a general platform issue.

Fastest check: Review policy processing and logon timing on affected devices, then test a reduced baseline or staged rollback on a small Finance-Win11 sample.

## Ranking Logic

The ranking is weighted heavily toward the change event itself: the timing is exact, the affected group is isolated, and the comparison group stayed stable. That makes the Finance-only configuration change the strongest evidence, so the most likely causes are the specific new startup behaviors introduced by that rollout.