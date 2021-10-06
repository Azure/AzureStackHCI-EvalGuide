$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:dnsServerDscCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DnsServerDsc.Common'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:dnsServerDscCommonPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

# Allow transfer to any server use 0, to one in name tab 1, specific one 2, no transfer 3
$XferId2Name= @('Any','Named','Specific','None')

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
        [ValidateSet("None","Any","Named","Specific")]
        [System.String]
        $Type
    )

#region Input Validation

    # Check for DnsServer module/role
    Assert-Module -ModuleName 'DnsServer'

#endregion
    Write-Verbose -Message 'Getting DNS zone.'
    $currentZone = Get-CimInstance `
        -ClassName MicrosoftDNS_Zone `
        -Namespace root\MicrosoftDNS `
        -Verbose:$false | Where-Object -FilterScript {$_.Name -eq $Name}

    @{
        Name            = $Name
        Type            = $XferId2Name[$currentZone.SecureSecondaries]
        SecondaryServer = $currentZone.SecondaryServers
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
        [ValidateSet("None","Any","Named","Specific")]
        [System.String]
        $Type,

        [Parameter()]
        [String[]]
        $SecondaryServer
    )
    Write-Verbose -Message 'Setting DNS zone.'
    if ($PSBoundParameters.ContainsKey('Debug'))
    {
        $null = $PSBoundParameters.Remove('Debug')
    }
    Test-ResourceProperties @PSBoundParameters -Apply

    # Restart the DNS service
    Restart-Service -Name DNS
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
        [ValidateSet("None","Any","Named","Specific")]
        [System.String]
        $Type,

        [Parameter()]
        [String[]]
        $SecondaryServer
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

function Test-ResourceProperties
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("None","Any","Named","Specific")]
        [System.String]
        $Type,

        [Parameter()]
        [String[]]
        $SecondaryServer,

        [Parameter()]
        [Switch]
        $Apply
    )

    $checkZoneMessage = $($script:localizedData.CheckingZoneMessage) `
        -f $Name
    Write-Verbose -Message $checkZoneMessage

    # Get the current value of transfer zone
    $currentZone = Get-CimInstance `
        -ClassName MicrosoftDNS_Zone `
        -Namespace root\MicrosoftDNS `
        -Verbose:$false | Where-Object -FilterScript {$_.Name -eq $Name}
    $currentZoneTransfer = $currentZone.SecureSecondaries

    # Hashtable with 2 keys: SecureSecondaries,SecondaryServers
    $Arguments = @{}

    switch ($Type)
    {
        'None'
        {
            $Arguments['SecureSecondaries'] = 3
        }
        'Any'
        {
            $Arguments['SecureSecondaries'] = 0
        }
        'Named'
        {
            $Arguments['SecureSecondaries'] = 1
        }
        'Specific'
        {
            $Arguments['SecureSecondaries'] = 2
            $Arguments['SecondaryServers']=$SecondaryServer
        }
    }

    # Check the current value against expected value
    if ($currentZoneTransfer -eq $Arguments.SecureSecondaries)
    {
        $desiredZoneMessage = ($script:localizedData.DesiredZoneMessage) `
            -f $XferId2Name[$currentZoneTransfer]
        Write-Verbose -Message $desiredZoneMessage

        # If the Type is specific, and SecondaryServer doesn't match
        if (($currentZoneTransfer -eq 2) `
            -and (Compare-Object $currentZone.SecondaryServers $SecondaryServer))
        {
            $notDesiredPropertyMessage = ($script:localizedData.NotDesiredPropertyMessage) `
                -f ($SecondaryServer -join ','),($currentZone.SecondaryServers -join ',')
            Write-Verbose -Message $notDesiredPropertyMessage

            # Set the SecondaryServer property
            if ($Apply)
            {
                $settingPropertyMessage = ($script:localizedData.SettingPropertyMessage) `
                    -f ($SecondaryServer -join ',')
                Write-Verbose -Message $settingPropertyMessage

                $null = Invoke-CimMethod `
                    -InputObject $currentZone `
                    -MethodName ResetSecondaries `
                    -Arguments $Arguments `
                    -Verbose:$false

                $setPropertyMessage = $script:localizedData.SetPropertyMessage
                Write-Verbose -Message $setPropertyMessage
            }
            else
            {
                return $false
            }
        } # end SecondaryServer match

        if (-not $Apply)
        {
            return $true
        }
    } # end currentZoneTransfer -eq ExpectedZoneTransfer
    else
    {
        $notDesiredZoneMessage = $($script:localizedData.NotDesiredZoneMessage) `
            -f $XferId2Name[$Arguments.SecureSecondaries], `
               $XferId2Name[$currentZoneTransfer]
        Write-Verbose -Message $notDesiredZoneMessage

        if ($Apply)
        {
            $null = Invoke-CimMethod `
                -InputObject $currentZone `
                -MethodName ResetSecondaries `
                -Arguments $Arguments `
                -Verbose:$false

            $setZoneMessage = $($script:localizedData.SetZoneMessage) `
                -f $Name,$XferId2Name[$Arguments.SecureSecondaries]
            Write-Verbose -Message $setZoneMessage
        }
        else
        {
            return $false
        }
    } # end currentZoneTransfer -ne ExpectedZoneTransfer
}

Export-ModuleMember -Function *-TargetResource
