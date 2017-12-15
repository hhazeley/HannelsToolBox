Function New-AzureV2VMFromGallaryImage
{
[cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    $rgName,
    [Parameter(Mandatory=$true)]
    $vmNames,
    [ValidateSet('eastasia','southeastasia','centralus','eastus','eastus2','westus','northcentralus','southcentralus','northeurope','westeurope','japanwest','japaneast','brazilsouth','australiaeast','australiasoutheast','southindia','centralindia','westindia','canadacentral','canadaeast','uksouth','ukwest','westcentralus','westus2')]
    $location,
    $saName,
    $vnetName,
    [ValidateSet('Standard_A0','Standard_A1','Standard_A2','Standard_A3','Standard_A5','Standard_A4','Standard_A6','Standard_A7','Basic_A0','Basic_A1','Basic_A2','Basic_A3','Basic_A4','Standard_D1_v2','Standard_D2_v2','Standard_D3_v2','Standard_D4_v2','Standard_D5_v2','Standard_D11_v2','Standard_D12_v2','Standard_D13_v2','Standard_D14_v2','Standard_D15_v2','Standard_F1','Standard_F2','Standard_F4','Standard_F8','Standard_F16','Standard_A1_v2','Standard_A2m_v2','Standard_A2_v2','Standard_A4m_v2','Standard_A4_v2','Standard_A8m_v2','Standard_A8_v2','Standard_DS1_v2','Standard_DS2_v2','Standard_DS3_v2','Standard_DS4_v2','Standard_DS5_v2','Standard_DS11_v2','Standard_DS12_v2','Standard_DS13_v2','Standard_DS14_v2','Standard_DS15_v2','Standard_F1s','Standard_F2s','Standard_F4s','Standard_F8s','Standard_F16s','Standard_D1','Standard_D2','Standard_D3','Standard_D4','Standard_D11','Standard_D12','Standard_D13','Standard_D14','Standard_DS1','Standard_DS2','Standard_DS3','Standard_DS4','Standard_DS11','Standard_DS12','Standard_DS13','Standard_DS14','Standard_G1','Standard_G2','Standard_G3','Standard_G4','Standard_G5','Standard_GS1','Standard_GS2','Standard_GS3','Standard_GS4','Standard_GS5','Standard_A8','Standard_A9','Standard_A10','Standard_A11','Standard_H8','Standard_H16','Standard_H8m','Standard_H16m','Standard_H16r','Standard_H16mr')]
    $vmSize,
    [ValidateSet('2008-R2-SP1','2008-R2-SP1-BYOL','2012-Datacenter','2012-Datacenter-BYOL','2012-R2-Datacenter','2012-R2-Datacenter-BYOL','2016-Datacenter','2016-Datacenter-Server-Core','2016-Datacenter-with-Containers','2016-Nano-Server')]
    $WindowsSku,
    $nsgName,
    $VMUsername,
    $VMPassword
)

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

If ($location -eq $null)
{
$location = "westus"
}
If ($vnetName -eq $null)
{
$vnetName = $rgName+"-VNet1"
}
If ($vmSize -eq $null)
{
$vmSize = "Standard_A2_v2"
}
If ($WindowsSku -eq $null)
{
$WindowsSku = "2012-R2-Datacenter"
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
$saName = $saName -replace '[^a-zA-Z0-9]', ''
$saName = $saName.ToLower() +"str1"

#Prepare storage account for virtual machine
$storageAccValidation = Get-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName $saName
if ($storageAccValidation -eq $null)
{
# Create a new storage account for the VM
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

If ($VMUsername -eq $null)
{
$VMUser = "VMAdmin"
}
Else
{
$VMUser = $VMUsername
}
If ($VMPassword -eq $null)
{
[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
$Pword = [System.Web.Security.Membership]::GeneratePassword(15,2)
}
Else
{
$Pword = $VMPassword
}

$VMPWord = ConvertTo-SecureString -String "$Pword" -AsPlainText -Force
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
If ($WindowsSku -ne "2016-Nano-Server")
{
$NSGRule = New-AzureRmNetworkSecurityRuleConfig -Name default-allow-rdp -Access Allow -Description "Allowing RDP connection" -DestinationAddressPrefix * -DestinationPortRange 3389 -Direction Inbound -Priority 1000 -Protocol Tcp -SourceAddressPrefix * -SourcePortRange *
New-AzureRmNetworkSecurityGroup -Location $location -Name $vmnsgName -ResourceGroupName $rgName -SecurityRules $NSGRule | Out-Null
[Switch]$nsgcreated = $true
ErrorCheck
}
else
{
$NSGRule = New-AzureRmNetworkSecurityRuleConfig -Name WinRM -Access Allow -Description "Allowing WinRM connection" -DestinationAddressPrefix * -DestinationPortRange 5985-5986 -Direction Inbound -Priority 1000 -Protocol Tcp -SourceAddressPrefix * -SourcePortRange *
New-AzureRmNetworkSecurityGroup -Location $location -Name $vmnsgName -ResourceGroupName $rgName -SecurityRules $NSGRule | Out-Null
[Switch]$nsgcreated = $true
ErrorCheck
}
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
If ($WindowsSku -ne "2016-Nano-Server")
{
$newVM = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm -ErrorVariable errorck
ErrorCheck
}
else
{
$newVM = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm -DisableBginfoExtension -ErrorVariable errorck
ErrorCheck
}
$vmIP = (Get-AzureRmPublicIpAddress -Name $ipName1 -ResourceGroupName $rgName).IpAddress
Write-Host "______________________________________________________________________"
Write-Host -ForegroundColor Green "Virtual Machine $vmName deployment completed."
Write-Host -ForegroundColor Green "Username: " -NoNewline
Write-Host -ForegroundColor White $VMUser -NoNewline
Write-Host -ForegroundColor Green " Password: " -NoNewline
Write-Host -ForegroundColor White $Pword -NoNewline
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