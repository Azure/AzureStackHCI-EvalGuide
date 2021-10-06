$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:dnsServerDscCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DnsServerDsc.Common'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:dnsServerDscCommonPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

$script:timeSpanProperties = @(
    'LameDelegationTTL'
    'MaximumSignatureScanPeriod'
    'MaximumTrustAnchorActiveRefreshInterval'
    'ZoneWritebackInterval'
)

<#
    .SYNOPSIS
        Returns the current state of the DNS server settings.

    .PARAMETER DnsServer
        Specifies the DNS server to connect to, or use 'localhost' for the current
        node.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DnsServer
    )

    Assert-Module -ModuleName 'DnsServer'

    Write-Verbose ($script:localizedData.GettingDnsServerSettings)

    $getDnsServerSettingParameters = @{
        All = $true
    }

    if ($DnsServer -ne 'localhost')
    {
        $getDnsServerSettingParameters['ComputerName'] = $DnsServer
    }

    $dnsServerInstance = Get-DnsServerSetting @getDnsServerSettingParameters

    $classProperties = @(
        'LocalNetPriority'
        'AutoConfigFileZones'
        'AddressAnswerLimit'
        'UpdateOptions'
        'DisableAutoReverseZone'
        'StrictFileParsing'
        'EnableDirectoryPartitions'
        'XfrConnectTimeout'
        'AllowUpdate'
        'BootMethod'
        'LooseWildcarding'
        'BindSecondaries'
        'AutoCacheUpdate'
        'EnableDnsSec'
        'NameCheckFlag'
        'SendPort'
        'WriteAuthorityNS'
        'ListeningIPAddress'
        'RpcProtocol'
        'RoundRobin'
        'ForwardDelegations'
        'EnableIPv6'
        'EnableOnlineSigning'
        'EnableDuplicateQuerySuppression'
        'AllowCnameAtNs'
        'EnableRsoForRodc'
        'OpenAclOnProxyUpdates'
        'NoUpdateDelegations'
        'EnableUpdateForwarding'
        'EnableWinsR'
        'DeleteOutsideGlue'
        'AppendMsZoneTransferTag'
        'AllowReadOnlyZoneTransfer'
        'EnableSendErrorSuppression'
        'SilentlyIgnoreCnameUpdateConflicts'
        'EnableIQueryResponseGeneration'
        'AdminConfigured'
        'PublishAutoNet'
        'ReloadException'
        'IgnoreServerLevelPolicies'
        'IgnoreAllPolicies'
        'EnableVersionQuery'
        'AutoCreateDelegation'
        'RemoteIPv4RankBoost'
        'RemoteIPv6RankBoost'
        'MaximumRodcRsoQueueLength'
        'MaximumRodcRsoAttemptsPerCycle'
        'MaxResourceRecordsInNonSecureUpdate'
        'LocalNetPriorityMask'
        'TcpReceivePacketSize'
        'SelfTest'
        'XfrThrottleMultiplier'
        'SocketPoolSize'
        'QuietRecvFaultInterval'
        'QuietRecvLogInterval'
        'SyncDsZoneSerial'
        'ScopeOptionValue'
        'VirtualizationInstanceOptionValue'
        'ServerLevelPluginDll'
        'RootTrustAnchorsURL'
        'SocketPoolExcludedPortRanges'
        'LameDelegationTTL'
        'MaximumSignatureScanPeriod'
        'MaximumTrustAnchorActiveRefreshInterval'
        'ZoneWritebackInterval'

        # Read-only properties
        'DsAvailable'
        'MajorVersion'
        'MinorVersion'
        'BuildNumber'
        'IsReadOnlyDC'
        'AllIPAddress'
        'ForestDirectoryPartitionBaseName'
        'DomainDirectoryPartitionBaseName'
        'MaximumUdpPacketSize'
    )

    $returnValue = @{}

    foreach ($property in $classProperties)
    {
        if ($property -in $script:timeSpanProperties)
        {
            $returnValue.Add($property, $dnsServerInstance.$property.ToString())
        }
        else
        {
            $returnValue.Add($property, $dnsServerInstance.$property)
        }
    }

    $returnValue.DnsServer = $DnsServer

    return $returnValue
}

