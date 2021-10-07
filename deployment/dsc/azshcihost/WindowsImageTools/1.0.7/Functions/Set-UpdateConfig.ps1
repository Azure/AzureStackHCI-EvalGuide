function Set-UpdateConfig
{
    <#
            .Synopsis
            Set the Windows Image Tools Update Config used for creating the temp VM
            .DESCRIPTION
            Set the config used by Invoke-WitUpdate to build a VM and update Windows Images
            .EXAMPLE
            Set-WitUpdateConfig -Path C:\WitUpdate -VmSwitch 'VM' -IpType DCHP
            Set the temp VM to attach to siwth "VM" and use DCHP for IP addresses 
            .EXAMPLE
            Set-WitUPdateConfig -Path C:\WitUpdate -VmSwitch CorpIntAccess -vLAN 1752 -IpType 'IPv4' -IPAddress '172.17.52.100' -SubnetMask 24 -Gateway '172.17.52.254' -DNS '208.67.222.123'
            Setup the temp VM to attache to swithc CorpIntAccess, tag the packets with vLAN id 1752, and set the statis IPv4 Address, mask, gateway and DNS
            .INPUTS
            System.IO.DirectoryInfo
            .OUTPUTS
            System.IO.DirectoryInfo
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.DirectoryInfo])]
    Param
    (
        # Path to the Windows Image Tools Update Folders (created via New-WitExample)
        [Parameter(Mandatory = $true, 
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    if (Test-Path $_) 
                    {
                        $true
                    }
                    else 
                    {
                        throw "Path $_ does not exist"
                    }
        })]
        [Alias('FullName')] 
        $Path,

        # Existing VM Switch
        [String]
        $VmSwitch,

        # vLAN to have the VM tag it's trafic to (0 = No vLAN taging)
        [int]
        $vLAN,

        # IP Address Type used to set give the Temporary VM internet access DHCP, IPv4, or IPv6
        [ValidateSet('DHCP', 'IPv4', 'Ipv4')]
        [String]
        $IpType,

        # Static IP IPv4 or IPv6 Address to asign the Temporary VM help description
        [ValidateScript({
                    $ipObj = [System.Net.IPAddress]::parse($_)
                    $isValidIP = [System.Net.IPAddress]::tryparse([string]$_, [ref]$ipObj)
                    if ($isValidIP) 
                    {
                        $true
                    } 
                    else 
                    {
                        throw 'IpAddress must be a valid IPv4 or IPv6 address'
                    }
        })]
        [String]
        $IpAddress,

        # IP SubnetMask Ex.
        [int]
        $SubnetMask,

        # Static Gateway
        [ValidateScript({
                    $ipObj = [System.Net.IPAddress]::parse($_)
                    $isValidIP = [System.Net.IPAddress]::tryparse([string]$_, [ref]$ipObj)
                    if ($isValidIP) 
                    {
                        $true
                    } 
                    else 
                    {
                        throw 'Gateway must be a valid IPv4 or IPv6 address'
                    }
        })]
        [String]
        $Gateway,

        # Static DNS Server
        [ValidateScript({
                    $ipObj = [System.Net.IPAddress]::parse($_)
                    $isValidIP = [System.Net.IPAddress]::tryparse([string]$_, [ref]$ipObj)
                    if ($isValidIP) 
                    {
                        $true
                    } 
                    else 
                    {
                        throw 'DNSServer must be a valid IPv4 or IPv6 address'
                    }
        })]
        [String]
        $DnsServer



    )

    if ($pscmdlet.ShouldProcess("$Path", 'Set the Windows Image Tools Update Configuration'))
    {
        $ConfigFilePath = $Path
        $ParentPath = (Get-Item $Path).Parent.FullName
        if (Test-Path -Path "$Path" -PathType Container) 
        {
            $ConfigFilePath = "$Path\Config.xml"
            $ParentPath = $Path
        }
        try 
        {
            $ConfigData = Import-Clixml -Path $ConfigFilePath -ErrorAction Stop
        }
        catch
        {
            Write-Warning -Message "Unable to read Windows Image Tools Update Cofniguration from $ConfigFilePath, creating a new file"
            $ConfigData = @{
                VmSwitch   = 'vmswitch'
                vLan       = 0
                IpAddress  = '192.168.0.100'
                SubnetMask = 24
                Gateway    = '192.168.0.1'
                DnsServer  = '192.168.0.1'
                IpType     = 'DHCP'
            }
        }
        # validate data structure incase useing older or malformed xml
        If (-not ($ConfigData.ContainsKey('VmSwitch'))) 
        {
            $ConfigData.add('VmSwitch','vmswitch')
        }
        If (-not ($ConfigData.ContainsKey('vLan'))) 
        {
            $ConfigData.add('vLan','0')
        }
        If (-not ($ConfigData.ContainsKey('IpType'))) 
        {
            $ConfigData.add('IpType','DHCP')
        }
        If (-not ($ConfigData.ContainsKey('IpAddress'))) 
        {
            $ConfigData.add('IpAddress','192.168.0.100')
        }
        If (-not ($ConfigData.ContainsKey('SubnetMask'))) 
        {
            $ConfigData.add('SubnetMask','24')
        }
        If (-not ($ConfigData.ContainsKey('Gateway'))) 
        {
            $ConfigData.add('Gateway','192.168.0.1')
        }
        If (-not ($ConfigData.ContainsKey('DnsServer'))) 
        {
            $ConfigData.add('DnsServer','192.168.0.1')
        }
      
        # update values
        if ($VmSwitch) 
        {
            $ConfigData.VmSwitch = $VmSwitch
        }
        if ($vLAN) 
        {
            $ConfigData.vLan = $vLAN
        }
        if ($IpType) 
        {
            $ConfigData.IpType = $IpType
        }
        if ($IpAddress) 
        {
            $ConfigData.IpAddress = $IpAddress
        }
        if ($SubnetMask) 
        {
            $ConfigData.SubnetMask = $SubnetMask
        }
        if ($Gateway) 
        {
            $ConfigData.Gateway = $Gateway
        }
        if ($DnsServer) 
        {
            $ConfigData.DnsServer = $DnsServer
        }
    
        Write-Verbose -Message 'New Configuration'
        Write-Verbose -Message ($ConfigData | Out-String)

        try 
        {
            $ConfigData | Export-Clixml -Path $ConfigFilePath -ErrorAction Stop
        }
        catch 
        {
            Throw "Failed to write $ConfigFilePath. $($_.Exception.Message)"
        }
        return (Get-Item $ParentPath)
    }
}

