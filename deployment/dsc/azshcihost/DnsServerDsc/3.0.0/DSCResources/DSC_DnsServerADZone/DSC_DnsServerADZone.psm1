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
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('None','NonSecureAndSecure','Secure')]
        [System.String]
        $DynamicUpdate = 'Secure',

        [Parameter(Mandatory = $true)]
        [ValidateSet('Custom','Domain','Forest','Legacy')]
        [System.String]
        $ReplicationScope,

        [Parameter()]
        [System.String]
        $DirectoryPartitionName,

        [Parameter()]
        [System.String]
        $ComputerName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )
    Assert-Module -ModuleName 'DNSServer'
    Write-Verbose ($script:localizedData.CheckingZoneMessage -f $Name, $Ensure)

    if (!$PSBoundParameters.ContainsKey('ComputerName') -and $PSBoundParameters.ContainsKey('Credential'))
    {
        throw $script:localizedData.CredentialRequiresComputerNameMessage
    }

    $getParams = @{
        Name = $Name
        ErrorAction = 'SilentlyContinue'
    }

    if ($PSBoundParameters.ContainsKey('ComputerName'))
    {
        $cimSessionParams = @{
            ErrorAction = 'SilentlyContinue'
            ComputerName = $ComputerName
        }
        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $cimSessionParams += @{
                Credential = $Credential
            }
        }
        $getParams += @{
            CimSession = (New-CimSession @cimSessionParams)
        }
    }

    $dnsServerZone = Get-DnsServerZone @getParams
    if ($getParams.CimSession)
    {
        Remove-CimSession -CimSession $getParams.CimSession
    }
    $targetResource = @{
        Name = $dnsServerZone.ZoneName
        DynamicUpdate = $dnsServerZone.DynamicUpdate
        ReplicationScope = $dnsServerZone.ReplicationScope
        DirectoryPartitionName = $dnsServerZone.DirectoryPartitionName
        Ensure = if ($null -eq $dnsServerZone) { 'Absent' } else { 'Present' }
    }
    return $targetResource
} #end function Get-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('None','NonSecureAndSecure','Secure')]
        [System.String]
        $DynamicUpdate = 'Secure',

        [Parameter(Mandatory = $true)]
        [ValidateSet('Custom','Domain','Forest','Legacy')]
        [System.String]
        $ReplicationScope,

        [Parameter()]
        [System.String]
        $DirectoryPartitionName,

        [Parameter()]
        [System.String]
        $ComputerName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $targetResource = Get-TargetResource @PSBoundParameters

    $targetResourceInCompliance = $true

    if ($Ensure -eq 'Present')
    {
        if ($targetResource.Ensure -eq 'Present')
        {
            if ($targetResource.DynamicUpdate -ne $DynamicUpdate)
            {
                Write-Verbose ($script:localizedData.NotDesiredPropertyMessage -f `
                    'DynamicUpdate', $DynamicUpdate, $targetResource.DynamicUpdate)

                $targetResourceInCompliance = $false
            }

            if ($targetResource.ReplicationScope -ne $ReplicationScope)
            {
                Write-Verbose ($script:localizedData.NotDesiredPropertyMessage -f `
                    'ReplicationScope', $ReplicationScope, $targetResource.ReplicationScope)

                $targetResourceInCompliance = $false
            }

            if ($DirectoryPartitionName -and $targetResource.DirectoryPartitionName -ne $DirectoryPartitionName)
            {
                Write-Verbose ($script:localizedData.NotDesiredPropertyMessage -f `
                    'DirectoryPartitionName', $DirectoryPartitionName, $targetResource.DirectoryPartitionName)

                $targetResourceInCompliance = $false
            }
        }
        else
        {
            # Dns zone is present and needs removing
            Write-Verbose ($script:localizedData.NotDesiredPropertyMessage -f 'Ensure', 'Present', 'Absent')

            $targetResourceInCompliance = $false
        }
    }
    else
    {
        if ($targetResource.Ensure -eq 'Present')
        {
            ## Dns zone is absent and should be present
            Write-Verbose ($script:localizedData.NotDesiredPropertyMessage -f 'Ensure', 'Absent', 'Present')

            $targetResourceInCompliance = $false
        }
    }

    return $targetResourceInCompliance
} #end function Test-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('None','NonSecureAndSecure','Secure')]
        [System.String]
        $DynamicUpdate = 'Secure',

        [Parameter(Mandatory = $true)]
        [ValidateSet('Custom','Domain','Forest','Legacy')]
        [System.String]
        $ReplicationScope,

        [Parameter()]
        [System.String]
        $DirectoryPartitionName,

        [Parameter()]
        [System.String]
        $ComputerName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Assert-Module -ModuleName 'DNSServer'

    $targetResource = Get-TargetResource @PSBoundParameters

    $params = @{
        Name = $Name
    }

    if ($PSBoundParameters.ContainsKey('ComputerName'))
    {
        $cimSessionParams = @{
            ErrorAction = 'SilentlyContinue'
            ComputerName = $ComputerName
        }

        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $cimSessionParams += @{
                Credential = $Credential
            }
        }

        $params += @{
            CimSession = (New-CimSession @cimSessionParams)
        }
    }

    if ($Ensure -eq 'Present')
    {
        if ($targetResource.Ensure -eq 'Present')
        {
            ## Update the existing zone
            if ($targetResource.DynamicUpdate -ne $DynamicUpdate)
            {
                $params += @{
                    DynamicUpdate = $DynamicUpdate
                }

                Write-Verbose ($script:localizedData.SetPropertyMessage -f 'DynamicUpdate')
            }

            if ($targetResource.ReplicationScope -ne $ReplicationScope)
            {
                $params += @{
                    ReplicationScope = $ReplicationScope
                }

                Write-Verbose ($LocalizedData.SetPropertyMessage -f 'ReplicationScope')
            }

            if ($DirectoryPartitionName -and $targetResource.DirectoryPartitionName -ne $DirectoryPartitionName)
            {
                if ($ReplicationScope -ne 'Custom')
                {
                    # ReplicationScope must be 'Custom' if a DirectoryPartitionName is specified
                    $errorMessage = $script:localizedData.DirectoryPartitionReplicationScopeError

                    New-InvalidArgumentException -ArgumentName 'ReplicationScope' -Message $errorMessage
                }

                # ReplicationScope is a required parameter if DirectoryPartitionName is specified
                if ($params.keys -notcontains 'ReplicationScope')
                {
                    $params += @{
                        ReplicationScope = $ReplicationScope
                    }
                }

                $params += @{
                    DirectoryPartitionName = $DirectoryPartitionName
                }

                Write-Verbose ($script:localizedData.SetPropertyMessage -f 'DirectoryPartitionName')
            }

            Set-DnsServerPrimaryZone @params
        }
        elseif ($targetResource.Ensure -eq 'Absent')
        {
            # Create the zone
            Write-Verbose ($script:localizedData.AddingZoneMessage -f $targetResource.Name)

            $params += @{
                DynamicUpdate = $DynamicUpdate
                ReplicationScope = $ReplicationScope
            }

            if ($DirectoryPartitionName)
            {
                if ($ReplicationScope -ne 'Custom')
                {
                    # ReplicationScope must be 'Custom' if a DirectoryPartitionName is specified
                    $errorMessage = $script:localizedData.DirectoryPartitionReplicationScopeError

                    New-InvalidArgumentException -ArgumentName 'ReplicationScope' -Message $errorMessage
                }

                $params += @{
                    DirectoryPartitionName = $DirectoryPartitionName
                }
            }

            Add-DnsServerPrimaryZone @params
        }
    }
    elseif ($Ensure -eq 'Absent')
    {
        # Remove the DNS Server zone
        Write-Verbose ($script:localizedData.RemovingZoneMessage -f $targetResource.Name)

        Remove-DnsServerZone @params -Force
    }

    if ($params.CimSession)
    {
        Remove-CimSession -CimSession $params.CimSession
    }
} #end function Set-TargetResource
