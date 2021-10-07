$script:DSCModuleName      = 'xHyper-V'
$script:DSCResourceName    = 'MSFT_xVMProcessor'

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

# Using try/finally to always cleanup even if something awful happens.
try
{
    $VMName = 'HyperVIntTestsVM'
    $VMPath = Join-Path -Path $env:Temp `
        -ChildPath $VMName

    # Make sure test VM does not exist
    if (Get-VM -Name $VMName -ErrorAction SilentlyContinue)
    {
        $null = Remove-VM -Name $VMName -Force
    } # if

    # Create the VM that will be used to test with
    $null = New-VM -Name $VMName -NoVHD -Path $VMPath

    # Create a config data object to pass to the DSC Configs
    $ConfigData = @{
        AllNodes = @(
            @{
                NodeName                                     = 'localhost'
                VMName                                       = $VMName
                CompatibilityForMigrationEnabled             = $true
                CompatibilityForOlderOperatingSystemsEnabled = $true
            }
        )
    }

    # Set processor option(s)
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_set.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Set_Integration" {
        Context 'Configure VM' {
            #region DEFAULT TESTS
            It 'Should compile without throwing' {
                {
                    & "$($script:DSCResourceName)_Set_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $ConfigData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
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
                $current.VMName | Should Be $VMName
                $current.CompatibilityForMigrationEnabled | Should Be $true
                $current.CompatibilityForOlderOperatingSystemsEnabled | Should Be $true
            }
        }
    }
}
finally
{
    #region FOOTER
    # Make sure the test VM has been removed
    if (Get-VM -Name $VMName -ErrorAction SilentlyContinue)
    {
        $null = Remove-VM -Name $VMName -Force
    } # if

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