<#
    .SYNOPSIS
        Set the desired state of the DNS server settings.

    .PARAMETER DnsServer
        Specifies the DNS server to connect to, or use 'localhost' for the current
        node.

    .PARAMETER AddressAnswerLimit
        Specifies the maximum number of A (host IP address) resource records that
        the DNS server can insert in the answer section of a response to an A record
        query (a query for an IP address). The value of this entry also influences
        the setting of the truncation bit. If the value of this entry can be between
        5 and 28, or 0. The truncation bit is not set on the response, even when the
        packet space is exceeded.

    .PARAMETER AllowUpdate
        Specifies whether the DNS Server accepts dynamic update requests. $true to
        allow any DNS update operation; otherwise, $false.

    .PARAMETER AutoCacheUpdate
        Specifies whether the DNS Server attempts to update its cache entries using
        data from root servers. $true to cache delegation information; otherwise,
        $false.

    .PARAMETER AutoConfigFileZones
        Specifies the type of zones for which SOA and NS records will be automatically
        configured with the DNS server's local host name as the primary DNS server for
        the zone when the zone is loaded from file.

    .PARAMETER BindSecondaries
        Specifies whether the server will permit send DNS zone transfer response
        messages with more than one record in each response if the zone transfer
        request did not have the characters MS appended to it. If set to $true,
        the DNS server will include only one record in each response if the zone
        transfer request did not have the characters MS appended to it.

    .PARAMETER BootMethod
        Specifies the boot method used by the DNS server.

    .PARAMETER DisableAutoReverseZone
        Specifies whether the DNS Server automatically creates standard reverse
        look up zones. $true to disables automatic reverse zones; otherwise, $false.

    .PARAMETER EnableDirectoryPartitions
        Specifies whether the DNS server will support application directory partitions.

    .PARAMETER EnableDnsSec
        Specifies whether the DNS Server includes DNSSEC-specific RRs, KEY, SIG,
        and NXT in a response. $true to enable DNSSEC validation on the DNS server;
        otherwise, $false.

    .PARAMETER ForwardDelegations
        Specifies how the DNS server will handle forwarding and delegations. If
        set to $true, the DNS server MUST use forwarders instead of a cached
        delegation when both are available. Otherwise, the DNS server MUST use a
        cached delegation instead of forwarders when both are available.

    .PARAMETER ListeningIPAddress
        Specifies the listening IP addresses of the DNS server. The list of IP
        addresses on which the DNS Server can receive queries.

    .PARAMETER LocalNetPriority
        Specifies whether the DNS Server gives priority to the local net address
        when returning A records. $true to return A records in order of their
        similarity to the IP address of the querying client.; otherwise, $false.

    .PARAMETER LooseWildcarding
        Specifies he type of algorithm that the DNS server will use to locate a
        wildcard node when using a DNS wildcard record RFC1034 to answer a query.
        If true, the DNS server will use the first node it encounters with a record
        of the same type as the query type. Otherwise, the DNS server will use the
        first node it encounters that has records of any type.

    .PARAMETER NameCheckFlag
        Specifies the level of domain name checking and validation on the DNS server,
        the set of eligible characters to be used in DNS names.

    .PARAMETER RoundRobin
        Specifies whether the DNS Server round robins multiple A records. $true to
        enable Round-robin DNS on the DNS server; otherwise, $false.

    .PARAMETER RpcProtocol
        Specifies the DNS_RPC_PROTOCOLS section 2.2.1.1.2 value corresponding to
        the RPC protocols to which the DNS server will respond. If this value is
        set to 0x00000000, the DNS server MUST NOT respond to RPC requests for
        any protocol.

    .PARAMETER SendPort
        Specifies the port number to use as the source port when sending UDP queries
        to a remote DNS server. If set to zero, the DNS server allow the stack to
        select a random port.

    .PARAMETER StrictFileParsing
        Specifies whether the DNS server will treat errors encountered while reading
        zones from a file as fatal.

    .PARAMETER UpdateOptions
        Specifies the DNS update options used by the DNS server.

    .PARAMETER WriteAuthorityNS
        Specifies whether the DNS server will include NS records for the root of a
        zone in DNS responses that are answered using authoritative zone data.

    .PARAMETER XfrConnectTimeout
        Specifies the time span, in seconds, in which a primary DNS server waits
        for a transfer response from its secondary server. The default value is 30.
        After the time-out value expires, the connection is terminated.

    .PARAMETER EnableIPv6
        Specifies whether IPv6 should be enabled on the DNS Server. $true to enable
        IPv6 on the DNS server; otherwise, $false.

    .PARAMETER EnableOnlineSigning
        Specifies whether online signing should be enabled on the DNS Server. $true
        to enable online signing; otherwise, $false.

    .PARAMETER EnableDuplicateQuerySuppression
        Specifies whether the DNS server will not send remote queries when there is
        already a remote query with the same name and query type outstanding.

    .PARAMETER AllowCnameAtNs
        Specifies whether the server will permit the target domain names of NS records
        to resolve to CNAME records. If $true, this pattern of DNS records will be
        allowed; otherwise, the DNS server will return errors when encountering this
        pattern of DNS records while resolving queries.

    .PARAMETER EnableRsoForRodc
        Specifies whether the DNS server will attempt to replicate single updated
        DNS objects from remote directory servers ahead of normally scheduled replication
        when operating on a directory server that does not support write operations.

    .PARAMETER OpenAclOnProxyUpdates
        Specifies whether the DNS server allows sharing of DNS records with the
        DnsUpdateProxy group when processing updates in secure zones that are stored
        in the directory service.

    .PARAMETER NoUpdateDelegations
        Specifies whether the DNS server will accept DNS updates to delegation
        records of type NS.

    .PARAMETER EnableUpdateForwarding
        Specifies whether the DNS server will forward updates received for secondary
        zones to the primary DNS server for the zone.

    .PARAMETER EnableWinsR
        Specifies whether the DNS server will perform NetBIOS name resolution in
        order to map IP addresses to machine names while processing queries in zones
        where WINS-R information has been configured.

    .PARAMETER DeleteOutsideGlue
        Specifies whether the DNS server will delete DNS glue records found outside
        a delegated subzone when reading records from persistent storage.

    .PARAMETER AppendMsZoneTransferTag
        Specifies whether the DNS server will indicate to the remote DNS servers
        that it supports multiple DNS records in each zone transfer response message
        by appending the characters MS at the end of zone transfer requests. The
        value SHOULD be limited to 0x00000000 and 0x0000000, but it MAY be any value.

    .PARAMETER AllowReadOnlyZoneTransfer
        Specifies whether the DNS server will allow zone transfers for zones that
        are stored in the directory server when the directory server does not support
        write operations.

    .PARAMETER EnableSendErrorSuppression
        Specifies whether the DNS server will attempt to suppress large volumes
        of DNS error responses sent to remote IP addresses that may be attempting
        to attack the DNS server.

    .PARAMETER SilentlyIgnoreCnameUpdateConflicts
        Specifies whether the DNS server will ignore CNAME conflicts during DNS
        update processing.

    .PARAMETER EnableIQueryResponseGeneration
        Specifies whether the DNS server will fabricate IQUERY responses. If set
        to $true, the DNS server MUST fabricate IQUERY responses when it receives
        queries of type IQUERY. Otherwise, the DNS server will return an error when
        such queries are received.

    .PARAMETER AdminConfigured
        Specifies whether the server has been configured by an administrator.

    .PARAMETER PublishAutoNet
        Specifies whether the DNS server will publish local IPv4 addresses in the
        169.254.x.x subnet as IPv4 addresses for the local machine's domain name.

    .PARAMETER ReloadException
        Specifies whether the DNS server will perform an internal restart if an
        unexpected fatal error is encountered.

    .PARAMETER IgnoreServerLevelPolicies
        Specifies whether to ignore the server level policies on the DNS server.
        $true to ignore the server level policies on the DNS server; otherwise,
        $false.

    .PARAMETER IgnoreAllPolicies
        Specifies whether to ignore all policies on the DNS server. $true to ignore
        all policies on the DNS server; otherwise, $false.

    .PARAMETER EnableVersionQuery
        Specifies what version information the DNS server will respond with when a
        DNS query with class set to CHAOS and type set to TXT is received.

    .PARAMETER AutoCreateDelegation
        Specifies possible settings for automatic delegation creation for new zones
        on the DNS server. The value SHOULD be limited to the range from 0x00000000
        to 0x00000002, inclusive, but it MAY be any value.

    .PARAMETER RemoteIPv4RankBoost
        Specifies the value to add to all IPv4 addresses for remote DNS servers when
        selecting between IPv4 and IPv6 remote DNS server addresses. The value MUST
        be limited to the range from 0x00000000 to 0x0000000A, inclusive.

    .PARAMETER RemoteIPv6RankBoost
        Specifies the value to add to all IPv6 addresses for remote DNS servers when
        selecting between IPv4 and IPv6 remote DNS server addresses. The value MUST
        be limited to the range from 0x00000000 to 0x0000000A, inclusive.

    .PARAMETER MaximumRodcRsoQueueLength
        Specifies the maximum number of single object replication operations that
        may be queued at any given time by the DNS server. The value MUST be limited
        to the range from 0x00000000 to 0x000F4240, inclusive. If the value is
        0x00000000 the DNS server MUST NOT enforce an upper bound on the number of
        single object replication operations queued at any given time.

    .PARAMETER MaximumRodcRsoAttemptsPerCycle
        Specifies the maximum number of queued single object replication operations
        that should be attempted during each five minute interval of DNS server
        operation. The value MUST be limited to the range from 0x00000001 to 0x000F4240,
        inclusive.

    .PARAMETER MaxResourceRecordsInNonSecureUpdate
        Specifies the maximum number of resource records that the DNS server will
        accept in a single DNS update request. The value SHOULD be limited to the
        range from 0x0000000A to 0x00000078, inclusive, but it MAY be any value.

    .PARAMETER LocalNetPriorityMask
        Specifies the value which specifies the network mask the DNS server will
        use to sort IPv4 addresses. A value of 0xFFFFFFFF indicates that the DNS
        server MUST use traditional IPv4 network mask for the address. Any other
        value is a network mask, in host byte order that the DNS server MUST use
        to retrieve network masks from IP addresses for sorting purposes.

    .PARAMETER TcpReceivePacketSize
        Specifies the maximum TCP packet size, in bytes, that the DNS server can
        accept. The value MUST be limited to the range from 0x00004000 to 0x00010000,
        inclusive.

    .PARAMETER SelfTest
        Specifies the mask value indicating whether data consistency checking
        should be performed once, each time the service starts. If the check fails,
        the server posts an event log warning. If the least significant bit (regardless
        of other bits) of this value is one, the DNS server will verify for each
        active and update-allowing primary zone, that the IP address records are
        present in the zone for the zone's SOA record's master server. If the
        least significant bit (regardless of other bits) of this value is zero,
        no data consistency checking will be performed.

    .PARAMETER XfrThrottleMultiplier
        Specifies the multiple used to determine how long the DNS server should
        refuse zone transfer requests after a successful zone transfer has been
        completed. The total time for which a zone will refuse another zone
        transfer request at the end of a successful zone transfer is computed as
        this value multiplied by the number of seconds required for the zone
        transfer that just completed. The server SHOULD refuse zone transfer
        requests for no more than ten minutes. The value SHOULD be limited to
        the range from 0x00000000 to 0x00000064, inclusive, but it MAY be any
        value.

    .PARAMETER SocketPoolSize
        Specifies the number of UDP sockets per address family that the DNS server
        will use for sending remote queries.

    .PARAMETER QuietRecvFaultInterval
        Specifies the minimum time interval, in seconds, starting when the server
        begins waiting for the query to arrive on the network, after which the
        server MAY log a debug message indicating that the server is to stop running.
        If the value is zero or is less than the value of QuietRecvLogInterval*,
        then the value of QuietRecvLogInterval MUST be used. If the value is
        greater than or equal to the value of QuietRecvLogInterval, then the
        literal value of QuietRecvFaultInterval MUST be used. Used to debug
        reception of UDP traffic for a recursive query.

    .PARAMETER QuietRecvLogInterval
        Specifies the minimum time interval, in seconds, starting when the server
        begins waiting for the query to arrive on the network, or when the server
        logs an eponymous debug message for the query, after which the server MUST
        log a debug message indicating that the server is still waiting to receive
        network traffic. If the value is zero, logging associated with the two
        QuietRecv properties MUST be disabled, and the QuietRecvFaultInterval
        property MUST be ignored. If the value is non-zero, logging associated with
        the two QuietRecv properties MUST be enabled, and the QuietRecvFaultInterval
        property MUST NOT be ignored. Used to debug reception of UDP traffic for a
        recursive query.

    .PARAMETER SyncDsZoneSerial
        Specifies the conditions under which the DNS server should immediately
        commit uncommitted zone serial numbers to persistent storage. The value
        SHOULD be limited to the range from 0x00000000 to 0x00000004, inclusive,
        but it MAY be any value.

    .PARAMETER ScopeOptionValue
        Specifies the extension mechanism for the DNS (ENDS0) scope setting on the
        DNS server.

    .PARAMETER VirtualizationInstanceOptionValue
        Specifies the virtualization instance option to be sent in ENDS0.

    .PARAMETER ServerLevelPluginDll
        Specifies the path of a custom plug-in. When DllPath specifies the fully
        qualified path name of a valid DNS server plug-in, the DNS server calls
        functions in the plug-in to resolve name queries that are outside the
        scope of all locally hosted zones. If a queried name is out of the scope
        of the plug-in, the DNS server performs name resolution using forwarding
        or recursion, as configured. If DllPath is not specified, the DNS server
        ceases to use a custom plug-in if a custom plug-in was previously configured.

    .PARAMETER RootTrustAnchorsURL
        Specifies the URL of the root trust anchor on the DNS server.

    .PARAMETER SocketPoolExcludedPortRanges
        Specifies the port ranges that should be excluded.

    .PARAMETER LameDelegationTTL
        Specifies the time span that must elapse before the DNS server will re-query
        DNS servers of the parent zone when a lame delegation is encountered. The
        value SHOULD be limited to the range from 0x00000000 to 0x00278D00 30 days,
        inclusive, but it MAY be any value.

    .PARAMETER MaximumSignatureScanPeriod
        Specifies the maximum period between zone scans to update DnsSec signatures
        for resource records.

    .PARAMETER MaximumTrustAnchorActiveRefreshInterval
        Specifies the maximum value for the active refresh interval for a trust
        anchor. Must not be higher than 15 days.

    .PARAMETER ZoneWritebackInterval
        Specifies the zone write back interval for file backed zones.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DnsServer,

        [Parameter()]
        [System.UInt32]
        $AddressAnswerLimit,

        [Parameter()]
        [System.Boolean]
        $AllowUpdate,

        [Parameter()]
        [System.Boolean]
        $AutoCacheUpdate,

        [Parameter()]
        [System.UInt32]
        $AutoConfigFileZones,

        [Parameter()]
        [System.Boolean]
        $BindSecondaries,

        [Parameter()]
        [System.UInt32]
        $BootMethod,

        [Parameter()]
        [System.Boolean]
        $DisableAutoReverseZone,

        [Parameter()]
        [System.Boolean]
        $EnableDirectoryPartitions,

        [Parameter()]
        [System.Boolean]
        $EnableDnsSec,

        [Parameter()]
        [System.Boolean]
        $ForwardDelegations,

        [Parameter()]
        [System.String[]]
        $ListeningIPAddress,

        [Parameter()]
        [System.Boolean]
        $LocalNetPriority,

        [Parameter()]
        [System.Boolean]
        $LooseWildcarding,

        [Parameter()]
        [System.UInt32]
        $NameCheckFlag,

        [Parameter()]
        [System.Boolean]
        $RoundRobin,

        [Parameter()]
        [System.UInt32]
        $RpcProtocol,

        [Parameter()]
        [System.UInt32]
        $SendPort,

        [Parameter()]
        [System.Boolean]
        $StrictFileParsing,

        [Parameter()]
        [System.UInt32]
        $UpdateOptions,

        [Parameter()]
        [System.Boolean]
        $WriteAuthorityNS,

        [Parameter()]
        [System.UInt32]
        $XfrConnectTimeout,

        [Parameter()]
        [System.Boolean]
        $EnableIPv6,

        [Parameter()]
        [System.Boolean]
        $EnableOnlineSigning,

        [Parameter()]
        [System.Boolean]
        $EnableDuplicateQuerySuppression,

        [Parameter()]
        [System.Boolean]
        $AllowCnameAtNs,

        [Parameter()]
        [System.Boolean]
        $EnableRsoForRodc,

        [Parameter()]
        [System.Boolean]
        $OpenAclOnProxyUpdates,

        [Parameter()]
        [System.Boolean]
        $NoUpdateDelegations,

        [Parameter()]
        [System.Boolean]
        $EnableUpdateForwarding,

        [Parameter()]
        [System.Boolean]
        $EnableWinsR,

        [Parameter()]
        [System.Boolean]
        $DeleteOutsideGlue,

        [Parameter()]
        [System.Boolean]
        $AppendMsZoneTransferTag,

        [Parameter()]
        [System.Boolean]
        $AllowReadOnlyZoneTransfer,

        [Parameter()]
        [System.Boolean]
        $EnableSendErrorSuppression,

        [Parameter()]
        [System.Boolean]
        $SilentlyIgnoreCnameUpdateConflicts,

        [Parameter()]
        [System.Boolean]
        $EnableIQueryResponseGeneration,

        [Parameter()]
        [System.Boolean]
        $AdminConfigured,

        [Parameter()]
        [System.Boolean]
        $PublishAutoNet,

        [Parameter()]
        [System.Boolean]
        $ReloadException,

        [Parameter()]
        [System.Boolean]
        $IgnoreServerLevelPolicies,

        [Parameter()]
        [System.Boolean]
        $IgnoreAllPolicies,

        [Parameter()]
        [System.UInt32]
        $EnableVersionQuery,

        [Parameter()]
        [System.UInt32]
        $AutoCreateDelegation,

        [Parameter()]
        [System.UInt32]
        $RemoteIPv4RankBoost,

        [Parameter()]
        [System.UInt32]
        $RemoteIPv6RankBoost,

        [Parameter()]
        [System.UInt32]
        $MaximumRodcRsoQueueLength,

        [Parameter()]
        [System.UInt32]
        $MaximumRodcRsoAttemptsPerCycle,

        [Parameter()]
        [System.UInt32]
        $MaxResourceRecordsInNonSecureUpdate,

        [Parameter()]
        [System.UInt32]
        $LocalNetPriorityMask,

        [Parameter()]
        [System.UInt32]
        $TcpReceivePacketSize,

        [Parameter()]
        [System.UInt32]
        $SelfTest,

        [Parameter()]
        [System.UInt32]
        $XfrThrottleMultiplier,

        [Parameter()]
        [System.UInt32]
        $SocketPoolSize,

        [Parameter()]
        [System.UInt32]
        $QuietRecvFaultInterval,

        [Parameter()]
        [System.UInt32]
        $QuietRecvLogInterval,

        [Parameter()]
        [System.UInt32]
        $SyncDsZoneSerial,

        [Parameter()]
        [System.UInt32]
        $ScopeOptionValue,

        [Parameter()]
        [System.UInt32]
        $VirtualizationInstanceOptionValue,

        [Parameter()]
        [System.String]
        $ServerLevelPluginDll,

        [Parameter()]
        [System.String]
        $RootTrustAnchorsURL,

        [Parameter()]
        [System.String[]]
        $SocketPoolExcludedPortRanges,

        [Parameter()]
        [System.String]
        $LameDelegationTTL,

        [Parameter()]
        [System.String]
        $MaximumSignatureScanPeriod,

        [Parameter()]
        [System.String]
        $MaximumTrustAnchorActiveRefreshInterval,

        [Parameter()]
        [System.String]
        $ZoneWritebackInterval
    )

    Assert-Module -ModuleName 'DnsServer'

    $PSBoundParameters.Remove('DnsServer')

    $dnsProperties = Remove-CommonParameter -Hashtable $PSBoundParameters

    $getDnServerSettingResult = Get-DnsServerSetting -All

    $propertiesInDesiredState = @()

    foreach ($property in $dnsProperties.keys)
    {
        if ($property -in ('ListeningIPAddress', 'SocketPoolExcludedPortRanges'))
        {
            # Compare array

            $compareObjectParameters = @{
                ReferenceObject  = $dnsProperties.$property
                DifferenceObject = $getDnServerSettingResult.$property
            }

            $isPropertyInDesiredState = -not (Compare-Object @compareObjectParameters)
        }
        else
        {
            $isPropertyInDesiredState = $dnsProperties.$property -eq $getDnServerSettingResult.$property
        }

        if ($isPropertyInDesiredState)
        {
            # Property in desired state.

            Write-Verbose -Message ($script:localizedData.PropertyInDesiredState -f $property)

            $propertiesInDesiredState += $property

        }
        else
        {
            # Property not in desired state.

            Write-Verbose -Message ($script:localizedData.SetDnsServerSetting -f $property, ($dnsProperties[$property] -join ', '))
        }
    }

    # Remove passed parameters that are in desired state.
    $propertiesInDesiredState | ForEach-Object -Process {
        $dnsProperties.Remove($_)
    }

    if ($dnsProperties.Keys.Count -eq 0)
    {
        Write-Verbose -Message $script:localizedData.SettingsInDesiredState
    }
    else
    {
        # Set all desired values for the properties that were not in desired state.
        $dnsProperties.Keys | ForEach-Object -Process {
            $property = $_

            if ($property -in $script:timeSpanProperties)
            {
                $timeSpan = New-TimeSpan

                <#
                    When this resource is converted to a class-based resource this should
                    be replaced by private function ConvertTo-TimeSpan.
                #>
                if (-not [System.TimeSpan]::TryParse($dnsProperties.$property, [ref] $timeSpan))
                {
                    throw ($script:localizedData.UnableToParseTimeSpan -f $dnsProperties.$property, $property )
                }

                $getDnServerSettingResult.$property = $timeSpan
            }
            else
            {
                $getDnServerSettingResult.$property = $dnsProperties.$property
            }
        }

        $setDnServerSettingParameters = @{
            ErrorAction = 'Stop'
        }

        if ($DnsServer -ne 'localhost')
        {
            $setDnServerSettingParameters['ComputerName'] = $DnsServer
        }

        $getDnServerSettingResult | Set-DnsServerSetting @setDnServerSettingParameters
    }
}

