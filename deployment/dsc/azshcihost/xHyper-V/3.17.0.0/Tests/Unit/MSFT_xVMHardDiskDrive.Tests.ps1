$script:DSCModuleName      = 'xHyper-V'
$script:DSCResourceName    = 'MSFT_xVMHardDiskDrive'

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
        $testHardDiskPath = 'TestDrive:\{0}.vhdx' -f $testVMName

        Describe 'MSFT_xVMHardDiskDrive\Get-TargetResource' {

            $stubHardDiskDrive = @{
                VMName             = $testVMName
                Path               = $testHardDiskPath
                ControllerLocation = 0
                ControllerNumber   = 0
                ControllerType     = 'SCSI'
            }

            # Guard mocks
            Mock Assert-Module { }

            function Get-VMHardDiskDrive {
                [CmdletBinding()]
                param
                (
                    [System.String]
                    $VMName
                )
            }

            It 'Should return a [System.Collections.Hashtable] object type' {
                Mock Get-VMHardDiskDrive { return $stubHardDiskDrive }

                $result = Get-TargetResource -VMName $testVMName -Path $testhardDiskPath

                $result -is [System.Collections.Hashtable] | Should Be $true
            }

            It 'Should return "Present" when hard disk is attached' {
                Mock Get-VMHardDiskDrive { return $stubHardDiskDrive }

                $result = Get-TargetResource -VMName $testVMName -Path $testhardDiskPath

                $result.Ensure | Should Be 'Present'
            }

            It 'Should return "Absent" when hard disk is not attached' {
                Mock Get-VMHardDiskDrive { }

                $result = Get-TargetResource -VMName $testVMName -Path $testhardDiskPath

                $result.Ensure | Should Be 'Absent'
            }

            It 'Should assert Hyper-V module is installed' {
                Mock Assert-Module { }
                Mock Get-VMHardDiskDrive { return $stubHardDiskDrive }

                $null = Get-TargetResource -VMName $testVMName -Path $testhardDiskPath

                Assert-MockCalled Assert-Module -ParameterFilter { $Name -eq 'Hyper-V' } -Scope It
            }
        } # descrive Get-TargetResource

        Describe 'MSFT_xVMHardDiskDrive\Test-TargetResource' {

            # Guard mocks
            Mock Assert-Module { }

            function Get-VMHardDiskDrive {
                [CmdletBinding()]
                param
                (
                    [System.String]
                    $VMName
                )
            }

            $stubTargetResource = @{
                VMName             = $testVMName
                Path               = $testHardDiskPath
                ControllerType     = 'SCSI'
                ControllerNumber   = 0
                ControllerLocation = 0
                Ensure             = 'Present'
            }

            It 'Should return a [System.Boolean] object type' {
                Mock Get-TargetResource { return $stubTargetResource }

                $result = Test-TargetResource -VMName $testVMName -Path $testHardDiskPath

                $result -is [System.Boolean] | Should Be $true
            }

            $parameterNames = @(
                'ControllerNumber',
                'ControllerLocation'
            )

            foreach ($parameterName in $parameterNames)
            {
                $parameterValue = $stubTargetResource[$parameterName]
                $testTargetResourceParams = @{
                    VMName = $testVMName
                    Path   = $testHardDiskPath
                }

                It "Should pass when parameter '$parameterName' is correct" {
                    # Pass value verbatim so it should always pass first
                    $testTargetResourceParams[$parameterName] = $parameterValue

                    $result = Test-TargetResource @testTargetResourceParams

                    $result | Should Be $true
                }

                It "Should fail when parameter '$parameterName' is incorrect" {
                    # Add one to cause a test failure
                    $testTargetResourceParams[$parameterName] = $parameterValue + 1

                    $result = Test-TargetResource @testTargetResourceParams

                    $result | Should Be $false
                }
            }

            It "Should pass when parameter 'ControllerType' is correct" {
                $testTargetResourceParams = @{
                    VMName         = $testVMName
                    Path           = $testHardDiskPath
                    ControllerType = $stubTargetResource['ControllerType']
                }

                $result = Test-TargetResource @testTargetResourceParams

                $result | Should Be $true
            }

            It "Should fail when parameter 'ControllerType' is incorrect" {
                $testTargetResourceParams = @{
                    VMName         = $testVMName
                    Path           = $testHardDiskPath
                    ControllerType = 'IDE'
                }

                $result = Test-TargetResource @testTargetResourceParams

                $result | Should Be $false
            }

            It "Should pass when parameter 'Ensure' is correct" {
                $testTargetResourceParams = @{
                    VMName = $testVMName
                    Path   = $testHardDiskPath
                    Ensure = $stubTargetResource['Ensure']
                }

                $result = Test-TargetResource @testTargetResourceParams

                $result | Should Be $true
            }

            It "Should fail when parameter 'Ensure' is incorrect" {
                $testTargetResourceParams = @{
                    VMName = $testVMName
                    Path   = $testHardDiskPath
                    Ensure = 'Absent'
                }

                $result = Test-TargetResource @testTargetResourceParams

                $result | Should Be $false
            }

            It 'Should throw when IDE controller number 2 is specified' {
                $testTargetResourceParams = @{
                    VMName           = $testVMName
                    Path             = $testHardDiskPath
                    ControllerType   = 'IDE'
                    ControllerNumber = 2
                }

                { Test-TargetResource @testTargetResourceParams } | Should Throw 'not valid'
            }

            It 'Should throw when IDE controller location 2 is specified' {
                $testTargetResourceParams = @{
                    VMName             = $testVMName
                    Path               = $testHardDiskPath
                    ControllerType     = 'IDE'
                    ControllerLocation = 2
                }

                { Test-TargetResource @testTargetResourceParams } | Should Throw 'not valid'
            }
        } # describe Test-TargetResource

        Describe 'MSFT_xVMHardDiskDrive\Set-TargetResource' {

            function Get-VMHardDiskDrive {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    [System.String]
                    $VMName,

                    [System.String]
                    $Path,

                    [System.String]
                    $ControllerType,

                    [System.Int32]
                    $ControllerNumber,

                    [System.Int32]
                    $ControllerLocation
                )
            }

            function Set-VMHardDiskDrive {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    [System.String]
                    $VMName,

                    [System.String]
                    $Path,

                    [System.String]
                    $ControllerType,

                    [System.Int32]
                    $ControllerNumber,

                    [System.Int32]
                    $ControllerLocation
                )
            }

            function Add-VMHardDiskDrive {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    [System.String]
                    $VMName,

                    [System.String]
                    $Path,

                    [System.String]
                    $ControllerType,

                    [System.Int32]
                    $ControllerNumber,

                    [System.Int32]
                    $ControllerLocation
                )
            }

            function Remove-VMHardDiskDrive {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    [System.String]
                    $VMName,

                    [System.String]
                    $Path,

                    [System.String]
                    $ControllerType,

                    [System.Int32]
                    $ControllerNumber,

                    [System.Int32]
                    $ControllerLocation
                )
            }

            # Guard mocks
            Mock Assert-Module { }
            Mock Get-VMHardDiskDrive { }
            Mock Set-VMHardDiskDrive { }
            Mock Add-VMHardDiskDrive { }
            Mock Remove-VMHardDiskDrive { }

            $stubHardDiskDrive = @{
                VMName             = $testVMName
                Path               = $testHardDiskPath
                ControllerLocation = 0
                ControllerNumber   = 0
                ControllerType     = 'SCSI'
            }

            It 'Should assert Hyper-V module is installed' {
                Mock Get-VMHardDiskDrive { return $stubHardDiskDrive }

                $null = Set-TargetResource -VMName $testVMName -Path $testHardDiskPath

                Assert-MockCalled Assert-Module -ParameterFilter { $Name -eq 'Hyper-V' } -Scope It
            }

            It 'Should update existing hard disk' {
                Mock Get-VMHardDiskDrive { return $stubHardDiskDrive }

                $null = Set-TargetResource -VMName $testVMName -Path $testHardDiskPath

                Assert-MockCalled Set-VMHardDiskDrive -Scope It
            }

            It 'Should add hard disk when is not attached' {
                Mock Get-VMHardDiskDrive { }
                Mock Get-VMHardDiskDrive -ParameterFilter { $PSBoundParameters.ContainsKey('ControllerType') }

                $null = Set-TargetResource -VMName $testVMName -Path $testHardDiskPath

                Assert-MockCalled Add-VMHardDiskDrive -Scope It
            }

            It 'Should throw when an existing disk is attached to controller/location' {
                Mock Get-VMHardDiskDrive { }
                Mock Get-VMHardDiskDrive -ParameterFilter { $PSBoundParameters.ContainsKey('ControllerType') } { return $stubHardDiskDrive }

                { Set-TargetResource -VMName $testVMName -Path $testHardDiskPath } | Should Throw 'disk present'
            }

            It 'Should remove attached hard disk when Ensure is "Absent"' {
                Mock Get-VMHardDiskDrive { return $stubHardDiskDrive }

                $null = Set-TargetResource -VMName $testVMName -Path $testHardDiskPath -Ensure 'Absent'

                Assert-MockCalled Remove-VMHardDiskDrive -Scope It
            }
        } # describe Set-TargetResource
    } # InModuleScope
}
finally
{
    Invoke-TestCleanup
}
