$script:DSCModuleName      = 'xHyper-V'
$script:DSCResourceName    = 'MSFT_xVMHost'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {

}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {

        $testVMName = 'UnitTestVM'

        Describe 'MSFT_xVMHost\Get-TargetResource' {

            $fakeVMHost = @{
                ResourceMeteringSaveInterval = 60;
            }

            # Guard mocks

            function Get-VMHost { }

            It 'Should return a [System.Collections.Hashtable] object type' {
                Mock Assert-Module { }
                Mock Get-VMHost { return $fakeVMHost }

                $result = Get-TargetResource -IsSingleInstance 'Yes'

                $result -is [System.Collections.Hashtable] | Should Be $true
            }

            It 'Should assert Hyper-V module is installed' {
                Mock Assert-Module { }
                Mock Get-VMHost { return $fakeVMHost }

                $result = Get-TargetResource -IsSingleInstance 'Yes'

                Assert-MockCalled Assert-Module -ParameterFilter { $Name -eq 'Hyper-V' } -Scope It
            }

        } # describe Get-TargetResource

        Describe 'MSFT_xVMHost\Test-TargetResource' {

            # Guard mocks
            Mock Assert-Module { }

            function Get-VMHost { }

            $fakeTargetResource = @{
                IsSingleInstance = 'Yes';
                EnableEnhancedSessionMode = $true;
                FibreChannelWwnn = 'C003FF0000FFFF00';
                FibreChannelWwpnMaximum = 'C003FFFBEAE1FFFF';
                FibreChannelWwpnMinimum = 'C003FFFBEAE10000';
                MacAddressMinimum = '00155D327500';
                MacAddressMaximum = '00155D3275FF';
                MaximumStorageMigrations = 2;
                MaximumVirtualMachineMigrations = 2;
                NumaSpanningEnabled = $true;
                ResourceMeteringSaveIntervalMinute = 60;
                UseAnyNetworkForMigration = $false;
                VirtualMachinePath ='C:\ProgramData\Microsoft\Windows\Hyper-V';
                VirtualMachineMigrationAuthenticationType = 'CredSSP';
                VirtualMachineMigrationPerformanceOption = 'TCPIP';
                VirtualHardDiskPath = 'C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks';
                VirtualMachineMigrationEnabled = $true
            }

            It 'Should return a [System.Boolean] object type' {
                Mock Get-TargetResource { return $fakeTargetResource }

                $testTargetResourceParams = @{
                    IsSingleInstance = 'Yes';
                    EnableEnhancedSessionMode = $fakeTargetResource.EnableEnhancedSessionMode;
                    VirtualMachineMigrationEnabled = $fakeTargetResource.VirtualMachineMigrationEnabled
                }
                $result = Test-TargetResource @testTargetResourceParams

                $result -is [System.Boolean] | Should Be $true
            }

            It 'Should assert Hyper-V module is installed' {
                Mock Get-TargetResource { return $fakeTargetResource }

                $testTargetResourceParams = @{
                    IsSingleInstance = 'Yes';
                    EnableEnhancedSessionMode = $fakeTargetResource.EnableEnhancedSessionMode;
                }
                $result = Test-TargetResource @testTargetResourceParams

                Assert-MockCalled Assert-Module -ParameterFilter { $Name -eq 'Hyper-V' } -Scope It
            }

            $parameterNames = @(
                'EnableEnhancedSessionMode',
                'FibreChannelWwnn',
                'FibreChannelWwpnMaximum',
                'FibreChannelWwpnMinimum',
                'MacAddressMaximum',
                'MacAddressMinimum',
                'MaximumStorageMigrations',
                'MaximumVirtualMachineMigrations',
                'NumaSpanningEnabled',
                'ResourceMeteringSaveIntervalMinute',
                'UseAnyNetworkForMigration',
                'VirtualHardDiskPath',
                'VirtualMachinePath',
                'VirtualMachineMigrationEnabled'
            )

            # Test each individual parameter value separately
            foreach ($parameterName in $parameterNames)
            {
                $parameterValue = $fakeTargetResource[$parameterName];
                $testTargetResourceParams = @{
                    IsSingleInstance = 'Yes';
                }

                # Pass value verbatim so it should always pass first
                It "Should pass when parameter '$parameterName' is correct" {
                    $testTargetResourceParams[$parameterName] = $parameterValue

                    $result = Test-TargetResource @testTargetResourceParams;

                    $result | Should Be $true;
                }

                if ($parameterValue -is [System.Boolean]) {

                    # Invert parameter value to cause a test failure
                    $testTargetResourceParams[$parameterName] = -not $parameterValue
                }
                elseif ($parameterValue -is [System.String]) {

                    # Repeat string to cause a test failure
                    $testTargetResourceParams[$parameterName] = "$parameterValue$parameterValue"
                }
                elseif ($parameterValue -is [System.Int32] -or $parameterValue -is [System.Int64]) {

                    # Add one to cause a test failure
                    $testTargetResourceParams[$parameterName] = $parameterValue + 1
                }

                It "Should fail when parameter '$parameterName' is incorrect" {
                    $result = Test-TargetResource @testTargetResourceParams;

                    $result | Should Be $false;
                }
            }

            It "Should pass when parameter <Parameter> is correct" -TestCases @(
                @{  Parameter = 'VirtualMachineMigrationAuthenticationType';
                    Value = $fakeTargetResource.VirtualMachineMigrationAuthenticationType;
                    Expected = $true; }
                @{  Parameter = 'VirtualMachineMigrationPerformanceOption';
                    Value = $fakeTargetResource.VirtualMachineMigrationPerformanceOption;
                    Expected = $true; }
                @{  Parameter = 'VirtualMachineMigrationEnabled';
                    Value = $fakeTargetResource.VirtualMachineMigrationEnabled;
                    Expected = $true; }
            ) -Test {
                param (
                    [System.String] $Parameter,
                    [System.Object] $Value,
                    [System.Boolean] $Expected
                )

                $testTargetResourceParams = @{
                    IsSingleInstance = 'Yes';
                    $Parameter = $Value;
                }
                $result = Test-TargetResource @testTargetResourceParams | Should Be $Expected;
            }

            It "Should fail when parameter <Parameter> is incorrect" -TestCases @(
                @{  Parameter = 'VirtualMachineMigrationAuthenticationType';
                    Value = 'Kerberos';
                    Expected = $false; }
                @{  Parameter = 'VirtualMachineMigrationPerformanceOption';
                    Value = 'Compression';
                    Expected = $false; }
                @{  Parameter = 'VirtualMachineMigrationEnabled';
                    Value = $true;
                    Expected = $true; }
            ) -Test {
                    param
                    (
                        [System.String] $Parameter,
                        [System.Object] $Value,
                        [System.Boolean] $Expected
                    )

                    $testTargetResourceParams = @{
                        IsSingleInstance = 'Yes';
                        $Parameter = $Value;
                    }
                    $result = Test-TargetResource @testTargetResourceParams | Should Be $Expected;
                }

        } # describe Test-TargetResource

        Describe 'MSFT_xVMHost\Set-TargetResource' {

            function Get-VMHost { }
            function Set-VMHost { param ($ResourceMeteringSaveInterval) }

            function Enable-VMMigration { }

            function Disable-VMMigration { }

            # Guard mocks
            Mock Assert-Module { }
            Mock Get-VMHost { }
            Mock Set-VMHost { }
            Mock Enable-VMMigration { }
            Mock Disable-VMMigration { }

            It 'Should assert Hyper-V module is installed' {
                $setTargetResourceParams = @{
                    IsSingleInstance = 'Yes';
                }

                $result = Set-TargetResource @setTargetResourceParams

                Assert-MockCalled Assert-Module -ParameterFilter { $Name -eq 'Hyper-V' } -Scope It
            }

            It 'Should call "Set-VMHost" with [System.TimeSpan] object when "ResourceMeteringSaveIntervalMinute" specified' {
                $setTargetResourceParams = @{
                    IsSingleInstance = 'Yes';
                    ResourceMeteringSaveIntervalMinute = 60;
                }
                $result = Set-TargetResource @setTargetResourceParams

                Assert-MockCalled Set-VMHost -ParameterFilter { $ResourceMeteringSaveInterval -is [System.TimeSpan] }
            }

            It 'Should call "Enable-VMMigration" when "VirtualMachineMigrationEnabled" is set to true and computer is domain joined' {
                Mock -CommandName 'Get-CimInstance' -MockWith {
                    [pscustomobject]@{
                        PartOfDomain = $true
                    }
                }

                Mock -CommandName 'Write-Error'

                $setTargetResourceParams = @{
                    IsSingleInstance = 'Yes'
                    VirtualMachineMigrationEnabled = $true
                }

                $result = Set-TargetResource @setTargetResourceParams
                Assert-MockCalled -CommandName Write-Error -Times 0 -Exactly -Scope it
                Assert-MockCalled -CommandName Enable-VMMigration -Times 1 -Exactly -Scope it
                Assert-MockCalled -CommandName Disable-VMMigration -Times 0 -Exactly -Scope it
            }

            It 'Should not call "Enable-VMMigration" and should throw when "VirtualMachineMigrationEnabled" is set to true and computer is not domain joined' {
                Mock -CommandName 'Get-CimInstance' -MockWith {
                    [pscustomobject]@{
                        PartOfDomain = $false
                    }
                }

                $setTargetResourceParams = @{
                    IsSingleInstance = 'Yes'
                    VirtualMachineMigrationEnabled = $true
                }

                { Set-TargetResource @setTargetResourceParams } | Should -Throw
                Assert-MockCalled -CommandName Enable-VMMigration -Times 0 -Exactly -Scope it
                Assert-MockCalled -CommandName Disable-VMMigration -Times 0 -Exactly -Scope it
            }

            It 'Should call "Disable-VMMigration" when "VirtualMachineMigrationEnabled" is set to false' {
                $setTargetResourceParams = @{
                    IsSingleInstance = 'Yes'
                    VirtualMachineMigrationEnabled = $false
                }

                $result = Set-TargetResource @setTargetResourceParams
                Assert-MockCalled -CommandName Enable-VMMigration -Times 0 -Exactly -Scope it
                Assert-MockCalled -CommandName Disable-VMMigration -Times 1 -Exactly -Scope it
            }

            It 'Should not call "Disable-VMMigration" or "Enable-VMMigration" when "VirtualMachineMigrationEnabled" is not set' {
                $setTargetResourceParams = @{
                    IsSingleInstance = 'Yes'
                }

                $result = Set-TargetResource @setTargetResourceParams

                Assert-MockCalled -CommandName Enable-VMMigration -Times 0 -Exactly -Scope it
                Assert-MockCalled -CommandName Disable-VMMigration -Times 0 -Exactly -Scope it
            }

            It 'Should not call "Set-VMHost" when only "VirtualMachineMigrationEnabled" is set' {
                $setTargetResourceParams = @{
                    IsSingleInstance = 'Yes'
                    VirtualMachineMigrationEnabled = $false
                    Verbose = $true
                }

                $result = Set-TargetResource @setTargetResourceParams

                Assert-MockCalled -CommandName Enable-VMMigration -Times 0 -Exactly -Scope it
                Assert-MockCalled -CommandName Disable-VMMigration -Times 1 -Exactly -Scope it
                Assert-MockCalled -CommandName Set-VMHost -Times 0 -Exactly -Scope it
            }

        } # describe Set-TargetResource

    } # InModuleScope
}
finally
{
    Invoke-TestCleanup
}
