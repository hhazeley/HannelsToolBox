Function Switch-AzureV2VMOSDisk
{

<#
  .SYNOPSIS
  Backup and switch Virtual machine's OS disk 
  
  .DESCRIPTION
  This cmdlet will backup a virtual machine's Operating System disk.  
    
  .PARAMETER SubscriptionId
  Subscription ID for the subscription that virtual machine is on. Required
    
  .PARAMETER rgName
  The Resource Group the virtual machine belongs to. Required

  .PARAMETER vmName
  The name of the virtual machine you need to create image from to be deleted. Required

  .NOTES
  Author     : Hannel Hazeley - hhazeley@outlook.com

  .LINK
  https://github.com/hhazeley/HannelsToolBox/blob/master/Functions/Switch-AzureV2VMOSDisk.ps1

  .EXAMPLE
  Switch-AzureV2VMOSDisk -SubscriptionId 1d6737e7-4f6c-4e3c-8cd4-996b6f003d0e -rgName DVideoRG1 -vmName DV1-DPBIMG-001
  
  Creates a backup of the OS Disk of virtual machine and switch OS disk to newly created backup. 
  #>

 Param(
    [Parameter(Mandatory=$true)]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    $rgName,
    [Parameter(Mandatory=$true)]
    $vmName
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

#Backup VHD
$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName -ErrorVariable errorck
ErrorCheck
$status = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Status
$state = $status.Statuses[1].Code
if ($state -ne "PowerState/deallocated")
{
Write-host
Write-host -ForegroundColor Red "Virtual machine $vmName needs to be in a 'deallocated' state to switch disk.  Please stop virtual machine and retry switch operation again."
Write-host
Break
}
else
{
$osDisk = $vm.StorageProfile.OsDisk
if ($osDisk.ManagedDisk -eq $null)
{
$vhduri = $vm.StorageProfile.OsDisk.Vhd.Uri
$saName = ($vhduri).Split('/')[2].Split('.')[0]
$vhdName = ($vhduri).Split('/')[-1]
$contName = ($vhduri).Split('/')[-2]
$sa = Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName -ErrorVariable errorck
ErrorCheck
$sasToken = $sa | New-AzureStorageAccountSASToken -Service Blob -ResourceType Container,Object -Permission racwl  -ErrorVariable errorck
ErrorCheck
$srccontext = New-AzureStorageContext -SasToken "$sasToken" -StorageAccountName $saName -Protocol Https
$hout = New-AzureStorageContainer -Name backup -Context $srccontext
$diskdate = Get-Date -Format yyMMddHHmmss
$bvhdName = $vmName +"-OSDisk-bk$diskdate.vhd"
$bvhd = Start-AzureStorageBlobCopy -SrcBlob $vhdName -SrcContainer $contName -Context $srccontext -DestBlob $bvhdName -DestContainer backup -DestContext $srccontext -ErrorVariable errorck
ErrorCheck
Write-Host -ForegroundColor Green "Backup Completed. VHD $vhdName has been copied to $bvhdName in the 'backup' container"
Write-Host -ForegroundColor Green "Switching OS Disk for $vmName to new back up disk $bvhdName........"
$newvhduri = $bvhd.Context.BlobEndPoint+"backup/"+$bvhd.Name
$vm.StorageProfile.OsDisk.Vhd.Uri = $newvhduri
Update-AzureRmVM -ResourceGroupName $rgname -VM $vm -ErrorVariable errorck
ErrorCheck
Write-Host -ForegroundColor Green "Switch Completed. Disk $bvhdName now attached to VM $vmName"
Write-Host " "
Write-Host -ForegroundColor Green "Original VHDUri: " -NoNewline
Write-Host -ForegroundColor Cyan  $vhduri
Write-Host " "
}
else
{
$osDiskID = $osDisk.ManagedDisk.Id
$bdisk = New-AzureRmDiskConfig -CreateOption Copy -Location $vm.location -OsType $osDisk.OsType -SourceResourceId $osDiskID
$diskdate = Get-Date -Format yyMMddHHmmss
$bdiskName  = $vmName +"-OSDisk-bk"+$diskdate
$bdisk = New-AzureRmDisk -Disk $bdisk -DiskName $bdiskName -ResourceGroupName $rgName -ErrorVariable errorck
ErrorCheck
Write-Host -ForegroundColor Green "Backup Completed. Disk"$osDisk.Name"has been copied to"$bdisk.Name"."
Write-Host -ForegroundColor Green "Switching OS Disk for $vmName to new back up disk"$bdisk.Name"........"
#Set the new disk properties and update the VM
Set-AzureRmVMOSDisk -VM $vm -ManagedDiskId $bdisk.Id -Name $bdisk.Name | Update-AzureRmVM -ErrorVariable errorck
ErrorCheck
Write-Host -ForegroundColor Green "Switch Completed. Disk"$bdisk.Name"now attached to VM $vmName"
Write-Host " "
Write-Host -ForegroundColor Green "Original ManagedDisk ID: " -NoNewline
Write-Host -ForegroundColor Cyan  $osDiskID
Write-Host " "
}
}
}

Export-ModuleMember -Function Switch-AzureV2VMOSDisk