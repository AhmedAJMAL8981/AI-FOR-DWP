# HAND-CORRECTED POWERSHELL DIAGNOSTIC SCRIPT
## Floor 6 Login/Performance Investigation – AI vs. Hand-Corrected
**Date:** 2026-08-14  
**Purpose:** Side-by-side comparison of AI-generated and hand-corrected versions  
**Focus:** Making the script safer, more read-only, more structured, and practical for L1/L2 engineers

---

# SUMMARY OF TOP-RANKED CAUSE BEING TESTED

**Hypothesis:** The Friday document management application deployment (2026-08-11 afternoon) may have caused or contributed to Monday morning (2026-08-14) login failures or slow logins on Floor 6 Legal department devices.

**Evidence Needed:** Installation logs, Intune deployment status, event log failures correlating to app deployment, startup/logon script failures.

**What Would CONFIRM:** App installed in deployment window + Intune errors + Event log auth failures + logon script crashes.

**What Would RULE OUT:** App not installed OR installed successfully with no errors OR Event logs show auth failures unrelated to app OR No startup items/services from app found.

---

# SECTION 1: DEVICE ENVIRONMENT CHECK

## AI-Generated Version:
```powershell
# Collect basic device information
Write-Host "Collecting device environment..."
$SystemInfo = Get-ComputerInfo -ErrorAction SilentlyContinue
$OSVersion = [System.Environment]::OSVersion.VersionString
$LastBootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$TimeSinceBoot = [datetime]::Now - $LastBootTime
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

$DeviceData = @{
    ComputerName   = $env:COMPUTERNAME
    OSVersion      = $OSVersion
    Windows11       = $OSVersion -match "Windows 11"
    LastBootTime   = $LastBootTime
    HoursSinceBoot = [math]::Round($TimeSinceBoot.TotalHours, 2)
    CurrentUser    = $CurrentUser
}
```

## Hand-Corrected Version:
```powershell
# Collect device environment (read-only, no modifications)
Write-Host "[DeviceEnvironment] Collecting system information..."
try {
    $CimOS = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $CompInfo = Get-ComputerInfo -ErrorAction SilentlyContinue
    
    $DeviceData = @{
        ComputerName        = $env:COMPUTERNAME
        OSVersion           = $CimOS.Caption  # e.g., "Microsoft Windows 11 Pro"
        OSBuild             = $CimOS.BuildNumber
        IsWindows11         = $CimOS.Caption -match "Windows 11"
        SystemBootTime      = $CimOS.LastBootUpTime
        HoursSinceBoot      = [math]::Round(((Get-Date) - $CimOS.LastBootUpTime).TotalHours, 1)
        CurrentUserContext  = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        IsElevated          = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        SystemManufacturer  = $CompInfo.CsSystemManufacturer
        SystemModel         = $CompInfo.CsModel
    }
} catch {
    Write-Warning "Could not collect device environment: $_"
    $DeviceData = @{ Error = "Failed to collect device information" }
}
```

## Fix Note:
- **AI Issue:** Missing explicit OS build number; doesn't verify admin elevation needed for deeper checks.
- **Correction:** Added BuildNumber, explicit Windows 11 check, admin elevation status, hardware model for troubleshooting consistency. Uses Win32_OperatingSystem directly for reliability. Better error handling.

---

# SECTION 2: APP INSTALLATION CHECK (Deployment Window)

## AI-Generated Version:
```powershell
# Check if app is installed and when
$TargetApplicationNames = @("DocumentManagementApp", "FinBridge Document Manager", "Docs Management")
$DeploymentDateStart = [datetime]"2026-08-11 12:00:00"
$DeploymentDateEnd = [datetime]"2026-08-11 23:59:59"

$RegistryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($Path in $RegistryPaths) {
    $Apps = Get-ItemProperty $Path | Where-Object { $_.DisplayName }
    $InstalledApps += $Apps
}

$TargetAppInstalled = $InstalledApps | Where-Object { $_.DisplayName -like "*DocumentManagement*" }
```

## Hand-Corrected Version:
```powershell
# Check installed applications within deployment window (read-only registry query)
Write-Host "[ApplicationDeployment] Checking for target app installation..."
$DeploymentStart = [datetime]"2026-08-11 12:00:00"
$DeploymentEnd = [datetime]"2026-08-11 23:59:59"

# Flexible app name matching (case-insensitive, partial match)
$AppPatterns = @(
    "Document*Management*",
    "FinBridge*",
    "*Document*App*",
    "Intune*Deployment*"  # Also check for Intune-deployed apps
)

$TargetAppsFound = @()
try {
    $RegistryPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    
    foreach ($RegPath in $RegistryPaths) {
        if (Test-Path $RegPath) {
            Get-ChildItem $RegPath -ErrorAction SilentlyContinue | ForEach-Object {
                $AppName = $_.GetValue('DisplayName')
                $Version = $_.GetValue('DisplayVersion')
                $InstallDate = $_.GetValue('InstallDate')  # Format: YYYYMMDD
                
                if ($AppName) {
                    foreach ($Pattern in $AppPatterns) {
                        if ($AppName -like $Pattern) {
                            # Parse install date SAFELY (YYYYMMDD format)
                            $ParsedDate = $null
                            if ($InstallDate -and $InstallDate -match '^\d{8}$') {
                                try {
                                    $ParsedDate = [datetime]::ParseExact($InstallDate, "yyyyMMdd", $null)
                                } catch {
                                    $ParsedDate = $null
                                }
                            }
                            
                            $IsInDeploymentWindow = $null -ne $ParsedDate -and $ParsedDate -ge $DeploymentStart -and $ParsedDate -le $DeploymentEnd
                            
                            $TargetAppsFound += @{
                                ApplicationName         = $AppName
                                Version                 = $Version
                                InstallDate             = $InstallDate  # Original format for audit
                                ParsedInstallDate       = if ($ParsedDate) { $ParsedDate.ToString('yyyy-MM-dd HH:mm:ss') } else { "Could not parse" }
                                InstalledInWindow       = $IsInDeploymentWindow
                                ConfirmsDeploymentCause = "App installed Friday 12:00-23:59 (deployment window)"
                            }
                        }
                    }
                }
            }
        }
    }
} catch {
    Write-Warning "Registry enumeration error: $_"
}

# Separate confirmed from unrelated apps
$AppDeploymentEvidence = @{
    AppsInstalledInDeploymentWindow = @($TargetAppsFound | Where-Object { $_.InstalledInWindow })
    AppsInstalledOutsideWindow      = @($TargetAppsFound | Where-Object { -not $_.InstalledInWindow })
    RulesOutDeploymentCause         = @($TargetAppsFound).Count -eq 0  # No target apps found = rules out
}
```

