$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:dnsServerDscCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DnsServerDsc.Common'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:dnsServerDscCommonPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String[]]
        $MasterServers
    )

#region Input Validation

    # Check for DnsServer module/role
    Assert-Module -ModuleName 'DnsServer'

#endregion

    Write-Verbose -Message 'Getting DNS zone.'
    $dnsZone = Get-DnsServerZone -Name $Name -ErrorAction SilentlyContinue
    if ($dnsZone)
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

    @{
        Name = $Name
        Ensure = $Ensure
        MasterServers = [string[]]$($dnsZone.MasterServers.IPAddressToString)
        Type = $dnsZone.ZoneType
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String[]]
        $MasterServers,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present'
    )
    Write-Verbose -Message 'Setting DNS zone.'
    if ($PSBoundParameters.ContainsKey('Debug'))
    {
        $null = $PSBoundParameters.Remove('Debug')
    }
    Test-ResourceProperties @PSBoundParameters -Apply

    # Restart the DNS service
    Restart-Service DNS
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String[]]
        $MasterServers,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present'
    )

#region Input Validation

    # Check for DnsServer module/role
    Assert-Module -ModuleName 'DnsServer'

#endregion
    Write-Verbose -Message 'Validating DNS zone.'
    if ($PSBoundParameters.ContainsKey('Debug'))
    {
        $null = $PSBoundParameters.Remove('Debug')
    }
    Test-ResourceProperties @PSBoundParameters

}

#region Helper Functions
function Test-ResourceProperties
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String[]]
        $MasterServers,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [Switch]
        $Apply
    )

    $zoneMessage = $($script:localizedData.CheckingZoneMessage) -f $Name
    Write-Verbose -Message $zoneMessage

    $dnsZone = Get-DnsServerZone -Name $Name -ErrorAction SilentlyContinue

    # Found DNS Zone
    if ($dnsZone)
    {
        $testZoneMessage = $($script:localizedData.TestZoneMessage) -f 'present', $Ensure
        Write-Verbose -Message $testZoneMessage

        # If the zone should be present
        if ($Ensure -eq 'Present')
        {
            # Check if the zone is secondary
            $secondaryZoneMessage = $script:localizedData.CheckingSecondaryZoneMessage
            Write-Verbose -Message $secondaryZoneMessage

            # If the zone is already secondary zone
            if ($dnsZone.ZoneType -eq "Secondary")
            {
                $correctZoneMessage = $($script:localizedData.AlreadySecondaryZoneMessage) -f $Name
                Write-Verbose -Message $correctZoneMessage

                # Check the master server property
                $checkPropertyMessage = $($script:localizedData.CheckPropertyMessage) -f 'master servers'
                Write-Verbose -Message $checkPropertyMessage

                # Compare the master server property
                if ((-not $dnsZone.MasterServers) -or (Compare-Object $($dnsZone.MasterServers.IPAddressToString) $MasterServers))
                {
                    $notDesiredPropertyMessage = $($script:localizedData.NotDesiredPropertyMessage) -f `
                        'master servers',$MasterServers,$dnsZone.MasterServers
                    Write-Verbose -Message $notDesiredPropertyMessage

                    if ($Apply)
                    {
                        Set-DnsServerSecondaryZone -Name $Name -MasterServers $MasterServers

                        $setPropertyMessage = $($script:localizedData.SetPropertyMessage) -f 'master servers'
                        Write-Verbose -Message $setPropertyMessage
                    }
                    else
                    {
                        return $false
                    }
                } # end master server mismatch
                else
                {
                    $desiredPropertyMessage = $($script:localizedData.DesiredPropertyMessage) -f 'master servers'
                    Write-Verbose -Message $desiredPropertyMessage
                    if (-not $Apply)
                    {
                        return $true
                    }
                } # end master servers match

            } # end zone is already secondary

            # If the zone is not secondary, make it so
            else
            {
                $notCorrectZoneMessage = $($script:localizedData.NotSecondaryZoneMessage) -f $Name,$dnsZone.ZoneType
                Write-Verbose -Message $notCorrectZoneMessage

                # Convert the zone to Secondary zone
                if ($Apply)
                {
                    ConvertTo-DnsServerSecondaryZone -Name $Name -MasterServers $MasterServers -ZoneFile $Name -Force

                    $setZoneMessage = $($script:localizedData.SetSecondaryZoneMessage) -f $Name
                    Write-Verbose -Message $setZoneMessage
                }
                else
                {
                    return $false
                }
            } # end zone is not secondary

        }# end ensure -eq present

        # If zone should be absent
        else
        {
            if ($Apply)
            {
                $removingZoneMessage = $script:localizedData.RemovingZoneMessage
                Write-Verbose -Message $removingZoneMessage

                Remove-DnsServerZone -Name $Name -Force

                $deleteZoneMessage = $($script:localizedData.DeleteZoneMessage) -f $Name
                Write-Verbose -Message $deleteZoneMessage
            }
            else
            {
                return $false
            }
        } # end ensure -eq absent

    } # end found dns zone

    # Not found DNS Zone
    else
    {
        $testZoneMessage = $($script:localizedData.TestZoneMessage) -f 'absent', $Ensure
        Write-Verbose -Message $testZoneMessage

        if ($Ensure -eq 'Present')
        {
            if ($Apply)
            {
                $addingSecondaryZoneMessage = $script:localizedData.AddingSecondaryZoneMessage
                Write-Verbose -Message $addingSecondaryZoneMessage

                # Add the zone and start the transfer
                Add-DnsServerSecondaryZone -Name $Name -MasterServers $MasterServers -ZoneFile $Name
                Start-DnsServerZoneTransfer -Name $Name -FullTransfer

                $newSecondaryZoneMessage = $($script:localizedData.NewSecondaryZoneMessage) -f $Name
                Write-Verbose -Message $newSecondaryZoneMessage
            }
            else
            {
                return $false
            }
        } # end ensure -eq Present
        else
        {
            if (-not $Apply)
            {
                return $true
            }
        } # end ensure -eq Absent
    }
}
#endregion

Export-ModuleMember -Function *-TargetResource
