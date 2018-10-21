Function Remove-AzureV2VMandResources
{ 

<#
  .SYNOPSIS
  Ever feel it�s a pain to clear resources of a test virtual machine azure, worry no more.

  .DESCRIPTION
  This cmdlet deletes resources unique to a virtual machine. The cmdlet will delete a machine and all its resource i.e. Public IP, Network Interface, Virtual Machine and Disks. It will not delete any resource that can be a shared resource e.g. Virtual Network, Network Security Groups, or storage account.

  .PARAMETER SubscriptionId
  Subscription ID for the subscription that virtual machine is on
    
  .PARAMETER rgName
  The Resource Group the virtual machine belongs to. Required

  .PARAMETER vmNames
  The name or names of the virtual machine(s) to be deleted. Required
  
  .PARAMETER DeleteDisks
  When switch is present, cmdlet will delete disk attached to virtual machine. DELETING OF DISK MEANS THERE IS A POTENTIAL FOR DATA LOSS, USE AT YOUR OWN RISK.

  .PARAMETER DeleteVNet
  When switch is present, cmdlet will try to delete VNet the virtual machine was attached to, VNet will not be deleted if it is in use by other Virtual machines.
  
  .PARAMETER DeleteStorageAccount
  When switch is present, cmdlet will try to delete Storage Account the virtual machine was attached to, Storage Account will not be deleted if it contains VHDs. DELETING OF STORAGE ACCOUNT MEANS THERE IS A POTENTIAL FOR DATA LOSS, USE AT YOUR OWN RISK.

  .PARAMETER DeleteRG
  When switch is present, cmdlet will try to delete Resource group the virtual machine was attached to, Resource group will not be deleted if it is in use by other Resources.
  
  .PARAMETER DeleteALL
  When switch is present, All the delete Switch will be enabled.

  .NOTES
  Author     : Hannel Hazeley - hhazeley@outlook.com

  .LINK
  https://github.com/hhazeley/HannelsToolBox/blob/master/Functions/Remove-AzureV2VMandResources.ps1

  .EXAMPLE
  Remove-AzureV2VMandResources -SubscriptionId "1d6737e7-4f6c-4e3c-8cd4-996b6f003d0e" -rgName DVideoRG1 -vmNames DV1-DPBSV1-002 -DeleteDisks

  This will delete virtual machine and all resources including OS and data disks attached to virtual machine 
      
  .EXAMPLE
  Remove-AzureV2VMandResources -SubscriptionId "1d6737e7-4f6c-4e3c-8cd4-996b6f003d0e" -rgName DVideoRG1 -vmNames DV1-DPBSV1-002

  This will delete virtual machine and all resources excluding OS and data disks attached to virtual machine
    
  .EXAMPLE
  Remove-AzureV2VMandResources -SubscriptionId "1d6737e7-4f6c-4e3c-8cd4-996b6f003d0e" -rgName DVideoRG1 -vmNames "DV1-DPBSV1-001","DV1-DPBSV1-002"

  This will delete both virtual machines and all resources excluding their OS and data disks attached to virtual machines
  #>

[cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    $rgName,
    [Parameter(Mandatory=$true)]
    $vmNames,
    [Parameter(ParameterSetName='options')]
    [Switch]$DeleteDisks,
    [Parameter(ParameterSetName='options')]
    [Switch]$DeleteVNet,
    [Parameter(ParameterSetName='options')]
    [Switch]$DeleteStorageAccount,
    [Parameter(ParameterSetName='options')]
    [Switch]$DeleteRG,
    [Parameter(ParameterSetName='all')]
    [Switch]$DeleteAll
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

If ($DeleteAll.IsPresent)
{
$DeleteDisks = $DeleteVNet = $DeleteStorageAccount = $DeleteRG = $true
}

#Selecting subscription
$hout = Select-AzureRmSubscription -SubscriptionId $SubscriptionId -ErrorVariable errorck
ErrorCheck

foreach ($vmName in $vmNames)
{
Write-Host
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Green "Starting Clean-up for Virtual Machine $vmName."
Write-Host "______________________________________________________________________"
Write-Host
#stop VM
Write-Host -ForegroundColor Green "Stopping Virtual Machine $vmName"
$hout = Stop-AzureRmVM -Name $vmName -ResourceGroupName $rgName -Force -ErrorVariable errorck
ErrorCheck

#Get details of VM
$vm = get-azurermvm -ResourceGroupName $rgName -Name $vmName -ErrorVariable errorck
ErrorCheck

#Deleting VM
Write-Host -ForegroundColor Green "Deleting Virtual Machine $vmName"
$hout = Remove-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Force -ErrorVariable errorck
ErrorCheck

#Use VM details to identify and delete Availability Set
If ($vm.AvailabilitySetReference -ne $null)
{
$avsetname = $vm.AvailabilitySetReference.Id -replace '.*?availabilitySets/',""
$avsetrgname = $vm.AvailabilitySetReference.Id -replace '.*?resourceGroups/',"" -replace '/providers/.*',""
$avsetcount = (Get-AzureRmAvailabilitySet -ResourceGroupName $avsetrgname -Name $avsetname).VirtualMachinesReferences.Count
If ($avsetcount -eq 0)
{
Write-Host -ForegroundColor Green "Availability Set $avsetname not in use, deleting Availability Set"
$hout = Remove-AzureRmAvailabilitySet -ResourceGroupName $avsetrgname -Name $avsetname -Force -ErrorVariable errorck
ErrorCheck
}
else
{
Write-Host -ForegroundColor Yellow -BackgroundColor Black "Availability Set $avsetname is in use, Skipping deletion of Availability Set"
}
}

#Use VM details to identify and delete network resources, NIC and PIP
$nics = $vm.NetworkProfile.NetworkInterfaces.id
$nics | % {
$nicName = $_ -replace '.*?interfaces/',""

$nic = Get-AzureRmNetworkInterface -ExpandResource NetworkSecurityGroup -Name "$nicName" -ResourceGroupName $rgName

$pipName = $nic.IpConfigurations.Publicipaddress.Id -replace '.*?addresses/',""
Write-Host -ForegroundColor Green "Deleting network interface $nicName"
Remove-AzureRmNetworkInterface -Name "$nicName" -ResourceGroupName $rgName -Force

$nsg = $nic.NetworkSecurityGroup
If ($nsg -ne $null){
$nsgID = $nsg.Id
$nsgName = $nsgID -replace '.*?networkSecurityGroups/',""
$nsgrgName = $nsgID -replace '.*?resourceGroups/',"" -replace '/providers/.*',""
$nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $nsgrgname
$nifc = ($nsg.NetworkInterfaces).Count
$snc = ($nsg.Subnets).Count
if ($snc -eq "0" -and $nifc -eq "0")
{
Write-Host -ForegroundColor Green "NSG $nsgName not in use, deleting NSG"
Remove-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $nsgrgName -Force
}
Else 
{
Write-Host -ForegroundColor Yellow -BackgroundColor Black "NSG $nsgName is in use, Skipping deletion of NSG"
}
}

if ($pipName -ne $null)
{
Write-Host -ForegroundColor Green "Deleting Public IP '$pipName'"
Remove-AzureRmPublicIpAddress -Name "$pipName" -ResourceGroupName $rgName -Force
}

$vmid = $vm.VmId
$bootdiagstruri = $vm.DiagnosticsProfile.BootDiagnostics.StorageUri
if ($bootdiagstruri -ne $null)
{
$SAName = ($bootdiagstruri).Split('/')[2].Split('.')[0]
$recourceInfo = Get-AzureRmResource | ?{$_.Name -eq "$SAName" -and $_.ResourceType -eq "Microsoft.Storage/storageAccounts"}
$SA = Get-AzureRmStorageAccount -ResourceGroupName $recourceInfo.ResourceGroupName -name $SAName
$contianerName = ($SA | Get-AzureStorageContainer | ?{$_.name -like "*$vmid"}).Name
Write-Host -ForegroundColor Green "Deleting diagnostic contianer $contianerName from $SAName....."
$SA | Remove-AzureStorageContainer -Name $contianername -Force
}

if ($DeleteVNet.IsPresent)
{
$subnetID = $nic.IpConfigurations.Subnet.Id
$vnetname = $subnetID -replace '.*?virtualNetworks/',"" -replace '/subnets/.*',""
$vnetrgname = $subnetID -replace '.*?resourceGroups/',"" -replace '/providers/.*',""
$VNet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $vnetrgname
$ips = $VNet.Subnets | % {($_.IpConfigurations).Count}
$total = ($ips | Measure-Object -Sum).Sum
if ($total -eq "0")
{
Write-Host -ForegroundColor Green "Virtual Network '$vnetname' not in use, deleting Virtual Network"
Remove-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $vnetrgname -Force
}
Else 
{
Write-Host -ForegroundColor  Yellow -BackgroundColor Black "Virtual Network '$vnetname' in use, Skipping deletion of Virtual Network"
}
}
}

if ($DeleteDisks.IsPresent)
{
#2 minutes script sleep to release disks 
Start-Sleep -Seconds 120
Use VM details to identify OS disk
$osDisk = $vm.StorageProfile.OsDisk
if ($osDisk.ManagedDisk -eq $null)
{
#Use VM details to identify and delete data disk 
$DataDisks = $vm.StorageProfile.DataDisks
$DataDisks | % {
$vhduri = $_.Vhd.Uri
$SAName = ($VHDuri).Split('/')[2].Split('.')[0] 
$SA = Get-AzureRmStorageAccount -ResourceGroupName $rgName -name $SAName
Write-Host -ForegroundColor Green "Deleting Data Disk VHD(s)....."
$SA | Remove-AzureStorageBlob -Blob ($VHDuri).Split('/')[-1] -Container ($VHDuri).Split('/')[-2] -Force
}

#Deleting OS disk
$vhduri = $Osdisk.Vhd.Uri
$SAName = ($VHDuri).Split('/')[2].Split('.')[0] 
$SA = Get-AzureRmStorageAccount -ResourceGroupName $rgName -name $SAName
Write-Host -ForegroundColor Green "Deleting OS Disk VHD....."
$SA | Remove-AzureStorageBlob -Blob ($VHDuri).Split('/')[-1] -Container ($VHDuri).Split('/')[-2] -Force

if ($DeleteStorageAccount.IsPresent -and $osDisk.ManagedDisk -eq $null)
{
Start-Sleep -Seconds 30
$vhdcheck = ($SA | Get-AzureStorageContainer | Get-AzureStorageBlob | ? {$_.Name -like "*.vhd"}).count
$fscheck = ($SA | Get-AzureStorageShare).count
$bdcheck = ($SA | Get-AzureStorageContainer | ?{$_.name -like "bootdiagnostics-*"}).count
if ($vhdcheck -eq "0" -and $fscheck -eq "0" -and $bdcheck -eq "0")
{
Write-Host -ForegroundColor Green "No VHDs, fileshare or boot diagnostics container found in Storage Account '$SAName', deleting Storage Account"
Remove-AzureRmStorageAccount -Name $SAName -ResourceGroupName $rgName -Force
}
Else 
{
Write-Host -ForegroundColor  Yellow -BackgroundColor Black "VHDs, fileshare or boot diagnostics container found in Storage Account '$SAName', Skipping deletion of Storage Account"
}
}
}
else
{
#Use VM details to identify and delete data disk 
$DataDisks = $vm.StorageProfile.DataDisks
$DataDisks | % {
$vhdResourceID = $_.ManagedDisk.Id
Write-Host -ForegroundColor Green "Deleting Data Disk(s)....."
Remove-AzureRmResource -ResourceId $vhdResourceID -Force | Out-Null
}

#Deleting OS disk
$vhdResourceID = $Osdisk.ManagedDisk.Id
Write-Host -ForegroundColor Green "Deleting OS Disk....."
Remove-AzureRmResource -ResourceId $vhdResourceID -Force | Out-Null
}
}

Write-Host " "
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Green "Clean-up for Virtual Machine $vmName completed."
Write-Host "______________________________________________________________________"
Write-Host " "
}

If ($DeleteRG.IsPresent)
{
Start-Sleep -Seconds 30
$rgrcount = (Get-AzureRmResource | ?{$_.ResourceGroupName -eq "$rgName"}).count
if ($rgrcount -eq "0")
{
Write-Host " "
Write-Host -ForegroundColor Green "No Resources found in Resource Group '$rgName', deleting Resource Group"
Remove-AzureRmResourceGroup -Name $rgName -Force | Out-Null
Write-Host " "
}
Else
{
Write-Host " "
Write-Host -ForegroundColor  Yellow -BackgroundColor Black "Resource found in Resource Group '$rgName', Skipping deletion of Resource Group"
Write-Host " "
}
}
}

Export-ModuleMember -Function Remove-AzureV2VMandResources
