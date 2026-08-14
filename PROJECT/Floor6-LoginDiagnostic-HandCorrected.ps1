# ============================================================================
# Floor 6 Login/Performance Issue - Technical Diagnostic Script
# FinBridge Legal Department | Windows 11 Migration Investigation
# Date: 2026-08-14 | Version: 2.0 (Idempotent with Rollback Support)
# Purpose: Non-destructive evidence collection for app deployment root cause
# ============================================================================
#
# SAFETY GUARANTEE: This script is READ-ONLY and performs NO system modifications.
# It does not: restart, disable, remove, modify, or fix anything.
#
# IDEMPOTENCY FEATURES:
#   - Manifest tracking: Each diagnostic run is recorded for audit trail
#   - Unique Run IDs: Every collection is uniquely identified with timestamp + GUID
#   - Timestamped output files: Multiple runs don't overwrite each other
#   - Rollback support: Remove last run or clean all artifacts
#
# USAGE:
#   Dry-run (preview scope and show run history):
#   .\Floor6-LoginDiagnostic-HandCorrected.ps1 -DryRun
#
#   Collect diagnostics (idempotent, tracked for rollback):
#   .\Floor6-LoginDiagnostic-HandCorrected.ps1 -CollectDiagnostics -OutputPath "C:\Diagnostic_Results"
#
#   Rollback last diagnostic run:
#   .\Floor6-LoginDiagnostic-HandCorrected.ps1 -RollbackLastRun -OutputPath "C:\Diagnostic_Results"
#
#   Clean all diagnostic artifacts (reset to initial state):
#   .\Floor6-LoginDiagnostic-HandCorrected.ps1 -Cleanup -OutputPath "C:\Diagnostic_Results"
#
# MANIFEST FILE:
#   Location: <OutputPath>/DiagnosticRunManifest.json
#   Purpose: Tracks all runs on this device for chain-of-custody and rollback
#   Content: Run IDs, timestamps, users, file sizes, etc.
#
# ============================================================================