<#
    .SYNOPSIS
        Tests the desired state of the DNS server settings.

    .PARAMETER DnsServer
        Specifies the DNS server to connect to, or use 'localhost' for the current
        node.

    .PARAMETER AddressAnswerLimit
        Specifies the maximum number of A (host IP address) resource records that
        the DNS server can insert in the answer section of a response to an A record
        query (a query for an IP address). The value of this entry also influences
        the setting of the truncation bit. If the value of this entry can be between
        5 and 28, or 0. The truncation bit is not set on the response, even when the
        packet space is exceeded.

    .PARAMETER AllowUpdate
        Specifies whether the DNS Server accepts dynamic update requests. $true to
        allow any DNS update operation; otherwise, $false.

    .PARAMETER AutoCacheUpdate
        Specifies whether the DNS Server attempts to update its cache entries using
        data from root servers. $true to cache delegation information; otherwise,
        $false.

    .PARAMETER AutoConfigFileZones
        Specifies the type of zones for which SOA and NS records will be automatically
        configured with the DNS server's local host name as the primary DNS server for
        the zone when the zone is loaded from file.

    .PARAMETER BindSecondaries
        Specifies whether the server will permit send DNS zone transfer response
        messages with more than one record in each response if the zone transfer
        request did not have the characters MS appended to it. If set to $true,
        the DNS server will include only one record in each response if the zone
        transfer request did not have the characters MS appended to it.

    .PARAMETER BootMethod
        Specifies the boot method used by the DNS server.

    .PARAMETER DisableAutoReverseZone
        Specifies whether the DNS Server automatically creates standard reverse
        look up zones. $true to disables automatic reverse zones; otherwise, $false.

    .PARAMETER EnableDirectoryPartitions
        Specifies whether the DNS server will support application directory partitions.

    .PARAMETER EnableDnsSec
        Specifies whether the DNS Server includes DNSSEC-specific RRs, KEY, SIG,
        and NXT in a response. $true to enable DNSSEC validation on the DNS server;
        otherwise, $false.

    .PARAMETER ForwardDelegations
        Specifies how the DNS server will handle forwarding and delegations. If
        set to $true, the DNS server MUST use forwarders instead of a cached
        delegation when both are available. Otherwise, the DNS server MUST use a
        cached delegation instead of forwarders when both are available.

    .PARAMETER ListeningIPAddress
        Specifies the listening IP addresses of the DNS server. The list of IP
        addresses on which the DNS Server can receive queries.

    .PARAMETER LocalNetPriority
        Specifies whether the DNS Server gives priority to the local net address
        when returning A records. $true to return A records in order of their
        similarity to the IP address of the querying client.; otherwise, $false.

    .PARAMETER LooseWildcarding
        Specifies he type of algorithm that the DNS server will use to locate a
        wildcard node when using a DNS wildcard record RFC1034 to answer a query.
        If true, the DNS server will use the first node it encounters with a record
        of the same type as the query type. Otherwise, the DNS server will use the
        first node it encounters that has records of any type.

    .PARAMETER NameCheckFlag
        Specifies the level of domain name checking and validation on the DNS server,
        the set of eligible characters to be used in DNS names.

    .PARAMETER RoundRobin
        Specifies whether the DNS Server round robins multiple A records. $true to
        enable Round-robin DNS on the DNS server; otherwise, $false.

    .PARAMETER RpcProtocol
        Specifies the DNS_RPC_PROTOCOLS section 2.2.1.1.2 value corresponding to
        the RPC protocols to which the DNS server will respond. If this value is
        set to 0x00000000, the DNS server MUST NOT respond to RPC requests for
        any protocol.

    .PARAMETER SendPort
        Specifies the port number to use as the source port when sending UDP queries
        to a remote DNS server. If set to zero, the DNS server allow the stack to
        select a random port.

    .PARAMETER StrictFileParsing
        Specifies whether the DNS server will treat errors encountered while reading
        zones from a file as fatal.

    .PARAMETER UpdateOptions
        Specifies the DNS update options used by the DNS server.

    .PARAMETER WriteAuthorityNS
        Specifies whether the DNS server will include NS records for the root of a
        zone in DNS responses that are answered using authoritative zone data.

    .PARAMETER XfrConnectTimeout
        Specifies the time span, in seconds, in which a primary DNS server waits
        for a transfer response from its secondary server. The default value is 30.
        After the time-out value expires, the connection is terminated.

    .PARAMETER EnableIPv6
        Specifies whether IPv6 should be enabled on the DNS Server. $true to enable
        IPv6 on the DNS server; otherwise, $false.

    .PARAMETER EnableOnlineSigning
        Specifies whether online signing should be enabled on the DNS Server. $true
        to enable online signing; otherwise, $false.

    .PARAMETER EnableDuplicateQuerySuppression
        Specifies whether the DNS server will not send remote queries when there is
        already a remote query with the same name and query type outstanding.

    .PARAMETER AllowCnameAtNs
        Specifies whether the server will permit the target domain names of NS records
        to resolve to CNAME records. If $true, this pattern of DNS records will be
        allowed; otherwise, the DNS server will return errors when encountering this
        pattern of DNS records while resolving queries.

    .PARAMETER EnableRsoForRodc
        Specifies whether the DNS server will attempt to replicate single updated
        DNS objects from remote directory servers ahead of normally scheduled replication
        when operating on a directory server that does not support write operations.

    .PARAMETER OpenAclOnProxyUpdates
        Specifies whether the DNS server allows sharing of DNS records with the
        DnsUpdateProxy group when processing updates in secure zones that are stored
        in the directory service.

    .PARAMETER NoUpdateDelegations
        Specifies whether the DNS server will accept DNS updates to delegation
        records of type NS.

    .PARAMETER EnableUpdateForwarding
        Specifies whether the DNS server will forward updates received for secondary
        zones to the primary DNS server for the zone.

    .PARAMETER EnableWinsR
        Specifies whether the DNS server will perform NetBIOS name resolution in
        order to map IP addresses to machine names while processing queries in zones
        where WINS-R information has been configured.

    .PARAMETER DeleteOutsideGlue
        Specifies whether the DNS server will delete DNS glue records found outside
        a delegated subzone when reading records from persistent storage.

    .PARAMETER AppendMsZoneTransferTag
        Specifies whether the DNS server will indicate to the remote DNS servers
        that it supports multiple DNS records in each zone transfer response message
        by appending the characters MS at the end of zone transfer requests. The
        value SHOULD be limited to 0x00000000 and 0x0000000, but it MAY be any value.

    .PARAMETER AllowReadOnlyZoneTransfer
        Specifies whether the DNS server will allow zone transfers for zones that
        are stored in the directory server when the directory server does not support
        write operations.

    .PARAMETER EnableSendErrorSuppression
        Specifies whether the DNS server will attempt to suppress large volumes
        of DNS error responses sent to remote IP addresses that may be attempting
        to attack the DNS server.

    .PARAMETER SilentlyIgnoreCnameUpdateConflicts
        Specifies whether the DNS server will ignore CNAME conflicts during DNS
        update processing.

    .PARAMETER EnableIQueryResponseGeneration
        Specifies whether the DNS server will fabricate IQUERY responses. If set
        to $true, the DNS server MUST fabricate IQUERY responses when it receives
        queries of type IQUERY. Otherwise, the DNS server will return an error when
        such queries are received.

    .PARAMETER AdminConfigured
        Specifies whether the server has been configured by an administrator.

    .PARAMETER PublishAutoNet
        Specifies whether the DNS server will publish local IPv4 addresses in the
        169.254.x.x subnet as IPv4 addresses for the local machine's domain name.

    .PARAMETER ReloadException
        Specifies whether the DNS server will perform an internal restart if an
        unexpected fatal error is encountered.

    .PARAMETER IgnoreServerLevelPolicies
        Specifies whether to ignore the server level policies on the DNS server.
        $true to ignore the server level policies on the DNS server; otherwise,
        $false.

    .PARAMETER IgnoreAllPolicies
        Specifies whether to ignore all policies on the DNS server. $true to ignore
        all policies on the DNS server; otherwise, $false.

    .PARAMETER EnableVersionQuery
        Specifies what version information the DNS server will respond with when a
        DNS query with class set to CHAOS and type set to TXT is received.

    .PARAMETER AutoCreateDelegation
        Specifies possible settings for automatic delegation creation for new zones
        on the DNS server. The value SHOULD be limited to the range from 0x00000000
        to 0x00000002, inclusive, but it MAY be any value.

    .PARAMETER RemoteIPv4RankBoost
        Specifies the value to add to all IPv4 addresses for remote DNS servers when
        selecting between IPv4 and IPv6 remote DNS server addresses. The value MUST
        be limited to the range from 0x00000000 to 0x0000000A, inclusive.

    .PARAMETER RemoteIPv6RankBoost
        Specifies the value to add to all IPv6 addresses for remote DNS servers when
        selecting between IPv4 and IPv6 remote DNS server addresses. The value MUST
        be limited to the range from 0x00000000 to 0x0000000A, inclusive.

    .PARAMETER MaximumRodcRsoQueueLength
        Specifies the maximum number of single object replication operations that
        may be queued at any given time by the DNS server. The value MUST be limited
        to the range from 0x00000000 to 0x000F4240, inclusive. If the value is
        0x00000000 the DNS server MUST NOT enforce an upper bound on the number of
        single object replication operations queued at any given time.

    .PARAMETER MaximumRodcRsoAttemptsPerCycle
        Specifies the maximum number of queued single object replication operations
        that should be attempted during each five minute interval of DNS server
        operation. The value MUST be limited to the range from 0x00000001 to 0x000F4240,
        inclusive.

    .PARAMETER MaxResourceRecordsInNonSecureUpdate
        Specifies the maximum number of resource records that the DNS server will
        accept in a single DNS update request. The value SHOULD be limited to the
        range from 0x0000000A to 0x00000078, inclusive, but it MAY be any value.

    .PARAMETER LocalNetPriorityMask
        Specifies the value which specifies the network mask the DNS server will
        use to sort IPv4 addresses. A value of 0xFFFFFFFF indicates that the DNS
        server MUST use traditional IPv4 network mask for the address. Any other
        value is a network mask, in host byte order that the DNS server MUST use
        to retrieve network masks from IP addresses for sorting purposes.

    .PARAMETER TcpReceivePacketSize
        Specifies the maximum TCP packet size, in bytes, that the DNS server can
        accept. The value MUST be limited to the range from 0x00004000 to 0x00010000,
        inclusive.

    .PARAMETER SelfTest
        Specifies the mask value indicating whether data consistency checking
        should be performed once, each time the service starts. If the check fails,
        the server posts an event log warning. If the least significant bit (regardless
        of other bits) of this value is one, the DNS server will verify for each
        active and update-allowing primary zone, that the IP address records are
        present in the zone for the zone's SOA record's master server. If the
        least significant bit (regardless of other bits) of this value is zero,
        no data consistency checking will be performed.

    .PARAMETER XfrThrottleMultiplier
        Specifies the multiple used to determine how long the DNS server should
        refuse zone transfer requests after a successful zone transfer has been
        completed. The total time for which a zone will refuse another zone
        transfer request at the end of a successful zone transfer is computed as
        this value multiplied by the number of seconds required for the zone
        transfer that just completed. The server SHOULD refuse zone transfer
        requests for no more than ten minutes. The value SHOULD be limited to
        the range from 0x00000000 to 0x00000064, inclusive, but it MAY be any
        value.

    .PARAMETER SocketPoolSize
        Specifies the number of UDP sockets per address family that the DNS server
        will use for sending remote queries.

    .PARAMETER QuietRecvFaultInterval
        Specifies the minimum time interval, in seconds, starting when the server
        begins waiting for the query to arrive on the network, after which the
        server MAY log a debug message indicating that the server is to stop running.
        If the value is zero or is less than the value of QuietRecvLogInterval*,
        then the value of QuietRecvLogInterval MUST be used. If the value is
        greater than or equal to the value of QuietRecvLogInterval, then the
        literal value of QuietRecvFaultInterval MUST be used. Used to debug
        reception of UDP traffic for a recursive query.

    .PARAMETER QuietRecvLogInterval
        Specifies the minimum time interval, in seconds, starting when the server
        begins waiting for the query to arrive on the network, or when the server
        logs an eponymous debug message for the query, after which the server MUST
        log a debug message indicating that the server is still waiting to receive
        network traffic. If the value is zero, logging associated with the two
        QuietRecv properties MUST be disabled, and the QuietRecvFaultInterval
        property MUST be ignored. If the value is non-zero, logging associated with
        the two QuietRecv properties MUST be enabled, and the QuietRecvFaultInterval
        property MUST NOT be ignored. Used to debug reception of UDP traffic for a
        recursive query.

    .PARAMETER SyncDsZoneSerial
        Specifies the conditions under which the DNS server should immediately
        commit uncommitted zone serial numbers to persistent storage. The value
        SHOULD be limited to the range from 0x00000000 to 0x00000004, inclusive,
        but it MAY be any value.

    .PARAMETER ScopeOptionValue
        Specifies the extension mechanism for the DNS (ENDS0) scope setting on the
        DNS server.

    .PARAMETER VirtualizationInstanceOptionValue
        Specifies the virtualization instance option to be sent in ENDS0.

    .PARAMETER ServerLevelPluginDll
        Specifies the path of a custom plug-in. When DllPath specifies the fully
        qualified path name of a valid DNS server plug-in, the DNS server calls
        functions in the plug-in to resolve name queries that are outside the
        scope of all locally hosted zones. If a queried name is out of the scope
        of the plug-in, the DNS server performs name resolution using forwarding
        or recursion, as configured. If DllPath is not specified, the DNS server
        ceases to use a custom plug-in if a custom plug-in was previously configured.

    .PARAMETER RootTrustAnchorsURL
        Specifies the URL of the root trust anchor on the DNS server.

    .PARAMETER SocketPoolExcludedPortRanges
        Specifies the port ranges that should be excluded.

    .PARAMETER LameDelegationTTL
        Specifies the time span that must elapse before the DNS server will re-query
        DNS servers of the parent zone when a lame delegation is encountered. The
        value SHOULD be limited to the range from 0x00000000 to 0x00278D00 30 days,
        inclusive, but it MAY be any value.

    .PARAMETER MaximumSignatureScanPeriod
        Specifies the maximum period between zone scans to update DnsSec signatures
        for resource records.

    .PARAMETER MaximumTrustAnchorActiveRefreshInterval
        Specifies the maximum value for the active refresh interval for a trust
        anchor. Must not be higher than 15 days.

    .PARAMETER ZoneWritebackInterval
        Specifies the zone write back interval for file backed zones.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DnsServer,

        [Parameter()]
        [System.UInt32]
        $AddressAnswerLimit,

        [Parameter()]
        [System.Boolean]
        $AllowUpdate,

        [Parameter()]
        [System.Boolean]
        $AutoCacheUpdate,

        [Parameter()]
        [System.UInt32]
        $AutoConfigFileZones,

        [Parameter()]
        [System.Boolean]
        $BindSecondaries,

        [Parameter()]
        [System.UInt32]
        $BootMethod,

        [Parameter()]
        [System.Boolean]
        $DisableAutoReverseZone,

        [Parameter()]
        [System.Boolean]
        $EnableDirectoryPartitions,

        [Parameter()]
        [System.Boolean]
        $EnableDnsSec,

        [Parameter()]
        [System.Boolean]
        $ForwardDelegations,

        [Parameter()]
        [System.String[]]
        $ListeningIPAddress,

        [Parameter()]
        [System.Boolean]
        $LocalNetPriority,

        [Parameter()]
        [System.Boolean]
        $LooseWildcarding,

        [Parameter()]
        [System.UInt32]
        $NameCheckFlag,

        [Parameter()]
        [System.Boolean]
        $RoundRobin,

        [Parameter()]
        [System.UInt32]
        $RpcProtocol,

        [Parameter()]
        [System.UInt32]
        $SendPort,

        [Parameter()]
        [System.Boolean]
        $StrictFileParsing,

        [Parameter()]
        [System.UInt32]
        $UpdateOptions,

        [Parameter()]
        [System.Boolean]
        $WriteAuthorityNS,

        [Parameter()]
        [System.UInt32]
        $XfrConnectTimeout,

        [Parameter()]
        [System.Boolean]
        $EnableIPv6,

        [Parameter()]
        [System.Boolean]
        $EnableOnlineSigning,

        [Parameter()]
        [System.Boolean]
        $EnableDuplicateQuerySuppression,

        [Parameter()]
        [System.Boolean]
        $AllowCnameAtNs,

        [Parameter()]
        [System.Boolean]
        $EnableRsoForRodc,

        [Parameter()]
        [System.Boolean]
        $OpenAclOnProxyUpdates,

        [Parameter()]
        [System.Boolean]
        $NoUpdateDelegations,

        [Parameter()]
        [System.Boolean]
        $EnableUpdateForwarding,

        [Parameter()]
        [System.Boolean]
        $EnableWinsR,

        [Parameter()]
        [System.Boolean]
        $DeleteOutsideGlue,

        [Parameter()]
        [System.Boolean]
        $AppendMsZoneTransferTag,

        [Parameter()]
        [System.Boolean]
        $AllowReadOnlyZoneTransfer,

        [Parameter()]
        [System.Boolean]
        $EnableSendErrorSuppression,

        [Parameter()]
        [System.Boolean]
        $SilentlyIgnoreCnameUpdateConflicts,

        [Parameter()]
        [System.Boolean]
        $EnableIQueryResponseGeneration,

        [Parameter()]
        [System.Boolean]
        $AdminConfigured,

        [Parameter()]
        [System.Boolean]
        $PublishAutoNet,

        [Parameter()]
        [System.Boolean]
        $ReloadException,

        [Parameter()]
        [System.Boolean]
        $IgnoreServerLevelPolicies,

        [Parameter()]
        [System.Boolean]
        $IgnoreAllPolicies,

        [Parameter()]
        [System.UInt32]
        $EnableVersionQuery,

        [Parameter()]
        [System.UInt32]
        $AutoCreateDelegation,

        [Parameter()]
        [System.UInt32]
        $RemoteIPv4RankBoost,

        [Parameter()]
        [System.UInt32]
        $RemoteIPv6RankBoost,

        [Parameter()]
        [System.UInt32]
        $MaximumRodcRsoQueueLength,

        [Parameter()]
        [System.UInt32]
        $MaximumRodcRsoAttemptsPerCycle,

        [Parameter()]
        [System.UInt32]
        $MaxResourceRecordsInNonSecureUpdate,

        [Parameter()]
        [System.UInt32]
        $LocalNetPriorityMask,

        [Parameter()]
        [System.UInt32]
        $TcpReceivePacketSize,

        [Parameter()]
        [System.UInt32]
        $SelfTest,

        [Parameter()]
        [System.UInt32]
        $XfrThrottleMultiplier,

        [Parameter()]
        [System.UInt32]
        $SocketPoolSize,

        [Parameter()]
        [System.UInt32]
        $QuietRecvFaultInterval,

        [Parameter()]
        [System.UInt32]
        $QuietRecvLogInterval,

        [Parameter()]
        [System.UInt32]
        $SyncDsZoneSerial,

        [Parameter()]
        [System.UInt32]
        $ScopeOptionValue,

        [Parameter()]
        [System.UInt32]
        $VirtualizationInstanceOptionValue,

        [Parameter()]
        [System.String]
        $ServerLevelPluginDll,

        [Parameter()]
        [System.String]
        $RootTrustAnchorsURL,

        [Parameter()]
        [System.String[]]
        $SocketPoolExcludedPortRanges,

        [Parameter()]
        [System.String]
        $LameDelegationTTL,

        [Parameter()]
        [System.String]
        $MaximumSignatureScanPeriod,

        [Parameter()]
        [System.String]
        $MaximumTrustAnchorActiveRefreshInterval,

        [Parameter()]
        [System.String]
        $ZoneWritebackInterval
    )

    Write-Verbose -Message $script:localizedData.EvaluatingDnsServerSettings

    $currentState = Get-TargetResource -DnsServer $DnsServer

    $null = $PSBoundParameters.Remove('DnsServer')

    $result = $true

    # Returns an item for each property that is not in desired state.
    if (Compare-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters -Verbose:$VerbosePreference)
    {
        $result = $false
    }

    return $result
}
