Function Remove-AzureNSGRuleForRemoteLocation
{ 
<#
  .SYNOPSIS
  Removes a custom rule from NSG(s).

  .DESCRIPTION
  This cmdlet removes a custom rule from NSG(s) tied to a VM. 

  .PARAMETER SubscriptionId
  Subscription ID for the subscription that virtual machine is on. Required
    
  .PARAMETER rgName
  The Resource Group the virtual machine belongs to. Required

  .PARAMETER vmName
  The name of the virtual machine. Required
  
  .PARAMETER ruleName
  Provide a name for the custom rule, if no name is provided system will look for default name "AllowRuleForRemoteLocation" .

  .NOTES
  Author     : Hannel Hazeley - hhazeley@outlook.com

  .LINK
  https://github.com/hhazeley/HannelsToolBox/blob/master/Functions/Remove-AzureNSGRuleForRemoteLocation.ps1

  .EXAMPLE
  Remove-AzureNSGRuleForRemoteLocation -SubscriptionId 1d6737e7-4f6c-4e3c-8cd4-996b6f003d0e -rgName DDemo -vmName DDemo-VM3

  This searches for default rule "AllowRuleForRemoteLocation" and remove it from NSG(s) tied to VM 
      
  .EXAMPLE
  Remove-AzureNSGRuleForRemoteLocation -SubscriptionId ad3d5476-1607-4a62-b3e9-ce3eb2472c57 -rgName DDemo -vmName DDemo-VM3 -ruleName AllowSSH2

  This searches for rule "AllowSSH2" and remove it from NSG(s) tied to VM 

  #>

[cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    $rgName,
    [Parameter(Mandatory=$true)]
    $vmName,
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
Write-host -ForegroundColor Red "Virtual machine $vmName needs to be in a 'running' state to allow connection from remote location. Please 'Start' virtual machine and retry script again."
Write-host
Break
}
Else
{
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

#Getting NSG information 
$nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgname -ResourceGroupName $nsgrg -ErrorVariable errorck
ErrorCheck

#Getting rules information from NSG
$rules = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg
$rulenames = @()

foreach ($rule in $rules)
{
$rulenames += $rule.Name
}
If ($rulenames -notcontains "$ruleName")
{
#Adding new rule
$priorityNew = ($priorities | measure -Maximum).Maximum + 1
Write-Host -ForegroundColor Yellow -BackgroundColor Black "Cannot find rule $ruleName on Network Security Group $nsgname"
}
else
{
#Updating existing rule
Write-Host -ForegroundColor Green "Deleting rule $ruleName on Network Security Group $nsgname"
$hout = Remove-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $ruleName -ErrorVariable errorck
ErrorCheck
$hout = Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg -ErrorVariable errorck
ErrorCheck
}
}
}
Write-host
}

Export-ModuleMember -Function Remove-AzureNSGRuleForRemoteLocation