Function Add-AzureADTestUser
{ 
<#
  .SYNOPSIS
  Add test users to Azure Active Directory.

  .DESCRIPTION
  This cmdlet uses the AzureADPreview module to add test users to Azure Active Directory.  All that you need to provide is the user's name and domain, plain text password is optional.

  .PARAMETER Domain
  Domain name for the user. This needs to be a verified domain on Azure Active Directory. . Required
    
  .PARAMETER Names
  Full name(s) of the test users to add to Azure Active Directory. Required

  .PARAMETER Password
  This password will be used to create usre(S). Note that this will not be a temporary password and will not need to be reset.
  
  .NOTES
  Author     : Hannel Hazeley - hhazeley@outlook.com

  .LINK
  https://github.com/hhazeley/HannelsToolBox/blob/master/Functions/Add-AzureADTestUser.ps1

  .EXAMPLE
  Add-AzureADTestUser -domain azure.hazelnest.com -names "John Jones","Alex A. Smith"

  This will add 2 user to Azure Active Directory and generated random password for each user that does not need to be reset. 
      
  .EXAMPLE
  Add-AzureADTestUser -domain azure.hazelnest.com -names "Clark Kent","John B. Smith" -Password Str0ngP@55word13!

  This will add 2 user to Azure Active Directory and use provided password for both users, password does not need to be reset. 
   
  #>
[cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
    $Domain,
    [Parameter(Mandatory=$true)]
    $Names,
    $Password
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
$DomainVerification = Get-AzureADDomain -Name $domain -ErrorVariable errorck
ErrorCheck
If ($DomainVerification.IsVerified -eq $false)
{
Write-host
Write-host -ForegroundColor Red "ERROR: " -NoNewline
Write-Host -ForegroundColor Red "Domain" $Domainverification.Name "is not verified and cannot be used. Please complete Domain verification and try again."
Write-host
Break
}
If ($Password -eq $null)
{
[Switch]$GeneratePassword = $true
}
Write-Host
foreach ($name in $names)
{
$fullname = $name.Split(' ')
$givenname = $fullname[0]
$surnname = $fullname[-1]
$mailnickname = $givenname.ToCharArray()[0] + $surnname
$mailnickname = $mailnickname.ToLower()
$count = (get-azureadUser | ?{$_.UserPrincipalName -like "$mailnickname`@*"}).count
If ($count -ge 1)
{
$n = 1
Do {
$mnname = $mailnickname+$n++
$count = (get-azureadUser | ?{$_.UserPrincipalName -like "$mnname`@*"}).count
} 
While ($count -ne 0)
$mailnickname = $mnname
}
$upn = $mailnickname +"@"+ $domain
$upn = $upn.ToLower()
If ($GeneratePassword.IsPresent)
{
[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
$Password = [System.Web.Security.Membership]::GeneratePassword(12,2)
}
$uPassword = New-Object "Microsoft.Open.AzureAD.Model.PasswordProfile"
$upassword.ForceChangePasswordNextLogin = $false
$upassword.Password = $Password
$hout = New-AzureADUser -AccountEnabled $true -DisplayName $name -PasswordProfile $upassword -GivenName $givenname -Surname $surnname -UserPrincipalName $upn -MailNickName $mailnickname -ErrorVariable errorck
ErrorCheck
Write-Host -ForegroundColor Green "User $name created, UPN: $upn Password: $Password."
}
Write-Host
}
Export-ModuleMember -Function Add-AzureADTestUser