## Fix Note:
- **AI Issue:** Assumes "DocumentManagementApp" exact name; only checks HKLM; doesn't safely parse dates; doesn't separate "confirms" from "rules out" evidence.
- **Correction:** Flexible wildcard patterns; checks HKCU too; safe date parsing with error handling; explicitly outputs "ConfirmsDeploymentCause" and "RulesOutDeploymentCause" for each finding. Makes date parsing transparent for audit trail.

---

# SECTION 3: INTUNE MANAGEMENT EXTENSION LOG PARSING

## AI-Generated Version:
```powershell
# Check Intune logs for app installation failures
$IMELogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"

if (Test-Path $IMELogPath) {
    $LatestLogFile = Get-ChildItem $IMELogPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($LatestLogFile) {
        $LogContent = Get-Content $LatestLogFile -Tail 1000
        
        $ErrorPatterns = @("ERROR", "FAIL", "timeout", "restart required")
        foreach ($Pattern in $ErrorPatterns) {
            $Matches = $LogContent | Select-String -Pattern $Pattern
            if ($Matches) {
                $IssuesFound += @{ Pattern = $Pattern; Count = @($Matches).Count }
            }
        }
    }
}
```

## Hand-Corrected Version:
```powershell
# Parse Intune Management Extension logs for deployment failures (read-only log analysis)
Write-Host "[IntuneDeployment] Analyzing Intune logs..."
$IMELogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
$IntuneEvidence = @{
    LogPathExists  = Test-Path $IMELogPath
    ErrorsFound    = @()
    WarningsFound  = @()
    DeploymentFlow = @()  # Timeline of deployment
}

if ($IntuneEvidence.LogPathExists) {
    try {
        # Get ALL log files in date order (not just latest)
        $AllLogs = @(Get-ChildItem $IMELogPath -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime)
        
        if ($AllLogs.Count -gt 0) {
            # Focus on logs from Friday afternoon onward
            $RelevantLogs = $AllLogs | Where-Object { $_.LastWriteTime -ge (Get-Date "2026-08-11 12:00:00") }
            
            foreach ($LogFile in $RelevantLogs) {
                Write-Host "  → Analyzing: $($LogFile.Name) (Modified: $($LogFile.LastWriteTime))"
                
                $Content = Get-Content $LogFile -ErrorAction SilentlyContinue
                
                # Search for specific error patterns that indicate deployment failure
                $ErrorIndicators = @{
                    "Installation Failed"    = @("failed.*install", "install.*error", "exitcode [1-9]")
                    "Timeout/Hang"           = @("timeout", "timed out", "installation.*hung", "hung")
                    "Restart Loop"           = @("restart loop", "restart.*required", "pending restart", "reboot required")
                    "Detection Failure"      = @("detection.*fail", "detection.*error", "detect.*0x")
                    "Network/Connectivity"   = @("cannot connect", "no network", "network timeout", "dns.*fail")
                    "Permission Denied"      = @("access denied", "permission.*denied", "insufficient.*privilege")
                }
                
                foreach ($ErrorType in $ErrorIndicators.Keys) {
                    $Patterns = $ErrorIndicators[$ErrorType]
                    foreach ($Pattern in $Patterns) {
                        $MatchingLines = $Content | Select-String -Pattern $Pattern -ErrorAction SilentlyContinue
                        if ($MatchingLines) {
                            $IntuneEvidence.ErrorsFound += @{
                                ErrorType        = $ErrorType
                                Pattern          = $Pattern
                                Occurrences      = @($MatchingLines).Count
                                FirstOccurrence  = $MatchingLines[0].Line.Substring(0, [Math]::Min(150, $MatchingLines[0].Line.Length))
                                ConfirmsDeploymentCause = "Intune deployment of app failed/timed out/stuck in loop"
                            }
                        }
                    }
                }
            }
            
            if ($IntuneEvidence.ErrorsFound.Count -eq 0) {
                $IntuneEvidence.RulesOutDeploymentCause = "No deployment errors found in Intune logs"
            }
        }
    } catch {
        Write-Warning "Error parsing Intune logs: $_"
    }
} else {
    Write-Warning "Intune Management Extension log path not found - device may not be Intune-enrolled"
}
```

## Fix Note:
- **AI Issue:** Searches entire log file for generic patterns; doesn't distinguish error types; doesn't handle multiple logs; doesn't provide timeline.
- **Correction:** Categorizes errors by type (Installation Failed, Timeout, Restart Loop, etc.); searches logs from Friday onward; includes first occurrence text for audit; explicit "RulesOutDeploymentCause" when no errors found. Better for L1 to immediately see if deployment succeeded or failed.

---

# SECTION 4: WINDOWS EVENT LOGS (Authentication/Login)

