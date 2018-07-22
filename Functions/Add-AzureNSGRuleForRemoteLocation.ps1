Function Add-AzureNSGRuleForRemoteLocation
{ 
<#
  .SYNOPSIS
  Adding a rule to NSG(s) to allow connection from current location

  .DESCRIPTION
  This cmdlet identifies your current IP and adds a rule in virtual machine's NSG(s) to allow connection 

  .PARAMETER SubscriptionId
  Subscription ID for the subscription that virtual machine is on. Required
    
  .PARAMETER rgName
  The Resource Group the virtual machine belongs to. Required

  .PARAMETER vmName
  The name of the virtual machine. Required

  .PARAMETER OS
  Select OS to automatically set port default connection  port, Linux: 22 & Windows: 3389.
  
  .PARAMETER Port
  The destination port number on the Network Security Group (NSG).

  .PARAMETER ruleName
  Provide a name for the custom rule.
  
  .NOTES
  Author     : Hannel Hazeley - hhazeley@outlook.com

  .LINK
  https://github.com/hhazeley/HannelsToolBox/blob/master/Functions/Add-AzureNSGRuleForRemoteLocation.ps1

  .EXAMPLE
  Add-AzureNSGRuleForRemoteLocation -SubscriptionId 1d6737e7-4f6c-4e3c-8cd4-996b6f003d0e -rgName DDemo -vmName DDemo-VM2

  This will create a custom rule using default port (3389) as destination port, default name (AllowRuleForRemoteLocation) and current public IP as Source IP. 
      
  .EXAMPLE
  Add-AzureNSGRuleForRemoteLocation -SubscriptionId 1d6737e7-4f6c-4e3c-8cd4-996b6f003d0e -rgName DDemo -vmName DDemo-VM2 -Port 22 -ruleName AllowSSH

  This will create a custom rule using port 22 as destination port, 'AllowSSH' as name and current public IP as Source IP.

  #>

[cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    $rgName,
    [Parameter(Mandatory=$true)]
    $vmName,
    [Parameter(Mandatory=$true)]
    [ValidateSet('Windows','Linux')]
    $OS,
    $Port,
    $ruleName = "AllowRuleForRemoteLocation"
)

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue" 

#Function for error checks
Function ErrorCheck{
If ($errorck -ne $null)
{
Write-host
Write-host -ForegroundColor Red "ERROR: " -NoNewline
Write-Host -ForegroundColor Red $errorck
Write-host
Break
}
}

If ($Port -eq $null -and $OS -eq "Windows")
{
$Port = "3389"
}

If ($Port -eq $null -and $OS -eq "Linux") 
{
$Port = "22"
}

#Selecting subscription
$hout = Select-AzureRmSubscription -SubscriptionId $SubscriptionId -ErrorVariable errorck
ErrorCheck

#Getting status of VM
$vmstatus = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Status -ErrorVariable errorck
ErrorCheck

#Checking if VM is running 
$state = $vmstatus.Statuses[1].Code
if ($state -ne "PowerState/running")
{
Write-host
Write-host -ForegroundColor Yellow -BackgroundColor Black "Virtual machine $vmName needs to be in a 'running' state to allow connection from remote location. Please 'Start' virtual machine and retry script again."
Write-host
Break
}
Else
{
#Get you current public IP
$current_IP = (Invoke-WebRequest -Uri "https://aptsprojects.azurewebsites.net/ip.php" -Method get).content

#Get Vm information 
$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName -ErrorVariable errorck
ErrorCheck

#Get NSG tied to the NIC of the VM
$nicname = $vm.NetworkProfile.NetworkInterfaces[0].Id -replace '.*?networkInterfaces/',""
$nicrg  = $vm.NetworkProfile.NetworkInterfaces[0].Id -replace  '.*?resourceGroups/',"" -replace '/providers/.*',""
$nsgids = (Get-AzureRmEffectiveNetworkSecurityGroup -NetworkInterfaceName $nicname -ResourceGroupName $nicrg).NetworkSecurityGroup.Id
Write-host

#Add rules to mutiple NSG if mor than one NSG is tied to VM
foreach($nsgid in $nsgids)
{
$nsgname = $nsgid -replace '.*?networkSecurityGroups/',""
$nsgrg = $nsgid -replace  '.*?resourceGroups/',"" -replace '/providers/.*',""

#Gettin NSG information 
$nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgname -ResourceGroupName $nsgrg -ErrorVariable errorck
ErrorCheck

#Getting rules information from NSG
$rules = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg
$rulenames = @()
$priorities = @()

foreach ($rule in $rules)
{
$rulenames += $rule.Name
$priorities += $rule.Priority
}

If ($rulenames -notcontains "$ruleName")
{
#Adding new rule
$priorityNew = ($priorities | measure -Maximum).Maximum + 1
Write-Host -ForegroundColor Green "Adding rule $ruleName to Network Security Groups $nsgname"
$hout = Add-AzureRmNetworkSecurityRuleConfig -Name $ruleName -NetworkSecurityGroup $nsg -Access Allow -Description "Allowing RDP connection from current location" -DestinationAddressPrefix * -DestinationPortRange $port -Direction Inbound -Priority $priorityNew -Protocol * -SourceAddressPrefix $current_IP -SourcePortRange * -ErrorVariable errorck
ErrorCheck
$hout = Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg -ErrorVariable errorck
ErrorCheck
}
else
{
#Updating existing rule
Write-Host -ForegroundColor Green "Updating rule $ruleName on Network Security Groups $nsgname"
$crule = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $ruleName
$hout = Set-AzureRmNetworkSecurityRuleConfig -Name $ruleName -NetworkSecurityGroup $nsg -Access Allow -Description "Allowing RDP connection from current location" -DestinationAddressPrefix * -DestinationPortRange $port -Direction Inbound -Priority $crule.Priority -Protocol * -SourceAddressPrefix $current_IP -SourcePortRange * -ErrorVariable errorck
ErrorCheck
$hout = Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg -ErrorVariable errorck
ErrorCheck
}
}
}
Write-host
}

Export-ModuleMember -Function Add-AzureNSGRuleForRemoteLocation