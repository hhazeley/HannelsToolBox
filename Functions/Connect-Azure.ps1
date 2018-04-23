Function Connect-Azure
{

<#
  .SYNOPSIS
  Connect to Azure 
  
  .DESCRIPTION
  This cmdlet allows you to connect to Azure using stored credentials
    
  .PARAMETER Path
  Path to the xml stored credential

  .NOTES
  Author     : Hannel Hazeley - hhazeley@outlook.com

  .LINK
  https://github.com/hhazeley/HannelsToolBox/blob/master/Functions/Connect-Azure.ps1

  .EXAMPLE
  Connect-Azure -Path C:\Secure\AzureCred.xml
  
  Connects to Azure using credential stored in xml file. 
  #>

 Param(
    $Path
   )

   $ErrorActionPreference = "SilentlyContinue"
   $WarningPreference = "SilentlyContinue"

   if ($Path -eq $null)
   {
       Login-AzureRmAccount -ErrorVariable LoginError
       Write-Host -ForegroundColor Red $LoginError
   }
   else 
   {
       $cred = Import-Clixml $Path
       if ($cred -eq $null -or $cred.UserName -eq $null)
       {
       Write-Host -ForegroundColor Red "No credential in file, please provide credential"
       Login-AzureRmAccount -ErrorVariable LoginError
       Write-Host -ForegroundColor Red $LoginError
       }
       else 
       {
       Login-AzureRmAccount -Credential $cred -ErrorVariable LoginError
       Write-Host -ForegroundColor Red $LoginError
       }
   }

}

Export-ModuleMember -Function Connect-Azure