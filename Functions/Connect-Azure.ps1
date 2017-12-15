Function Connect-AzureTest
{
 Param(
    $Path
   )

   $ErrorActionPreference = "SilentlyContinue"
   $WarningActionPreference = "SilentlyContinue"

   if ($Path -eq $null)
   {
       $cred = Import-Clixml C:\Scripts\azurecred.xml
       if ($cred -eq $null -or $cred.UserName -eq $null)
       {
       Login-AzureRmAccount -ErrorVariable LoginError
       Write-Host -ForegroundColor Red $LoginError
       }
       else 
       {
       Login-AzureRmAccount -Credential $cred -ErrorVariable LoginError
       Write-Host -ForegroundColor Red $LoginError
       }
   }
   else 
   {
       $cred = Import-Clixml $Path
       if ($cred -eq $null -or $cred.UserName -eq $null)
       {
       Write-Host -ForegroundColor Cyan "No credential in file, please provide credential"
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

Export-ModuleMember -Function Connect-AzureTest