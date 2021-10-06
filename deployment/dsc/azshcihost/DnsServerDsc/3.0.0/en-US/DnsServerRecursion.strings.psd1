<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DnsServerRecursion.
#>

ConvertFrom-StringData @'
    GetCurrentState = Getting the current state of the recursion settings for the server '{0}'. (DSR0001)
    TestDesiredState = Determining the current state of the recursion settings for the server '{0}'. (DSR0002)
    SetDesiredState = Setting the desired state for the recursion settings for the server '{0}'. (DSR0003)
    NotInDesiredState = The recursion settings for the server '{0}' is not in desired state. (DSR0004)
    InDesiredState = The recursion settings for the server '{0}' is in desired state. (DSR0005)
    SetProperty = The recursion property '{0}' will be set to '{1}'. (DSR0006)
    PropertyIsNotInValidRange = The property '{0}' has the value '{1}' that is not within the range of 1 seconds to 15 seconds. (DSR0007)
'@
