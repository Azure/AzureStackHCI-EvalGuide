$Global:DSCModuleName      = 'xDhcpServer'
$Global:DSCResourceName    = 'MSFT_xDhcpServerScope'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        # TODO: Optional Load Mock for use in Pester tests here...
        #endregion

        $testScopeName = 'Test Scope'
        $testScopeID = '192.168.1.0'
        $testIPStartRange = '192.168.1.10'
        $testIPEndRange = '192.168.1.99'
        $testSubnetMask = '255.255.255.0'
        $testState = 'Active'
        $testLeaseDuration = New-TimeSpan -Days 8
        $testDescription = 'Scope description'
        $testAddressFamily = 'IPv4'
        
        $testParams = @{
            ScopeId = $testScopeID
            Name = $testScopeName
            IPStartRange = $testIPStartRange
            IPEndRange = $testIPEndRange
            SubnetMask = $testSubnetMask
        }
                
        $fakeDhcpServerv4Scope = [PSCustomObject] @{
            ScopeID = $testScopeID
            Name = $testScopeName
            StartRange = $testIPStartRange
            EndRange = $testIPEndRange
            Description = $testDescription
            SubnetMask = $testSubnetMask
            LeaseDuration = $testLeaseDuration
            State = $testState
            AddressFamily = $testAddressFamily
        }

        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }
            Mock Assert-ScopeParameter -ParameterFilter {
                $ScopeId -eq $testScopeID -and
                $SubnetMask -eq $testSubnetMask -and
                $IPStartRange -eq $testIPStartRange -and
                $IPEndRange -eq $testIPEndRange -and
                $AddressFamily -eq $testAddressFamily
            }

            It 'Should call "Assert-Module" to ensure "DHCPServer" module is available' {
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                
                $result = Get-TargetResource @testParams
                
                Assert-MockCalled Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } -Scope It
            }

            It 'Should call "Assert-ScopeParameter" to ensure parameters passed are correct' {
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                $result = Get-TargetResource @testParams
                Assert-MockCalled Assert-Module -Scope It
            }

            It 'Should return a "System.Collections.Hashtable" object type' {
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                Get-TargetResource @testParams | Should -BeOfType System.Collections.Hashtable
            }

            It 'Should return all information about existing scope with specified ScopeId' {
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                $result = Get-TargetResource @testParams
                $result.Name          | Should -Be $testScopeName
                $result.IPStartRange  | Should -Be $testIPStartRange
                $result.IPEndRange    | Should -Be $testIPEndRange
                $result.SubnetMask    | Should -Be $testSubnetMask
                $result.Description   | Should -Be $testDescription
                $result.LeaseDuration | Should -Be $testLeaseDuration
                $result.State         | Should -Be $testState
                $result.AddressFamily | Should -Be $testAddressFamily
                $result.Ensure        | Should -Be Present
            }

            It 'Should return basic information about missing scope with specified ScopeId' {
                Mock Get-DhcpServerv4Scope {}
                $result = Get-TargetResource @testParams
                $result.Name          | Should -BeNullOrEmpty
                $result.IPStartRange  | Should -BeNullOrEmpty
                $result.IPEndRange    | Should -BeNullOrEmpty
                $result.SubnetMask    | Should -BeNullOrEmpty
                $result.Description   | Should -BeNullOrEmpty
                $result.LeaseDuration | Should -BeNullOrEmpty
                $result.State         | Should -BeNullOrEmpty
                $result.AddressFamily | Should -Be $testAddressFamily
                $result.Ensure        | Should -Be Absent
            }
        }
        #endregion Function Get-TargetResource

        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            
            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }

            It 'Should return a "System.Boolean" object type' {
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                Test-TargetResource @testParams | Should -BeOfType System.Boolean
            }
            
            It 'Should pass when all parameters are correct' {
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                Test-TargetResource @testParams | Should -BeTrue
            }

            It 'Should pass when optional <Parameter> parameter is correct' {
                param (
                    $Parameter,
                    $Value
                )
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                $optionalParameters = @{
                    $Parameter = $Value
                }
                Test-TargetResource @testParams @optionalParameters | Should -BeTrue
            } -TestCases @(
                @{
                    Parameter = 'Description'
                    Value = $testDescription
                }
                @{
                    Parameter = 'LeaseDuration'
                    Value = $testLeaseDuration.ToString()
                }
                @{
                    Parameter = 'State'
                    Value = $testState
                }
            )
            
            It 'Should pass when "Ensure" = "Absent" and scope does not exist' {
                Mock Get-DhcpServerv4Scope { }
                Test-TargetResource @testParams -Ensure 'Absent' | Should -BeTrue
            }
            
            It 'Should fail when <parameter> parameter is incorrect' {
                param (
                    $Parameter,
                    $Value
                )
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                $testNameParams = $testParams.Clone()
                $testNameParams[$Parameter] = $Value
                Test-TargetResource @testNameParams | Should -BeFalse
            } -TestCases @(
                @{
                    Parameter = 'Name'
                    Value = 'IncorrectName'
                }
                @{
                    Parameter = 'IPStartRange'
                    Value = '192.168.1.1'
                }
                @{
                    Parameter = 'IPEndRange'
                    Value = '192.168.1.254'
                }
                @{
                    Parameter = 'SubnetMask'
                    Value = '255.255.255.128'
                }
                @{
                    Parameter = 'Description'
                    Value = 'Wrong description'
                }
                @{
                    Parameter = 'LeaseDuration'
                    Value = '08:00:00'
                }
                @{
                    Parameter = 'State'
                    Value = 'Inactive'
                }
                @{
                    Parameter = 'Ensure'
                    Value = 'Absent'
                }
            )
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            
            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }
            
            It 'Should call "Add-DhcpServerv4Scope" when "Ensure" = "Present" and scope does not exist' {
                Mock Get-DhcpServerv4Scope { }
                Mock Add-DhcpServerv4Scope { }
                
                Set-TargetResource @testParams
                
                Assert-MockCalled Add-DhcpServerv4Scope -Scope It -Times 1 -Exactly -ParameterFilter {
                    $StartRange -eq $testIPStartRange -and
                    $EndRange   -eq $testIPEndRange   -and
                    $SubnetMask -eq $testSubnetMask   -and
                    $Name       -eq $testScopeName
                }
            }
            
            It 'Should call "Remove-DhcpServerv4Scope" when "Ensure" = "Absent" and scope does exist' {
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                Mock Remove-DhcpServerv4Scope { }
                
                Set-TargetResource @testParams -Ensure 'Absent'
                
                Assert-MockCalled Remove-DhcpServerv4Scope -Scope It -Times 1 -Exactly -ParameterFilter { $ScopeId -eq $testScopeID }
            }
            
            It 'Should call "Set-DhcpServerv4Scope" when "Ensure" = "Present" and scope does exist' {
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                Mock Set-DhcpServerv4Scope { }
                
                Set-TargetResource @testParams -LeaseDuration '08:00:00'
                
                Assert-MockCalled Set-DhcpServerv4Scope -Scope It -Times 1 -Exactly -ParameterFilter {
                    $ScopeId       -eq $testScopeID -and
                    $LeaseDuration -eq (New-TimeSpan -Hours 8)
                }
            }
            
            It 'Should call "Remove-DhcpServerv4Scope" when "Ensure" = "Present", scope does exist but "SubnetMask" is incorrect' {
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope }
                Mock Remove-DhcpServerv4Scope { }
                Mock Set-DhcpServerv4Scope { }
                $testSubnetMaskParams = $testParams.Clone()
                $testSubnetMaskParams['SubnetMask'] = '255.255.255.128'
                
                Set-TargetResource @testSubnetMaskParams
                
                Assert-MockCalled Remove-DhcpServerv4Scope -Scope It -Times 1 -Exactly -ParameterFilter { $ScopeId -eq $testScopeID }
                Assert-MockCalled Add-DhcpServerv4Scope -Scope It -Times 1 -Exactly -ParameterFilter {
                    $StartRange -eq $testIPStartRange -and
                    $EndRange   -eq $testIPEndRange   -and
                    $SubnetMask -eq '255.255.255.128' -and
                    $Name       -eq $testScopeName
                }

            }
            
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Validate-ResourceProperties" {
            # TODO: Complete Tests...
        }
        #endregion

    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
