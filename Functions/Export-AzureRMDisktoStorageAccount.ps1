Function Export-AzureRMDisktoStorageAccount
{
<#
  .SYNOPSIS
  Export Azure Managed disk to storage account.
  
  .DESCRIPTION
  This cmdlet will export a managed disk within your subscription or a managed disk you have a SAS token for to a storage account within your subscription. 
  
  .PARAMETER StorageAccountName
  The name of the storage account to export managed disk to. Required
    
  .PARAMETER StorageAccountRG
  The name of Resource group where storage account is. Required

  .PARAMETER DiskName
  The name of the managed disk you want to export. If you are exporting using a SAS token this is still required. Required

  .PARAMETER DiskRG
  The name of Resource group where the managed disk you want to export is. This is required if you are exporting a managed disk within your subscription.

  .PARAMETER MDSASuri
  SAS token for the managed disk you want to export. This is required if you are exporting a managed disk using a SAS token.

  .NOTES
  Author     : Hannel Hazeley - hhazeley@outlook.com

  .LINK
  https://github.com/hhazeley/HannelsToolBox/blob/master/Functions/Export-AzureRMDisktoStorageAccount.ps1

  .EXAMPLE
  $sasuri = "https://md-jtvc3rvr31p0.blob.core.windows.net/mdc141fxh4kk/abcd?sv=2017-04-17&sr=b&si=371d9d60-1d03-4595-ba14-8da2c339c284&sig=gJu8lmkp1JqOnp8pZgKoHa4rrOPCn%2B0Pnr8QdCUCM3M%3D"
  Export-AzureRMDisktoStorageAccount -StorageAccountName storagedemostr1 -StorageAccountRG StorageDemo -DiskName testdisk1 -MDSASuri $sasuri

  This will export managed disk using SAS token into storage account within your subscription.
  
  .EXAMPLE
  Export-AzureRMDisktoStorageAccount -StorageAccountName storagedemostr1 -StorageAccountRG StorageDemo -DiskName testdisk1 -DiskRG StorageDemo

  This will export managed disk within your subscription into storage account within your subscription.
  #>

[cmdletbinding(DefaultParameterSetName="Local")]
Param (
    [Parameter(Mandatory=$true)]
    $StorageAccountName,
    [Parameter(Mandatory=$true)]
    $StorageAccountRG,
    [Parameter(Mandatory=$true)]
    $DiskName,
    [Parameter(ParameterSetName="Local",Mandatory=$true)]
    $DiskRG,
    [Parameter(ParameterSetName="SAS",Mandatory=$true)]
    $MDSASuri
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
if ($DiskAccess.IsPresent)
{
Write-Host -ForegroundColor Yellow -BackgroundColor Black "Rolling back..... Revoking disk access....."
Revoke-AzureRmDiskAccess -DiskName $DiskName -ResourceGroupName $DiskRG | Out-Null
}
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Red "Script aborted and actions rolled back, see above error."
Write-Host "______________________________________________________________________"
Break
}
}

if ($DiskRG -ne $null)
{
$md = Get-AzureRmDisk | ? {$_.Name -eq "$DiskName" -and $_.ResourceGroupName -eq "$DiskRG"}
If ($md.count -ne "1")
{
Write-host
Write-host -ForegroundColor Red "ERROR: Validate you have the right Managed disk name ($DiskName) and/or Resource Group name ($DiskRG) and you are logged in with right account."
Write-Host
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Red "Script aborted and actions rolled back, see above error."
Write-Host "______________________________________________________________________"
Break
}
$MDSASuri = Grant-AzureRmDiskAccess -DiskName $DiskName -ResourceGroupName $DiskRG -Access read -DurationInSecond 3600 -ErrorVariable errorck
ErrorCheck
[Switch]$DiskAccess = $true
$MDSASuri = $MDSASuri.AccessSAS
}

if ($MDSASuri -ne $null)
{
$MDSASuriCheck = Invoke-WebRequest -Method Head -Uri $MDSASuri -ErrorVariable errorck
If ($errorck -ne $null)
{
Write-host
Write-host -ForegroundColor Red "ERROR: SAS uri not valid"
Write-Host -ForegroundColor Red $errorck
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Red "Script aborted and actions rolled back, see above error."
Write-Host "______________________________________________________________________"
Break
}
}

$diskdate = Get-Date -Format yyMMddHHmmss
$vhdName = $DiskName + $diskdate + ".vhd"
$storageAcc = Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $StorageAccountRG -ErrorVariable errorck
ErrorCheck
$hout = New-AzureStorageContainer -Name backup -Context $storageAcc.Context
$hout = Start-AzureStorageBlobCopy -AbsoluteUri $MDSASuri -DestBlob $vhdName -DestContainer backup -DestContext $storageAcc.Context -Force -ErrorVariable errorck
ErrorCheck
Write-host
Write-host -ForegroundColor Green "Exporting Managed Disk $DiskName to $vhdName in Storage Account $StorageAccountName..........."
Get-AzureStorageBlobCopyState -Blob $vhdName -Container backup -Context $storageAcc.Context -WaitForComplete
if ($DiskAccess.IsPresent)
{
Revoke-AzureRmDiskAccess -DiskName $DiskName -ResourceGroupName $DiskRG | Out-Null
}
}
Export-ModuleMember -Function Export-AzureRMDisktoStorageAccount