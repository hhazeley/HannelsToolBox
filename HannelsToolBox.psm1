# Gather all files
$Functions = @( Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the functions
ForEach ($File in $Functions) {
### ForEach ($File in @($PublicFunctions + $PrivateFunctions)) {
    Try {
        . $File.FullName
    } Catch {
        Write-Error -Message "Failed to import function $($File.FullName): $_"
    }
}

Export-ModuleMember -Function $Functions.Basename