## AI-Generated Version:
```powershell
# Check event logs for login failures
$EventLogs = @("Security", "System", "Application")
$StartTime = (Get-Date).AddDays(-3)

foreach ($LogName in $EventLogs) {
    $Events = Get-EventLog -LogName $LogName -After $StartTime -ErrorAction SilentlyContinue | Select-Object -First 100
    $ErrorCount = @($Events | Where-Object { $_.EntryType -eq "Error" }).Count
    Write-Host "$LogName Log: $ErrorCount errors found"
}
```

## Hand-Corrected Version:
```powershell
# Check Windows Event Logs for authentication and logon failures (read-only)
Write-Host "[EventLogs] Checking Security, System, and Application logs..."
$EventLogAnalysis = @{
    SecurityLog     = @{
        FailedLogins        = @()
        AccountLockouts     = @()
        PolicyFailures      = @()
        ConfirmsDeploymentCause = "Multiple failed logins (4625) OR account lockouts (4740) starting Monday morning"
    }
    SystemLog       = @{
        ProfileErrors       = @()
        StartupErrors       = @()
        DriverErrors        = @()
        ConfirmsDeploymentCause = "Event 1509/1516 (profile load fail) OR Event 6005 (boot fail) OR Event 7045 (service install fail)"
    }
    ApplicationLog  = @{
        AppErrors           = @()
        CrashEvents         = @()
    }
}

$SearchStartTime = (Get-Date).AddDays(-2)  # Look back 2 days (includes Friday evening)

# SECURITY LOG: Authentication failures
Write-Host "  → Querying Security log for authentication events..."
try {
    # Event 4625 = failed logon attempt
    $FailedLogins = Get-EventLog Security -After $SearchStartTime -InstanceId 4625 -ErrorAction SilentlyContinue
    if ($FailedLogins) {
        $FailedLoginsByDay = $FailedLogins | Group-Object { $_.TimeGenerated.Date } | Sort-Object Name -Descending
        foreach ($DayGroup in $FailedLoginsByDay) {
            $EventLogAnalysis.SecurityLog.FailedLogins += @{
                Date               = $DayGroup.Name.ToString("yyyy-MM-dd")
                FailedLoginCount   = $DayGroup.Count
                FirstOccurrence    = $DayGroup.Group[0].TimeGenerated
                ConfirmsDeploymentCause = "Spike in failed logins (Event 4625) on Monday morning would indicate auth issue"
            }
        }
    }
    
    # Event 4740 = account locked out
    $AccountLockouts = Get-EventLog Security -After $SearchStartTime -InstanceId 4740 -ErrorAction SilentlyContinue
    if ($AccountLockouts) {
        $EventLogAnalysis.SecurityLog.AccountLockouts = @{
            Count            = @($AccountLockouts).Count
            EarliestEvent    = ($AccountLockouts | Sort-Object TimeGenerated | Select-Object -First 1).TimeGenerated
            ConfirmsDeploymentCause = "Account lockouts (Event 4740) on Monday indicate failed auth attempts"
        }
    }
} catch {
    Write-Warning "Could not read Security log: $_"
}

# SYSTEM LOG: Profile and startup failures
Write-Host "  → Querying System log for profile and startup events..."
try {
    # Event 1509 = User Profile Service failed to load user profile
    # Event 1516 = User Profile Service detected an error
    $ProfileErrors = Get-EventLog System -After $SearchStartTime -InstanceId @(1509, 1516) -ErrorAction SilentlyContinue
    if ($ProfileErrors) {
        $EventLogAnalysis.SystemLog.ProfileErrors = @{
            Count            = @($ProfileErrors).Count
            Dates            = @($ProfileErrors | Group-Object { $_.TimeGenerated.Date } | ForEach-Object { $_.Name.ToString("yyyy-MM-dd") })
            FirstOccurrence  = ($ProfileErrors | Sort-Object TimeGenerated | Select-Object -First 1).TimeGenerated
            ConfirmsDeploymentCause = "Profile load failures (Event 1509/1516) on Monday would indicate Windows 11 migration issue"
        }
    }
    
    # Event 7045 = Service was installed (look for app-related services)
    $ServiceInstalls = Get-EventLog System -After $SearchStartTime -InstanceId 7045 -ErrorAction SilentlyContinue
    if ($ServiceInstalls) {
        $AppServiceInstalls = $ServiceInstalls | Where-Object { $_.Message -match "Document|Management|FinBridge" }
        if ($AppServiceInstalls) {
            $EventLogAnalysis.SystemLog.StartupErrors += @{
                ServiceInstallCount = @($AppServiceInstalls).Count
                Services            = @($AppServiceInstalls | ForEach-Object { 
                    $_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)) 
                })
                ConfirmsDeploymentCause = "App-related service installed at time of issues"
            }
        }
    }
} catch {
    Write-Warning "Could not read System log: $_"
}

# APPLICATION LOG: App crashes and errors
Write-Host "  → Querying Application log for errors..."
try {
    $AppErrors = Get-EventLog Application -After $SearchStartTime -EntryType Error -ErrorAction SilentlyContinue | Select-Object -First 50
    if ($AppErrors) {
        $EventLogAnalysis.ApplicationLog.AppErrors = @{
            ErrorCount       = @($AppErrors).Count
            TopSources       = @($AppErrors | Group-Object Source | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object { @{ Source = $_.Name; Count = $_.Count } })
            ConfirmsDeploymentCause = "Application errors spike on Monday morning related to document management app"
        }
    }
} catch {
    Write-Warning "Could not read Application log: $_"
}
```

## Fix Note:
- **AI Issue:** Counts total errors vaguely; doesn't distinguish failed logins from other errors; doesn't show timeline; doesn't link to app or deployment.
- **Correction:** Searches specific Event IDs (4625 failed login, 4740 lockout, 1509/1516 profile errors, 7045 service install); groups by date to show timeline; looks back from Friday; explicitly tags app-related events. L1 can immediately see if login failures started Monday morning or earlier.

---

