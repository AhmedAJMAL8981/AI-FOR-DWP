<#
.SYNOPSIS
    DWP Endpoint Health Report - PowerShell 5.1, strictly read-only.

.DESCRIPTION
    Reports system uptime, free disk space, pending reboot status, top processes
    by memory/CPU, recent System log errors, internet speed, Microsoft Defender
    service status, logged-in user count, and last Windows Update install date.

    This script performs NO write/change operations to the system (no registry
    writes, no service/process changes, no file writes other than transient
    in-memory data used for the internet speed test).

.ITEMS TO VERIFY BEFORE RUNNING
    1) INTERNET SPEED TEST: downloads a small file from an external public URL
       (default: https://speed.hetzner.de/10MB.bin) to measure throughput.
       - CONFIRM this is permitted by your network/security/proxy policy before
         running on a DWP-managed endpoint (outbound internet access, data usage,
         allow-listed domains). Replace the URL with an internal test endpoint if
         required. If the request fails (proxy/firewall block), the section will
         report the failure rather than stop the script.
    2) LOGGED-IN USER COUNT: uses "quser". This relies on Terminal Services APIs;
       on some locked-down builds or if the service is disabled it may return no
       data or an error - verify this works in your environment.
    3) LAST WINDOWS UPDATE: uses Get-HotFix (Win32_QuickFixEngineering), which does
       not always reflect every update mechanism (e.g. some updates pushed via
       WSUS/Intune/feature updates may not appear). Treat as indicative, not
       definitive - verify against Windows Update history (Settings) if precision
       is required.
    4) PENDING REBOOT: checks common registry indicators (Component Based
       Servicing, Windows Update, PendingFileRenameOperations). This does not
       cover every possible pending-reboot source (e.g. SCCM-specific keys) -
       verify against your patching tool if it manages reboots separately.
    5) Reading HKLM registry values normally does not require elevation, but
       verify the account running this script has read access in your environment.
#>

#Requires -Version 5.1

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " DWP Endpoint Health Report - $(Get-Date)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# --- 1. System Uptime ---
Write-Host "`n--- System Uptime ---" -ForegroundColor Yellow
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $uptime = (Get-Date) - $os.LastBootUpTime
    [PSCustomObject]@{
        LastBootUpTime = $os.LastBootUpTime
        Uptime         = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
    } | Format-List
}
catch {
    Write-Warning "Could not retrieve system uptime: $_"
}

# --- 2. Free Disk Space ---
Write-Host "`n--- Free Disk Space ---" -ForegroundColor Yellow
try {
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop |
        Select-Object DeviceID,
            @{N = "Size(GB)"; E = { [math]::Round($_.Size / 1GB, 2) } },
            @{N = "FreeSpace(GB)"; E = { [math]::Round($_.FreeSpace / 1GB, 2) } },
            @{N = "FreePercent"; E = { if ($_.Size) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { "n/a" } } } |
        Format-Table -AutoSize
}
catch {
    Write-Warning "Could not retrieve disk space: $_"
}

# --- 3. Pending Reboot Check (registry, read-only) ---
Write-Host "`n--- Pending Reboot Status ---" -ForegroundColor Yellow
try {
    $rebootPending = $false
    $reasons = @()

    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
        $rebootPending = $true
        $reasons += "Component Based Servicing\RebootPending key present"
    }
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
        $rebootPending = $true
        $reasons += "Windows Update\Auto Update\RebootRequired key present"
    }
    $pfro = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
    if ($pfro) {
        $rebootPending = $true
        $reasons += "PendingFileRenameOperations value present"
    }

    [PSCustomObject]@{
        RebootPending = $rebootPending
        Reasons       = if ($reasons.Count) { $reasons -join "; " } else { "None detected" }
    } | Format-List
}
catch {
    Write-Warning "Could not determine pending reboot status: $_"
}