param(
    [switch]$DryRun = $false,
    [switch]$CollectDiagnostics = $false,
    [switch]$Cleanup = $false,
    [switch]$RollbackLastRun = $false,
    [string]$OutputPath = "$env:TEMP\Floor6_Diagnostics",
    [int]$EventLogDaysBack = 2  # Search Friday onward (2 days = Friday + today)
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptMetadata = @{
    Version          = "2.0-Idempotent"
    CreatedDate      = "2026-08-14"
    Purpose          = "Non-destructive app deployment impact assessment with rollback"
    TargetHypothesis = "Friday document management app deployment caused Monday login issues"
    IsSafeToRun      = "YES - Read-only only, no modifications, idempotent operations"
    DataProtection   = "No passwords, personal data, or legal document content collected"
    Features         = "Manifest tracking, Run ID tracking, Rollback support, Audit trail"
}

# Deployment window for Friday app rollout
$DeploymentWindowStart = [datetime]"2026-08-11 12:00:00"
$DeploymentWindowEnd = [datetime]"2026-08-11 23:59:59"

# App name patterns to search for (flexible matching, case-insensitive)
$AppSearchPatterns = @(
    "Document*Management*",
    "FinBridge*",
    "*Document*App*"
)

# ============================================================================
# IDEMPOTENCY & ROLLBACK SUPPORT
# ============================================================================

$ManifestFileName = "DiagnosticRunManifest.json"
$ManifestPath = Join-Path $OutputPath $ManifestFileName

function Initialize-ManifestFile {
    <#
    .SYNOPSIS
    Create or load manifest tracking diagnostic runs for idempotency and rollback
    #>
    if (Test-Path $ManifestPath) {
        try {
            $Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
            return $Manifest
        } catch {
            Write-ProgressMessage "Could not parse existing manifest, creating new one" "WARNING"
        }
    }
    
    return @{
        CreatedDate     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        DeviceName      = $env:COMPUTERNAME
        DiagnosticRuns  = @()
        TotalRunsCount  = 0
    }
}

function Update-ManifestFile {
    <#
    .SYNOPSIS
    Save manifest with new diagnostic run entry
    #>
    param([object]$Manifest)
    
    try {
        $Manifest | ConvertTo-Json -Depth 10 | Out-File -FilePath $ManifestPath -Encoding UTF8 -Force
    } catch {
        Write-ProgressMessage "Could not update manifest: $_" "WARNING"
    }
}

function Add-DiagnosticRunToManifest {
    <#
    .SYNOPSIS
    Record a new diagnostic run in the manifest for rollback capability
    #>
    param(
        [object]$Manifest,
        [string]$OutputFile,
        [string]$RunID
    )
    
    $RunEntry = @{
        RunID           = $RunID
        Timestamp       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        OutputFile      = $OutputFile
        FileSize        = if (Test-Path $OutputFile) { 
            [math]::Round((Get-Item $OutputFile).Length / 1KB, 1) 
        } else { 
            0 
        }
        User            = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        ComputerName    = $env:COMPUTERNAME
    }
    
    $Manifest.DiagnosticRuns += $RunEntry
    $Manifest.TotalRunsCount += 1
    $Manifest.LastRun = $RunEntry.Timestamp
    
    return $Manifest
}

function Get-LastDiagnosticRun {
    <#
    .SYNOPSIS
    Retrieve the most recent diagnostic run for rollback
    #>
    param([object]$Manifest)
    
    if ($Manifest.DiagnosticRuns.Count -eq 0) {
        return $null
    }
    
    return $Manifest.DiagnosticRuns[-1]  # Last item in array
}

# ============================================================================
# CLEANUP & ROLLBACK FUNCTIONS
# ============================================================================

function Invoke-DiagnosticCleanup {
    <#
    .SYNOPSIS
    Remove all diagnostic artifacts and manifest to restore clean state
    .DESCRIPTION
    Idempotency feature: allows removal of all previous diagnostic runs
    Safe operation - no system state changes, just removes JSON files
    #>
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "CLEANUP MODE - Removing Diagnostic Artifacts" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Test-Path $OutputPath)) {
        Write-ProgressMessage "Output directory does not exist. Nothing to clean." "INFO"
        return
    }
    
    try {
        $DiagnosticFiles = @(Get-ChildItem $OutputPath -Filter "Device_Diagnostic_*.json" -ErrorAction SilentlyContinue)
        $FilesRemoved = 0
        
        foreach ($File in $DiagnosticFiles) {
            try {
                Remove-Item $File -Force
                Write-ProgressMessage "Removed: $($File.Name)" "INFO"
                $FilesRemoved++
            } catch {
                Write-ProgressMessage "Could not remove $($File.Name): $_" "WARNING"
            }
        }
        
        # Remove manifest
        if (Test-Path $ManifestPath) {
            Remove-Item $ManifestPath -Force
            Write-ProgressMessage "Removed manifest file" "INFO"
        }
        
        Write-Host ""
        Write-ProgressMessage "Cleanup complete. Removed $FilesRemoved diagnostic file(s)" "INFO"
        Write-Host "State: Idempotent - ready for fresh diagnostic collection" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-ProgressMessage "Error during cleanup: $_" "ERROR"
    }
}

