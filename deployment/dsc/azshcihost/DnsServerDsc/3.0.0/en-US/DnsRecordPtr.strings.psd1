<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DnsRecordPtr.
#>

ConvertFrom-StringData @'
    GettingDnsRecordMessage   = Getting specified DNS {0} record in zone '{1}' from '{3}'.
    CreatingDnsRecordMessage  = Creating {0} record specified in zone '{1}' on '{3}'.
    NotAnIPv4Zone             = The zone "{0}" is not an IPv4 reverse lookup zone.
    NotAnIPv6Zone             = The zone "{0}" is not an IPv6 reverse lookup zone.
    WrongZone                 = "{0}" does not belong to the "{1}" zone.
'@