function Get-UpdateConfig
{
    <#
            .Synopsis
            Get the Windows Image Tools Update Config used for creating the temp VM
            .DESCRIPTION
            This command will Get the config used by Invoke-WindowsImageUpdate to build a VM and update Windows Images
            .EXAMPLE
            Set-WitUpdateConfig -Path C:\WitUpdate -VmSwitch 'VM' -IpType DCHP
            Set the temp VM to attach to siwth "VM" and use DCHP for IP addresses 
            .EXAMPLE
            Set-WitUPdateConfig -Path C:\WitUpdate -VmSwitch CorpIntAccess -vLAN 1752 -IpType 'IPv4' -IPAddress '172.17.52.100' -SubnetMask 24 -Gateway '172.17.52.254' -DNS '208.67.222.123'
            Setup the temp VM to attache to swithc CorpIntAccess, tag the packets with vLAN id 1752, and set the statis IPv4 Address, mask, gateway and DNS
            .INPUTS
            System.IO.DirectoryInfo
            .OUTPUTS
            System.IO.DirectoryInfo
    #>
    [CmdletBinding()]
    [Alias()]
    [OutputType([Hashtable])]
    Param
    (
        # Path to the Windows Image Tools Update Folders (created via New-WitExample)
        [Parameter(Mandatory = $true, 
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    if (Test-Path $_) 
                    {
                        $true
                    }
                    else 
                    {
                        throw "Path $_ does not exist"
                    }
        })]
        [Alias('FullName')] 
        $Path
    )

    return (Import-Clixml -Path "$Path\config.xml")
}