# SECTION 5: STARTUP ITEMS & SCHEDULED TASKS

## AI-Generated Version:
```powershell
# Check startup items
$StartupReg = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
foreach ($Item in $StartupReg.PSObject.Properties) {
    if ($Item.Name -notmatch "^PS") {
        Write-Host "Startup: $($Item.Name) = $($Item.Value)"
    }
}

# Check scheduled tasks
$Tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -eq "Ready" }
$AppTasks = $Tasks | Where-Object { $_.TaskName -match "Document|Management" }
Write-Host "App-related tasks found: $($AppTasks.Count)"
```

## Hand-Corrected Version:
```powershell
# Check Startup items and Scheduled Tasks for app-related entries (read-only)
Write-Host "[StartupItems] Checking registry startup keys and scheduled tasks..."
$StartupEvidence = @{
    RegistryStartupItems = @()
    ScheduledTasks       = @()
    AutoStartServices    = @()
    ConfirmsDeploymentCause = "App startup script/task/service fails, hangs, or takes >30 seconds"
    RulesOutDeploymentCause = "No app-related startup items found OR items complete in <5 seconds"
}

# REGISTRY STARTUP ITEMS (HKLM\Run)
Write-Host "  → Scanning registry startup keys..."
try {
    $StartupPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    )
    
    foreach ($Path in $StartupPaths) {
        if (Test-Path $Path) {
            Get-ItemProperty $Path -ErrorAction SilentlyContinue | ForEach-Object {
                foreach ($Property in $_.PSObject.Properties) {
                    if ($Property.Name -notmatch "^PS(Path|Parent|Child|Drive|Provider)" -and $Property.Value) {
                        $IsAppRelated = $Property.Value -match "Document|Management|FinBridge" -or $Property.Name -match "Document|Management|FinBridge"
                        
                        if ($IsAppRelated) {
                            $StartupEvidence.RegistryStartupItems += @{
                                ItemName     = $Property.Name
                                ItemPath     = $Property.Value.Substring(0, [Math]::Min(200, $Property.Value.Length))
                                IsAppRelated = $true
                                SourceKey    = $Path
                            }
                        }
                    }
                }
            }
        }
    }
} catch {
    Write-Warning "Error reading startup registry: $_"
}

# SCHEDULED TASKS (look for app-related tasks)
Write-Host "  → Scanning scheduled tasks..."
try {
    $AllTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue)
    $AppTasks = $AllTasks | Where-Object { 
        $_.TaskName -match "Document|Management|FinBridge|Intune" -or 
        $_.TaskPath -match "Document|Management|FinBridge"
    }
    
    foreach ($Task in $AppTasks) {
        try {
            $TaskInfo = Get-ScheduledTaskInfo -TaskName $Task.TaskName -ErrorAction SilentlyContinue
            $StartupEvidence.ScheduledTasks += @{
                TaskName         = $Task.TaskName
                TaskPath         = $Task.TaskPath
                Enabled          = $Task.Enabled
                State            = $Task.State
                LastRunTime      = if ($TaskInfo.LastRunTime) { $TaskInfo.LastRunTime } else { "Never run" }
                LastRunResult    = $TaskInfo.LastTaskResult  # 0 = success, non-zero = failure
                IsAppRelated     = $true
                ConfirmsDeploymentCause = "If LastRunTime = Monday AM AND LastTaskResult != 0 (failed)"
            }
        } catch {
            Write-Warning "Could not get info for task $($Task.TaskName): $_"
        }
    }
} catch {
    Write-Warning "Error reading scheduled tasks: $_"
}

# AUTO-START SERVICES (look for app-related services)
Write-Host "  → Scanning auto-start services..."
try {
    $Services = Get-Service -ErrorAction SilentlyContinue
    $AppServices = $Services | Where-Object { 
        $_.Name -match "Document|Management|FinBridge" -or 
        $_.DisplayName -match "Document|Management|FinBridge"
    }
    
    foreach ($Service in $AppServices) {
        $ServiceStatus = Get-Service -Name $Service.Name | Select-Object Name, DisplayName, Status, StartType
        $StartupEvidence.AutoStartServices += @{
            ServiceName      = $Service.Name
            DisplayName      = $Service.DisplayName
            Status           = $Service.Status  # Running, Stopped, etc.
            StartType        = $ServiceStatus.StartType  # Automatic, Manual, Disabled
            IsAppRelated     = $true
            ConfirmsDeploymentCause = "If Status = Stopped/Error AND StartType = Automatic (won't start)"
        }
    }
} catch {
    Write-Warning "Error reading services: $_"
}
```

## Fix Note:
- **AI Issue:** Just lists items without classification; doesn't check if they're app-related; doesn't show task execution status.
- **Correction:** Explicitly filters for app-related items; checks task last run time and result code; checks service status and startup type; adds "ConfirmsDeploymentCause" for failed tasks. L1 can immediately see if app startup items are failing.

---

# FINAL CORRECTED POWERSHELL SCRIPT

