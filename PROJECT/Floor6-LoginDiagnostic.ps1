# ============================================================================
# TECHNICAL DIAGNOSTIC SCRIPT: Floor 6 Login/Performance Issue Investigation
# FinBridge Legal Department | Windows 11 Migration Cohort
# Date: 2026-08-14 | Script Purpose: Non-destructive evidence collection
# AI-GENERATED: This script was created by an AI assistant based on DWP methodology
# ============================================================================
# 
# OVERVIEW:
# This script performs read-only diagnostic checks on a Floor 6 device
# to determine if the Friday document management app deployment caused
# Monday login/performance issues. Evidence is collected in JSON format
# for structured analysis and escalation.
#
# SAFETY: This script is READ-ONLY. It does not modify, restart, remove,
# or disable anything. Safe to run on production systems.
#
# USAGE:
#   Dry-run (preview what would be collected):
#   .\Floor6-LoginDiagnostic.ps1 -DryRun
#
#   Actual collection (saves JSON to file):
#   .\Floor6-LoginDiagnostic.ps1 -OutputPath "C:\Diagnostic_Results"
#
# OUTPUT:
#   JSON file: Device_Diagnostic_[ComputerName]_[DateTime].json
#   Contains: Device info, app details, event logs, services, tasks, performance metrics
#
# ============================================================================

param(
    [switch]$DryRun = $false,
    [string]$OutputPath = "C:\Temp",
    [int]$EventLogDaysBack = 3  # Search last 3 days of events
)

# ============================================================================
# CONFIGURATION & CONSTANTS
# ============================================================================

$ScriptVersion = "1.0.0"
$ScriptCreatedDate = "2026-08-14"
$TargetApplicationNames = @(
    "DocumentManagementApp",
    "FinBridge Document Manager",
    "Docs Management",
    "Document Management"
)

# Friday deployment date for filtering
$DeploymentDateStart = [datetime]"2026-08-11 12:00:00"
$DeploymentDateEnd = [datetime]"2026-08-11 23:59:59"

# Criteria for "slow login" evidence
$SlowLoginThresholdSeconds = 30

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Output progress messages (visible in both dry-run and actual)
function Write-Progress-Message {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Cyan
}

# Convert object to JSON with proper formatting
function ConvertTo-JsonIndented {
    param([object]$Object)
    $Object | ConvertTo-Json -Depth 10 | Out-String
}

# Create diagnostic evidence object
function New-DiagnosticEvidence {
    param(
        [string]$CheckName,
        [string]$Category,
        [object]$Evidence,
        [string]$ConfirmsDeploymentCause,
        [string]$RulesOutDeploymentCause,
        [string]$RecommendedAction,
        [string]$Severity = "INFO"  # INFO, WARNING, CRITICAL
    )

    return @{
        CheckName                    = $CheckName
        Category                     = $Category
        Timestamp                    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Evidence                     = $Evidence
        ConfirmsDeploymentCause      = $ConfirmsDeploymentCause
        RulesOutDeploymentCause      = $RulesOutDeploymentCause
        RecommendedAction            = $RecommendedAction
        Severity                     = $Severity
    }
}

# ============================================================================
# SECTION 1: DEVICE ENVIRONMENT & SYSTEM INFO
# ============================================================================

Write-Progress-Message "=== Section 1: Device Environment & System Information ==="

$DiagnosticResults = [ordered]@{}

