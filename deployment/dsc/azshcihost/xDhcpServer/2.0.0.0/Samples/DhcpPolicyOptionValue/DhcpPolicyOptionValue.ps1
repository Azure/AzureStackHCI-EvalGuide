<#
    .SYNOPSiS
       This example sets an option ID 8 (cookie servers) on a policy at server level and at scope level.
#>
configuration Example
{
    Import-DscResource -ModuleName PSDscResources
    Import-DscResource -moduleName xDhcpServer
    WindowsFeature DHCP
    {
       Name = 'DHCP'
       Ensure = 'Present'
    }

    DhcpPolicyOptionValue policyOptionValue_ID-008
    {
        OptionId      = 8
        Value         = '1.1.1.1'
        ScopeId       = ''
        VendorClass   = ''
        AddressFamily = 'IPv4'
        PolicyName    = 'TestPolicy'
        Ensure        = 'Present'
    }

    DhcpPolicyOptionValue policyOptionValue_ID-008-scope
    {
        OptionId      = 8
        Value         = '1.1.1.1'
        ScopeId       = '192.168.0.0'
        VendorClass   = ''
        AddressFamily = 'IPv4'
        PolicyName    = 'TestPolicy'
        Ensure        = 'Present'
    }
}
