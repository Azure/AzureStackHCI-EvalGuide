<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DnsServerCache.
#>

ConvertFrom-StringData @'
    GetCurrentState = Getting the current state of the cache settings for the server '{0}'. (DSC0001)
    TestDesiredState = Determining the current state of the cache settings for the server '{0}'. (DSC0002)
    SetDesiredState = Setting the desired state for the cache settings for the server '{0}'. (DSC0003)
    NotInDesiredState = The cache settings for the server '{0}' is not in desired state. (DSC0004)
    InDesiredState = The cache settings for the server '{0}' is in desired state. (DSC0005)
    SetProperty = The cache property '{0}' will be set to '{1}'. (DSC0006)
'@
