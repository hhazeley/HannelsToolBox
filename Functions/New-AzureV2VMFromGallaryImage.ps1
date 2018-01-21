Function New-AzureV2VMFromGallaryImage
{

<#
  .SYNOPSIS
  Creating virtual machine(s) from gallery image with one line.
  
  .DESCRIPTION
  This cmdlet will create a single or numerous virtual machines from gallery image with just one line. 
  
  .PARAMETER SubscriptionId
  Subscription ID for the subscription that virtual machine(s) is on. Required
    
  .PARAMETER rgName
  Resource group where the resources will be created. Required

  .PARAMETER vmNames
  Name or names of the virtual machine(s) to be created. Required

  .PARAMETER location
  Location where the Azure resources will be created.

  .PARAMETER saName
  Name of the storage account name to use if you want to use un-managed disk. Note: If storage account doesn't exist, cmdlet will create a unique storage account.

  .PARAMETER vnetName
  Name of the virtual network that virtual machine will be on.

  .PARAMETER vmSize
  Size of the new virtual machine that is been created Example: Standard_A0 See information in link https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes/.

  .PARAMETER WindowsSku
  Windows SKU to use to create the virtual machine(s).

  .PARAMETER nsgName
  Specify a NIC NSG that you will like machine to be on. If not specified a Windows default NSG will be used/created automatically.

  .PARAMETER VMUser
  Username that will be used for the Windows configuration.

  .PARAMETER VMPass
  Password that will be used for the Windows configuration. If not specified a strong random password will be generated and used.

  .NOTES
  Author     : Hannel Hazeley - hhazeley@outlook.com

  .LINK
  https://github.com/hhazeley/HannelsToolBox/blob/master/Functions/New-AzureV2VMFromGallaryImage.ps1

  .EXAMPLE
  New-AzureV2VMFromGallaryImage -SubscriptionId 1d6737e7-4f6c-4e3c-8cd4-996b6f003d0e -rgName DVideoRG1 -vmNames DV1-DPBSV1-001

  This will create virtual machine using all cmdlet default configuration.
  #>

[cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    $rgName,
    [Parameter(Mandatory=$true)]
    $vmNames,
    [ValidateSet('eastasia','southeastasia','centralus','eastus','eastus2','westus','northcentralus','southcentralus','northeurope','westeurope','japanwest','japaneast','brazilsouth','australiaeast','australiasoutheast','southindia','centralindia','westindia','canadacentral','canadaeast','uksouth','ukwest','westcentralus','westus2','koreacentral','koreasouth')]
    $location,
    $saName,
    $vnetName,
    [ValidateSet('Standard_DS1_v2','Standard_DS2_v2','Standard_DS3_v2','Standard_DS4_v2','Standard_DS5_v2','Standard_DS11_v2','Standard_DS12_v2','Standard_DS13-2_v2','Standard_DS13-4_v2','Standard_DS13_v2','Standard_DS14-4_v2','Standard_DS14-8_v2','Standard_DS14_v2','Standard_DS15_v2','Standard_F1s','Standard_F2s','Standard_F4s','Standard_F8s','Standard_F16s','Standard_A0','Standard_A1','Standard_A2','Standard_A3','Standard_A5','Standard_A4','Standard_A6','Standard_A7','Basic_A0','Basic_A1','Basic_A2','Basic_A3','Basic_A4','Standard_D1_v2','Standard_D2_v2','Standard_D3_v2','Standard_D4_v2','Standard_D5_v2','Standard_D11_v2','Standard_D12_v2','Standard_D13_v2','Standard_D14_v2','Standard_D15_v2','Standard_DS1','Standard_DS2','Standard_DS3','Standard_DS4','Standard_DS11','Standard_DS12','Standard_DS13','Standard_DS14','Standard_B1ms','Standard_B1s','Standard_B2ms','Standard_B2s','Standard_B4ms','Standard_B8ms','Standard_D2_v3','Standard_D4_v3','Standard_D8_v3','Standard_D16_v3','Standard_D32_v3','Standard_D64_v3','Standard_D2s_v3','Standard_D4s_v3','Standard_D8s_v3','Standard_D16s_v3','Standard_D32s_v3','Standard_D64s_v3','Standard_E2_v3','Standard_E4_v3','Standard_E8_v3','Standard_E16_v3','Standard_E32_v3','Standard_E64_v3','Standard_E2s_v3','Standard_E4s_v3','Standard_E8s_v3','Standard_E16s_v3','Standard_E32-8s_v3','Standard_E32-16s_v3','Standard_E32s_v3','Standard_E64-16s_v3','Standard_E64-32s_v3','Standard_E64s_v3','Standard_G1','Standard_G2','Standard_G3','Standard_G4','Standard_G5','Standard_GS1','Standard_GS2','Standard_GS3','Standard_GS4','Standard_GS4-4','Standard_GS4-8','Standard_GS5','Standard_GS5-8','Standard_GS5-16','Standard_L4s','Standard_L8s','Standard_L16s','Standard_L32s','Standard_A8','Standard_A9','Standard_A10','Standard_A11','Standard_H8','Standard_H16','Standard_H8m','Standard_H16m','Standard_H16r','Standard_H16mr')]
    $vmSize,
    [ValidateSet('2008-R2-SP1','2008-R2-SP1-smalldisk','2012-Datacenter','2012-Datacenter-smalldisk','2012-R2-Datacenter','2012-R2-Datacenter-smalldisk','2016-Datacenter','2016-Datacenter-smalldisk')]
    $WindowsSku,
    $nsgName,
    $VMUser,
    $VMPass
)

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

If ($location -eq $null)
{
$location = "westus2"
}
If ($vnetName -eq $null)
{
$vnetName = $rgName+"-VNet1"
}
If ($vmSize -eq $null)
{
$vmSize = "Standard_B2ms"
}
If ($WindowsSku -eq $null)
{
$WindowsSku = "2012-R2-Datacenter-smalldisk"
}
If ($StorageSku -eq $null)
{
$StorageSku = "Standard_LRS"
}
If ($SubnetAddressPrefix -eq $null)
{
$SubnetAddressPrefix = "10.0.1.0/24"
}
If ($VNetAddressPrefix -eq $null)
{
$VNetAddressPrefix = "10.0.0.0/16"
}

#Function for error checks
Function ErrorCheck{
If ($errorck -ne $null)
{
Write-host
Write-host -ForegroundColor Red "ERROR: " -NoNewline
Write-Host -ForegroundColor Red $errorck
if ($nic1created.IsPresent)
{
Write-Host -ForegroundColor Yellow -BackgroundColor Black "Rolling back..... Removing Network Interface $ipName1"
Remove-AzureRmNetworkInterface -Name $ipName1 -ResourceGroupName $rgName -Force | Out-Null
}
if ($pip1created.IsPresent)
{
Write-Host -ForegroundColor Yellow -BackgroundColor Black "Rolling back..... Removing Public IP $ipName1"
Remove-AzureRmPublicIpAddress -Name $ipName1 -ResourceGroupName $rgName -Force | Out-Null
}
if ($nsgcreated.IsPresent)
{
Write-Host -ForegroundColor Yellow -BackgroundColor Black "Rolling back..... Removing NSG $vmnsgName"
Remove-AzureRmNetworkSecurityGroup -Name $vmnsgName -ResourceGroupName $rgName -Force | Out-Null
}
if ($VNetcreated.IsPresent)
{
Write-Host -ForegroundColor Yellow -BackgroundColor Black "Rolling back..... Removing Virtual Network $vnetName"
Remove-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Force | Out-Null
}
if ($sacreated.IsPresent)
{
Write-Host -ForegroundColor Yellow -BackgroundColor Black "Rolling back..... Removing Storage Account $saName"
Remove-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName -Force | Out-Null
}
if ($rgcreated.IsPresent)
{
Write-Host -ForegroundColor Yellow -BackgroundColor Black "Rolling back..... Removing Resource Group $rgName"
Remove-AzureRmResourceGroup -Name $rgName -Force | Out-Null
}
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Red "Script aborted and actions rolled back, see above error."
Write-Host "______________________________________________________________________"
Break
}
}

#Set subscription
$hout = Select-AzureRmSubscription -SubscriptionId $SubscriptionId -ErrorVariable errorck
ErrorCheck

Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Cyan "Starting deployment"
Write-Host "______________________________________________________________________"
Write-Host 

#Check for and/or created Azure Resource Group
$rgNameValidation = Get-AzureRmResourceGroup -Name $rgName 
if ($rgNameValidation -eq $null)
{
Write-Host -ForegroundColor Green "Creating Resource Group $rgName"
$rg = New-AzureRmResourceGroup -Name $rgName -location $location -Force -ErrorVariable errorck
ErrorCheck
[Switch]$rgcreated = $true
}
Else
{
$rgLocation = $rgNameValidation.Location
If ($rgLocation -ne $location)
{
Write-Host -ForegroundColor Yellow -BackgroundColor Black "Resource Group location is different from specified location, resource will be created using same location as Resource Group ($rgLocation)."
$location = $rgLocation
}
}

If ($saName -ne $null)
{

#Prepare storage account for virtual machine
$storageAccValidation = Get-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName $saName
if ($storageAccValidation -eq $null)
{
# Create a new storage account for the VM

$rnum = Get-Random -Minimum 1000 -Maximum 9999
$userID = (Get-AzureRmContext).Account.Id
$userID = $userID.Substring(0,3)
if ($rgName.Length -gt 14)
{
$rgNamestr = $rgName.Substring(0,14)
}
else
{
$rgNamestr = $rgName
}
$saName = $rgNamestr+"str"+$userID+$rnum 
$saName = $saName -replace '[^a-zA-Z0-9]', ''
$saName = $saName.ToLower()

Write-Host -ForegroundColor Green "Creating Storage Account $saName"
$storageAcc = New-AzureRmStorageAccount -Location $location -Name $saName -ResourceGroupName $rgName -SkuName $StorageSku -Kind Storage -ErrorVariable errorck
ErrorCheck
[Switch]$sacreated = $true
}
Else
{
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName $saName
}
}

$vnetvalidation = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName
If ($vnetvalidation -eq $null)
{
Write-Host -ForegroundColor Green "Creating Virtual Network $vnetName"
$Subnet =New-AzureRmVirtualNetworkSubnetConfig -AddressPrefix $SubnetAddressPrefix -Name Subnet1 -ErrorVariable errorck
ErrorCheck
$vnet = New-AzureRmVirtualNetwork -AddressPrefix $VNetAddressPrefix -Location $location -Name $vnetName -ResourceGroupName $rgName -Force -Subnet $Subnet -ErrorVariable errorck
ErrorCheck
[Switch]$VNetcreated = $true
}
Else
{
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName
}

Foreach ($vmName in $vmNames)
{
$vmNameValidation = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName
if ($vmNameValidation -ne $null)
{
Write-Host
Write-Host -ForegroundColor Red "Cannot create Virtual Machine, $vmName already exist."
Write-Host
Break
}
Write-Host -ForegroundColor Green "Starting deployment for Virtual Machine $vmName."

If ($VMUser -eq $null)
{
$VMUser = "VMAdmin"
}

If ($VMPass -eq $null)
{
[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
$VMPass = [System.Web.Security.Membership]::GeneratePassword(15,2)
}

$VMPWord = ConvertTo-SecureString -String "$VMPass" -AsPlainText -Force
$cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $VMUser, $VMPWord

#Getting existing NSG in resource group
If ($nsgName -eq $null)
{
$vmnsgName = $vmName+"-nsg"
}
Else
{
$vmnsgName = $nsgName
}
$VNetworkSecurityGroup = (Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName).Name
#Validating Default NSG exists 
If ($VNetworkSecurityGroup -notcontains "$vmnsgName")
{
#Creating Default Windows NSG
Write-Host -ForegroundColor Green "Creating Network Security Groups $vmnsgName"
$NSGRule = New-AzureRmNetworkSecurityRuleConfig -Name default-allow-rdp -Access Allow -Description "Allowing RDP connection" -DestinationAddressPrefix * -DestinationPortRange 3389 -Direction Inbound -Priority 1000 -Protocol Tcp -SourceAddressPrefix * -SourcePortRange *
New-AzureRmNetworkSecurityGroup -Location $location -Name $vmnsgName -ResourceGroupName $rgName -SecurityRules $NSGRule | Out-Null
[Switch]$nsgcreated = $true
ErrorCheck
}

#Setting NSG to windows default NSG, since its not provided
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Name $vmnsgName

#Set the VM name and size
#Use "Get-Help New-AzureRmVMConfig" to know the available options for -VMsize
Write-Host -ForegroundColor Green "Creating Virtual Machine $vmName configuration"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

#Set the Windows operating system configuration and add the NIC
$computerName = $vmName
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate 
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus $WindowsSku -Version "latest" -ErrorVariable errorck
ErrorCheck

$rnum = Get-Random -Minimum 100 -Maximum 999
$ipName1 = $vmName + $rnum
Write-Host -ForegroundColor Green "Creating Public IP $ipName1"
$pip1 = New-AzureRmPublicIpAddress -Name $ipName1 -Location $location -ResourceGroupName $rgName -AllocationMethod Dynamic
[Switch]$pip1created = $true
Write-Host -ForegroundColor Green "Creating Network Interface $ipName1"
$nic1 = New-AzureRmNetworkInterface -Name $ipName1 -ResourceGroupName $rgName -Location $location -PublicIpAddressId $pip1.Id -SubnetId $vnet.Subnets[0].Id -NetworkSecurityGroupId $nsg.Id
[Switch]$nic1created = $true
Write-Host -ForegroundColor Green "Adding Network Interface $ipName1 to Virtual Machine $vmName"
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic1.Id -Primary

# Set OSDisk Name
$diskdate = Get-Date -Format yyyyMMddHHmmss
$osDiskName  = $vmName +"-OSDisk"+$diskdate

If ($saName -eq $null)
{
#You set this variable when you uploaded the VHD
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -CreateOption FromImage
}
else
{
#Create the OS disk URI
$osDiskUri = '{0}vhds/{1}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $osDiskName

#You set this variable when you uploaded the VHD
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption FromImage 
}
#Create the new VM
Write-Host -ForegroundColor Green "Creating Virtual Machine $vmName"
$newVM = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm -ErrorVariable errorck
ErrorCheck

$vmIP = (Get-AzureRmPublicIpAddress -Name $ipName1 -ResourceGroupName $rgName).IpAddress
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Green "Virtual Machine $vmName deployment completed."
Write-Host -ForegroundColor Green "Username: " -NoNewline
Write-Host -ForegroundColor White $VMUser -NoNewline
Write-Host -ForegroundColor Green " Password: " -NoNewline
Write-Host -ForegroundColor White $VMPass -NoNewline
Write-Host -ForegroundColor Green " PublicIP: " -NoNewline
Write-Host -ForegroundColor White $vmIP
Write-Host "______________________________________________________________________"
Write-Host 
}

Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Cyan "Deployment Completed"
Write-Host "______________________________________________________________________"
}

Export-ModuleMember -Function New-AzureV2VMFromGallaryImage