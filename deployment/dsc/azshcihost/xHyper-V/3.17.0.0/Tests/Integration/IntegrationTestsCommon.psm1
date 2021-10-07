<#
    .SYNOPSIS
    Tests if Hyper-V is installed on this OS.

    .OUTPUTS
    True if Hyper-V is installed. False otherwise.
#>
function Test-HyperVInstalled
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
    )

    # Ensure that the tests can be performed on this computer
    if ($PSVersionTable.PSEdition -eq 'Core')
    {
        # Nano Server uses Get-WindowsOptionalFeature like Desktop OS
        $ProductType = 1
    }
    else
    {
        $ProductType = (Get-CimInstance Win32_OperatingSystem).ProductType
    } # if
    switch ($ProductType) {
        1
        {
            # Desktop OS or Nano Server
            $HyperVInstalled = (((Get-WindowsOptionalFeature `
                    -FeatureName Microsoft-Hyper-V `
                    -Online).State -eq 'Enabled') -and `
                ((Get-WindowsOptionalFeature `
                    -FeatureName Microsoft-Hyper-V-Management-PowerShell `
                    -Online).State -eq 'Enabled'))
            Break
        }
        3
        {
            # Server OS
            $HyperVInstalled = (((Get-WindowsFeature -Name Hyper-V).Installed) -and `
                ((Get-WindowsFeature -Name Hyper-V-PowerShell).Installed))
            Break
        }
        default
        {
            # Unsupported OS type for testing
            Write-Verbose -Message "Integration tests cannot be run on this operating system." -Verbose
            Break
        }
    }

    if ($HyperVInstalled -eq $false)
    {
        Write-Verbose -Message "Integration tests cannot be run because Hyper-V Components not installed." -Verbose
        Return $false
    }
    Return $True
} # end function Test-HyperVInstalled
