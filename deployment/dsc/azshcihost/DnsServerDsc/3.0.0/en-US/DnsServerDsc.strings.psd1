<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DnsServerDsc module. This file should only contain
        localized strings for private and public functions.
#>

ConvertFrom-StringData @'
    PropertyHasWrongFormat = The property '{0}' has the value '{1}' that cannot be converted to [System.TimeSpan]. (DS0001)
    TimeSpanExceedMaximumValue = The property '{0}' has the value '{1}' that exceeds the maximum value of '{2}'. (DS0002)
    TimeSpanBelowMinimumValue = The property '{0}' has the value '{1}' that is below the minimum value of '{2}'. (DS0003)
'@
