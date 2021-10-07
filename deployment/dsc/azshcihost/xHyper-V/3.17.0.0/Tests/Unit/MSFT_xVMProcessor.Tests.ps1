$script:DSCModuleName      = 'xHyper-V'
$script:DSCResourceName    = 'MSFT_xVMProcessor'

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
        $testResourcePoolName = 'Unit Test Resource Pool'

        Describe 'MSFT_xVMProcessor\Get-TargetResource' {

            $fakeVMProcessor = @{
                EnableHostResourceProtection = $true
            }

            # Guard mocks
            Mock Assert-Module { }

            function Get-VMProcessor {
                [CmdletBinding()]
                param
                (
                    [System.String]
                    $VMName
                )
            }

            It 'Should return a [System.Collections.Hashtable] object type' {
                Mock Get-VMProcessor { return $fakeVMProcessor }

                $result = Get-TargetResource -VMName $testVMName

                $result -is [System.Collections.Hashtable] | Should Be $true
            }

            It 'Should assert Hyper-V module is installed' {
                Mock Assert-Module { }
                Mock Get-VMProcessor { return $fakeVMProcessor }

                $null = Get-TargetResource -VMName $testVMName

                Assert-MockCalled Assert-Module -ParameterFilter { $Name -eq 'Hyper-V' } -Scope It
            }

            It 'Should throw when VM processor is not found' {
                Mock Get-Module { return $true }
                Mock Get-VMProcessor { Write-Error 'Not Found' }
                { $null = Get-TargetResource -VMName $testVMName } | Should Throw 'Not Found'
            }
        } # descrive Get-TargetResource

        Describe 'MSFT_xVMProcessor\Test-TargetResource' {

            # Guard mocks
            Mock Assert-Module { }
            Mock Assert-TargetResourceParameter { }

            function Get-VM {
                param (
                    [System.String]
                    $Name
                )
            }

            function Get-VMProcessor {
                param (
                    [System.String]
                    $VMName
                )
            }

            function Set-VMProcessor {
                param (
                    [System.String]
                    $VMName
                )
            }

            $fakeTargetResource = @{
                VMName = $testVMName
                EnableHostResourceProtection = $true
                ExposeVirtualizationExtensions = $true
                HwThreadCountPerCore = 1
                Maximum = 99
                MaximumCountPerNumaNode = 4
                MaximumCountPerNumaSocket = 1
                RelativeWeight = 99
                Reserve = 0
                ResourcePoolName = $testResourcePoolName
                CompatibilityForMigrationEnabled = $false
                CompatibilityForOlderOperatingSystemsEnabled = $false
            }

            It 'Should return a [System.Boolean] object type' {
                Mock Get-TargetResource { return $fakeTargetResource }

                $result = Test-TargetResource -VMName $testVMName

                $result -is [System.Boolean] | Should Be $true
            }

            It 'Should assert Hyper-V module is installed' {
                Mock Get-VMProcessor { return $fakeVMProcessor }

                $null = Test-TargetResource -VMName $testVMName

                Assert-MockCalled Assert-Module -ParameterFilter { $Name -eq 'Hyper-V' } -Scope It
            }

            It 'Should assert parameter values are valid' {
                Mock Get-VMProcessor { return $fakeVMProcessor }

                $null = Test-TargetResource -VMName $testVMName

                Assert-MockCalled Assert-TargetResourceParameter -Scope It
            }

            $parameterNames = @(
                'EnableHostResourceProtection',
                'ExposeVirtualizationExtensions',
                'HwThreadCountPerCore',
                'Maximum',
                'MaximumCountPerNumaNode',
                'MaximumCountPerNumaSocket',
                'RelativeWeight',
                'Reserve',
                'ResourcePoolName',
                'CompatibilityForMigrationEnabled',
                'CompatibilityForOlderOperatingSystemsEnabled'
            )

            # Test each individual parameter value separately
            foreach ($parameterName in $parameterNames)
            {
                $parameterValue = $fakeTargetResource[$parameterName]
                $testTargetResourceParams = @{
                    VMName = $testVMName
                }

                # Pass value verbatim so it should always pass first
                It "Should pass when parameter '$parameterName' is correct" {
                    $testTargetResourceParams[$parameterName] = $parameterValue

                    $result = Test-TargetResource @testTargetResourceParams

                    $result | Should Be $true
                }

                if ($parameterValue -is [System.Boolean])
                {
                    # Invert parameter value to cause a test failure
                    $testTargetResourceParams[$parameterName] = -not $parameterValue
                }
                elseif ($parameterValue -is [System.String])
                {
                    # Repeat string to cause a test failure
                    $testTargetResourceParams[$parameterName] = "$parameterValue$parameterValue"
                }
                elseif ($parameterValue -is [System.Int32] -or $parameterValue -is [System.Int64])
                {
                    # Add one to cause a test failure
                    $testTargetResourceParams[$parameterName] = $parameterValue + 1
                }

                It "Should fail when parameter '$parameterName' is incorrect" {
                    $result = Test-TargetResource @testTargetResourceParams

                    $result | Should Be $false
                }
            }
        } # describe Test-TargetResource

        Describe 'MSFT_xVMProcessor\Set-TargetResource' {

            function Get-VM {
                param
                (
                    [System.String]
                    $Name
                )
            }

            function Get-VMProcessor {
                param
                (
                    [System.String]
                    $VMName
                )
            }

            function Set-VMProcessor {
                param
                (
                    [System.String]
                    $VMName
                )
            }

            # Guard mocks
            Mock Assert-Module { }
            Mock Assert-TargetResourceParameter { }
            Mock Get-VM { }
            Mock Set-VMProcessor { }
            Mock Set-VMProperty { }

            It 'Should assert Hyper-V module is installed' {
                $null = Set-TargetResource -VMName $testVMName

                Assert-MockCalled Assert-Module -ParameterFilter { $Name -eq 'Hyper-V' } -Scope It
            }

            It 'Should assert parameter values are valid' {
                $null = Set-TargetResource -VMName $testVMName

                Assert-MockCalled Assert-TargetResourceParameter -Scope It
            }

            $restartRequiredParameters = @{
                'ExposeVirtualizationExtensions' = $false;
                'CompatibilityForMigrationEnabled' = $true;
                'CompatibilityForOlderOperatingSystemsEnabled' = $true;
                'HwThreadCountPerCore' = 2;
                'MaximumCountPerNumaNode' = 2
                'MaximumCountPerNumaSocket' = 2
                'ResourcePoolName' = $testResourcePoolName;
            }

            foreach ($parameter in $restartRequiredParameters.GetEnumerator())
            {
                $setTargetResourceParams = @{
                    VMName = $testVMName;
                    $parameter.Name = $parameter.Value;
                }

                It "Should not throw when VM is off, '$($parameter.Name)' is specified and 'RestartIfNeeded' is False" {
                    Mock Get-VM { return @{ State = 'Off' } }

                    { Set-TargetResource @setTargetResourceParams } | Should Not Throw
                }

                It "Should throw when VM is running, '$($parameter.Name)' is specified and 'RestartIfNeeded' is False" {
                    Mock Get-VM { return @{ State = 'Running' } }

                    { Set-TargetResource @setTargetResourceParams } | Should Throw
                }

                It "Should shutdown VM when running, '$($parameter.Name)' is specified and 'RestartIfNeeded' is True" {
                    Mock Get-VM { return @{ State = 'Running' } }

                    Set-TargetResource @setTargetResourceParams -RestartIfNeeded $true

                    Assert-MockCalled Set-VMProperty -Scope It -Exactly 1
                }
            }

            $noRestartRequiredParameters = @{
                'EnableHostResourceProtection' = $true;
                'Maximum' = 50;
                'RelativeWeight' = 50;
                'Reserve' = 50;
            }

            foreach ($parameter in $noRestartRequiredParameters.GetEnumerator())
            {
                $setTargetResourceParams = @{
                    VMName = $testVMName;
                    $parameter.Name = $parameter.Value;
                }

                It "Should not shutdown VM running and '$($parameter.Name) is specified" {
                    Mock Get-VM { return @{ State = 'Running' } }

                    Set-TargetResource @setTargetResourceParams

                    Assert-MockCalled Set-VMProcessor -Scope It -Exactly 1
                    Assert-MockCalled Set-VMProperty -Scope It -Exactly 0
                }
            }
        } # describe Set-TargetResource

        Describe 'MSFT_xVMProcessor\Assert-TargetResourceParameter' {

            # Return Windows Server 2012 R2/Windows 8.1 Update 1
            Mock Get-CimInstance { return @{ BuildNumber = '9600' } }

            It "Should not throw when parameter 'ResourcePoolName' is specified on 2012 R2 host" {
                { Assert-TargetResourceParameter -ResourcePoolName 'TestPool' } | Should Not Throw
            }

            $server2016OnlyParameters = @{
                EnableHostResourceProtection = $true;
                ExposeVirtualizationExtensions = $true;
                HwThreadCountPerCore = 1;
            }

            foreach ($parameter in $server2016OnlyParameters.GetEnumerator())
            {
                $assertTargetResourceParameterParams = @{
                    $parameter.Name = $parameter.Value;
                }

                It "Should throw when parameter '$($parameter.Name)' is specified on 2012 R2 host" {
                    { Assert-TargetResourceParameter @assertTargetResourceParameterParams } | Should Throw '14393'
                }
            }
        } # describe Assert-TargetResourceParameter
    } # InModuleScope
}
finally
{
    Invoke-TestCleanup
}