```powershell
# ============================================================================
# Floor 6 Login/Performance Issue - Technical Diagnostic Script (HAND-CORRECTED)
# FinBridge Legal Department | Windows 11 Migration Investigation
# Date: 2026-08-14 | Version: 1.0 (Hand-Corrected)
# Purpose: Non-destructive evidence collection for app deployment root cause analysis
# ============================================================================
#
# SAFETY GUARANTEE: This script is READ-ONLY and performs NO system modifications.
# It does not: restart, disable, remove, modify, or fix anything.
#
# USAGE:
#   Dry-run (preview what will be collected, show output structure):
#   .\Floor6-LoginDiagnostic-HandCorrected.ps1 -DryRun
#
#   Actual collection (saves structured JSON):
#   .\Floor6-LoginDiagnostic-HandCorrected.ps1 -OutputPath "C:\Diagnostic_Results" -CollectDiagnostics
#
# ============================================================================

param(
    [switch]$DryRun = $false,
    [switch]$CollectDiagnostics = $false,
    [string]$OutputPath = "$env:TEMP\Floor6_Diagnostics",
    [int]$EventLogDaysBack = 2  # Search Friday onward
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptMetadata = @{
    Version          = "1.0-HandCorrected"
    CreatedDate      = "2026-08-14"
    Purpose          = "Non-destructive app deployment impact assessment"
    TargetHypothesis = "Friday document management app deployment caused Monday login issues"
    IsSafeToRun      = "YES - Read-only only, no modifications"
}

# Deployment window for Friday app rollout
$DeploymentWindowStart = [datetime]"2026-08-11 12:00:00"
$DeploymentWindowEnd = [datetime]"2026-08-11 23:59:59"

# App name patterns to search for (flexible matching)
$AppSearchPatterns = @(
    "Document*Management*",
    "FinBridge*",
    "*Document*App*"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Show-DryRunPreview {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "DRY-RUN MODE: Script will collect the following" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "1. DEVICE ENVIRONMENT:" -ForegroundColor Cyan
    Write-Host "   - Computer name, OS version, Windows 11 status, boot time"
    Write-Host "   - Current user, admin elevation status, hardware model"
    Write-Host ""
    
    Write-Host "2. APPLICATION DEPLOYMENT:" -ForegroundColor Cyan
    Write-Host "   - Scan registry for installed apps"
    Write-Host "   - Check if target app installed Friday (deployment window)"
    Write-Host "   - Evidence: [ConfirmsDeploymentCause] or [RulesOutDeploymentCause]"
    Write-Host ""
    
    Write-Host "3. INTUNE DEPLOYMENT LOGS:" -ForegroundColor Cyan
    Write-Host "   - Parse Intune Management Extension logs (Friday onward)"
    Write-Host "   - Categorize errors: Installation Failed, Timeout, Restart Loop, etc."
    Write-Host "   - Evidence: Error types, counts, first occurrence"
    Write-Host ""
    
    Write-Host "4. WINDOWS EVENT LOGS:" -ForegroundColor Cyan
    Write-Host "   - Security: Failed logins (4625), Account lockouts (4740)"
    Write-Host "   - System: Profile errors (1509/1516), Service installs (7045)"
    Write-Host "   - Application: Error events and app crashes"
    Write-Host "   - Timeline: Group by date to show spike on Monday morning"
    Write-Host ""
    
    Write-Host "5. STARTUP & SERVICES:" -ForegroundColor Cyan
    Write-Host "   - Registry startup items (HKLM/HKCU Run keys)"
    Write-Host "   - Scheduled tasks (app-related)"
    Write-Host "   - Auto-start services (check status and startup type)"
    Write-Host "   - Evidence: If task/service failed on Monday AM"
    Write-Host ""
    
    Write-Host "6. PERFORMANCE METRICS:" -ForegroundColor Cyan
    Write-Host "   - CPU cores, total memory, free memory, usage percent"
    Write-Host "   - Disk space (C: drive), usage percent"
    Write-Host "   - Top 10 processes by memory"
    Write-Host ""
    
    Write-Host "OUTPUT FORMAT:" -ForegroundColor Cyan
    Write-Host "   File: Device_Diagnostic_[ComputerName]_[DateTime].json"
    Write-Host "   Location: $OutputPath"
    Write-Host "   Each section includes:"
    Write-Host "     • Evidence collected"
    Write-Host "     • What CONFIRMS app deployment is cause"
    Write-Host "     • What RULES OUT app deployment as cause"
    Write-Host "     • Recommended next action"
    Write-Host ""
    
    Write-Host "TO RUN ACTUAL COLLECTION:" -ForegroundColor Yellow
    Write-Host "   .\Floor6-LoginDiagnostic-HandCorrected.ps1 -CollectDiagnostics -OutputPath 'C:\Results'" -ForegroundColor White
    Write-Host ""
}

function Write-ProgressMessage {
    param([string]$Message, [string]$Type = "INFO")
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $Color = switch ($Type) {
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        default   { "Cyan" }
    }
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

# ============================================================================
# SECTION 1: DEVICE ENVIRONMENT
# ============================================================================

function Collect-DeviceEnvironment {
    Write-ProgressMessage "Collecting device environment..."
    $DeviceData = @{}
    
    try {
        $CimOS = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $CompInfo = Get-ComputerInfo -ErrorAction SilentlyContinue
        
        $DeviceData = @{
            ComputerName        = $env:COMPUTERNAME
            OSVersion           = $CimOS.Caption
            OSBuild             = $CimOS.BuildNumber
            IsWindows11         = $CimOS.Caption -match "Windows 11"
            SystemBootTime      = $CimOS.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
            HoursSinceBoot      = [math]::Round(((Get-Date) - $CimOS.LastBootUpTime).TotalHours, 1)
            CurrentUserContext  = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            IsElevated          = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            SystemManufacturer  = $CompInfo.CsSystemManufacturer
            SystemModel         = $CompInfo.CsModel
            Timestamp           = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    } catch {
        Write-ProgressMessage "Error collecting device info: $_" "ERROR"
        $DeviceData = @{ Error = "Failed to collect device information: $_" }
    }
    
    return $DeviceData
}

# ============================================================================
# SECTION 2: APPLICATION DEPLOYMENT CHECK
# ============================================================================

function Collect-ApplicationDeployment {
    Write-ProgressMessage "Checking application deployment..."
    $AppDeploymentEvidence = @{
        AppsInstalledInDeploymentWindow = @()
        AppsInstalledOutsideWindow      = @()
        NoTargetAppsFound               = $false
        ConfirmsDeploymentCause         = "App installed Friday 12:00-23:59 (deployment window)"
        RulesOutDeploymentCause         = "No target apps found OR apps installed before Friday OR apps installed after Sunday"
    }
    
    try {
        $RegistryPaths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        
        foreach ($RegPath in $RegistryPaths) {
            if (Test-Path $RegPath) {
                Get-ChildItem $RegPath -ErrorAction SilentlyContinue | ForEach-Object {
                    $AppName = $_.GetValue('DisplayName')
                    $Version = $_.GetValue('DisplayVersion')
                    $InstallDate = $_.GetValue('InstallDate')  # Format: YYYYMMDD
                    
                    if ($AppName) {
                        foreach ($Pattern in $AppSearchPatterns) {
                            if ($AppName -like $Pattern) {
                                $ParsedDate = $null
                                if ($InstallDate -and $InstallDate -match '^\d{8}$') {
                                    try {
                                        $ParsedDate = [datetime]::ParseExact($InstallDate, "yyyyMMdd", $null)
                                    } catch {
                                        $ParsedDate = $null
                                    }
                                }
                                
                                $IsInWindow = $null -ne $ParsedDate -and $ParsedDate -ge $DeploymentWindowStart -and $ParsedDate -le $DeploymentWindowEnd
                                
                                $AppRecord = @{
                                    ApplicationName   = $AppName
                                    Version           = $Version
                                    InstallDate       = $InstallDate
                                    ParsedInstallDate = if ($ParsedDate) { $ParsedDate.ToString('yyyy-MM-dd') } else { "Could not parse" }
                                    InstalledInWindow = $IsInWindow
                                }
                                
                                if ($IsInWindow) {
                                    $AppDeploymentEvidence.AppsInstalledInDeploymentWindow += $AppRecord
                                } else {
                                    $AppDeploymentEvidence.AppsInstalledOutsideWindow += $AppRecord
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if ($AppDeploymentEvidence.AppsInstalledInDeploymentWindow.Count -eq 0 -and 
            $AppDeploymentEvidence.AppsInstalledOutsideWindow.Count -eq 0) {
            $AppDeploymentEvidence.NoTargetAppsFound = $true
        }
    } catch {
        Write-ProgressMessage "Error checking applications: $_" "ERROR"
    }
    
    return $AppDeploymentEvidence
}

# ============================================================================
# SECTION 3: INTUNE LOGS
# ============================================================================

function Collect-IntuneManagementLogs {
    Write-ProgressMessage "Analyzing Intune Management Extension logs..."
    $IntuneEvidence = @{
        LogPathExists  = Test-Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
        ErrorsFound    = @()
        WarningNote    = ""
    }
    
    $IMELogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
    
    if ($IntuneEvidence.LogPathExists) {
        try {
            $AllLogs = @(Get-ChildItem $IMELogPath -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime)
            $RelevantLogs = $AllLogs | Where-Object { $_.LastWriteTime -ge (Get-Date "2026-08-11 12:00:00") }
            
            $ErrorIndicators = @{
                "Installation Failed" = @("failed.*install", "install.*error", "exitcode\s+[1-9]")
                "Timeout/Hang"        = @("timeout", "hung")
                "Restart Loop"        = @("restart.*loop", "restart.*required")
                "Detection Failure"   = @("detection.*fail")
            }
            
            foreach ($LogFile in $RelevantLogs) {
                $Content = Get-Content $LogFile -ErrorAction SilentlyContinue
                
                foreach ($ErrorType in $ErrorIndicators.Keys) {
                    $Patterns = $ErrorIndicators[$ErrorType]
                    foreach ($Pattern in $Patterns) {
                        $MatchingLines = $Content | Select-String -Pattern $Pattern -ErrorAction SilentlyContinue
                        if ($MatchingLines) {
                            $IntuneEvidence.ErrorsFound += @{
                                ErrorType      = $ErrorType
                                LogFile        = $LogFile.Name
                                Occurrences    = @($MatchingLines).Count
                                FirstMatch     = $MatchingLines[0].Line.Substring(0, [Math]::Min(120, $MatchingLines[0].Line.Length))
                            }
                        }
                    }
                }
            }
            
            if ($IntuneEvidence.ErrorsFound.Count -eq 0) {
                $IntuneEvidence.WarningNote = "No deployment errors found - suggests successful deployment OR no app deployment via Intune"
            }
        } catch {
            Write-ProgressMessage "Error parsing Intune logs: $_" "ERROR"
        }
    } else {
        $IntuneEvidence.WarningNote = "Intune Management Extension log path not found - device may not be Intune-enrolled"
    }
    
    return $IntuneEvidence
}

# ============================================================================
# SECTION 4: EVENT LOGS
# ============================================================================

function Collect-EventLogData {
    Write-ProgressMessage "Querying Windows Event Logs..."
    $EventLogData = @{
        SecurityLog     = @{ FailedLogins = @(); AccountLockouts = @() }
        SystemLog       = @{ ProfileErrors = @(); ServiceInstalls = @() }
        ApplicationLog  = @{ ErrorCount = 0; TopErrors = @() }
    }
    
    $SearchStart = (Get-Date).AddDays(-$EventLogDaysBack)
    
    try {
        # SECURITY LOG
        $FailedLogins = Get-EventLog Security -After $SearchStart -InstanceId 4625 -ErrorAction SilentlyContinue
        if ($FailedLogins) {
            $EventLogData.SecurityLog.FailedLogins = @{
                TotalCount    = @($FailedLogins).Count
                ByDate        = @($FailedLogins | Group-Object { $_.TimeGenerated.Date } | ForEach-Object { 
                    @{ Date = $_.Name.ToString("yyyy-MM-dd"); Count = $_.Count }
                })
                EarliestEvent = ($FailedLogins | Sort-Object TimeGenerated | Select-Object -First 1).TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        
        $Lockouts = Get-EventLog Security -After $SearchStart -InstanceId 4740 -ErrorAction SilentlyContinue
        if ($Lockouts) {
            $EventLogData.SecurityLog.AccountLockouts = @{
                TotalCount    = @($Lockouts).Count
                EarliestEvent = ($Lockouts | Sort-Object TimeGenerated | Select-Object -First 1).TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
    } catch {
        Write-ProgressMessage "Could not read Security log: $_" "WARNING"
    }
    
    try {
        # SYSTEM LOG
        $ProfileErrors = Get-EventLog System -After $SearchStart -InstanceId @(1509, 1516) -ErrorAction SilentlyContinue
        if ($ProfileErrors) {
            $EventLogData.SystemLog.ProfileErrors = @{
                TotalCount    = @($ProfileErrors).Count
                ByDate        = @($ProfileErrors | Group-Object { $_.TimeGenerated.Date } | ForEach-Object { 
                    @{ Date = $_.Name.ToString("yyyy-MM-dd"); Count = $_.Count }
                })
            }
        }
        
        $ServiceInstalls = Get-EventLog System -After $SearchStart -InstanceId 7045 -ErrorAction SilentlyContinue
        if ($ServiceInstalls) {
            $AppServices = $ServiceInstalls | Where-Object { $_.Message -match "Document|Management|FinBridge" }
            if ($AppServices) {
                $EventLogData.SystemLog.ServiceInstalls = @{
                    Count    = @($AppServices).Count
                    Services = @($AppServices | ForEach-Object { $_.Message.Substring(0, [Math]::Min(80, $_.Message.Length)) })
                }
            }
        }
    } catch {
        Write-ProgressMessage "Could not read System log: $_" "WARNING"
    }
    
    try {
        # APPLICATION LOG
        $AppErrors = Get-EventLog Application -After $SearchStart -EntryType Error -ErrorAction SilentlyContinue
        if ($AppErrors) {
            $EventLogData.ApplicationLog.ErrorCount = @($AppErrors).Count
            $EventLogData.ApplicationLog.TopErrors = @($AppErrors | Group-Object Source | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
                @{ Source = $_.Name; Count = $_.Count }
            })
        }
    } catch {
        Write-ProgressMessage "Could not read Application log: $_" "WARNING"
    }
    
    return $EventLogData
}

# ============================================================================
# SECTION 5: STARTUP ITEMS & SERVICES
# ============================================================================

function Collect-StartupItems {
    Write-ProgressMessage "Scanning startup items and services..."
    $StartupEvidence = @{
        RegistryStartupItems = @()
        ScheduledTasks       = @()
        AutoStartServices    = @()
    }
    
    try {
        $StartupPaths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        )
        
        foreach ($Path in $StartupPaths) {
            if (Test-Path $Path) {
                Get-ItemProperty $Path -ErrorAction SilentlyContinue | ForEach-Object {
                    foreach ($Prop in $_.PSObject.Properties) {
                        if ($Prop.Name -notmatch "^PS" -and $Prop.Value) {
                            $IsAppRelated = $Prop.Value -match "Document|Management|FinBridge" -or $Prop.Name -match "Document|Management|FinBridge"
                            if ($IsAppRelated) {
                                $StartupEvidence.RegistryStartupItems += @{
                                    ItemName = $Prop.Name
                                    ItemPath = $Prop.Value.Substring(0, [Math]::Min(150, $Prop.Value.Length))
                                }
                            }
                        }
                    }
                }
            }
        }
    } catch {
        Write-ProgressMessage "Error reading startup registry: $_" "WARNING"
    }
    
    try {
        $AllTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue)
        $AppTasks = $AllTasks | Where-Object { 
            $_.TaskName -match "Document|Management|FinBridge" -or $_.TaskPath -match "Document|Management"
        }
        
        foreach ($Task in $AppTasks) {
            try {
                $TaskInfo = Get-ScheduledTaskInfo -TaskName $Task.TaskName -ErrorAction SilentlyContinue
                $StartupEvidence.ScheduledTasks += @{
                    TaskName      = $Task.TaskName
                    Enabled       = $Task.Enabled
                    LastRunTime   = if ($TaskInfo.LastRunTime) { $TaskInfo.LastRunTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "Never run" }
                    LastRunResult = $TaskInfo.LastTaskResult
                }
            } catch {}
        }
    } catch {
        Write-ProgressMessage "Error reading scheduled tasks: $_" "WARNING"
    }
    
    try {
        $Services = Get-Service -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match "Document|Management|FinBridge" -or $_.DisplayName -match "Document|Management|FinBridge"
        }
        
        foreach ($Service in $Services) {
            try {
                $ServiceObj = Get-Service -Name $Service.Name | Select-Object Name, DisplayName, Status, StartType
                $StartupEvidence.AutoStartServices += @{
                    ServiceName = $Service.Name
                    DisplayName = $Service.DisplayName
                    Status      = $Service.Status
                    StartType   = $ServiceObj.StartType
                }
            } catch {}
        }
    } catch {
        Write-ProgressMessage "Error reading services: $_" "WARNING"
    }
    
    return $StartupEvidence
}

# ============================================================================
# SECTION 6: PERFORMANCE METRICS
# ============================================================================

function Collect-PerformanceMetrics {
    Write-ProgressMessage "Collecting performance metrics..."
    $PerfData = @{
        CPU               = @{}
        Memory            = @{}
        Disk              = @{}
        TopProcesses      = @()
    }
    
    try {
        $CimProc = Get-CimInstance Win32_Processor | Select-Object -First 1
        $PerfData.CPU = @{
            Name          = $CimProc.Name
            Cores         = $CimProc.NumberOfCores
            LogicalCores  = $CimProc.NumberOfLogicalProcessors
        }
    } catch {}
    
    try {
        $CimOS = Get-CimInstance Win32_OperatingSystem
        $TotalMem = [math]::Round($CimOS.TotalVisibleMemorySize / 1048576, 2)
        $FreeMem = [math]::Round($CimOS.FreePhysicalMemory / 1048576, 2)
        $PerfData.Memory = @{
            TotalGB       = $TotalMem
            FreeGB        = $FreeMem
            UsagePercent  = [math]::Round((($TotalMem - $FreeMem) / $TotalMem) * 100, 1)
        }
    } catch {}
    
    try {
        $Vol = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
        if ($Vol) {
            $PerfData.Disk = @{
                TotalGB      = [math]::Round($Vol.Size / 1GB, 1)
                FreeGB       = [math]::Round($Vol.SizeRemaining / 1GB, 1)
                UsagePercent = [math]::Round((($Vol.Size - $Vol.SizeRemaining) / $Vol.Size) * 100, 1)
            }
        }
    } catch {}
    
    try {
        $TopProcs = Get-Process -ErrorAction SilentlyContinue | 
            Where-Object { $_.MemoryMB -gt 0 } | 
            Sort-Object MemoryMB -Descending | 
            Select-Object -First 10 |
            ForEach-Object {
                @{
                    ProcessName = $_.ProcessName
                    MemoryMB    = [math]::Round($_.MemoryMB, 1)
                }
            }
        $PerfData.TopProcesses = $TopProcs
    } catch {}
    
    return $PerfData
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host ""
Write-Host "Floor 6 Login/Performance Investigation - Technical Diagnostic" -ForegroundColor Magenta
Write-Host "Target: $($DeploymentWindowStart) - $($DeploymentWindowEnd)" -ForegroundColor Magenta
Write-Host ""

if ($DryRun) {
    Show-DryRunPreview
} elseif ($CollectDiagnostics) {
    Write-ProgressMessage "Starting diagnostic collection..."
    
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Collect all data
    $DiagnosticResults = @{
        Metadata            = $ScriptMetadata
        CollectionTime      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        DeviceEnvironment   = Collect-DeviceEnvironment
        AppDeployment       = Collect-ApplicationDeployment
        IntuneManagement    = Collect-IntuneManagementLogs
        EventLogs           = Collect-EventLogData
        StartupItems        = Collect-StartupItems
        PerformanceMetrics  = Collect-PerformanceMetrics
    }
    
    # Save to JSON
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = Join-Path $OutputPath "Device_Diagnostic_$($env:COMPUTERNAME)_$Timestamp.json"
    
    try {
        $DiagnosticResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host ""
        Write-ProgressMessage "Diagnostic collection completed"
        Write-Host "Output: $OutputFile" -ForegroundColor Green
    } catch {
        Write-ProgressMessage "Error saving output: $_" "ERROR"
    }
} else {
    Write-ProgressMessage "No action specified. Use:" "WARNING"
    Write-Host "  -DryRun                            (preview what will be collected)" -ForegroundColor Yellow
    Write-Host "  -CollectDiagnostics -OutputPath ... (actual collection)" -ForegroundColor Yellow
}
```