# Collect basic device information
if (-not $DryRun) {
    Write-Progress-Message "Collecting device information..."
    
    $SystemInfo = Get-ComputerInfo -ErrorAction SilentlyContinue
    $OSVersion = [System.Environment]::OSVersion.VersionString
    $LastBootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $TimeSinceBoot = [datetime]::Now - $LastBootTime
    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    
    $DiagnosticResults["DeviceEnvironment"] = @{
        ComputerName         = $env:COMPUTERNAME
        OSVersion            = $OSVersion
        OSBuild              = $SystemInfo.OsVersion
        Windows11            = $OSVersion -match "Windows 11"
        LastBootTime         = $LastBootTime
        HoursSinceBoot       = [math]::Round($TimeSinceBoot.TotalHours, 2)
        CurrentUser          = $CurrentUser
        IsElevated           = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        Timestamp            = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
else {
    Write-Progress-Message "[DRY RUN] Would collect: Device name, OS version, Windows 11 status, boot time, current user, elevated status"
}

# ============================================================================
# SECTION 2: INSTALLED APPLICATIONS (App Deployment Check)
# ============================================================================

Write-Progress-Message "=== Section 2: Document Management App Installation Check ==="

if (-not $DryRun) {
    Write-Progress-Message "Scanning installed applications..."
    
    $InstalledApps = @()
    
    # Check Registry for installed applications (all hives)
    try {
        $RegistryPaths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($Path in $RegistryPaths) {
            $Apps = Get-ItemProperty $Path -ErrorAction SilentlyContinue | 
                Where-Object { $_.DisplayName -and $_.InstallDate } |
                Select-Object -Property DisplayName, DisplayVersion, InstallDate, UninstallString, Publisher
            
            $InstalledApps += $Apps
        }
    }
    catch {
        Write-Progress-Message "Warning: Could not access registry for app enumeration: $_"
    }
    
    # Filter for target application
    $TargetAppInstalled = $null
    $TargetAppInstalledRecently = $false
    $TargetAppDetails = @()
    
    foreach ($App in $InstalledApps) {
        foreach ($TargetName in $TargetApplicationNames) {
            if ($App.DisplayName -like "*$TargetName*") {
                $TargetAppInstalled = $App.DisplayName
                
                # Check if installed on/after Friday (deployment date)
                if ($App.InstallDate) {
                    try {
                        $InstallDate = [datetime]::ParseExact($App.InstallDate, "yyyyMMdd", $null)
                        if ($InstallDate -ge $DeploymentDateStart -and $InstallDate -le $DeploymentDateEnd) {
                            $TargetAppInstalledRecently = $true
                        }
                    }
                    catch {
                        # If we can't parse the date, flag it for manual review
                        Write-Progress-Message "Warning: Could not parse install date for $($App.DisplayName)"
                    }
                }
                
                $TargetAppDetails += @{
                    DisplayName    = $App.DisplayName
                    Version        = $App.DisplayVersion
                    InstallDate    = $App.InstallDate
                    Publisher      = $App.Publisher
                    InDeploymentWindow = $TargetAppInstalledRecently
                }
            }
        }
    }
    
    $DiagnosticResults["ApplicationDeployment"] = @{
        TargetApplicationFound           = $null -ne $TargetAppInstalled
        TargetApplicationName            = $TargetAppInstalled
        InstalledInDeploymentWindow      = $TargetAppInstalledRecently
        DeploymentWindowStart            = $DeploymentDateStart
        DeploymentWindowEnd              = $DeploymentDateEnd
        TargetApplicationDetails         = $TargetAppDetails
        TotalInstalledApplicationCount   = $InstalledApps.Count
        ConfirmsDeploymentCause          = "App found AND installed within deployment window (Fri 12:00-23:59)"
        RulesOutDeploymentCause          = "App not found OR app installed before Friday OR app installed after Sunday"
    }
}
else {
    Write-Progress-Message "[DRY RUN] Would scan: HKLM registry for installed applications, filter for document management app, check install date vs Friday deployment window"
}

# ============================================================================
# SECTION 3: INTUNE MANAGEMENT EXTENSION LOGS
# ============================================================================

Write-Progress-Message "=== Section 3: Intune Management Extension Logs ==="

if (-not $DryRun) {
    Write-Progress-Message "Analyzing Intune Management Extension logs..."
    
    $IMELogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
    $IMEIssuesFound = @()
    $IMEAppRelatedEntries = @()
    
    if (Test-Path $IMELogPath) {
        try {
            # Get most recent log file
            $LatestLogFile = Get-ChildItem -Path $IMELogPath -Filter "*.log" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1
            
            if ($LatestLogFile) {
                $LogContent = Get-Content $LatestLogFile -ErrorAction SilentlyContinue -Tail 1000  # Last 1000 lines
                
                # Search for error patterns
                $ErrorPatterns = @(
                    "ERROR",
                    "FAIL",
                    "Exception",
                    "timeout",
                    "retry",
                    "Installation failed",
                    "Detection loop",
                    "Restart required"
                )
                
                foreach ($Pattern in $ErrorPatterns) {
                    $MatchingLines = $LogContent | Select-String -Pattern $Pattern -ErrorAction SilentlyContinue
                    if ($MatchingLines) {
                        $IMEIssuesFound += @{
                            ErrorPattern    = $Pattern
                            MatchCount      = @($MatchingLines).Count
                            SampleLines     = @($MatchingLines | Select-Object -First 3 | ForEach-Object { $_.Line })
                        }
                    }
                }
                
                # Search for app-related entries
                foreach ($TargetName in $TargetApplicationNames) {
                    $AppMatches = $LogContent | Select-String -Pattern $TargetName -ErrorAction SilentlyContinue
                    if ($AppMatches) {
                        $IMEAppRelatedEntries += @{
                            ApplicationName = $TargetName
                            MatchCount      = @($AppMatches).Count
                            SampleLines     = @($AppMatches | Select-Object -First 2 | ForEach-Object { $_.Line })
                        }
                    }
                }
            }
        }
        catch {
            Write-Progress-Message "Warning: Could not read Intune logs: $_"
        }
    }
    else {
        Write-Progress-Message "Note: Intune Management Extension log path not found (device may not be Intune-enrolled)"
    }
    
    $DiagnosticResults["IntuneManagementExtension"] = @{
        LogPathExists           = Test-Path $IMELogPath
        LogPath                 = $IMELogPath
        ErrorPatternsFound      = $IMEIssuesFound
        AppRelatedLogEntries    = $IMEAppRelatedEntries
        ConfirmsDeploymentCause = "Intune logs show app installation ERROR, FAIL, timeout, or restart loop"
        RulesOutDeploymentCause = "Intune logs show app installed successfully with no errors or app not mentioned"
    }
}
else {
    Write-Progress-Message "[DRY RUN] Would parse: Intune Management Extension logs, search for installation errors, timeouts, restart loops, app-related entries"
}

# ============================================================================
# SECTION 4: WINDOWS EVENT LOGS (Login, User Profile, Group Policy)
# ============================================================================

Write-Progress-Message "=== Section 4: Windows Event Logs Analysis ==="

if (-not $DryRun) {
    Write-Progress-Message "Collecting Windows Event Logs..."
    
    $EventLogAnalysis = @{}
    $StartTime = (Get-Date).AddDays(-$EventLogDaysBack)
    
    # Define event log sources to check
    $EventLogSources = @{
        "Security"      = @(4625, 4624, 4634)  # Failed logon, successful logon, logoff
        "System"        = @(1509, 1516, 6005, 6006)  # Profile errors, boot/shutdown
        "Application"   = @()  # Search for errors
    }
    
    foreach ($LogName in @("Security", "System", "Application")) {
        $EventsFound = @()
        
        try {
            if ($LogName -eq "Application") {
                # For Application log, search for general errors in last 3 days
                $Events = Get-EventLog -LogName $LogName -After $StartTime -EntryType Error -ErrorAction SilentlyContinue |
                    Select-Object -First 50 |
                    Select-Object TimeGenerated, EventID, Source, Message
            }
            else {
                # For Security and System, search specific event IDs
                $SpecificEventIDs = $EventLogSources[$LogName]
                $Events = @()
                foreach ($EventID in $SpecificEventIDs) {
                    $Events += Get-EventLog -LogName $LogName -InstanceId $EventID -After $StartTime -ErrorAction SilentlyContinue |
                        Select-Object TimeGenerated, EventID, Source, Message
                }
                $Events = $Events | Sort-Object TimeGenerated -Descending | Select-Object -First 50
            }
            
            # Count by severity
            $EventCount = @($Events).Count
            $CriticalEvents = @($Events | Where-Object { $_.Message -match "CRITICAL|FAIL|ERROR" }).Count
            
            $EventLogAnalysis[$LogName] = @{
                LogName                 = $LogName
                EventsInLastDays        = $EventLogDaysBack
                EventsFound             = $EventCount
                CriticalErrorsFound     = $CriticalEvents
                RecentEvents            = @($Events | ForEach-Object {
                    @{
                        TimeGenerated = $_.TimeGenerated
                        EventID       = $_.EventID
                        Source        = $_.Source
                        Message       = $_.Message.Substring(0, [Math]::Min(200, $_.Message.Length))
                    }
                })
                ConfirmsDeploymentCause = "Multiple login failures (EventID 4625), profile load errors (1509/1516), or app-related errors"
                RulesOutDeploymentCause = "No login failures, no profile errors, no authentication-related events"
            }
        }
        catch {
            Write-Progress-Message "Warning: Could not read $LogName event log: $_"
            $EventLogAnalysis[$LogName] = @{
                LogName  = $LogName
                Error    = "Could not read log: $_"
            }
        }
    }
    
    $DiagnosticResults["EventLogs"] = $EventLogAnalysis
}
else {
    Write-Progress-Message "[DRY RUN] Would query: Security log (failed logons, logons, logoffs), System log (profile errors, boot events), Application log (general errors)"
}

# ============================================================================
# SECTION 5: STARTUP ITEMS, SCHEDULED TASKS, SERVICES
# ============================================================================

Write-Progress-Message "=== Section 5: Startup Items, Scheduled Tasks, and Services ==="

if (-not $DryRun) {
    Write-Progress-Message "Scanning startup items and services..."
    
    $StartupItemsFound = @()
    $ScheduledTasksFound = @()
    $ServicesFound = @()
    
    # Check startup registry and folder
    try {
        $StartupRegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
        $StartupRegItems = Get-ItemProperty $StartupRegPath -ErrorAction SilentlyContinue
        
        foreach ($Item in $StartupRegItems.PSObject.Properties) {
            if ($Item.Name -ne "PSPath" -and $Item.Name -ne "PSParentPath" -and $Item.Name -ne "PSChildName" -and $Item.Name -ne "PSDrive" -and $Item.Name -ne "PSProvider") {
                # Check if matches target app
                $IsTargetApp = $false
                foreach ($TargetName in $TargetApplicationNames) {
                    if ($Item.Value -match $TargetName) {
                        $IsTargetApp = $true
                    }
                }
                
                $StartupItemsFound += @{
                    ItemName       = $Item.Name
                    ItemPath       = $Item.Value
                    IsTargetApp    = $IsTargetApp
                    Source         = "Registry"
                }
            }
        }
    }
    catch {
        Write-Progress-Message "Note: Could not read startup registry items"
    }
    
    # Check Startup folder
    $StartupFolders = @(
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    )
    
    foreach ($Folder in $StartupFolders) {
        if (Test-Path $Folder) {
            $StartupFiles = Get-ChildItem $Folder -Recurse -ErrorAction SilentlyContinue |
                Select-Object Name, FullPath, CreationTime, LastWriteTime
            
            foreach ($File in $StartupFiles) {
                $IsTargetApp = $false
                foreach ($TargetName in $TargetApplicationNames) {
                    if ($File.Name -match $TargetName) {
                        $IsTargetApp = $true
                    }
                }
                
                $StartupItemsFound += @{
                    ItemName       = $File.Name
                    ItemPath       = $File.FullPath
                    CreatedTime    = $File.CreationTime
                    ModifiedTime   = $File.LastWriteTime
                    IsTargetApp    = $IsTargetApp
                    Source         = "Folder"
                }
            }
        }
    }
    
    # Check for scheduled tasks related to app
    try {
        $AllTasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -eq "Ready" }
        
        foreach ($Task in $AllTasks) {
            $IsTargetApp = $false
            foreach ($TargetName in $TargetApplicationNames) {
                if ($Task.TaskName -match $TargetName -or $Task.Description -match $TargetName) {
                    $IsTargetApp = $true
                }
            }
            
            if ($IsTargetApp) {
                $ScheduledTasksFound += @{
                    TaskName          = $Task.TaskName
                    TaskPath          = $Task.TaskPath
                    State             = $Task.State
                    Enabled           = $Task.Enabled
                    LastRunTime       = (Get-ScheduledTaskInfo -TaskName $Task.TaskName -ErrorAction SilentlyContinue).LastRunTime
                    IsTargetApp       = $true
                }
            }
        }
    }
    catch {
        Write-Progress-Message "Note: Could not enumerate scheduled tasks"
    }
    
    # Check for services related to app
    try {
        $AllServices = Get-Service -ErrorAction SilentlyContinue
        
        foreach ($Service in $AllServices) {
            $IsTargetApp = $false
            foreach ($TargetName in $TargetApplicationNames) {
                if ($Service.Name -match $TargetName -or $Service.DisplayName -match $TargetName) {
                    $IsTargetApp = $true
                }
            }
            
            if ($IsTargetApp) {
                $ServicesFound += @{
                    ServiceName    = $Service.Name
                    DisplayName    = $Service.DisplayName
                    Status         = $Service.Status
                    StartType      = (Get-Service $Service.Name | Get-ItemProperty -Name StartType -ErrorAction SilentlyContinue).StartType
                    IsTargetApp    = $true
                }
            }
        }
    }
    catch {
        Write-Progress-Message "Note: Could not enumerate services"
    }
    
    $DiagnosticResults["StartupItems"] = @{
        RegisteredStartupItems     = $StartupItemsFound
        ScheduledTasks             = $ScheduledTasksFound
        Services                   = $ServicesFound
        ConfirmsDeploymentCause    = "Startup item, task, or service added by target app; crashes or hangs; runs at logon and causes delays"
        RulesOutDeploymentCause    = "No startup items or services from target app found; existing items not related to app"
    }
}
else {
    Write-Progress-Message "[DRY RUN] Would scan: Registry startup keys, Startup folders, scheduled tasks, Windows services for app-related items"
}

# ============================================================================
# SECTION 6: PERFORMANCE METRICS (CPU, Memory, Disk)
# ============================================================================

Write-Progress-Message "=== Section 6: System Performance Metrics ==="

if (-not $DryRun) {
    Write-Progress-Message "Collecting performance metrics..."
    
    $PerformanceData = @{}
    
    # CPU and Memory
    try {
        $CPUInfo = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $MemoryInfo = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
        $OperatingSystem = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        
        $PerformanceData["CPU"] = @{
            Name           = $CPUInfo.Name
            Cores          = $CPUInfo.NumberOfCores
            LogicalCores   = $CPUInfo.NumberOfLogicalProcessors
        }
        
        $PerformanceData["Memory"] = @{
            TotalMemoryGB      = [math]::Round($OperatingSystem.TotalVisibleMemorySize / 1048576, 2)
            FreeMemoryGB       = [math]::Round($OperatingSystem.FreePhysicalMemory / 1048576, 2)
            MemoryUsagePercent = [math]::Round((($OperatingSystem.TotalVisibleMemorySize - $OperatingSystem.FreePhysicalMemory) / $OperatingSystem.TotalVisibleMemorySize) * 100, 2)
        }
    }
    catch {
        Write-Progress-Message "Note: Could not collect CPU/Memory info"
    }
    
    # Disk space
    try {
        $SystemDrive = $env:SystemDrive
        $DiskInfo = Get-Volume -DriveLetter $SystemDrive[0] -ErrorAction SilentlyContinue
        
        if ($DiskInfo) {
            $PerformanceData["DiskSpace"] = @{
                DriveLetter        = "$($SystemDrive)\"
                TotalSizeGB        = [math]::Round($DiskInfo.Size / 1GB, 2)
                FreeSizeGB         = [math]::Round($DiskInfo.SizeRemaining / 1GB, 2)
                UsagePercent       = [math]::Round((($DiskInfo.Size - $DiskInfo.SizeRemaining) / $DiskInfo.Size) * 100, 2)
                IsLowDiskSpace     = $DiskInfo.SizeRemaining / $DiskInfo.Size -lt 0.1
            }
        }
    }
    catch {
        Write-Progress-Message "Note: Could not collect disk space info"
    }
    
    # Top processes by memory
    try {
        $TopProcesses = Get-Process -ErrorAction SilentlyContinue |
            Where-Object { $_.MemoryMB -gt 0 } |
            Sort-Object MemoryMB -Descending |
            Select-Object -First 10 |
            ForEach-Object {
                @{
                    ProcessName  = $_.ProcessName
                    MemoryMB     = [math]::Round($_.MemoryMB, 2)
                    CPUPercent   = [math]::Round($_.CPU, 2)
                    HandleCount  = $_.Handles
                }
            }
        
        $PerformanceData["TopProcessesByMemory"] = $TopProcesses
    }
    catch {
        Write-Progress-Message "Note: Could not collect process information"
    }
    
    $DiagnosticResults["PerformanceMetrics"] = @{
        MetricsCollected           = $PerformanceData
        ConfirmsDeploymentCause    = "Memory/disk usage abnormally high; process related to app consuming excessive resources"
        RulesOutDeploymentCause    = "Memory/disk usage normal; no app processes consuming excessive resources"
    }
}
else {
    Write-Progress-Message "[DRY RUN] Would collect: CPU cores, total/free memory, disk space, top processes by memory usage"
}

# ============================================================================
# SECTION 7: APPLICATION LOGON SCRIPT AND INTEGRATION
# ============================================================================

Write-Progress-Message "=== Section 7: Application Logon Script Check ==="

if (-not $DryRun) {
    Write-Progress-Message "Checking for app-related logon scripts..."
    
    $LogonScriptsFound = @()
    
    # Check common logon script locations
    $ScriptLocations = @(
        "$env:ProgramFiles\*\Logon.bat",
        "$env:ProgramFiles\*\Logon.cmd",
        "$env:ProgramFiles\*\Logon.ps1",
        "C:\Windows\System32\*\Logon.bat",
        "C:\Windows\System32\*\Logon.cmd"
    )
    
    foreach ($ScriptPattern in $ScriptLocations) {
        try {
            $Scripts = Get-Item $ScriptPattern -ErrorAction SilentlyContinue
            foreach ($Script in $Scripts) {
                $IsTargetApp = $false
                foreach ($TargetName in $TargetApplicationNames) {
                    if ($Script.FullPath -match $TargetName) {
                        $IsTargetApp = $true
                    }
                }
                
                if ($IsTargetApp) {
                    $LogonScriptsFound += @{
                        ScriptPath     = $Script.FullPath
                        CreatedTime    = $Script.CreationTime
                        ModifiedTime   = $Script.LastWriteTime
                        SizeBytes      = $Script.Length
                    }
                }
            }
        }
        catch {
            # Silent continue for pattern matching
        }
    }
    
    $DiagnosticResults["LogonScripts"] = @{
        LogonScriptsFound          = $LogonScriptsFound
        ScriptCount                = $LogonScriptsFound.Count
        ConfirmsDeploymentCause    = "App logon script found; script execution would cause login delay if script is slow or crashes"
        RulesOutDeploymentCause    = "No logon scripts found from app; or existing scripts complete quickly"
    }
}
else {
    Write-Progress-Message "[DRY RUN] Would search: Common logon script locations for app-related scripts"
}

# ============================================================================
# SECTION 8: EVIDENCE SUMMARY & RECOMMENDATIONS
# ============================================================================

Write-Progress-Message "=== Section 8: Diagnostic Summary ==="

$DiagnosticSummary = @{
    ScriptVersion               = $ScriptVersion
    ScriptCreatedDate           = $ScriptCreatedDate
    DiagnosticRunDate           = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TargetDevice                = $env:COMPUTERNAME
    DryRunMode                  = $DryRun
    EventLogSearchDays          = $EventLogDaysBack
    TargetApplicationsSearched  = $TargetApplicationNames
    DeploymentWindowStart       = $DeploymentDateStart
    DeploymentWindowEnd         = $DeploymentDateEnd
}

$DiagnosticResults["DiagnosticSummary"] = $DiagnosticSummary

# ============================================================================
# OUTPUT: SAVE JSON OR DISPLAY
# ============================================================================

Write-Progress-Message "=== Preparing Output ==="

if ($DryRun) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "DRY RUN MODE: No data collected" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "This script will collect the following diagnostic information:" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($Section in $DiagnosticResults.Keys) {
        Write-Host "[$Section]" -ForegroundColor Yellow
        if ($DiagnosticResults[$Section] -is [hashtable]) {
            foreach ($Key in $DiagnosticResults[$Section].Keys) {
                Write-Host "  • $Key"
            }
        }
        Write-Host ""
    }
    
    Write-Host "To run actual diagnostic collection, use:" -ForegroundColor Cyan
    Write-Host "  .\Floor6-LoginDiagnostic.ps1 -OutputPath 'C:\Diagnostic_Results'" -ForegroundColor White
    Write-Host ""
}
else {
    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Generate output filename
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFileName = "Device_Diagnostic_$($env:COMPUTERNAME)_$Timestamp.json"
    $OutputFilePath = Join-Path -Path $OutputPath -ChildPath $OutputFileName
    
    # Convert results to JSON and save
    try {
        $DiagnosticResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFilePath -Encoding UTF8
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Diagnostic collection completed successfully" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Output file saved: $OutputFilePath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "File size: $(((Get-Item $OutputFilePath).Length / 1KB).ToString('F2')) KB" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "NEXT STEPS:" -ForegroundColor Yellow
        Write-Host "1. Review JSON output for evidence of app-related issues" -ForegroundColor White
        Write-Host "2. Check 'ConfirmsDeploymentCause' and 'RulesOutDeploymentCause' fields in each section" -ForegroundColor White
        Write-Host "3. Cross-reference with event logs for authentication or profile errors" -ForegroundColor White
        Write-Host "4. If app confirmed as cause, escalate to application vendor and prepare rollback" -ForegroundColor White
        Write-Host "5. If app ruled out, investigate Intune policies and network connectivity" -ForegroundColor White
        Write-Host ""
    }
    catch {
        Write-Host "Error: Could not save output file: $_" -ForegroundColor Red
        Write-Host "Attempting to display results instead:" -ForegroundColor Yellow
        $DiagnosticResults | ConvertTo-Json -Depth 10
    }
}

Write-Progress-Message "Diagnostic script completed"
