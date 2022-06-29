# Localized resources for en-US.

ConvertFrom-StringData @'
    SettingExclusionRange   = Setting DHCP server exclusion range with StartRange "{0}" EndRange "{1}" for ScopeId "{2}".
    TestingExclusionRange   = Testing DHCP server exclusion scopeId '{0}'.
    RemovingExclusionRange  = Removing DHCP server exclusion StartRange "{0}" EndRange "{1}" for ScopeId "{2}".
    InvalidStartAndEndRange = StartRange must be less than EndRange.
    NotInDesiredState       = DHCP server scope "{0}" is NOT in desired state. Expected "{1}", actual "{2}".
    InDesiredState          = DHCP server scope "{0}" is in desired state.
    RetrievingExclusion     = Getting the current state of the scope id '{0}'.
    FoundExclusion          = Found exclusion with StartRange "{0}" and EndRange "{1}".
    ExclusionNotFound       = Exclusion with StartRange "{0}" and EndRange "{1}" not found.
'@
