#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xHyper-V' `
    -DSCResourceName 'MSFT_xVHD' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{

}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_xVHD' {
        Describe 'MSFT_xVHD\Get-TargetResource' {
            # Create an empty function to be able to mock the missing Hyper-V cmdlet
            function Get-VHD
            {

            }

            Context 'Should stop when Hyper-V module is missing' {
                Mock -CommandName Get-Module -ParameterFilter { ($Name -eq 'Hyper-V') -and ($ListAvailable -eq $true) } -MockWith {
                    return $false
                }

                It 'Should throw when the module is missing' {
                    { Test-TargetResource -Name 'server.vhdx' -Path 'C:\VMs' -Type 'Fixed' -MaximumSizeBytes 1GB } |
                        Should Throw 'Please ensure that Hyper-V role is installed with its PowerShell module'
                }
            }

            # Mocks "Get-Module -Name Hyper-V" so that the DSC resource thinks the Hyper-V module is on the test system
            Mock -CommandName Get-Module -ParameterFilter { ($Name -eq 'Hyper-V') -and ($ListAvailable -eq $true) } -MockWith {
                return $true
            }

            Mock -CommandName GetNameWithExtension -MockWith { 'server.vhdx' }

            Context 'VHD Present' {
                It 'Should return a hashtable with Ensure being Present' {
                    Mock -CommandName Get-VHD -MockWith {
                        [pscustomobject]@{
                            Path = 'server.vhdx'
                        }
                    }

                    $getTargetResult = Get-TargetResource -Name 'server' -Path 'c:\boguspath' -Generation 'vhdx'
                    $getTargetResult.Ensure | Should Be 'Present'
                    $getTargetResult | Should BeOfType hashtable
                }
            }

            Context 'VHD Not Present' {
                It 'Should return a hashtable with Ensure being Absent' {
                    Mock -CommandName Get-VHD

                    $getTargetResult = Get-TargetResource -Name 'server' -Path 'c:\boguspath' -Generation 'vhdx'
                    $getTargetResult.Ensure | Should Be 'Absent'
                    $getTargetResult | Should BeOfType hashtable
                }
            }
        }

        Describe 'MSFT_xVHD\GetNameWithExtension' {
            Context 'Name does not have extension' {
                It 'Should return server.vhdx with generation vhdx' {
                    GetNameWithExtension -Name 'server' -Generation 'vhdx' |
                        Should Be 'server.vhdx'
                }

                It 'Should return server.vhd with generation vhd' {
                    GetNameWithExtension -Name 'server' -Generation 'vhd' |
                        Should Be 'server.vhd'
                }

                It 'Should not throw' {
                    { GetNameWithExtension -Name 'server' -Generation 'vhd' } |
                        Should Not Throw
                }
            }

            Context 'Name has extension' {
                It 'Should return server.vhdx with Name server.vhdx and generation vhdx' {
                    GetNameWithExtension -Name 'server.vhd' -Generation 'vhd' |
                        Should Be 'server.vhd'
                }

                It 'Should throw with mismatch with extension from name and generation' {
                    { GetNameWithExtension -Name 'server.vhdx' -Generation 'vhd' } |
                        Should Throw 'the extension vhdx on the name does not match the generation vhd'
                }
            }
        }

        Describe 'MSFT_xVHD\Test-TargetResource' {
            # Create an empty function to be able to mock the missing Hyper-V cmdlet
            function Test-VHD
            {

            }

            Context 'Should stop when Hyper-V module is missing' {
                Mock -CommandName Get-Module -ParameterFilter { ($Name -eq 'Hyper-V') -and ($ListAvailable -eq $true) } -MockWith {
                    return $false
                }

                It 'Should throw when the module is missing' {
                    { Test-TargetResource -Name 'server.vhdx' -Path 'C:\VMs' -Type 'Fixed' -MaximumSizeBytes 1GB } |
                        Should Throw 'Please ensure that Hyper-V role is installed with its PowerShell module'
                }
            }

            # Mocks "Get-Module -Name Hyper-V" so that the DSC resource thinks the Hyper-V module is on the test system
            Mock -CommandName Get-Module -ParameterFilter { ($Name -eq 'Hyper-V') -and ($ListAvailable -eq $true) } -MockWith {
                return $true
            }

            Context 'Parameter validation' {
                It 'Fixed and Dynamic VHDs need MaximumSizeBytes specified' {
                    { Test-TargetResource -Name 'server' -Path 'C:\VMs' -Type 'Dynamic' } |
                        Should Throw 'Specify MaximumSizeBytes property for Fixed and Dynamic VHDs.'
                }

                It 'Parent Path is passed for a non Differencing disk' {
                    { Test-TargetResource -Name 'server' -Path 'C:\VMs' -ParentPath 'C:\VMs\Parent' -Type 'Fixed' -MaximumSizeBytes 1GB } |
                        Should Throw 'Parent path is only supported for Differencing disks'
                }

                It 'Differencing disk needs a Parent Path' {
                    { Test-TargetResource -Name 'server' -Path 'C:\VMs' -Type 'Differencing' } |
                        Should Throw 'Differencing requires a parent path'
                }
            }

            Context 'ParentPath specified' {
                It 'Should throw when ParentPath does not exist' {
                    Mock -CommandName Test-Path -MockWith { $false }

                    { Test-TargetResource -Name 'server' -Path 'C:\VMs' -Type 'Differencing' -ParentPath 'c:\boguspath' } |
                        Should Throw 'c:\boguspath does not exists'
                }

                # "Generation $Generation should match ParentPath extension $($ParentPath.Split('.')[-1])"
                It 'Should throw when file extension and generation have a mismatch' {
                    Mock -CommandName Test-Path -MockWith { $true }

                    { Test-TargetResource -Name 'server' -Path 'C:\VMs' -Type 'Differencing' -ParentPath 'c:\boguspath.vhd' -Generation 'Vhdx' } |
                        Should Throw 'Generation Vhdx should match ParentPath extension vhd'
                }
            }

            Context 'Path does not exist' {
                It 'Should throw when the path does not exist' {
                    Mock -CommandName Test-Path -MockWith { $false }

                    { Test-TargetResource -Name 'server.vhdx' -Path 'C:\VMs' -Type 'Fixed' -MaximumSizeBytes 1GB } |
                        Should Throw 'C:\VMs does not exists'
                }
            }

            Context 'Vhd exists' {
                BeforeEach {
                    Mock -CommandName Test-Path -MockWith { $true }
                    Mock -CommandName GetNameWithExtension -MockWith { 'server.vhdx' }
                    Mock -CommandName Test-VHD -MockWith { $true }
                }

                It 'Should not throw' {
                    { Test-TargetResource -Name 'server.vhdx' -Path 'C:\VMs' -Type 'Fixed' -MaximumSizeBytes 1GB } |
                        Should not Throw
                }

                It 'Should return a boolean and it should be true' {
                    $testResult = Test-TargetResource -Name 'server.vhdx' -Path 'C:\VMs' -Type 'Fixed' -MaximumSizeBytes 1GB
                    $testResult | Should BeOfType bool
                    $testResult -eq $true | Should Be $true
                }
            }

            Context 'Vhd does not exist' {
                BeforeEach {
                    Mock -CommandName Test-Path -MockWith { $true }
                    Mock -CommandName GetNameWithExtension -MockWith { 'server.vhdx' }
                    Mock -CommandName Test-VHD -MockWith { $false }
                }

                It 'Should not throw' {
                    { Test-TargetResource -Name 'server.vhdx' -Path 'C:\VMs' -Type 'Fixed' -MaximumSizeBytes 1GB } |
                        Should not Throw
                }

                It 'Should return a boolean and it should be false' {
                    $testResult = Test-TargetResource -Name 'server.vhdx' -Path 'C:\VMs' -Type 'Fixed' -MaximumSizeBytes 1GB
                    $testResult | Should BeOfType bool
                    $testResult -eq $true | Should Be $false
                }
            }
        }

        Describe 'MSFT_xVHD\Set-TargetResource' {
            # Create an empty function to be able to mock the missing Hyper-V cmdlet
            function Get-VHD
            {

            }

            function Set-VHD
            {

            }

            function Resize-VHD
            {

            }

            function New-VHD
            {

            }

            Context 'Ensure is Absent' {
                Mock -CommandName Test-Path -MockWith { $true }
                Mock -CommandName Remove-Item
                Mock -CommandName GetNameWithExtension -MockWith { 'server.vhdx' }

                It 'Should remove when Ensure is Absent and vhdx exists' {
                    $null = Set-TargetResource -Name 'server.vhdx' -Path 'TestDrive:\' -Ensure 'Absent'
                    Assert-MockCalled -CommandName Remove-Item -Times 1 -Exactly
                }
            }

            Context 'Ensure is Present' {
                BeforeEach {
                    Mock -CommandName Get-VHD -MockWith {
                        [pscustomobject]@{
                            Path = 'server.vhdx'
                            ParentPath = 'c:\boguspath\server.vhdx'
                            Size = 1073741824
                            Type = 'Differencing'
                        }
                    }

                    Mock -CommandName Set-VHD
                    Mock -CommandName Resize-VHD
                    Mock -CommandName GetNameWithExtension -MockWith { 'server.vhdx' }
                    Mock -CommandName New-VHD -MockWith { }
                }

                It 'Should Create a VHD when Ensure is present and no VHD exists yet for non Differencing disk' {
                    Mock -CommandName Get-VHD -MockWith { throw }

                    $null = Set-TargetResource -Name 'server.vhdx' -Path 'TestDrive:\' -Ensure 'Present'
                    Assert-MockCalled -CommandName New-VHD -Exactly -Times 1 -Scope It
                }

                It 'Should Create a VHD when Ensure is present and no VHD exists yet for Differencing disk' {
                    Mock -CommandName Get-VHD -MockWith { throw }

                    $null = Set-TargetResource -Name 'server.vhdx' -Path 'TestDrive:\' -Ensure 'Present' -ParentPath 'c:\boguspath\server.vhdx' -Type 'Differencing'
                    Assert-MockCalled -CommandName New-VHD -Exactly -Times 1 -Scope It
                }

                It 'Should resize a VHD which has a different size as intended' {
                    $null = Set-TargetResource -Name 'server.vhdx' -Path 'TestDrive:\' -MaximumSizeBytes 2GB -Ensure 'Present'
                    Assert-MockCalled -CommandName Resize-VHD -Exactly -Times 1 -Scope It
                }

                It 'Should update the parentpath if it is different from intent' {
                    $null = Set-TargetResource -Name 'server.vhdx' -Path 'TestDrive:\' -ParentPath 'c:\boguspath2\server.vhdx' -Ensure 'Present'
                    Assert-MockCalled -CommandName Set-VHD -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
