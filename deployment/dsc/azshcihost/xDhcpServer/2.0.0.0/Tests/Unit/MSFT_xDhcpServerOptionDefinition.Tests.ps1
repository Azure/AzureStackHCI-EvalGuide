$Global:DSCModuleName      = 'xDhcpServer'
$Global:DSCResourceName    = 'MSFT_xDhcpServerOptionDefinition'

#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force


$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xDhcpServer' `
    -DSCResourceName 'MSFT_xDhcpServerOptionDefinition' `
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
    
    InModuleScope 'MSFT_xDhcpServerOptionDefinition' {

        $optionId = 22
        $name =  'Test name'
        $addressFamily = 'IPv4'
        $description = 'Test Description'
        $type = 'IPv4Address'
        $vendorClass = ''
        $multiValued = $false
        
        $testParams = @{
            OptionId      = $optionId
            Name          = $name
            AddressFamily = $addressFamily
            Description   = $description
            Type          = $type
            VendorClass   = $vendorClass
            MultiValued   = $multiValued
        }
                
        $fakeDhcpServerv4OptionDefinition = [PSCustomObject] @{
            OptionId      = $optionId
            Name          = $name
            AddressFamily = $addressFamily
            Description   = $description
            Type          = $type
            VendorClass   = $vendorClass
            MultiValued   = $multiValued
        }

        Describe "xDhcpServer\Get-TargetResource" {

            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }
            Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition }
            Mock Set-DhcpServerv4OptionDefinition { }
            Mock Add-DhcpServerv4OptionDefinition { }
            Mock Remove-DhcpServerv4OptionDefinition { }

            It 'Should call "Assert-Module" to ensure "DHCPServer" module is available' {
     
                $result = Get-TargetResource -OptionId $OptionId -Name $Name -Type $Type -VendorClass $VendorClass -AddressFamily IPv4 -Ensure Present;
                Assert-MockCalled -CommandName Assert-Module -Scope It
            }
        
            It 'Returns a "System.Collections.Hashtable" object type' {

                    $result = Get-TargetResource -OptionId $OptionId -Name $Name -Type $Type -VendorClass $VendorClass -AddressFamily IPv4 -Ensure Present;
                    $result -is [System.Collections.Hashtable] | Should Be $true;
            }
        }

        Describe "xDhcpServer\Test-TargetResource" {

            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }
            Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition }
            Mock Set-DhcpServerv4OptionDefinition { }
            Mock Add-DhcpServerv4OptionDefinition { }
            Mock Remove-DhcpServerv4OptionDefinition { }

            It 'Returns a "System.Boolean" object type' {
                Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition; }

                $result = Test-TargetResource @testParams -Ensure Present;
                $result  | Should BeOfType [System.Boolean]
            }

            It 'Passes when all parameters are correct' {
                Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition; }
                
                $result = Test-TargetResource @testParams -Ensure Present;
                $result | Should Be $true;
            }
        }

        Describe "xDhcpServer\Set-TargetResource" {

            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }
            Mock Set-DhcpServerv4OptionDefinition { }
            Mock Add-DhcpServerv4OptionDefinition { }
            Mock Remove-DhcpServerv4OptionDefinition { }

            It 'Should call "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and definition does not exist' {
                
                Mock Get-DhcpServerv4OptionDefinition { return $null }

                $TempParams = $testParams.Clone() 
                $TempParams.OptionId = 2
                Set-TargetResource @TempParams -Ensure 'Present'
          
                Assert-MockCalled Add-DhcpServerv4OptionDefinition -Scope It
            }

            It 'Should call "Remove-DhcpServerv4OptionDefinition" when "Ensure" = "Absent" and Definition does exist' {

                Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition }

                Set-TargetResource @testParams -Ensure 'Absent'
                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Scope It
            }

            It 'Should call Set-DhcpServerv4OptionDefinition when "Ensure" = "Present" and Name or Description has changed' {
               
                Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition }

                $TempParams = $testParams.Clone() 
                $TempParams.Description = 'New Description'
                Set-TargetResource @TempParams -Ensure 'Present'
                
                Assert-MockCalled -CommandName Set-DhcpServerv4OptionDefinition -Scope It
            }

            It 'Should call "Remove-DhcpServerv4OptionDefinition" and then "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and Type, MultiValued, VendorClass has changed' {

                Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition }

                $TempParams = $testParams.Clone()
                $TempParams.Type = 'Byte'
                Set-TargetResource @TempParams -Ensure 'Present'

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Scope It
                Assert-MockCalled -CommandName Add-DhcpServerv4OptionDefinition -Scope It
            }
            

            It 'Should call "Remove-DhcpServerv4OptionDefinition" and then "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and Type has changed' {
                
                Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition }
                
                $TempParams = $testParams.Clone()
                $TempParams.Type = 'Byte'
                Set-TargetResource @tempParams -Ensure 'Present'
            
                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Scope It
                Assert-MockCalled -CommandName Add-DhcpServerv4OptionDefinition -Scope It
            }


            It 'Should call "Remove-DhcpServerv4OptionDefinition" and then "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and MultiValued has changed' {
                
                Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition }

                $TempParams = $testParams.Clone()
                $TempParams.MultiValued = $true
                Set-TargetResource @TempParams -Ensure 'Present'

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Scope It -Times 1 -Exactly
                Assert-MockCalled -CommandName Add-DhcpServerv4OptionDefinition -Scope It -Times 1 -Exactly
            }

            It 'Should call "Remove-DhcpServerv4OptionDefinition" and then "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and VendorClass has changed' {
                
                Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition }                
                
                $TempParams = $testParams.Clone()
                $TempParams.VendorClass = 'NewVendorClass'
                Set-TargetResource @TempParams -Ensure 'Present'

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Scope It -Times 1 -Exactly
                Assert-MockCalled -CommandName Add-DhcpServerv4OptionDefinition -Scope It -Times 1 -Exactly
            }

            
            It 'Should call "Remove-DhcpServerv4OptionDefinition" and then "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and VendorClass and Description has changed' {
                
                Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition }

                $TempParams = $testParams.Clone()
                $TempParams.VendorClass = 'NewVendorClass'
                $TempParams.Description = 'New Description'
                Set-TargetResource @TempParams -Ensure 'Present'

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Scope It -Times 1 -Exactly
                Assert-MockCalled -CommandName Add-DhcpServerv4OptionDefinition -Scope It -Times 1 -Exactly
            }

            It 'Should call "Set-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and Description has changed' {

                Mock Get-DhcpServerv4OptionDefinition { return $fakeDhcpServerv4OptionDefinition }

                $TempParams = $testParams.Clone()
                $TempParams.Description = 'New Description'
                Set-TargetResource @testParams -Ensure 'Present'
                
                Assert-MockCalled -CommandName Set-DhcpServerv4OptionDefinition -Scope It
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
