configuration Sample_xDhcpsServerScope_NewScope 
 { 
     Import-DscResource -module xDHCpServer 
     WindowsFeature DHCP
     {
        Name = 'DHCP'
        Ensure = 'Present'
     }
     xDhcpServerScope Scope 
     { 
         Ensure = 'Present'
         IPStartRange = '192.168.1.1' 
         IPEndRange = '192.168.1.254' 

         Name = 'ContosoScope' 
         SubnetMask = '255.255.255.0' 
         LeaseDuration = '00:08:00' 
         State = 'Active' 
         AddressFamily = 'IPv4'
         DependsOn = @('[WindowsFeature]DHCP') 
     } 
     xDhcpServerReservation PullServerIP 
     { 
         Ensure = 'Present' 
         ScopeID = '192.168.1.0' 
         ClientMACAddress = '00155D8A54A1' 
         IPAddress = '192.168.1.2' 
         Name = 'DSCPullServer' 
         AddressFamily = 'IPv4' 
         DependsOn = @('[WindowsFeature]DHCP') 
     }  
     xDhcpServerOption Option 
     { 
         Ensure = 'Present' 
         ScopeID = '192.168.1.0' 
         DnsDomain = 'contoso.com' 
         DnsServerIPAddress = '192.168.1.22','192.168.1.1' 
         AddressFamily = 'IPv4' 
         Router = '192.168.1.1'
         DependsOn = @('[WindowsFeature]DHCP') 
     } 

     xDhcpServerclass DHCPServerClass
     {
        ensure = 'Present'
        Name = 'VendorClass'
        Type = 'Vendor'
        AsciiData = 'sampledata'
        AddressFamily = 'IPv4'
        Description = 'Vendor Class Description' 
     }
 
    xDhcpServerOptionDefinition DHCPServerOptionDefinition
    {
        Ensure = 'Present'
        Name = 'Cisco AP c1700 Provisioning'
        OptionID = '200'
        Type = 'IPv4Address'
        AddressFamily = 'IPv4'
        VendorClass = 'Cisco AP c1700'
        Description = 'Sample description'
    }

    xDhcpServerOptionDefinition DHCPServerOptionDefinition
    {
        Ensure = 'Present'
        Name = 'sample name'
        OptionID = '200'
        Type = 'IPv4Address'
        AddressFamily = 'IPv4'
        VendorClass = ''  #default option class
        Description = 'Sample description'
    }
 } 
