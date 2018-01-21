Function Backup-AzureV2VMOSDisk
{

<#
  .SYNOPSIS
  Backup Virtual machine's OS disk 
  
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
  https://github.com/hhazeley/HannelsToolBox/blob/master/Functions/Backup-AzureV2VMosDisk.ps1

  .EXAMPLE
  Backup-AzureV2VMOSDisk -SubscriptionId 1d6737e7-4f6c-4e3c-8cd4-996b6f003d0e -rgName DVideoRG1 -vmName DV1-DPBIMG-001
  
  Creates a backup of the OS Disk of virtual machine  
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
$WarningActionPreference = "SilentlyContinue"

#Function for error checks
Function ErrorCheck{
If ($errorck -ne $null)
{
Write-host
Write-host -ForegroundColor Red "ERROR: " -NoNewline
$errorck
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
$osDisk = $vm.StorageProfile.OsDisk
if ($osDisk.ManagedDisk -eq $null)
{
$saName = ($vm.StorageProfile.OsDisk.Vhd.Uri).Split('/')[2].Split('.')[0]
$vhdName = ($vm.StorageProfile.OsDisk.Vhd.Uri).Split('/')[-1]
$contName = ($vm.StorageProfile.OsDisk.Vhd.Uri).Split('/')[-2]
$sa = Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName -ErrorVariable errorck
ErrorCheck
$sasToken = $sa | New-AzureStorageAccountSASToken -Service Blob -ResourceType Container,Object -Permission racwl  -ErrorVariable errorck
ErrorCheck
$srccontext = New-AzureStorageContext -SasToken "$sasToken" -StorageAccountName $saName -Protocol Https
$hout = New-AzureStorageContainer -Name backup -Context $srccontext
$diskdate = Get-Date -Format yyMMddHHmmss
$bvhdName = $vmName +"-OSDisk-bk$diskdate.vhd"
$hout = Start-AzureStorageBlobCopy -SrcBlob $vhdName -SrcContainer $contName -Context $srccontext -DestBlob $bvhdName -DestContainer backup -DestContext $srccontext -ErrorVariable errorck
ErrorCheck
Write-Host " "
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Green "Backup Completed. VHD $vhdName has been copied to $bvhdName in the 'backup' container"
Write-Host "______________________________________________________________________"
Write-Host " "
}
else
{
$bdisk = New-AzureRmDiskConfig -CreateOption Copy -Location $vm.location -OsType $osDisk.OsType -SourceResourceId $osDisk.ManagedDisk.Id
$diskdate = Get-Date -Format yyMMddHHmmss
$bdiskName  = $vmName +"-OSDisk-bk"+$diskdate
$hout = New-AzureRmDisk -Disk $bdisk -DiskName $bdiskName -ResourceGroupName $rgName -ErrorVariable errorck
ErrorCheck
Write-Host " "
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Green "Backup Completed. Managed Disk"$osDisk.Name"has been copied to"$hout.Name
Write-Host "______________________________________________________________________"
Write-Host " "
}
}

Export-ModuleMember -Function Backup-AzureV2VMOSDisk