# --- 4. Top 5 Processes by Memory (Working Set) ---
Write-Host "`n--- Top 5 Processes by Memory (Working Set) ---" -ForegroundColor Yellow
try {
    Get-Process -ErrorAction Stop |
        Sort-Object WS -Descending |
        Select-Object -First 5 Name, Id, @{N = "WorkingSet(MB)"; E = { [math]::Round($_.WS / 1MB, 1) } } |
        Format-Table -AutoSize
}
catch {
    Write-Warning "Could not retrieve process memory data: $_"
}

# --- 5. Top 5 Processes by CPU ---
# Note: CPU here is total processor time (seconds) accumulated since process start, not a live % figure.
Write-Host "`n--- Top 5 Processes by CPU (total processor time) ---" -ForegroundColor Yellow
try {
    Get-Process -ErrorAction Stop |
        Where-Object { $_.CPU } |
        Sort-Object CPU -Descending |
        Select-Object -First 5 Name, Id, @{N = "CPU(s)"; E = { [math]::Round($_.CPU, 1) } } |
        Format-Table -AutoSize
}
catch {
    Write-Warning "Could not retrieve process CPU data: $_"
}

# --- 6. Last 5 System Log Errors ---
Write-Host "`n--- Last 5 System Log Errors ---" -ForegroundColor Yellow
try {
    Get-EventLog -LogName System -EntryType Error -Newest 5 -ErrorAction Stop |
        Select-Object TimeGenerated, Source, EventID, Message |
        Format-List
}
catch {
    Write-Warning "Could not retrieve System log errors (or none found): $_"
}

# --- 7. Internet Speed (download test - see verification note above) ---
Write-Host "`n--- Internet Speed Test ---" -ForegroundColor Yellow
try {
    $testUrl = "https://speed.hetzner.de/10MB.bin"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -ErrorAction Stop
    $sw.Stop()
    $bytes = $response.RawContentLength
    if (-not $bytes) { $bytes = $response.Content.Length }
    $seconds = $sw.Elapsed.TotalSeconds
    $mbps = [math]::Round((($bytes * 8) / $seconds) / 1MB, 2)
    [PSCustomObject]@{
        TestFile    = $testUrl
        SizeMB      = [math]::Round($bytes / 1MB, 2)
        Seconds     = [math]::Round($seconds, 2)
        ApproxMbps  = $mbps
    } | Format-List
}
catch {
    Write-Warning "Internet speed test failed (network/proxy/firewall may be blocking outbound access): $_"
}

# --- 8. Microsoft Defender Service Status ---
Write-Host "`n--- Microsoft Defender Service Status ---" -ForegroundColor Yellow
try {
    $svc = Get-Service -Name WinDefend -ErrorAction Stop
    [PSCustomObject]@{
        ServiceName = $svc.Name
        DisplayName = $svc.DisplayName
        Status      = $svc.Status
        StartType   = $svc.StartType
    } | Format-List
}
catch {
    Write-Warning "Could not retrieve Microsoft Defender service status (service may not exist, e.g. third-party AV in use): $_"
}

# --- 9. Logged-in User Count ---
Write-Host "`n--- Logged-in Users ---" -ForegroundColor Yellow
try {
    $quserOutput = quser 2>$null
    if ($quserOutput) {
        $userLines = $quserOutput | Select-Object -Skip 1
        Write-Host "Logged-in session count: $($userLines.Count)"
        $quserOutput
    }
    else {
        Write-Host "No interactive sessions found, or 'quser' returned no data."
    }
}
catch {
    Write-Warning "Could not retrieve logged-in user data (quser may be unavailable on this build): $_"
}

# --- 10. Last Windows Update Install Date ---
Write-Host "`n--- Last Windows Update Installed ---" -ForegroundColor Yellow
try {
    $lastUpdate = Get-HotFix -ErrorAction Stop |
        Where-Object { $_.InstalledOn } |
        Sort-Object InstalledOn -Descending |
        Select-Object -First 1

    if ($lastUpdate) {
        $lastUpdate | Select-Object HotFixID, Description, InstalledOn | Format-List
    }
    else {
        Write-Host "No hotfix install date data available via Get-HotFix."
    }
}
catch {
    Write-Warning "Could not retrieve Windows Update history: $_"
}

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " Report Complete" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
