<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DnsRecordMx.
#>

ConvertFrom-StringData @'
    GettingDnsRecordMessage   = Getting specified DNS {0} record in zone '{1}' from '{3}'.
    CreatingDnsRecordMessage  = Creating {0} record specified in zone '{1}' on '{3}'.
    DomainZoneMismatch        = Email domain '{0}' must be the same as the zone specified ('{1}') or a subdomain thereof.
'@
