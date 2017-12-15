Function Remove-AzureV2VMandResources
{ 
[cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    $rgName,
    [Parameter(Mandatory=$true)]
    $vmNames,
    [Switch]$DeleteDisks,
    [Switch]$DeleteVNet,
    [Switch]$DeleteStorageAccount,
    [Switch]$DeleteRG,
    [Switch]$DeleteAll
)

$ErrorActionPreference = "SilentlyContinue"
$WarningActionPreference = "SilentlyContinue"

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
}
else
{
#Use VM details to identify and delete data disk 
$DataDisks = $vm.StorageProfile.DataDisks
$DataDisks | % {
$vhdResourceID = $_.ManagedDisk.Id
Write-Host -ForegroundColor Green "Deleting Data Disk VHD(s)....."
Remove-AzureRmResource -ResourceId $vhdResourceID -Force | Out-Null
}

#Deleting OS disk
$vhdResourceID = $Osdisk.ManagedDisk.Id
Write-Host -ForegroundColor Green "Deleting OS Disk VHD....."
Remove-AzureRmResource -ResourceId $vhdResourceID -Force | Out-Null
}
}
Write-Host " "
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Green "Clean-up for Virtual Machine $vmName completed."
Write-Host "______________________________________________________________________"
Write-Host " "
}

if ($DeleteStorageAccount.IsPresent -and $osDisk.ManagedDisk -eq $null)
{
Start-Sleep -Seconds 30
$vhdcheck = ($SA | Get-AzureStorageContainer | Get-AzureStorageBlob | ? {$_.Name -like "*.vhd"}).count
$fscheck = ($SA | Get-AzureStorageShare).count
if ($vhdcheck -eq "0" -and $fscheck -eq "0")
{
Write-Host -ForegroundColor Green "No VHDs or fileshare found in Storage Account '$SAName', deleting Storage Account"
Remove-AzureRmStorageAccount -Name $SAName -ResourceGroupName $rgName -Force
}
Else 
{
Write-Host -ForegroundColor  Yellow -BackgroundColor Black "VHDs found in Storage Account '$SAName', Skipping deletion of Storage Account"
}
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
