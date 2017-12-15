Function Backup-AzureV2VMOSDisk
{
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
$diskdate = Get-Date -Format yyyyMMddHHmmss
$bvhdName = $vhdName -replace ".vhd","_backup-$diskdate.vhd"
$hout = Start-AzureStorageBlobCopy -SrcBlob $vhdName -SrcContainer $contName -Context $srccontext -DestBlob $bvhdName -DestContainer backup -DestContext $srccontext -ErrorVariable errorck
ErrorCheck
}
else
{
Write-Host
Write-Host -ForegroundColor Red "Cannot backup disk for Virtual Machine $vmName because its a ManagedDisk, please look into snapshot instead."
Write-Host
}
}

Export-ModuleMember -Function Backup-AzureV2VMOSDisk