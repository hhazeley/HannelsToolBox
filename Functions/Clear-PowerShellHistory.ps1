Function Clear-PowerShellHistory{
<#
  .SYNOPSIS
  Clears PowerShell history on machine.
  
  .DESCRIPTION
  This cmdlet allows you to clear PowerShell history on machine.

  .NOTES
  Author     : Hannel Hazeley - hhazeley@outlook.com

  .LINK
  https://github.com/hhazeley/HannelsToolBox/blob/master/Functions/Clear-PowerShellHistory.ps1

  .EXAMPLE
  Clear-PowerShellHistory
  
  Clears PowerShell history on machine.
  #>
  $ErrorActionPreference = "SilentlyContinue"
  $WarningPreference = "SilentlyContinue"
  [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
  Remove-Item (Get-PSReadlineOption).HistorySavePath
  Exit
}
Export-ModuleMember -Function Clear-PowerShellHistory