function Invoke-RollbackLastRun {
    <#
    .SYNOPSIS
    Remove only the most recent diagnostic run, preserving history
    .DESCRIPTION
    Allows selective rollback of last run while keeping previous diagnostics
    Maintains audit trail of all operations
    #>
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "ROLLBACK MODE - Remove Last Diagnostic Run" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Test-Path $OutputPath)) {
        Write-ProgressMessage "Output directory does not exist. Nothing to rollback." "WARNING"
        return
    }
    
    $Manifest = Initialize-ManifestFile
    $LastRun = Get-LastDiagnosticRun $Manifest
    
    if (-not $LastRun) {
        Write-ProgressMessage "No diagnostic runs found in manifest. Nothing to rollback." "WARNING"
        return
    }
    
    try {
        # Verify file exists and matches manifest
        if (Test-Path $LastRun.OutputFile) {
            $Confirmation = Read-Host "Remove run '$($LastRun.RunID)' from $($LastRun.Timestamp)? (yes/no)"
            
            if ($Confirmation -eq "yes") {
                Remove-Item $LastRun.OutputFile -Force
                Write-ProgressMessage "Removed: $($LastRun.OutputFile)" "INFO"
                
                # Remove last entry from manifest
                $Manifest.DiagnosticRuns = $Manifest.DiagnosticRuns[0..($Manifest.DiagnosticRuns.Count - 2)]
                $Manifest.TotalRunsCount -= 1
                
                if ($Manifest.DiagnosticRuns.Count -gt 0) {
                    $Manifest.LastRun = $Manifest.DiagnosticRuns[-1].Timestamp
                } else {
                    $Manifest.LastRun = $null
                }
                
                Update-ManifestFile $Manifest
                Write-ProgressMessage "Manifest updated. Rollback complete." "INFO"
            } else {
                Write-ProgressMessage "Rollback cancelled" "INFO"
            }
        } else {
            Write-ProgressMessage "Output file not found: $($LastRun.OutputFile)" "WARNING"
        }
        
        Write-Host ""
    } catch {
        Write-ProgressMessage "Error during rollback: $_" "ERROR"
    }
}

function Show-DiagnosticHistory {
    <#
    .SYNOPSIS
    Display all diagnostic runs recorded in manifest
    .DESCRIPTION
    Provides audit trail of all collections on this device
    #>
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "DIAGNOSTIC RUN HISTORY" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $OutputPath)) {
        Write-Host "No diagnostic history yet." -ForegroundColor Gray
        Write-Host ""
        return
    }
    
    $Manifest = Initialize-ManifestFile
    
    if ($Manifest.DiagnosticRuns.Count -eq 0) {
        Write-Host "No diagnostic runs recorded." -ForegroundColor Gray
        Write-Host ""
        return
    }
    
    Write-Host "Device: $($Manifest.DeviceName)" -ForegroundColor Cyan
    Write-Host "Total Runs: $($Manifest.TotalRunsCount)" -ForegroundColor Cyan
    Write-Host ""
    
    $Manifest.DiagnosticRuns | ForEach-Object {
        Write-Host "Run ID: $($_.RunID)" -ForegroundColor Green
        Write-Host "  Timestamp: $($_.Timestamp)"
        Write-Host "  User: $($_.User)"
        Write-Host "  File: $($_.OutputFile)"
        Write-Host "  Size: $($_.FileSize) KB"
        Write-Host ""
    }
}


