$script:DSCModuleName      = 'xHyper-V'
$script:DSCResourceName    = 'MSFT_xVMScsiController'

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

        Describe 'MSFT_xVMScsiController\Get-TargetResource' {

            $stubScsiController = @{
                VMName           = $testVMName
                ControllerNumber = 0
            }

            # Guard mocks
            Mock Assert-Module { }

            function Get-VMScsiController {
                [CmdletBinding()]
                param
                (
                    [System.String]
                    $VMName,

                    [System.Int32]
                    $ControllerNumber
                )
            }

            It 'Should return a [System.Collections.Hashtable] object type' {
                Mock Get-VMScsiController { return $stubScsiController }

                $result = Get-TargetResource -VMName $testVMName -ControllerNumber 0

                $result -is [System.Collections.Hashtable] | Should Be $true
            }

            It 'Should return "Present" when controller is attached' {
                Mock Get-VMScsiController { return $stubScsiController }

                $result = Get-TargetResource -VMName $testVMName -ControllerNumber 0

                $result.Ensure | Should Be 'Present'
            }

            It 'Should return "Absent" when controller is not attached' {
                Mock Get-VMScsiController { }

                $result = Get-TargetResource -VMName $testVMName -ControllerNumber 0

                $result.Ensure | Should Be 'Absent'
            }

            It 'Should assert Hyper-V module is installed' {
                Mock Assert-Module { }
                Mock Get-VMScsiController { }

                $null = Get-TargetResource -VMName $testVMName -ControllerNumber 0

                Assert-MockCalled Assert-Module -ParameterFilter { $Name -eq 'Hyper-V' } -Scope It
            }
        } # descrive Get-TargetResource

        Describe 'MSFT_xVMScsiController\Test-TargetResource' {

            # Guard mocks
            Mock Assert-Module { }

            $stubTargetResource = @{
                VMName           = $testVMName
                ControllerNumber = 0
                Ensure           = 'Present'
            }

            It 'Should return a [System.Boolean] object type' {
                Mock Get-TargetResource { return $stubTargetResource }
                $testTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                }

                $result = Test-TargetResource @testTargetResourceParams

                $result -is [System.Boolean] | Should Be $true
            }

            It "Should pass when parameter 'Ensure' is correct" {
                Mock Get-TargetResource { return $stubTargetResource }
                $testTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                    Ensure           = $stubTargetResource['Ensure']
                }

                $result = Test-TargetResource @testTargetResourceParams

                $result | Should Be $true
            }

            It "Should fail when parameter 'Ensure' is incorrect" {
                Mock Get-TargetResource { return $stubTargetResource }
                $testTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                    Ensure           = 'Absent'
                }

                $result = Test-TargetResource @testTargetResourceParams

                $result | Should Be $false
            }
        } # describe Test-TargetResource

        Describe 'MSFT_xVMScsiController\Set-TargetResource' {

            function Get-VMScsiController {
                param
                (
                    [System.String]
                    $VMName
                )
            }

            function Add-VMScsiController {
                param
                (
                    [System.String]
                    $VMName
                )
            }

            function Remove-VMScsiController {
                param
                (
                    [System.String]
                    $VMName
                )
            }

            function Remove-VMHardDiskDrive {
                param (
                    [System.Object]
                    $VMHardDiskDrive
                )
            }

            # Guard mocks
            Mock Assert-Module { }
            Mock Get-VMScsiController { }
            Mock Add-VMScsiController { }
            Mock Remove-VMScsiController { }
            Mock Remove-VMHardDiskDrive { }
            Mock Set-VMState { }

            It 'Should assert Hyper-V module is installed' {
                Mock Get-VMHyperV { return @{ State = 'Running' } }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                    RestartIfNeeded  = $true
                }

                $null = Set-TargetResource @setTargetResourceParams

                Assert-MockCalled Assert-Module
            }

            It 'Should throw if "RestartIfNeeded" is not specified and VM is "Running"' {
                Mock Get-VMHyperV { return @{ State = 'Running' } }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                }

                { Set-TargetResource @setTargetResourceParams } | Should Throw 'RestartIfNeeded'
            }

            It 'Should not throw if "RestartIfNeeded" is not specified and VM is "Off"' {
                Mock Get-VMHyperV { return @{ State = 'Off' } }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                }

                { Set-TargetResource @setTargetResourceParams } | Should Not Throw
            }

            It 'Should call "Set-VMState" to stop running VM' {
                Mock Get-VMHyperV { return @{ State = 'Running' } }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                    RestartIfNeeded  = $true
                }

                $null = Set-TargetResource @setTargetResourceParams

                Assert-MockCalled Set-VMState -ParameterFilter { $State -eq 'Off' } -Scope It
            }

            It 'Should call "Set-VMState" to restore VM to its previous state' {
                $testVMState = 'Paused'
                Mock Get-VMHyperV { return @{ State = $testVMState } }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                    RestartIfNeeded  = $true
                }

                $null = Set-TargetResource @setTargetResourceParams

                Assert-MockCalled Set-VMState -ParameterFilter { $State -eq $testVMState } -Scope It
            }

            It 'Should add single controller when it does not exist' {
                Mock Get-VMHyperV { return @{ State = 'Running' } }
                Mock Get-VMScsiController { }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                    RestartIfNeeded  = $true
                }

                $null = Set-TargetResource @setTargetResourceParams

                Assert-MockCalled Add-VMScsiController -Scope It -Exactly 1
            }

            It 'Should add single controller when one already exists' {
                Mock Get-VMHyperV { return @{ State = 'Running' } }
                $fakeVMScsiController = [PSCustomObject] @{ ControllerNumber = 0 }
                Mock Get-VMScsiController { return $fakeVMScsiController }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 1
                    RestartIfNeeded  = $true
                }

                $null = Set-TargetResource @setTargetResourceParams

                Assert-MockCalled Add-VMScsiController -Scope It -Exactly 1
            }

            It 'Should throw when adding controller when intermediate controller(s) do not exist' {
                Mock Get-VMHyperV { return @{ State = 'Running' } }
                Mock Get-VMScsiController { }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 1
                    RestartIfNeeded  = $true
                }

                { Set-TargetResource @setTargetResourceParams } | Should Throw 'Cannot add controller'
            }

            It 'Should remove controller when Ensure = "Absent"' {
                Mock Get-VMHyperV { return @{ State = 'Running' } }
                $fakeVMScsiControllers = @(
                    [PSCustomObject] @{ ControllerNumber = 0 }
                    [PSCustomObject] @{ ControllerNumber = 1 }
                )
                Mock Get-VMScsiController { return $fakeVMScsiControllers }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 1
                    RestartIfNeeded  = $true
                    Ensure           = 'Absent'
                }

                $null = Set-TargetResource @setTargetResourceParams -WarningAction SilentlyContinue

                Assert-MockCalled Remove-VMScsiController -Scope It
            }

            It 'Should remove all attached disks when Ensure = "Absent"' {
                Mock Get-VMHyperV { return @{ State = 'Running' } }
                $fakeVMScsiController = [PSCustomObject] @{
                    ControllerNumber = 0
                    Drives = @(
                        [PSCustomObject] @{ Name = 'Hard Drive on SCSI controller number 0 at location 0' }
                        [PSCustomObject] @{ Name = 'Hard Drive on SCSI controller number 0 at location 1' }
                    )
                }
                Mock Get-VMScsiController { return $fakeVMScsiController }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                    RestartIfNeeded  = $true
                    Ensure           = 'Absent'
                }

                $null = Set-TargetResource @setTargetResourceParams -WarningAction SilentlyContinue

                Assert-MockCalled Remove-VMHardDiskDrive -Scope It -Exactly ($fakeVMScsiController.Drives.Count)
            }

            It 'Should throw removing a controller when additional/subsequent controller(s) exist' {
                Mock Get-VMHyperV { return @{ State = 'Running' } }
                $fakeVMScsiControllers = @(
                    [PSCustomObject] @{ ControllerNumber = 0 }
                    [PSCustomObject] @{ ControllerNumber = 1 }
                )
                Mock Get-VMScsiController { return $fakeVMScsiControllers }
                $setTargetResourceParams = @{
                    VMName           = $testVMName
                    ControllerNumber = 0
                    RestartIfNeeded  = $true
                    Ensure           = 'Absent'
                }

                { Set-TargetResource @setTargetResourceParams } | Should Throw 'Cannot remove controller'
            }

        } # describe Set-TargetResource
    } # InModuleScope
}
finally
{
    Invoke-TestCleanup
}
