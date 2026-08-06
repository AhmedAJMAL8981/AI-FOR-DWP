# Triage Summary - T-1006

## Summary (one line)
User reports overall system slowness after upgrading to Windows 11 two days ago.

## Impact (who/how many/business urgency)
- Who is affected: One reported user after recent Win11 upgrade (to-verify).
- How many are affected: Single known user currently; post-upgrade trend unknown (to-verify).
- Business urgency: Medium (to-verify), potentially High if slowness blocks critical workflows (to-verify).

## Known Facts
- Ticket reference: T-1006.
- Symptom: "Everything is slow" on the endpoint.
- Timing/context: User upgraded to Windows 11 two days ago.

## Missing Information to Gather
- Device model/spec and available free disk space (to-verify).
- Whether slowness is constant or tied to specific apps/tasks (to-verify).
- Whether issue appears at startup only or throughout the day (to-verify).
- Current CPU/memory/disk utilization pattern during slowdown (to-verify).
- Whether updates, indexing, app reprovisioning, or security scans are still running post-upgrade (to-verify).
- Whether network-dependent apps are specifically affected versus local apps (to-verify).
- Whether similar slowness is reported by other recently upgraded users on same hardware profile (to-verify).
- Baseline comparison: performance before upgrade versus now with concrete examples (to-verify).

## Likely Category
Endpoint Performance - Post-Windows 11 Upgrade Degradation (to-verify).

## First Diagnostic Step
Capture a quick performance baseline on the affected device by reproducing slowness and recording real-time CPU, memory, disk, and top process usage to identify the primary bottleneck.