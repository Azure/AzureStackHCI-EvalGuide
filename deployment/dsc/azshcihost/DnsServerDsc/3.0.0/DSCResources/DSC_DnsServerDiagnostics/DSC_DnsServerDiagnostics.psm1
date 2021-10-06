$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:dnsServerDscCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DnsServerDsc.Common'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:dnsServerDscCommonPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return a hashtable of results about DNS Diagnostics

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

    Write-Verbose -Message $script:localizedData.GettingDnsServerDiagnosticsMessage

    $getDnsServerDiagnosticsParameters = @{
        ErrorAction = 'Stop'
    }

    if ($DnsServer -ne 'localhost')
    {
        $getDnsServerDiagnosticsParameters['ComputerName'] = $DnsServer
    }

    $dnsServerDiagnostics = Get-DnsServerDiagnostics @getDnsServerDiagnosticsParameters

    $returnValue = @{
        DnsServer                            = $DnsServer
        Answers                              = $dnsServerDiagnostics.Answers
        EnableLogFileRollover                = $dnsServerDiagnostics.EnableLogFileRollover
        EnableLoggingForLocalLookupEvent     = $dnsServerDiagnostics.EnableLoggingForLocalLookupEvent
        EnableLoggingForPluginDllEvent       = $dnsServerDiagnostics.EnableLoggingForPluginDllEvent
        EnableLoggingForRecursiveLookupEvent = $dnsServerDiagnostics.EnableLoggingForRecursiveLookupEvent
        EnableLoggingForRemoteServerEvent    = $dnsServerDiagnostics.EnableLoggingForRemoteServerEvent
        EnableLoggingForServerStartStopEvent = $dnsServerDiagnostics.EnableLoggingForServerStartStopEvent
        EnableLoggingForTombstoneEvent       = $dnsServerDiagnostics.EnableLoggingForTombstoneEvent
        EnableLoggingForZoneDataWriteEvent   = $dnsServerDiagnostics.EnableLoggingForZoneDataWriteEvent
        EnableLoggingForZoneLoadingEvent     = $dnsServerDiagnostics.EnableLoggingForZoneLoadingEvent
        EnableLoggingToFile                  = $dnsServerDiagnostics.EnableLoggingToFile
        EventLogLevel                        = $dnsServerDiagnostics.EventLogLevel
        FilterIPAddressList                  = $dnsServerDiagnostics.FilterIPAddressList
        FullPackets                          = $dnsServerDiagnostics.FullPackets
        LogFilePath                          = $dnsServerDiagnostics.LogFilePath
        MaxMBFileSize                        = $dnsServerDiagnostics.MaxMBFileSize
        Notifications                        = $dnsServerDiagnostics.Notifications
        Queries                              = $dnsServerDiagnostics.Queries
        QuestionTransactions                 = $dnsServerDiagnostics.QuestionTransactions
        ReceivePackets                       = $dnsServerDiagnostics.ReceivePackets
        SaveLogsToPersistentStorage          = $dnsServerDiagnostics.SaveLogsToPersistentStorage
        SendPackets                          = $dnsServerDiagnostics.SendPackets
        TcpPackets                           = $dnsServerDiagnostics.TcpPackets
        UdpPackets                           = $dnsServerDiagnostics.UdpPackets
        UnmatchedResponse                    = $dnsServerDiagnostics.UnmatchedResponse
        Update                               = $dnsServerDiagnostics.Update
        UseSystemEventLog                    = $dnsServerDiagnostics.UseSystemEventLog
        WriteThrough                         = $dnsServerDiagnostics.WriteThrough
    }

    return $returnValue
}