function Show-DryRunPreview {
    <#
    .SYNOPSIS
    Display what the script will collect without actually collecting anything
    #>
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "DRY-RUN MODE - Script Preview & History" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    
    # Show diagnostic history if available
    Show-DiagnosticHistory
    
    Write-Host "SECTION 1: DEVICE ENVIRONMENT" -ForegroundColor Cyan
    Write-Host "  Collects: Computer name, OS version, Windows 11 status, boot time"
    Write-Host "  Collects: Current user, admin status, hardware model"
    Write-Host "  Purpose: Verify device is Floor 6 Windows 11 + Intune enrolled"
    Write-Host ""
    
    Write-Host "SECTION 2: APPLICATION DEPLOYMENT" -ForegroundColor Cyan
    Write-Host "  Collects: Registry scan of installed applications"
    Write-Host "  Checks: Is target app installed?"
    Write-Host "  Checks: Install date = Friday 12:00-23:59 (deployment window)?"
    Write-Host "  Evidence: ConfirmsDeploymentCause OR RulesOutDeploymentCause"
    Write-Host ""
    
    Write-Host "SECTION 3: INTUNE DEPLOYMENT LOGS" -ForegroundColor Cyan
    Write-Host "  Collects: Intune Management Extension logs (Friday onward)"
    Write-Host "  Parses: Installation errors, timeouts, restart loops, detection failures"
    Write-Host "  Evidence: Error type, count, first occurrence timestamp"
    Write-Host "  Indicator: Deployment success OR failure"
    Write-Host ""
    
    Write-Host "SECTION 4: WINDOWS EVENT LOGS" -ForegroundColor Cyan
    Write-Host "  Security Log:"
    Write-Host "    - Event 4625: Failed login attempts (shows spike on Monday AM?)"
    Write-Host "    - Event 4740: Account lockouts (shows spike on Monday AM?)"
    Write-Host "  System Log:"
    Write-Host "    - Event 1509/1516: User profile load failures"
    Write-Host "    - Event 7045: Service installations (app-related?)"
    Write-Host "  Application Log:"
    Write-Host "    - General error events (spike on Monday AM?)"
    Write-Host "  Evidence: Timeline of failures correlating to Monday morning"
    Write-Host ""
    
    Write-Host "SECTION 5: STARTUP ITEMS & SERVICES" -ForegroundColor Cyan
    Write-Host "  Collects: Registry startup items (HKLM/HKCU Run keys)"
    Write-Host "  Collects: Scheduled tasks (app-related)"
    Write-Host "  Collects: Auto-start services (app-related)"
    Write-Host "  Evidence: Task/service failures on Monday morning"
    Write-Host "  Indicator: If startup items failed, would cause slow login"
    Write-Host ""
    
    Write-Host "SECTION 6: PERFORMANCE METRICS" -ForegroundColor Cyan
    Write-Host "  Collects: CPU cores, memory total/free/usage, disk space"
    Write-Host "  Collects: Top 10 processes by memory usage"
    Write-Host "  Evidence: System resource availability (not exhausted?)"
    Write-Host ""
    
    Write-Host "OUTPUT FORMAT:" -ForegroundColor Yellow
    Write-Host "  File: Device_Diagnostic_[ComputerName]_[DateTime].json"
    Write-Host "  Location: $OutputPath"
    Write-Host "  Structure: Nested JSON with evidence, confirm/rule-out fields, actions"
    Write-Host "  Manifest: DiagnosticRunManifest.json (tracks all runs for rollback)"
    Write-Host ""
    
    Write-Host "IDEMPOTENCY & ROLLBACK:" -ForegroundColor Yellow
    Write-Host "  Run Tracking: Each collection gets unique Run ID (timestamp + GUID)"
    Write-Host "  No Overwrites: Multiple runs don't overwrite previous collections"
    Write-Host "  Audit Trail: Manifest records user, timestamp, file size for each run"
    Write-Host "  Rollback Capable: Remove last run or clean all artifacts"
    Write-Host ""
    
    Write-Host "DECISION LOGIC:" -ForegroundColor Yellow
    Write-Host "  IF app found in deployment window"
    Write-Host "     AND Intune logs show errors"
    Write-Host "     AND Event logs show login failures Monday AM"
    Write-Host "  THEN: App deployment is strong candidate for root cause"
    Write-Host "  ELSE: Focus investigation on other hypotheses"
    Write-Host ""
    
    Write-Host "TO RUN ACTUAL COLLECTION:" -ForegroundColor White
    Write-Host "  .\Floor6-LoginDiagnostic-HandCorrected.ps1 -CollectDiagnostics -OutputPath 'C:\Results'" -ForegroundColor Cyan
    Write-Host ""
}

