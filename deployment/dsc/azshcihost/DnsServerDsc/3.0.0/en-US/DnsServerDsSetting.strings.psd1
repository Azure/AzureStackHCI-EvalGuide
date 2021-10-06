<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DnsServerDsSetting.
#>

ConvertFrom-StringData @'
    GetCurrentState = Getting the current state of the directory services settings for the server '{0}'. (DSDS0001)
    TestDesiredState = Determining the current state of the directory services settings for the server '{0}'. (DSDS0002)
    SetDesiredState = Setting the desired state for the directory services settings for the server '{0}'. (DSDS0003)
    NotInDesiredState = The directory services settings for the server '{0}' is not in desired state. (DSDS0004)
    InDesiredState = The directory services settings for the server '{0}' is in desired state. (DSDS0005)
    SetProperty = The directory services property '{0}' will be set to '{1}'. (DSDS0006)
'@
