# Hannel's Tool Box

## Introduction 

Over the years i have accumulated/created a large amount of scripts through out my experience (Exchange, Office 365 and Azure).  HannelsToolBox is a project to clean up those scripts and put the useful and still valid one into a module.

### Prerequisites:

Powershell 5.0+

[PowerShellGet](https://www.powershellgallery.com/packages/PowerShellGet/)

[Azure PowerShell Module 5.7.0+](https://www.powershellgallery.com/packages/AzureRM/)

[Azure AD Module](https://www.powershellgallery.com/packages/AzureAD/)

#### Install:

Once the prerequisites are installed from PowerShell run command below

`Install-Module -Name HannelsToolBox`

#### Commands included in module:

[Add-AzureADTestUser](Functions\Add-AzureADTestUser.ps1)

[Add-AzureNSGRuleForRemoteLocation](Functions\Add-AzureNSGRuleForRemoteLocation.ps1)

[Backup-AzureV2VMosDisk](Functions\Backup-AzureV2VMosDisk.ps1)

[Clear-PowerShellHistory](Functions\Clear-PowerShellHistory.ps1)

[Connect-Azure](Functions\Connect-Azure.ps1)

[Export-AzureRMDisktoStorageAccount](Functions\Export-AzureRMDisktoStorageAccount.ps1)

[New-AzureV2VMFromGallaryImage](Functions\New-AzureV2VMFromGallaryImage.ps1)

[Remove-AzureNSGRuleForRemoteLocation](Functions\Remove-AzureNSGRuleForRemoteLocation.ps1)

[Remove-AzureV2VMandResources](Functions\Remove-AzureV2VMandResources.ps1)

[Switch-AzureV2VMOSDisk](Functions\Switch-AzureV2VMOSDisk.ps1)

#### Others

[HannelsToolBox YouTube Playlist](https://www.youtube.com/playlist?list=PLURKD77y7MK-MrW-88pCDnHozv0tIt2Vt)