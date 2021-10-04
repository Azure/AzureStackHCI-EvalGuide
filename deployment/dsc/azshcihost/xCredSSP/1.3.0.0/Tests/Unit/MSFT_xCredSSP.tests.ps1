<#
.Synopsis
   Unit tests for MSFT_xCredSSP
.DESCRIPTION
   Unit tests for MSFT_xCredSSP

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>


$Global:DSCModuleName      = 'xCredSSP' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xCredSSP' # Example MSFT_xFirewall

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
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

# TODO: Other Optional Init Code Goes Here...

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        # TODO: Optopnal Load Mock for use in Pester tests here...
        #endregion


        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            # TODO: Complete Tests...
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            # TODO: Complete Tests...
        }
        #endregion


        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            
            Context "Enable Server Role with invalid delegate Computer parameter" {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }
                
                mock Enable-WSManCredSSP -MockWith {} -Verifiable
                mock Disable-WSManCredSSP -MockWith {} 

                it 'should throw' {
                    { Set-TargetResource -Ensure 'Present' -Role Server -DelegateComputer 'foo' } | should throw 
                }
                it 'should have not called enable' {
                    Assert-MockCalled -CommandName Enable-WSManCredSSP -Times 0 -Scope 'Context'
                }
                it 'should have not called disable' {
                    Assert-MockCalled -CommandName Disable-WSManCredSSP -Times 0 -Scope 'Context'
                }
                it 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | should be $null
                }
            }
            
            Context "Enable Server Role when it has been configured using GPO" {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }
                
                mock Enable-WSManCredSSP -MockWith {} -Verifiable
                mock Disable-WSManCredSSP -MockWith {}
                mock Get-ItemProperty -MockWith {
                    return @{ AllowCredSSP = 1 }
                } -ParameterFilter { $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" }

                it 'should throw' {
                    { Set-TargetResource -Ensure 'Present' -Role Server }| should throw 
                }
                it 'should have not called enable' {
                    Assert-MockCalled -CommandName Enable-WSManCredSSP -Times 0 -Scope 'Context'
                }
                it 'should have not called disable' {
                    Assert-MockCalled -CommandName Disable-WSManCredSSP -Times 0 -Scope 'Context'
                }
                it 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | should be $null
                }
            } 

            Context "Enable Client Role when it has been configured using GPO" {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }
                
                mock Enable-WSManCredSSP -MockWith {} -Verifiable
                mock Disable-WSManCredSSP -MockWith {}
                mock Get-ItemProperty -MockWith {
                    return @{ AllowCredSSP = 1 }
                } -ParameterFilter { $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client" }

                it 'should throw' {
                    {Set-TargetResource -Ensure 'Present' -Role Client -DelegateComputers 'foo'}| should throw 
                }
                it 'should have not called enable' {
                    Assert-MockCalled -CommandName Enable-WSManCredSSP -Times 0 -Scope 'Context'
                }
                it 'should have not called disable' {
                    Assert-MockCalled -CommandName Disable-WSManCredSSP -Times 0 -Scope 'Context'
                }
                it 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | should be $null
                }
            } 

            Context "Enable Server Role" {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                mock Enable-WSManCredSSP -MockWith {} -Verifiable
                mock Disable-WSManCredSSP -MockWith {} 
                mock Get-ItemProperty -MockWith {
                    return @{ auth_credssp = 1 }
                }
                it 'should not return anything' {
                    Set-TargetResource -Ensure 'Present' -Role Server | should be $null 
                }
                it 'should have called enable'{
                    Assert-MockCalled -CommandName Enable-WSManCredSSP -Times 1 -ParameterFilter {$Role -eq 'Server' -and $Force -eq $true} 
                }
                it 'should have not called disable' {
                    Assert-MockCalled -CommandName Disable-WSManCredSSP -Times 0 
                }
                it 'Should have triggered a reboot'{
                    $global:DSCMachineStatus | should be 1
                }
            } 

            Context "Enable Client Role" {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock Get-WSManCredSSP -MockWith {@([string]::Empty,[string]::Empty)}
                mock Enable-WSManCredSSP -MockWith {} -Verifiable
                mock Disable-WSManCredSSP -MockWith {} 
                mock Get-ItemProperty -MockWith {
                    return @{
                        1 = "wsman/testserver.domain.com"
                        2 = "wsman/testserver2.domain.com"
                    }
                }
                mock Get-Item -MockWith {
                    $client1 = New-Object -typename PSObject| 
                                Add-Member NoteProperty "Name" 1 -PassThru |
                                Add-Member NoteProperty "Property" 1 -PassThru

                    $client2 = New-Object -typename PSObject| 
                                Add-Member NoteProperty "Name" 2 -PassThru |
                                Add-Member NoteProperty "Property" 2 -PassThru
                    
                    return @($client1, $client2)
                }

                it 'should not return anything' {
                    Set-TargetResource -Ensure 'Present' -Role Client -DelegateComputer 'foo' | should be $null 
                }
                it 'should have called enable'{
                    Assert-MockCalled -CommandName Enable-WSManCredSSP -Times 1 -ParameterFilter {$Role -eq 'Client' -and $Force -eq $true -and $DelegateComputer -eq 'foo'} 
                }
                it 'should have not called disable' {
                    Assert-MockCalled -CommandName Disable-WSManCredSSP -Times 0 
                }
                it 'Should have triggered a reboot'{
                    $global:DSCMachineStatus | should be 1
                }
            } 
            Context "Enable Client Role  with invalid delegate Computer parameter" {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock Get-WSManCredSSP -MockWith {@([string]::Empty,[string]::Empty)}
                mock Enable-WSManCredSSP -MockWith {} -Verifiable
                mock Disable-WSManCredSSP -MockWith {}
                mock Get-ItemProperty -MockWith {
                    return @{ auth_credssp = 1 }
                }
                mock Get-Item -MockWith {
                    return @(
                        @{
                            Name = 1
                            Property = "wsman/foo"
                        },
                        @{
                            Name = 1
                            Property = "wsman/testserver.domain.com"
                        }
                    )
                }
                
                it 'should throw' {
                    { Set-TargetResource -Ensure 'Present' -Role Client } | should throw 'DelegateComputers is required!' 
                }
                it 'should have not called get' {
                    Assert-MockCalled -CommandName Get-WSManCredSSP -Times 0 -Scope 'Context'
                }
                it 'should have called enable' {
                    Assert-MockCalled -CommandName Enable-WSManCredSSP -Times 0 -Scope 'Context'
                }
                it 'should have not called disable' {
                    Assert-MockCalled -CommandName Disable-WSManCredSSP -Times 0 -Scope 'Context'
                }
                it 'Should have triggered a reboot'{
                    $global:DSCMachineStatus | should be $null
                }
            }             
        }
        #endregion

        # TODO: Pester Tests for any Helper Cmdlets

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
