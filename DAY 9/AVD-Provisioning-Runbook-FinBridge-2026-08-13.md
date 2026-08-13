# Azure Virtual Desktop Provisioning Runbook (FinBridge)

Date: 2026-08-13  
Tenant: zippyops.in  
Subscription: 8d8da22c-cbf0-4314-bc16-246725646a4f  
Resource Group: dwpai-lab-rg  
Region: East US

## Scope Delivered

- Pooled host pool: POOL-FIN-01
- Load balancing: BreadthFirst
- Max sessions per host: 5
- Desktop app group: DAG-FIN-01
- Workspace: FinBridge-Workspace
- Session host VM resource: vm-fin-01
- Session host guest hostname (final): vm-fin-01a
- OS image: Windows 11 multi-session (win11-23h2-avd)
- VM size: Standard_B2ms
- Trusted Launch: enabled
- Secure Boot: enabled
- vTPM: enabled
- Entra-only intent: configured and validated

## 1. Operator Permission Validation (Pre-check)

The signed-in identity was validated before provisioning.

```powershell
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' account show --query "{subscription:id,tenant:tenantDisplayName,user:user.name}" -o table

$uid = & 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' ad signed-in-user show --query id -o tsv
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' role assignment list --assignee-object-id $uid --scope /subscriptions/8d8da22c-cbf0-4314-bc16-246725646a4f -o table
```

Result: operator had Owner role at subscription scope, so role assignment creation was permitted.

## 2. Core AVD Resource Provisioning

```powershell
# Resource Group exists check
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' group show -n dwpai-lab-rg -o table

# Network
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' network vnet create -g dwpai-lab-rg -n vnet-fin-01 -l eastus --address-prefixes 10.40.0.0/16 --subnet-name snet-avd-01 --subnet-prefixes 10.40.1.0/24

# Host pool
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' desktopvirtualization hostpool create -g dwpai-lab-rg -n POOL-FIN-01 -l eastus --host-pool-type Pooled --load-balancer-type BreadthFirst --max-session-limit 5 --preferred-app-group-type Desktop --friendly-name POOL-FIN-01

# Workspace
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' desktopvirtualization workspace create -g dwpai-lab-rg -n FinBridge-Workspace -l eastus --friendly-name FinBridge-Workspace

# Desktop Application Group
$hpId = '/subscriptions/8d8da22c-cbf0-4314-bc16-246725646a4f/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01'
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' desktopvirtualization applicationgroup create -g dwpai-lab-rg -n DAG-FIN-01 -l eastus --application-group-type Desktop --host-pool-arm-path $hpId --friendly-name 'FinBridge Desktop'

# Register app group to workspace
$agId = '/subscriptions/8d8da22c-cbf0-4314-bc16-246725646a4f/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/DAG-FIN-01'
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' desktopvirtualization workspace update -g dwpai-lab-rg -n FinBridge-Workspace --application-group-references $agId
```

## 3. Session Host VM Provisioning

```powershell
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' vm create -g dwpai-lab-rg -n vm-fin-01 -l eastus --image MicrosoftWindowsDesktop:windows-11:win11-23h2-avd:latest --size Standard_B2ms --admin-username localavdadmin --admin-password "<temp-password>" --vnet-name vnet-fin-01 --subnet snet-avd-01 --public-ip-sku Standard --nsg-rule RDP --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm true --license-type Windows_Client
```

Validation used:

```powershell
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' vm show -g dwpai-lab-rg -n vm-fin-01 --query "{vmSize:hardwareProfile.vmSize,securityType:securityProfile.securityType,secureBoot:securityProfile.uefiSettings.secureBootEnabled,vtpm:securityProfile.uefiSettings.vTpmEnabled,imageSku:storageProfile.imageReference.sku}" -o table
```

## 4. Entra Sign-in and Host Registration

### 4.1 AAD login extension

