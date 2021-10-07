$script:DSCModuleName      = 'xHyper-V'
$script:DSCResourceName    = 'MSFT_xVMHost'

#region HEADER
# Integration Test Template Version: 1.1.1
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

# Import the common integration test functions
Import-Module -Name ( Join-Path `
    -Path $PSScriptRoot `
    -ChildPath 'IntegrationTestsCommon.psm1' )

# Ensure that the tests can be performed on this computer
if (-not (Test-HyperVInstalled))
{
    Return
} # if

$currentVmHost = Get-VMHost
# Set-VMHost appears to update $currentVmHost by reference?!
$currentVirtualHardDiskPath = $currentVmHost.VirtualHardDiskPath
$currentVirtualMachinePath = $currentVmHost.VirtualMachinePath
$currentEnableEnhancedSessionMode = $currentVmHost.EnableEnhancedSessionMode

# Using try/finally to always cleanup even if something awful happens.
try
{
    # Import the configuration
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_set.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Set_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Set_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $ConfigData `
                    -VirtualHardDiskPath $TestDrive `
                    -VirtualMachinePath $TestDrive `
                    -EnableEnhancedSessionMode (-not $currentEnableEnhancedSessionMode)

                $startDscConfigurationParams = @{
                    Path = $TestDrive;
                    ComputerName = 'localhost';
                    Wait = $true;
                    Verbose = $true;
                    Force = $true;
                }
                Start-DscConfiguration @startDscConfigurationParams

            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Set_Config"
            }

            $current.VirtualHardDiskPath | Should Be $TestDrive.FullName
            $current.VirtualMachinePath  | Should Be $TestDrive.FullName
            $current.EnableEnhancedSessionMode | Should Be (-not $currentEnableEnhancedSessionMode)
        }
    }
}
finally
{
    #region FOOTER

    # Restore current host settings
    Set-VMHost -VirtualHardDiskPath $currentVirtualHardDiskPath `
                -VirtualMachinePath $currentVirtualMachinePath `
                -EnableEnhancedSessionMode $currentEnableEnhancedSessionMode -Verbose

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
