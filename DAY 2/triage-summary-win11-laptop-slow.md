# Triage Summary: Win11 Laptop Slow

## Likely Causes
1. High resource usage
   - Too many startup/background apps, browser tabs, Teams/Outlook sync, or endpoint tools causing sustained high CPU/RAM/disk.
2. Storage pressure
   - Low free space or heavy disk I/O from indexing, updates, OneDrive sync, or large temp/profile data.
3. Update/patch activity
   - Windows Update, Defender scans, or application patching running in the background.
4. Startup bloat
   - Non-essential auto-start apps extending login time and keeping the system busy after sign-in.
5. Hardware or thermal constraints
   - Older CPU, low RAM, HDD (not SSD), overheating/thermal throttling, or degrading battery power profile.
6. Security or malware impact
   - Legitimate security tooling overhead, or less commonly unwanted software.

## 3 Questions to Ask
1. When is it slow: right after sign-in, all day, or only in specific apps (for example Teams/Outlook/browser)?
2. Is slowness constant or intermittent, and did it start after a recent change (update, new software, VPN, location/network)?
3. What symptoms are visible: fan running hard, long app open times, freezing, high memory warning, or disk at 100% in Task Manager?

## First Diagnostic Step
Open Task Manager and capture a 2-minute idle snapshot of CPU, Memory, and Disk, then sort Processes by highest usage to identify the top resource consumer.

This immediately shows whether the issue is CPU-bound, memory pressure, or disk bottleneck and guides the next action.
