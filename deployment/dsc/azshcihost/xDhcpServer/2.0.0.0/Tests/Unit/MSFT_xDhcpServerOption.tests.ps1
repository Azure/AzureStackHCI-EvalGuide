$Global:DSCModuleName      = 'xDhcpServer' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xDhcpServerOption' # Example MSFT_xFirewall

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

# Begin Testing

try
{
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        # TODO: Optopnal Load Mock for use in Pester tests here...
        #endregion

        $testScopeID = '192.168.1.0';
        $testDnsServerIPAddress = '192.168.1.10';
        $testDnsDomain = 'contoso.com';
        $testRouter = '192.168.1.1';
        
        $testParams = @{
            ScopeID = $testScopeID;
            DnsServerIPAddress = $testDnsServerIPAddress;
        }
                
        $fakeDhcpServerv4Option = [PSCustomObject] @{
            ScopeID = $testScopeID;
            DnsDomain = $testDnsDomain;
            AddressFamily = 'IPv4';
            DnsServerIPAddress = $testDnsServerIPAddress;
            Router = $testRouter;
        }

        $fakeDhcpServerv4Scope = [PSCustomObject] @{
            ScopeID = $testScopeID;
        }

        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            It 'Returns all properties' {
                Mock Get-DhcpServerv4Scope { return $fakeDhcpServerv4Scope; }
                Mock Get-DhcpServerv4OptionValue { return $fakeDhcpServerv4Option }
                $result = Get-TargetResource @testParams;
                
                $missingCount = 
                (
                    $fakeDhcpServerv4Option.psobject.properties.ForEach{
                        $result.ContainsKey($_.Name)
                    } | Where-Object { -not $_ } | Measure-Object
                ).Count

                $missingCount | Should Be 0;
            }
        }
        #endregion Function Get-TargetResource

        #region Function ValidateResourceProperties
        Describe "$($Global:DSCResourceName)\ValidateResourceProperties" {
    
            $dnsDomainName = 'contoso.com'
            $dnsIpAddress = @('2.1.1.2','2.1.1.3')
            $routeripAddress = '1.1.1.2'
            Mock -CommandName Set-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith { }
            
            # Absent removes the whole option, so this is not new to this issue.
            # So not currently testing Absent and Apply = $true
            foreach($params in @(@{Ensure='Present';Apply=$false},@{Ensure='Absent';Apply=$false},@{Ensure='Present';Apply=$true}))
            {
                It "Return true when DNS Server scalar match, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=6;Value=$dnsIpAddress[1]})
                    } 

                    $expectedReturn = $true
                    if($params.Ensure -eq 'Absent')
                    {
                        $expectedReturn = $false
                    }            
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }    
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -DnsServerIPAddress $dnsIpAddress[1] -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue  -Scope It
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue -Exactly 0 -Scope It
                }
                
                It "Return true when DNS Server array match, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=6;Value=$dnsIpAddress})
                    } 

                    $expectedReturn = $true
                    if($params.Ensure -eq 'Absent')
                    {
                        $expectedReturn = $false
                    }            
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }      
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -DnsServerIPAddress $dnsIpAddress -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue -Exactly 0 -Scope It
                }
                
                It "Return false when DNS Server mismatch, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=6;Value=$dnsIpAddress})
                    } 

                    $expectedReturn = $false
                    $setMockCalledParams = @{}
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }          
                    else
                    {
                        $setMockCalledParams.Add('Exactly',$true)
                        $setMockCalledParams.Add('Times',0)
                    }  
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -DnsServerIPAddress '1.2.2.1' -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It           
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue @setMockCalledParams -Scope It
                }
                
                It "Return false when DNS Server empty, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=15;Value=$dnsDomainName})
                    } 

                    $expectedReturn = $false
                    $setMockCalledParams = @{}
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }          
                    else
                    {
                        $setMockCalledParams.Add('Exactly',$true)
                        $setMockCalledParams.Add('Times',0)
                    }  
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -DnsServerIPAddress '1.2.2.1' -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It           
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue @setMockCalledParams -Scope It
                }
                
                It "Return true when DNS domain name match, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=15;Value=$dnsDomainName})
                    } 

                    $expectedReturn = $true
                    if($params.Ensure -eq 'Absent')
                    {
                        $expectedReturn = $false
                    }            
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }          
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -DnsDomain $dnsDomainName -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue -Exactly 0 -Scope It
                }
                
                It "Return false when DNS domain name mismatch, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=15;Value=$dnsDomainName})
                    } 

                    $expectedReturn = $false
                    $setMockCalledParams = @{}
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }          
                    else
                    {
                        $setMockCalledParams.Add('Exactly',$true)
                        $setMockCalledParams.Add('Times',0)
                    }  
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -DnsDomain 'wrong.com' -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It           
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue @setMockCalledParams -Scope It
                }
                
                It "Return true when Router scalar match, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=3;Value=$routeripAddress})
                    } 

                    $expectedReturn = $true
                    if($params.Ensure -eq 'Absent')
                    {
                        $expectedReturn = $false
                    }            
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }          
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -Router $routeripAddress -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue -Exactly 0 -Scope It
                }

                It "Return true when Router array match, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=3;Value=$routeripAddress})
                    } 

                    $expectedReturn = $true
                    if($params.Ensure -eq 'Absent')
                    {
                        $expectedReturn = $false
                    }            
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }          
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -Router $routeripAddress -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It        
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue -Exactly 0 -Scope It
                }

                It "Return false when Router scalar mismatch, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=3;Value=$routeripAddress})
                    } 

                    $expectedReturn = $false
                    $setMockCalledParams = @{}
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }          
                    else
                    {
                        $setMockCalledParams.Add('Exactly',$true)
                        $setMockCalledParams.Add('Times',0)
                    }  
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -Router '1.1.1.3' -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It           
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue @setMockCalledParams -Scope It
                }

                It "Return false when Router array mismatch, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=3;Value=$routeripAddress})
                    } 

                    $expectedReturn = $false
                    $setMockCalledParams = @{}
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }          
                    else
                    {
                        $setMockCalledParams.Add('Exactly',$true)
                        $setMockCalledParams.Add('Times',0)
                    }  
                    
                    
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -Router @('1.1.1.2','1.1.1.4') -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It         
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue @setMockCalledParams -Scope It
                }
                
                It "Return false when Router array extra element, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=3;Value=$routeripAddress})
                    } 

                    $expectedReturn = $false
                    $setMockCalledParams = @{}
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }          
                    else
                    {
                        $setMockCalledParams.Add('Exactly',$true)
                        $setMockCalledParams.Add('Times',0)
                    }  
                    
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0'-Router @('1.1.1.2','1.1.1.3', '1.1.1.4') -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It             
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue @setMockCalledParams -Scope It
                }
                
                It "Return false when Router array missing element, apply: $($params.Apply), Ensure: $($params.Ensure)" {
                    Mock -CommandName Get-DhcpServerv4OptionValue -ModuleName MSFT_xDhcpServerOption -MockWith {
                        return @(new-object psobject -property @{OptionId=3;Value=$routeripAddress})
                    } 

                    $expectedReturn = $false
                    $setMockCalledParams = @{}
                    if($params.Apply)
                    {
                        $expectedReturn = $null
                    }          
                    else
                    {
                        $setMockCalledParams.Add('Exactly',$true)
                        $setMockCalledParams.Add('Times',0)
                    }  
                    $result = ValidateResourceProperties @params -scopeId '1.1.1.0' -Router @('1.1.1.2','1.1.1.3') -Verbose
                    
                    $result | should be $expectedReturn
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName Get-DhcpServerv4OptionValue -Scope It
                    Assert-MockCalled -ModuleName MSFT_xDhcpServerOption -commandName set-DhcpServerv4OptionValue @setMockCalledParams -Scope It
                }
            }
            #endregion

        } #endregion InModuleScope
        
    }
    #endregion

}
finally
{
     #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