<#
    .SYNOPSIS
        This will set the desired state

    .PARAMETER DnsServer
        Specifies the DNS server to connect to, or use 'localhost' for the current
        node.

    .PARAMETER Answers
        Specifies whether to enable the logging of DNS responses.

    .PARAMETER EnableLogFileRollover
        Specifies whether to enable log file rollover.

    .PARAMETER EnableLoggingForLocalLookupEvent
        Specifies whether the DNS server logs local lookup events.

    .PARAMETER EnableLoggingForPluginDllEvent
        Specifies whether the DNS server logs dynamic link library (DLL) plug-in events.

    .PARAMETER EnableLoggingForRecursiveLookupEvent
        Specifies whether the DNS server logs recursive lookup events.

    .PARAMETER EnableLoggingForRemoteServerEvent
        Specifies whether the DNS server logs remote server events.

    .PARAMETER EnableLoggingForServerStartStopEvent
        Specifies whether the DNS server logs server start and stop events.

    .PARAMETER EnableLoggingForTombstoneEvent
        Specifies whether the DNS server logs tombstone events.

    .PARAMETER EnableLoggingForZoneDataWriteEvent
        Specifies Controls whether the DNS server logs zone data write events.

    .PARAMETER EnableLoggingForZoneLoadingEvent
        Specifies whether the DNS server logs zone load events.

    .PARAMETER EnableLoggingToFile
        Specifies whether the DNS server logs logging-to-file.

    .PARAMETER EventLogLevel
        Specifies an event log level. Valid values are Warning, Error, and None.

    .PARAMETER FilterIPAddressList
        Specifies an array of IP addresses to filter. When you enable logging, traffic to and from these IP addresses is logged. If you do not specify any IP addresses, traffic to and from all IP addresses is logged.

    .PARAMETER FullPackets
        Specifies whether the DNS server logs full packets.

    .PARAMETER LogFilePath
        Specifies a log file path.

    .PARAMETER MaxMBFileSize
        Specifies the maximum size of the log file. This parameter is relevant if you set EnableLogFileRollover and EnableLoggingToFile to $True.

    .PARAMETER Notifications
        Specifies whether the DNS server logs notifications.

    .PARAMETER Queries
        Specifies whether the DNS server allows query packet exchanges to pass through the content filter, such as the IPFilterList parameter.

    .PARAMETER QuestionTransactions
        Specifies whether the DNS server logs queries.

    .PARAMETER ReceivePackets
        Specifies whether the DNS server logs receive packets.

    .PARAMETER SaveLogsToPersistentStorage
        Specifies whether the DNS server saves logs to persistent storage.

    .PARAMETER SendPackets
        Specifies whether the DNS server logs send packets.

    .PARAMETER TcpPackets
        Specifies whether the DNS server logs TCP packets.

    .PARAMETER UdpPackets
        Specifies whether the DNS server logs UDP packets.

    .PARAMETER UnmatchedResponse
        Specifies whether the DNS server logs unmatched responses.

    .PARAMETER Update
        Specifies whether the DNS server logs updates.

    .PARAMETER UseSystemEventLog
        Specifies whether the DNS server uses the system event log for logging.

    .PARAMETER WriteThrough
        Specifies whether the DNS server logs write-throughs.
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
        [Boolean]
        $Answers,

        [Parameter()]
        [Boolean]
        $EnableLogFileRollover,

        [Parameter()]
        [Boolean]
        $EnableLoggingForLocalLookupEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForPluginDllEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForRecursiveLookupEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForRemoteServerEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForServerStartStopEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForTombstoneEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForZoneDataWriteEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForZoneLoadingEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingToFile,

        [Parameter()]
        [UInt32]
        $EventLogLevel,

        [Parameter()]
        [String[]]
        $FilterIPAddressList,

        [Parameter()]
        [Boolean]
        $FullPackets,

        [Parameter()]
        [System.String]
        $LogFilePath,

        [Parameter()]
        [UInt32]
        $MaxMBFileSize,

        [Parameter()]
        [Boolean]
        $Notifications,

        [Parameter()]
        [Boolean]
        $Queries,

        [Parameter()]
        [Boolean]
        $QuestionTransactions,

        [Parameter()]
        [Boolean]
        $ReceivePackets,

        [Parameter()]
        [Boolean]
        $SaveLogsToPersistentStorage,

        [Parameter()]
        [Boolean]
        $SendPackets,

        [Parameter()]
        [Boolean]
        $TcpPackets,

        [Parameter()]
        [Boolean]
        $UdpPackets,

        [Parameter()]
        [Boolean]
        $UnmatchedResponse,

        [Parameter()]
        [Boolean]
        $Update,

        [Parameter()]
        [Boolean]
        $UseSystemEventLog,

        [Parameter()]
        [Boolean]
        $WriteThrough
    )

    $PSBoundParameters.Remove('DnsServer')

    $setDnsServerDiagnosticsParameters = Remove-CommonParameter -Hashtable $PSBoundParameters
    $setDnsServerDiagnosticsParameters['ErrorAction'] = 'Stop'

    if ($DnsServer -ne 'localhost')
    {
        $setDnsServerDiagnosticsParameters['ComputerName'] = $DnsServer
    }

    Write-Verbose -Message $script:localizedData.SettingDnsServerDiagnosticsMessage

    Set-DnsServerDiagnostics @setDnsServerDiagnosticsParameters
}

