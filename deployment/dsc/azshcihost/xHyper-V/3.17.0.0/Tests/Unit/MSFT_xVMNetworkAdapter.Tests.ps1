$Global:DSCModuleName   = 'xHyper-V'
$Global:DSCResourceName = 'MSFT_xVMNetworkAdapter'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $Global:DSCResourceName {

        # Create the Mock Objects that will be used for running tests
        $MockHostAdapter = [PSCustomObject] @{
            Id                  = 'HostManagement1'
            Name                = 'Management'
            SwitchName          = 'HostSwitch'
            VMName              = 'ManagementOS'
        }

        $propertiesStatic = @{
            IpAddress = "192.168.0.1"
            Subnet = "255.255.255.0"
        }

        $networkSettingsStatic = New-CimInstance -ClassName xNetworkSettings -Property $properties -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly

        $TestAdapter = [PSObject]@{
            Id                      = $MockHostAdapter.Id
            Name                    = $MockHostAdapter.Name
            SwitchName              = $MockHostAdapter.SwitchName
            VMName                  = $MockHostAdapter.VMName
        }

        $MockAdapter = [PSObject]@{
            Name                    = $TestAdapter.Name
            SwitchName              = $MockHostAdapter.SwitchName
            IsManagementOs          = $True
            MacAddress              = '14FEB5C6CE98'
        }

        $MockAdapterVlanUntagged = [PSObject]@{
            OperationMode = 'Untagged'
        }

        $MockAdapterVlanTagged = [PSObject]@{
            OperationMode = 'Access'
            AccessVlanId = '1'
        }

        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            #Function placeholders
            function Get-VMNetworkAdapter { }
            function Set-VMNetworkAdapter { }
            function Remove-VMNetworkAdapter { }
            function Get-VMNetworkAdapterVlan { }
            function Add-VMNetworkAdapter { }
            function Get-NetworkInformation { }
            Context 'NetAdapter does not exist' {
                Mock Get-VMNetworkAdapter
                Mock Get-VMNetworkAdapterVlan
                It 'should return ensure as absent' {
                    $Result = Get-TargetResource `
                        @TestAdapter
                    $Result.Ensure | Should Be 'Absent'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -commandName Get-VMNetworkAdapterVlan -Exactly 0
                }
            }

            Context 'NetAdapter exists' {
                Mock -CommandName Get-VMNetworkAdapter -MockWith {
                    $MockAdapter
                }
                Mock -CommandName Get-VMNetworkAdapterVlan -MockWith {
                    $MockAdapterVlanUntagged
                }
                Mock -CommandName Get-NetworkInformation -MockWith {
                    return @{
                        IpAddress = '10.10.10.10'
                        Subnet = '255.255.255.0'
                        DefaultGateway = '10.10.10.1'
                        DnsServer = '10.10.10.1'
                    }
                }

                It 'should return adapter properties' {
                    $Result = Get-TargetResource @TestAdapter
                    $Result.Ensure                 | Should Be 'Present'
                    $Result.Name                   | Should Be $TestAdapter.Name
                    $Result.SwitchName             | Should Be $TestAdapter.SwitchName
                    $Result.VMName                 | Should Be 'ManagementOS'
                    $Result.Id                     | Should Be $TestAdapter.Id
                    $Result.VlanId                 | Should -BeNullOrEmpty
                    $Result.NetworkSetting         | Should -Not -BeNullOrEmpty
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -commandName Get-VMNetworkAdapterVlan -Exactly 1
                }
            }

            Context 'NetAdapter exists' {
                Mock -CommandName Get-VMNetworkAdapter -MockWith {
                    $MockAdapter
                }
                Mock -CommandName Get-VMNetworkAdapterVlan -MockWith {
                    $MockAdapterVlanTagged
                }

                It 'should return adapter properties' {
                    $Result = Get-TargetResource @TestAdapter
                    $Result.Ensure                 | Should Be 'Present'
                    $Result.Name                   | Should Be $TestAdapter.Name
                    $Result.SwitchName             | Should Be $TestAdapter.SwitchName
                    $Result.VMName                 | Should Be 'ManagementOS'
                    $Result.Id                     | Should Be $TestAdapter.Id
                    $Result.VlanId                 | Should Be '1'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -commandName Get-VMNetworkAdapterVlan -Exactly 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            #Function placeholders
            function Get-VMNetworkAdapter { }
            function Get-VMNetworkAdapterVlan { }
            function Set-VMNetworkAdapter { }
            function Set-VMNetworkAdapterVlan { }
            function Remove-VMNetworkAdapter { }
            function Add-VMNetworkAdapter { }
            function Get-NetworkInformation { }
            function Set-NetworkInformation { }

            $newAdapter = [PSObject]@{
                Id                      = 'UniqueString'
                Name                    = $TestAdapter.Name
                SwitchName              = $TestAdapter.SwitchName
                VMName                  = 'VMName'
                NetworkSetting          = $networkSettingsStatic
                Ensure                  = 'Present'
            }

            Context 'Adapter does not exist but should' {

                Mock Get-VMNetworkAdapter
                Mock Get-VMNetworkAdapterVlan
                Mock Add-VMNetworkAdapter
                Mock Remove-VMNetworkAdapter
                Mock Set-VMNetworkAdapterVlan
                Mock Set-NetworkInformation

                It 'should not throw error' {
                    {
                        Set-TargetResource @newAdapter
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -CommandName Set-VMNetworkAdapterVlan -Exactly 0
                    Assert-MockCalled -commandName Add-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -commandName Remove-VMNetworkAdapter -Exactly 0
                    Assert-MockCalled -CommandName Set-NetworkInformation -Exactly 1
                }
            }

            Context 'Adapter exists but should not exist' {
                Mock Get-VMNetworkAdapter
                Mock Add-VMNetworkAdapter
                Mock Remove-VMNetworkAdapter
                Mock Set-VMNetworkAdapterVlan

                It 'should not throw error' {
                    {
                        $updateAdapter = $newAdapter.Clone()
                        $updateAdapter.Ensure = 'Absent'
                        Set-TargetResource @updateAdapter
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -commandName Add-VMNetworkAdapter -Exactly 0
                    Assert-MockCalled -commandName Remove-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -CommandName Set-VMNetworkAdapterVlan -Exactly 0
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            #Function placeholders
            function Get-VMNetworkAdapter { }
            function Get-VMNetworkAdapterVlan { }
            function Set-VMNetworkAdapter { }
            function Remove-VMNetworkAdapter { }
            function Add-VMNetworkAdapter { }
            function Get-NetworkInformation { }

            $newAdapter = [PSObject]@{
                Id                      = 'UniqueString'
                Name                    = $TestAdapter.Name
                SwitchName              = $TestAdapter.SwitchName
                VMName                  = 'ManagementOS'
                Ensure                  = 'Present'
            }

            Context 'Adapter does not exist but should' {
                Mock Get-VMNetworkAdapter
                Mock Get-VMNetworkAdapterVlan

                It 'should return false' {
                        Test-TargetResource @newAdapter | Should be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                }
            }

            Context 'Adapter exists but should not exist' {
                Mock Get-VMNetworkAdapter -MockWith { $MockAdapter }

                It 'should return $false' {
                    $updateAdapter = $newAdapter.Clone()
                    $updateAdapter.Ensure = 'Absent'
                    Test-TargetResource @updateAdapter | Should Be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                }
            }

            Context 'Adapter exists and no action needed without Vlan tag' {
                Mock Get-VMNetworkAdapter -MockWith { $MockAdapter }

                It 'should return true' {
                    $updateAdapter = $newAdapter.Clone()
                    Test-TargetResource @updateAdapter | Should Be $true
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                }
            }

            Context 'Adapter exists and no action needed with Vlan tag' {
                Mock Get-VMNetworkAdapter -MockWith { $MockAdapter }
                Mock Get-VMNetworkAdapterVlan -MockWith { $MockAdapterVlanTagged }
                Mock -CommandName Get-NetworkInformation

                It 'should return true' {
                    $updateAdapter = $newAdapter.Clone()
                    $updateAdapter.VMName     = "VMName"
                    $updateAdapter.MacAddress = '14FEB5C6CE98'
                    $updateAdapter.VlanId     = '1'
                    Test-TargetResource @updateAdapter | Should Be $true
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -commandName Get-VMNetworkAdapterVlan -Exactly 1
                }
            }

            Context 'Adapter exists but Vlan is not tagged' {
                Mock Get-VMNetworkAdapter -MockWith { $MockAdapter }
                Mock Get-VMNetworkAdapterVlan
                Mock -CommandName Get-NetworkInformation

                It 'should return false' {
                    $updateAdapter = $newAdapter.Clone()
                    $updateAdapter.VMName     = "VMName"
                    $updateAdapter.MacAddress = '14FEB5C6CE98'
                    $updateAdapter.VlanId = '1'
                    Test-TargetResource @updateAdapter | Should Be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -commandName Get-VMNetworkAdapterVlan -Exactly 1
                }
            }

            Context 'Adapter exists but Vlan tag is wrong' {
                Mock Get-VMNetworkAdapter -MockWith { $MockAdapter }
                Mock Get-VMNetworkAdapterVlan -MockWith { $MockAdapterVlanTagged }
                Mock -CommandName Get-NetworkInformation

                It 'should return false' {
                    $updateAdapter = $newAdapter.Clone()
                    $updateAdapter.VMName     = "VMName"
                    $updateAdapter.MacAddress = '14FEB5C6CE98'
                    $updateAdapter.VlanId = '2'
                    Test-TargetResource @updateAdapter | Should Be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -commandName Get-VMNetworkAdapterVlan -Exactly 1
                }
            }

            Context 'Adapter does not exist and no action needed' {
                Mock Get-VMNetworkAdapter

                It 'should return true' {
                    $updateAdapter = $newAdapter.Clone()
                    $updateAdapter.Ensure = 'Absent'
                    Test-TargetResource @updateAdapter | Should Be $true
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                }
            }

            Context 'Adapter exists but network settings are not correct' {
                Mock Get-VMNetworkAdapter -MockWith { $MockAdapter }
                Mock Get-VMNetworkAdapterVlan -MockWith { $MockAdapterVlanTagged }
                Mock -CommandName Get-NetworkInformation -MockWith {
                    @{ Dhcp = $false }
                }

                It 'should return false' {
                    $updateAdapter = $newAdapter.Clone()
                    $updateAdapter.VMName     = "VMName"
                    $updateAdapter.MacAddress = '14FEB5C6CE98'
                    Test-TargetResource @updateAdapter | Should Be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled -commandName Get-NetworkInformation -Exactly 1
                }
            }
        }

    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