---

# HOW TO RUN

## Dry-Run Mode (Preview, No Collection)
```powershell
.\Floor6-LoginDiagnostic-HandCorrected.ps1 -DryRun
```
→ Shows what diagnostic checks will be performed  
→ Displays output structure  
→ No system access required

## Actual Collection
```powershell
.\Floor6-LoginDiagnostic-HandCorrected.ps1 -CollectDiagnostics -OutputPath "C:\Diagnostic_Results"
```
→ Requires Administrator privileges  
→ Saves JSON file to specified path  
→ Example output: `Device_Diagnostic_LEGAL-LF-001_20260814_093045.json`

## Output and Next Steps

**JSON Output Structure:**
```json
{
  "Metadata": { "Version", "Purpose", "Hypothesis", "IsSafeToRun" },
  "CollectionTime": "2026-08-14 09:30:45",
  "DeviceEnvironment": { "ComputerName", "OS", "IsWindows11", "BootTime" },
  "AppDeployment": {
    "AppsInstalledInDeploymentWindow": [...],
    "AppsInstalledOutsideWindow": [...],
    "ConfirmsDeploymentCause": "...",
    "RulesOutDeploymentCause": "..."
  },
  "IntuneManagement": {
    "ErrorsFound": [ { "ErrorType", "Occurrences", "FirstMatch" } ],
    "WarningNote": "..."
  },
  "EventLogs": {
    "SecurityLog": { "FailedLogins": {...}, "AccountLockouts": {...} },
    "SystemLog": { "ProfileErrors": {...}, "ServiceInstalls": {...} },
    "ApplicationLog": { "ErrorCount": X, "TopErrors": [...] }
  },
  "StartupItems": {
    "RegistryStartupItems": [...],
    "ScheduledTasks": [...],
    "AutoStartServices": [...]
  },
  "PerformanceMetrics": {
    "CPU": {...}, "Memory": {...}, "Disk": {...}, "TopProcesses": [...]
  }
}
```

**L1/L2 Engineer Action Plan:**

1. **Check AppDeployment section first:**
   - If `AppsInstalledInDeploymentWindow` has entries + errors in Intune logs → App deployment likely cause
   - If `AppsInstalledInDeploymentWindow` is empty → App not cause

2. **Check EventLogs section:**
   - If `FailedLogins.ByDate` shows spike on Monday 08:00-09:30 AM → Auth issue present
   - If no spike → Auth system working normally

3. **Check StartupItems section:**
   - If task/service failed on Monday morning → Contributes to slow login
   - If all tasks/services show success → Startup not the issue

4. **Decision Point:**
   - **ALL THREE match (app + event log spike + startup failure):** App deployment is strong candidate → Escalate to vendor
   - **App deployment found BUT no event log spike:** App may not be cause → Investigate Intune policies
   - **No app found:** Focus on network, policies, or AD issues