<#
    .SYNOPSIS
        This will set the desired state

    .PARAMETER DnsServer
        Specifies the DNS server to connect to, or use 'localhost' for the current
        node.

    .PARAMETER Answers
        Specifies whether to enable the logging of DNS responses.

    .PARAMETER EnableLogFileRollover
        Specifies whether to enable log file rollover.

    .PARAMETER EnableLoggingForLocalLookupEvent
        Specifies whether the DNS server logs local lookup events.

    .PARAMETER EnableLoggingForPluginDllEvent
        Specifies whether the DNS server logs dynamic link library (DLL) plug-in events.

    .PARAMETER EnableLoggingForRecursiveLookupEvent
        Specifies whether the DNS server logs recursive lookup events.

    .PARAMETER EnableLoggingForRemoteServerEvent
        Specifies whether the DNS server logs remote server events.

    .PARAMETER EnableLoggingForServerStartStopEvent
        Specifies whether the DNS server logs server start and stop events.

    .PARAMETER EnableLoggingForTombstoneEvent
        Specifies whether the DNS server logs tombstone events.

    .PARAMETER EnableLoggingForZoneDataWriteEvent
        Specifies Controls whether the DNS server logs zone data write events.

    .PARAMETER EnableLoggingForZoneLoadingEvent
        Specifies whether the DNS server logs zone load events.

    .PARAMETER EnableLoggingToFile
        Specifies whether the DNS server logs logging-to-file.

    .PARAMETER EventLogLevel
        Specifies an event log level. Valid values are Warning, Error, and None.

    .PARAMETER FilterIPAddressList
        Specifies an array of IP addresses to filter. When you enable logging, traffic to and from these IP addresses is logged. If you do not specify any IP addresses, traffic to and from all IP addresses is logged.

    .PARAMETER FullPackets
        Specifies whether the DNS server logs full packets.

    .PARAMETER LogFilePath
        Specifies a log file path.

    .PARAMETER MaxMBFileSize
        Specifies the maximum size of the log file. This parameter is relevant if you set EnableLogFileRollover and EnableLoggingToFile to $True.

    .PARAMETER Notifications
        Specifies whether the DNS server logs notifications.

    .PARAMETER Queries
        Specifies whether the DNS server allows query packet exchanges to pass through the content filter, such as the IPFilterList parameter.

    .PARAMETER QuestionTransactions
        Specifies whether the DNS server logs queries.

    .PARAMETER ReceivePackets
        Specifies whether the DNS server logs receive packets.

    .PARAMETER SaveLogsToPersistentStorage
        Specifies whether the DNS server saves logs to persistent storage.

    .PARAMETER SendPackets
        Specifies whether the DNS server logs send packets.

    .PARAMETER TcpPackets
        Specifies whether the DNS server logs TCP packets.

    .PARAMETER UdpPackets
        Specifies whether the DNS server logs UDP packets.

    .PARAMETER UnmatchedResponse
        Specifies whether the DNS server logs unmatched responses.

    .PARAMETER Update
        Specifies whether the DNS server logs updates.

    .PARAMETER UseSystemEventLog
        Specifies whether the DNS server uses the system event log for logging.

    .PARAMETER WriteThrough
        Specifies whether the DNS server logs write-throughs.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DnsServer,

        [Parameter()]
        [Boolean]
        $Answers,

        [Parameter()]
        [Boolean]
        $EnableLogFileRollover,

        [Parameter()]
        [Boolean]
        $EnableLoggingForLocalLookupEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForPluginDllEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForRecursiveLookupEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForRemoteServerEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForServerStartStopEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForTombstoneEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForZoneDataWriteEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingForZoneLoadingEvent,

        [Parameter()]
        [Boolean]
        $EnableLoggingToFile,

        [Parameter()]
        [UInt32]
        $EventLogLevel,

        [Parameter()]
        [String[]]
        $FilterIPAddressList,

        [Parameter()]
        [Boolean]
        $FullPackets,

        [Parameter()]
        [System.String]
        $LogFilePath,

        [Parameter()]
        [UInt32]
        $MaxMBFileSize,

        [Parameter()]
        [Boolean]
        $Notifications,

        [Parameter()]
        [Boolean]
        $Queries,

        [Parameter()]
        [Boolean]
        $QuestionTransactions,

        [Parameter()]
        [Boolean]
        $ReceivePackets,

        [Parameter()]
        [Boolean]
        $SaveLogsToPersistentStorage,

        [Parameter()]
        [Boolean]
        $SendPackets,

        [Parameter()]
        [Boolean]
        $TcpPackets,

        [Parameter()]
        [Boolean]
        $UdpPackets,

        [Parameter()]
        [Boolean]
        $UnmatchedResponse,

        [Parameter()]
        [Boolean]
        $Update,

        [Parameter()]
        [Boolean]
        $UseSystemEventLog,

        [Parameter()]
        [Boolean]
        $WriteThrough
    )

    Write-Verbose -Message $script:localizedData.EvaluatingDnsServerDiagnosticsMessage

    $currentState = Get-TargetResource -DnsServer $DnsServer

    $null = $PSBoundParameters.Remove('DnsServer')

    $result = Test-DscDnsParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters -TurnOffTypeChecking -Verbose:$VerbosePreference

    return $result
}

Export-ModuleMember -Function *-TargetResource