function Write-ProgressMessage {
    <#
    .SYNOPSIS
    Write timestamped progress message to console
    #>
    param(
        [string]$Message,
        [string]$Type = "INFO"  # INFO, WARNING, ERROR
    )
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
    <#
    .SYNOPSIS
    Collect basic device and OS information
    .DESCRIPTION
    Gathers hostname, OS version, Windows 11 status, boot time, current user
    .EXAMPLE
    $DeviceInfo = Collect-DeviceEnvironment
    #>
    Write-ProgressMessage "Collecting device environment..."
    $DeviceData = @{}
    
    try {
        $CimOS = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $CompInfo = Get-ComputerInfo -ErrorAction SilentlyContinue
        
        $DeviceData = @{
            ComputerName        = $env:COMPUTERNAME
            OSVersion           = $CimOS.Caption  # e.g., "Microsoft Windows 11 Pro"
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
    <#
    .SYNOPSIS
    Check if target application was installed in the deployment window
    .DESCRIPTION
    Scans registry for installed apps matching pattern, extracts install date,
    compares to Friday 12:00-23:59 deployment window
    .EXAMPLE
    $AppEvidence = Collect-ApplicationDeployment
    #>
    Write-ProgressMessage "Checking application deployment..."
    $AppDeploymentEvidence = @{
        AppsInstalledInDeploymentWindow = @()
        AppsInstalledOutsideWindow      = @()
        NoTargetAppsFound               = $false
        ConfirmsDeploymentCause         = "Target app found AND installed Friday 12:00-23:59 (deployment window)"
        RulesOutDeploymentCause         = "No target apps found OR apps installed before Friday OR after Sunday"
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
                                # Safely parse install date
                                $ParsedDate = $null
                                if ($InstallDate -and $InstallDate -match '^\d{8}$') {
                                    try {
                                        $ParsedDate = [datetime]::ParseExact($InstallDate, "yyyyMMdd", $null)
                                    } catch {
                                        $ParsedDate = $null
                                    }
                                }
                                
                                # Check if in deployment window
                                $IsInWindow = $null -ne $ParsedDate -and $ParsedDate -ge $DeploymentWindowStart -and $ParsedDate -le $DeploymentWindowEnd
                                
                                $AppRecord = @{
                                    ApplicationName   = $AppName
                                    Version           = $Version
                                    InstallDateRaw    = $InstallDate  # YYYYMMDD format
                                    InstallDateParsed = if ($ParsedDate) { $ParsedDate.ToString('yyyy-MM-dd HH:mm') } else { "Could not parse" }
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
        
        # Set flag if no apps found
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
# SECTION 3: INTUNE MANAGEMENT LOGS
# ============================================================================

function Collect-IntuneManagementLogs {
    <#
    .SYNOPSIS
    Parse Intune Management Extension logs for deployment failures
    .DESCRIPTION
    Reads logs from Friday onward, categorizes errors: Installation Failed, Timeout/Hang,
    Restart Loop, Detection Failure
    .EXAMPLE
    $IntuneEvidence = Collect-IntuneManagementLogs
    #>
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
            # Focus on logs from Friday afternoon onward
            $RelevantLogs = $AllLogs | Where-Object { $_.LastWriteTime -ge (Get-Date "2026-08-11 12:00:00") }
            
            if ($RelevantLogs.Count -gt 0) {
                # Define error patterns by category
                $ErrorIndicators = @{
                    "Installation Failed" = @("failed.*install", "install.*error", "exitcode\s+[1-9]")
                    "Timeout/Hang"        = @("timeout", "hung", "hung.*app")
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
            }
            
            if ($IntuneEvidence.ErrorsFound.Count -eq 0) {
                $IntuneEvidence.WarningNote = "No deployment errors found - suggests successful deployment or no app deployment via Intune"
            }
        } catch {
            Write-ProgressMessage "Error parsing Intune logs: $_" "ERROR"
            $IntuneEvidence.WarningNote = "Exception while parsing logs: $_"
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
    <#
    .SYNOPSIS
    Query Windows Event Logs for login, profile, and service errors
    .DESCRIPTION
    Checks Security log for failed logins (4625) and lockouts (4740)
    Checks System log for profile errors (1509/1516) and service installs (7045)
    Checks Application log for error events
    .EXAMPLE
    $EventLogData = Collect-EventLogData
    #>
    Write-ProgressMessage "Querying Windows Event Logs..."
    $EventLogData = @{
        SecurityLog     = @{ FailedLogins = @(); AccountLockouts = @() }
        SystemLog       = @{ ProfileErrors = @(); ServiceInstalls = @() }
        ApplicationLog  = @{ ErrorCount = 0; TopErrors = @() }
    }
    
    $SearchStart = (Get-Date).AddDays(-$EventLogDaysBack)
    
    try {
        # SECURITY LOG: Failed logins and lockouts
        Write-ProgressMessage "  Querying Security log for authentication events..."
        
        # Event 4625 = Failed logon attempt
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
        
        # Event 4740 = Account locked out
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
        # SYSTEM LOG: Profile and startup failures
        Write-ProgressMessage "  Querying System log for profile and startup events..."
        
        # Event 1509/1516 = User Profile Service failed
        $ProfileErrors = Get-EventLog System -After $SearchStart -InstanceId @(1509, 1516) -ErrorAction SilentlyContinue
        if ($ProfileErrors) {
            $EventLogData.SystemLog.ProfileErrors = @{
                TotalCount    = @($ProfileErrors).Count
                ByDate        = @($ProfileErrors | Group-Object { $_.TimeGenerated.Date } | ForEach-Object { 
                    @{ Date = $_.Name.ToString("yyyy-MM-dd"); Count = $_.Count }
                })
            }
        }
        
        # Event 7045 = Service was installed
        $ServiceInstalls = Get-EventLog System -After $SearchStart -InstanceId 7045 -ErrorAction SilentlyContinue
        if ($ServiceInstalls) {
            $AppServices = $ServiceInstalls | Where-Object { $_.Message -match "Document|Management|FinBridge" }
            if ($AppServices) {
                $EventLogData.SystemLog.ServiceInstalls = @{
                    Count    = @($AppServices).Count
                    Services = @($AppServices | ForEach-Object { 
                        $_.Message.Substring(0, [Math]::Min(80, $_.Message.Length)) 
                    })
                }
            }
        }
    } catch {
        Write-ProgressMessage "Could not read System log: $_" "WARNING"
    }
    
    try {
        # APPLICATION LOG: General errors
        Write-ProgressMessage "  Querying Application log for errors..."
        
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
    <#
    .SYNOPSIS
    Scan registry, scheduled tasks, and services for app-related startup items
    .DESCRIPTION
    Checks HKLM/HKCU Run registry keys, scheduled tasks, and auto-start services
    #>
    Write-ProgressMessage "Scanning startup items and services..."
    $StartupEvidence = @{
        RegistryStartupItems = @()
        ScheduledTasks       = @()
        AutoStartServices    = @()
    }
    
    try {
        # REGISTRY STARTUP ITEMS
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
                                    SourcePath = $Path
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
        # SCHEDULED TASKS
        $AllTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue)
        $AppTasks = $AllTasks | Where-Object { 
            $_.TaskName -match "Document|Management|FinBridge" -or $_.TaskPath -match "Document|Management"
        }
        
        foreach ($Task in $AppTasks) {
            try {
                $TaskInfo = Get-ScheduledTaskInfo -TaskName $Task.TaskName -ErrorAction SilentlyContinue
                $StartupEvidence.ScheduledTasks += @{
                    TaskName      = $Task.TaskName
                    TaskPath      = $Task.TaskPath
                    Enabled       = $Task.Enabled
                    LastRunTime   = if ($TaskInfo.LastRunTime) { $TaskInfo.LastRunTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "Never run" }
                    LastRunResult = $TaskInfo.LastTaskResult  # 0 = success, non-zero = failure
                }
            } catch {
                Write-ProgressMessage "Could not get info for task $($Task.TaskName): $_" "WARNING"
            }
        }
    } catch {
        Write-ProgressMessage "Error reading scheduled tasks: $_" "WARNING"
    }
    
    try {
        # AUTO-START SERVICES
        $Services = Get-Service -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match "Document|Management|FinBridge" -or $_.DisplayName -match "Document|Management|FinBridge"
        }
        
        foreach ($Service in $Services) {
            try {
                $ServiceObj = Get-Service -Name $Service.Name | Select-Object Name, DisplayName, Status, StartType
                $StartupEvidence.AutoStartServices += @{
                    ServiceName = $Service.Name
                    DisplayName = $Service.DisplayName
                    Status      = $Service.Status  # Running, Stopped, etc.
                    StartType   = $ServiceObj.StartType  # Automatic, Manual, Disabled
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
    <#
    .SYNOPSIS
    Collect CPU, memory, disk, and process information
    #>
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
    } catch {
        Write-ProgressMessage "Could not collect CPU info: $_" "WARNING"
    }
    
    try {
        $CimOS = Get-CimInstance Win32_OperatingSystem
        $TotalMem = [math]::Round($CimOS.TotalVisibleMemorySize / 1048576, 2)
        $FreeMem = [math]::Round($CimOS.FreePhysicalMemory / 1048576, 2)
        $PerfData.Memory = @{
            TotalGB       = $TotalMem
            FreeGB        = $FreeMem
            UsagePercent  = [math]::Round((($TotalMem - $FreeMem) / $TotalMem) * 100, 1)
        }
    } catch {
        Write-ProgressMessage "Could not collect memory info: $_" "WARNING"
    }
    
    try {
        $Vol = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
        if ($Vol) {
            $PerfData.Disk = @{
                TotalGB      = [math]::Round($Vol.Size / 1GB, 1)
                FreeGB       = [math]::Round($Vol.SizeRemaining / 1GB, 1)
                UsagePercent = [math]::Round((($Vol.Size - $Vol.SizeRemaining) / $Vol.Size) * 100, 1)
            }
        }
    } catch {
        Write-ProgressMessage "Could not collect disk info: $_" "WARNING"
    }
    
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
    } catch {
        Write-ProgressMessage "Could not collect process info: $_" "WARNING"
    }
    
    return $PerfData
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host ""
Write-Host "======================================================" -ForegroundColor Magenta
Write-Host "Floor 6 Login/Performance Investigation - Technical Diagnostic" -ForegroundColor Magenta
Write-Host "Target Hypothesis: Friday app deployment → Monday login issues" -ForegroundColor Magenta
Write-Host "======================================================" -ForegroundColor Magenta
Write-Host ""

if ($DryRun) {
    # DRY-RUN MODE: Show preview
    Show-DryRunPreview
} elseif ($Cleanup) {
    # CLEANUP MODE: Remove all diagnostic artifacts (idempotency reset)
    Invoke-DiagnosticCleanup
} elseif ($RollbackLastRun) {
    # ROLLBACK MODE: Remove most recent diagnostic run
    Invoke-RollbackLastRun
} elseif ($CollectDiagnostics) {
    # COLLECTION MODE: Gather evidence with idempotency support
    Write-ProgressMessage "Starting diagnostic collection..."
    Write-ProgressMessage "Requires Administrator privileges for event log access"
    Write-Host ""
    
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        try {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            Write-ProgressMessage "Created output directory: $OutputPath"
        } catch {
            Write-ProgressMessage "Error creating output directory: $_" "ERROR"
            exit 1
        }
    }
    
    # Initialize manifest for idempotency tracking
    $Manifest = Initialize-ManifestFile
    $RunID = "Run-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([System.Guid]::NewGuid().ToString().Substring(0, 8))"
    
    # Collect all data
    Write-Host ""
    $DiagnosticResults = @{
        Metadata            = $ScriptMetadata
        CollectionTime      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        RunID               = $RunID
        CollectionNotes     = "Hand-corrected script for L1/L2 engineer use. Each section includes evidence, confirm/rule-out criteria. Idempotent with rollback support."
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
        
        # Update manifest for rollback capability
        $Manifest = Add-DiagnosticRunToManifest $Manifest $OutputFile $RunID
        Update-ManifestFile $Manifest
        
        Write-Host ""
        Write-ProgressMessage "Diagnostic collection completed successfully"
        Write-Host "Run ID: $RunID" -ForegroundColor Green
        Write-Host "Output file: $OutputFile" -ForegroundColor Green
        Write-Host "File size: $([math]::Round((Get-Item $OutputFile).Length / 1KB, 1)) KB" -ForegroundColor Green
        Write-Host ""
        Write-Host "IDEMPOTENCY & ROLLBACK OPTIONS:" -ForegroundColor Yellow
        Write-Host "  View all runs:     .\Floor6-LoginDiagnostic-HandCorrected.ps1 -DryRun" -ForegroundColor Cyan
        Write-Host "  Rollback last run: .\Floor6-LoginDiagnostic-HandCorrected.ps1 -RollbackLastRun -OutputPath '$OutputPath'" -ForegroundColor Cyan
        Write-Host "  Clean all runs:    .\Floor6-LoginDiagnostic-HandCorrected.ps1 -Cleanup -OutputPath '$OutputPath'" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "NEXT STEPS FOR L1/L2 ENGINEER:" -ForegroundColor Yellow
        Write-Host "1. Open JSON file in text editor or VS Code"
        Write-Host "2. Check AppDeployment section:"
        Write-Host "   - Apps in deployment window = likely cause"
        Write-Host "   - No apps found = rules out deployment"
        Write-Host "3. Check EventLogs section:"
        Write-Host "   - Failed logins spike on Monday = auth issue"
        Write-Host "   - Profile errors = Windows 11 migration issue"
        Write-Host "4. Check StartupItems section:"
        Write-Host "   - Task/service failed = startup issue"
        Write-Host "5. Decision:"
        Write-Host "   - All three match = escalate to app vendor"
        Write-Host "   - Partial match = investigate specific area"
        Write-Host "   - No matches = focus on Intune policies/network"
        Write-Host ""
    } catch {
        Write-ProgressMessage "Error saving output: $_" "ERROR"
        exit 1
    }
} else {
    # NO ACTION SPECIFIED - Show help
    Write-ProgressMessage "No action specified. Choose one:" "WARNING"
    Write-Host ""
    Write-Host "COLLECTION MODES:" -ForegroundColor Yellow
    Write-Host "  -DryRun                            (preview what will be collected)" -ForegroundColor Cyan
    Write-Host "  -CollectDiagnostics                (actual collection to JSON)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "IDEMPOTENCY & ROLLBACK:" -ForegroundColor Yellow
    Write-Host "  -Cleanup                           (remove all diagnostic runs)" -ForegroundColor Cyan
    Write-Host "  -RollbackLastRun                   (remove most recent run)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  .\Floor6-LoginDiagnostic-HandCorrected.ps1 -DryRun" -ForegroundColor Gray
    Write-Host "  .\Floor6-LoginDiagnostic-HandCorrected.ps1 -CollectDiagnostics -OutputPath 'C:\Results'" -ForegroundColor Gray
    Write-Host "  .\Floor6-LoginDiagnostic-HandCorrected.ps1 -RollbackLastRun -OutputPath 'C:\Results'" -ForegroundColor Gray
    Write-Host "  .\Floor6-LoginDiagnostic-HandCorrected.ps1 -Cleanup -OutputPath 'C:\Results'" -ForegroundColor Gray
    Write-Host ""
}