```powershell
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' vm identity assign -g dwpai-lab-rg -n vm-fin-01
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' vm extension set -g dwpai-lab-rg --vm-name vm-fin-01 --publisher Microsoft.Azure.ActiveDirectory --name AADLoginForWindows
```

### 4.2 Host pool registration token

```powershell
$exp = (Get-Date).ToUniversalTime().AddDays(1).ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ")
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' desktopvirtualization hostpool update -g dwpai-lab-rg -n POOL-FIN-01 --registration-info expiration-time=$exp registration-token-operation=Update
$token = & 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' desktopvirtualization hostpool retrieve-registration-token -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv
```

### 4.3 AVD agent + bootloader install from VM run-command

```powershell
$script = @'
param([string]$RegistrationToken)
$ErrorActionPreference = "Stop"
New-Item -Path C:\Temp -ItemType Directory -Force | Out-Null
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile "C:\Temp\AVD-Agent.msi"
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile "C:\Temp\AVD-BootLoader.msi"
Start-Process msiexec.exe -ArgumentList "/i C:\Temp\AVD-Agent.msi /qn /norestart REGISTRATIONTOKEN=$RegistrationToken" -Wait
Start-Process msiexec.exe -ArgumentList "/i C:\Temp\AVD-BootLoader.msi /qn /norestart" -Wait
Get-Service -Name RDAgent,RDAgentBootLoader | Select Name,Status,StartType
'@

& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' vm run-command invoke -g dwpai-lab-rg -n vm-fin-01 --command-id RunPowerShellScript --scripts $script --parameters RegistrationToken=$token
```

## 5. Access Role Assignments for User p47@zippyops.in

```powershell
# Direct RDP to VM
$scopeVm = '/subscriptions/8d8da22c-cbf0-4314-bc16-246725646a4f/resourceGroups/dwpai-lab-rg/providers/Microsoft.Compute/virtualMachines/vm-fin-01'
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' role assignment create --assignee p47@zippyops.in --role "Virtual Machine User Login" --scope $scopeVm

# Access published desktop in AVD client
$scopeDag = '/subscriptions/8d8da22c-cbf0-4314-bc16-246725646a4f/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/DAG-FIN-01'
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' role assignment create --assignee p47@zippyops.in --role "Desktop Virtualization User" --scope $scopeDag
```

## 6. Issue Encountered and Fix Applied

Issue observed:
- Session host registered but stayed Unavailable.
- Health checks reported domain checks failed.
- AAD login extension showed error 0x801c0083: hostname already used by another device in tenant.

Constraints:
- Current operator did not have Graph permission to delete stale Entra device object.

Fix performed:
1. Set Entra-focused RDP properties on host pool.
2. Renamed in-guest hostname from vm-fin-01 to vm-fin-01a.
3. Restarted VM and re-ran AAD join/extension flow.

Result:
- Session host object became POOL-FIN-01/vm-fin-01a
- Host status became Available
- AzureAdJoined reported YES in guest

## 7. Final Validation Commands

```powershell
# Session host status
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' rest --method get --url "https://management.azure.com/subscriptions/8d8da22c-cbf0-4314-bc16-246725646a4f/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2024-04-03" --query "value[].{name:name,status:properties.status,lastHeartBeat:properties.lastHeartBeat,updateState:properties.updateState}" -o table

# Guest hostname + Entra joined
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd' vm run-command invoke -g dwpai-lab-rg -n vm-fin-01 --command-id RunPowerShellScript --scripts "hostname; dsregcmd /status | findstr /I AzureAdJoined" --query "value[0].message" -o tsv
```

Expected final outputs:
- Session host name: POOL-FIN-01/vm-fin-01a
- Session host status: Available
- AzureAdJoined : YES

## 8. Script/File Movement Note

No standalone provisioning script files were created in the workspace during this run.  
All automation was executed directly in terminal and Azure VM Run Command.

Therefore, there were no new script files to move into Day 9.
