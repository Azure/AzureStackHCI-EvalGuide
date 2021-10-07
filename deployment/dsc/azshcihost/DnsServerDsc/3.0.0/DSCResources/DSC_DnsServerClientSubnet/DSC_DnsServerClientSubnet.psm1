$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:dnsServerDscCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DnsServerDsc.Common'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:dnsServerDscCommonPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return the current state of the resource.

    .PARAMETER Name
        Specifies the name of the client subnet.

    .PARAMETER IPv4Subnet
        Specify an array (1 or more values) of IPv4 Subnet addresses in CIDR Notation.

    .PARAMETER IPv6Subnet
        Specify an array (1 or more values) of IPv6 Subnet addresses in CIDR Notation.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name

    )

    Write-Verbose -Message ($script:localizedData.GettingDnsServerClientSubnetMessage -f $Name)
    $record = Get-DnsServerClientSubnet -Name $Name -ErrorAction SilentlyContinue

    if ($null -eq $record)
    {
        return @{
            Name       = $Name
            IPv4Subnet = $null
            IPv6Subnet = $null
            Ensure     = 'Absent'
        }
    }

    return @{
        Name       = $record.Name
        IPv4Subnet = $record.IPv4Subnet
        IPv6Subnet = $record.IPv6Subnet
        Ensure     = 'Present'
    }
} #end function Get-TargetResource

<#
    .SYNOPSIS
        This will configure the resource.

    .PARAMETER Name
        Specifies the name of the client subnet.

    .PARAMETER IPv4Subnet
        Specify an array (1 or more values) of IPv4 Subnet addresses in CIDR Notation.

    .PARAMETER IPv6Subnet
        Specify an array (1 or more values) of IPv6 Subnet addresses in CIDR Notation.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String[]]
        $IPv4Subnet,

        [Parameter()]
        [System.String[]]
        $IPv6Subnet,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $dnsServerClientSubnetParameters = @{
        Name = $Name
    }
    $clientSubnet = Get-DnsServerClientSubnet -Name $Name -ErrorAction SilentlyContinue
    if ($Ensure -eq 'Present')
    {
        if ($IPv4Subnet)
        {
            $dnsServerClientSubnetParameters.Add('IPv4Subnet',$IPv4Subnet)
        }
        if ($IPv6Subnet)
        {
            $dnsServerClientSubnetParameters.Add('IPv6Subnet',$IPv6Subnet)
        }

        if ($clientSubnet)
        {
            $dnsServerClientSubnetParameters.Add('Action', "REPLACE")
            Write-Verbose -Message ($script:localizedData.UpdatingDnsServerClientSubnetMessage -f `
                $Name, "$IPv4Subnet", "$IPv6Subnet")
            Set-DnsServerClientSubnet @dnsServerClientSubnetParameters
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.CreatingDnsServerClientSubnetMessage -f `
                $Name, "$IPv4Subnet", "$IPv6Subnet")
            Add-DnsServerClientSubnet @dnsServerClientSubnetParameters
        }
    }
    elseif ($Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($script:localizedData.RemovingDnsServerClientSubnetMessage -f $Name)
        Remove-DnsServerClientSubnet -Name $Name
    }
} #end function Set-TargetResource

<#
    .SYNOPSIS
        This will return whether the resource is in desired state.

    .PARAMETER Name
        Specifies the name of the client subnet.

    .PARAMETER IPv4Subnet
        Specify an array (1 or more values) of IPv4 Subnet addresses in CIDR Notation.

    .PARAMETER IPv6Subnet
        Specify an array (1 or more values) of IPv6 Subnet addresses in CIDR Notation.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String[]]
        $IPv4Subnet,

        [Parameter()]
        [System.String[]]
        $IPv6Subnet,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $result = Get-TargetResource -Name $Name

    if ($Ensure -ne $result.Ensure)
    {
        Write-Verbose -Message ($script:localizedData.NotDesiredPropertyMessage -f `
            'Ensure', $Ensure, $result.Ensure)
        Write-Verbose -Message ($script:localizedData.NotInDesiredStateMessage -f $Name)
        return $false
    }
    elseif ($Ensure -eq 'Present')
    {
        $IPv4SubnetResult = $result.IPv4Subnet
        $IPv6SubnetResult = $result.IPv6Subnet

        if (($null -eq $IPv4Subnet) -and ($null -ne $IPv4SubnetResult))
        {
            Write-Verbose -Message ($script:localizedData.NotDesiredPropertyMessage -f `
                'IPv4Subnet', "$IPv4Subnet", "$IPv4SubnetResult")
            Write-Verbose -Message ($script:localizedData.NotInDesiredStateMessage -f $Name)
            return $false
        }

        if (($null -eq $IPv4SubnetResult) -and ($null -ne $IPv4Subnet))
        {
            Write-Verbose -Message ($script:localizedData.NotDesiredPropertyMessage -f `
                'IPv4Subnet', "$IPv4Subnet", "$IPv4SubnetResult")
            Write-Verbose -Message ($script:localizedData.NotInDesiredStateMessage -f $Name)
            return $false
        }

        if ($IPv4Subnet)
        {
            $IPv4Difference = Compare-Object -ReferenceObject $IPv4Subnet -DifferenceObject $IPv4SubnetResult
            if ($IPv4Difference)
            {
                Write-Verbose -Message ($script:localizedData.NotDesiredPropertyMessage -f `
                    'IPv4Subnet', "$IPv4Subnet", "$IPv4SubnetResult")
                Write-Verbose -Message ($script:localizedData.NotInDesiredStateMessage -f $Name)
                return $false
            }
        }

        if (($null -eq $IPv6Subnet) -and ($null -ne $IPv6SubnetResult))
        {
            Write-Verbose -Message ($script:localizedData.NotDesiredPropertyMessage -f `
                'IPv6Subnet', "$IPv6Subnet", "$IPv6SubnetResult")
            Write-Verbose -Message ($script:localizedData.NotInDesiredStateMessage -f $Name)
            return $false
        }

        if (($null -eq $IPv6SubnetResult) -and ($null -ne $IPv6Subnet))
        {
            Write-Verbose -Message ($script:localizedData.NotDesiredPropertyMessage -f `
                'IPv6Subnet', "$IPv6Subnet", "$IPv6SubnetResult")
            Write-Verbose -Message ($script:localizedData.NotInDesiredStateMessage -f $Name)
            return $false
        }

        if ($IPv6Subnet)
        {
            $IPv6Difference = Compare-Object -ReferenceObject $IPv6Subnet -DifferenceObject $IPv6SubnetResult
            if ($IPv6Difference)
            {
                Write-Verbose -Message ($script:localizedData.NotDesiredPropertyMessage -f `
                    'IPv6Subnet', "$IPv6Subnet", "$IPv6SubnetResult")
                Write-Verbose -Message ($script:localizedData.NotInDesiredStateMessage -f $Name)
                return $false
            }
        }
    }
    Write-Verbose -Message ($script:localizedData.InDesiredStateMessage -f $Name)
    return $true
} #end function Test-TargetResource

Export-ModuleMember -Function *-TargetResource
