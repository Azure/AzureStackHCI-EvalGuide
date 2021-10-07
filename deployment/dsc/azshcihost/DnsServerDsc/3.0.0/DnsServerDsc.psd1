@{
    # Version number of this module.
    moduleVersion     = '3.0.0'

    # ID used to uniquely identify this module
    GUID              = '5f70e6a1-f1b2-4ba0-8276-8967d43a7ec2'

    # Author of this module
    Author            = 'DSC Community'

    # Company or vendor of this module
    CompanyName       = 'DSC Community'

    # Copyright statement for this module
    Copyright         = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'This module contains DSC resources for the management and configuration of Windows Server DNS Server.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Script module or binary module file associated with this manifest.
    RootModule = 'DnsServerDsc.psm1'

    # Functions to export from this module
    FunctionsToExport = @()

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    DscResourcesToExport = @('DnsRecordCname','DnsRecordPtr','DnsRecordA','DnsRecordAaaa','DnsRecordCnameScoped','DnsRecordMx','DnsRecordNs','DnsRecordSrv','DnsServerCache','DnsServerDsSetting','DnsServerEDns','DnsServerRecursion','DnsServerScavenging','DnsRecordAaaaScoped','DnsRecordAScoped','DnsRecordMxScoped','DnsRecordNsScoped','DnsRecordSrvScoped','DnsServerADZone','DnsServerClientSubnet','DnsServerConditionalForwarder','DnsServerDiagnostics','DnsServerForwarder','DnsServerPrimaryZone','DnsServerRootHint','DnsServerSecondaryZone','DnsServerSetting','DnsServerSettingLegacy','DnsServerZoneAging','DnsServerZoneScope','DnsServerZoneTransfer')

    <#
      Private data to pass to the module specified in RootModule/ModuleToProcess.
      This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    #>
    PrivateData       = @{
        PSData = @{
            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = ''

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/dsccommunity/DnsServerDsc/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/dsccommunity/DnsServerDsc'

            # A URL to an icon representing this module.
            IconUri = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [3.0.0] - 2021-05-26

### Removed

- xDnsRecord
  - BREAKING CHANGE: The resource has been replaced by _DnsServerA_, _DnsServerPtr_,
  and _DnsServerCName_ ([issue #221](https://github.com/dsccommunity/DnsServerDsc/issues/221)).
- xDnsServerMx
  - BREAKING CHANGE: The resource has been replaced by _DnsServerMx_ ([issue #228](https://github.com/dsccommunity/DnsServerDsc/issues/228)).
- DnsServerSetting
  - BREAKING CHANGE: The properties `Forwarders` and `ForwardingTimeout` has
    been removed ([issue #192](https://github.com/dsccommunity/DnsServerDsc/issues/192)).
    Use the resource _DnsServerForwarder_ to enforce these properties.
  - BREAKING CHANGE: The properties `EnableEDnsProbes` and `EDnsCacheTimeout` has
    been removed ([issue #195](https://github.com/dsccommunity/DnsServerDsc/issues/195)).
    Use the resource _DnsServerEDns_ to enforce these properties.
  - BREAKING CHANGE: The properties `SecureResponses`, `MaxCacheTTL`, and
    `MaxNegativeCacheTTL` has been removed ([issue #197](https://github.com/dsccommunity/DnsServerDsc/issues/197)).
    To enforce theses properties, use resource _DnsServerEDns_ using the
    properties `EnablePollutionProtection`, `MaxTtl`, and `MaxNegativeTtl`
    respectively.
  - BREAKING CHANGE: The properties `DefaultAgingState`, `ScavengingInterval`,
    `DefaultNoRefreshInterval`, and `DefaultRefreshInterval` have been removed.
    Use the resource _DnsServerScavenging_ to enforce this properties ([issue #193](https://github.com/dsccommunity/DnsServerDsc/issues/193)).
  - BREAKING CHANGE: The properties `NoRecursion`, `RecursionRetry`, and
    `RecursionTimeout` has been removed ([issue #200](https://github.com/dsccommunity/DnsServerDsc/issues/200)).
    To enforce theses properties, use resource _DnsServerRecursion_ using the
    properties `Enable`, `RetryInterval`, and `Timeout` respectively.
  - BREAKING CHANGE: A few properties that are not supported by any DNS
    Server PowerShell cmdlet was moved to the new resource _DnsServerSettingLegacy_.
  - BREAKING CHANGE: The properties `DsPollingInterval` and `DsTombstoneInterval`
    has been removed ([issue #252](https://github.com/dsccommunity/DnsServerDsc/issues/252)).
    Use the resource _DnsServerDsSetting_ to enforce these properties.

- ResourceBase
  - For the method `Get()` the overload that took a `[Microsoft.Management.Infrastructure.CimInstance]`
    was removed as it is not the correct pattern going forward.

### Added

- DnsServerDsc
  - Added new resource
    - _DnsServerCache_ - resource to enforce cache settings ([issue #196](https://github.com/dsccommunity/DnsServerDsc/issues/196)).
    - _DnsServerRecursion_ - resource to enforce recursion settings ([issue #198](https://github.com/dsccommunity/DnsServerDsc/issues/198)).
  - Added new private function `Get-ClassName` that returns the class name
    or optionally an array with the class name and all inherited base class
    named.
  - Added new private function `Get-LocalizedDataRecursive` that gathers
    all localization strings from an array of class names. This can be used
    in classes to be able to inherit localization strings from one or more
    base class. If a localization string key exist in a parent class''s
    localization string file it will override the localization string key
    in any base class.
  - Fixed code coverage in the pipeline ([issue #246](https://github.com/dsccommunity/DnsServerDsc/issues/246)).
- ResourceBase
  - Added new method `Assert()` tha calls `Assert-Module` and `AssertProperties()`.
- DnsRecordNs
  - Added new resource to manage NS records
- DnsRecordNsScoped
  - Added new resource to manage scoped NS records
- DnsServerDsSetting
  - Added new resource to manage AD-integrated DNS settings
- DnsServerSettingLegacy
  - A new resource to manage legacy DNS Server settings that are not supported
    by any DNS Server PowerShell cmdlet.

### Changed

- DnsServerDsc
  - BREAKING CHANGE: Renamed the module to DnsServerDsc ([issue #179](https://github.com/dsccommunity/DnsServerDsc/issues/179)).
  - BREAKING CHANGE: Removed the prefix ''x'' from all MOF-based resources
    ([issue #179](https://github.com/dsccommunity/DnsServerDsc/issues/179)).
  - Renamed a MOF-based resource to use the prefix ''DSC'' ([issue #225](https://github.com/dsccommunity/DnsServerDsc/issues/225)).
  - Fix stub `Get-DnsServerResourceRecord` so it throws if it is not mocked
    correctly ([issue #204](https://github.com/dsccommunity/DnsServerDsc/issues/204)).
  - Switch the order in the deploy pipeline so that creating the GitHub release
    is made after a successful release.
  - Updated stub functions to throw if they are used (when missing a mock in
    unit test) ([issue #235](https://github.com/dsccommunity/DnsServerDsc/issues/235)).
- ResourceBase
  - Added support for inherit localization strings and also able to override
    a localization string that exist in a base class.
  - Moved more logic from the resources into the base class for the method
    `Test()`, `Get()`, and `Set()`. The base class now have three methods
    `AssertProperties()`, `Modify()`, and `GetCurrentState()` where the
    two latter ones must be overridden by a resource if calling the base
    methods `Set()` and `Get()`.
  - Moved the `Assert-Module` from the constructor to a new method `Assert()`
    that is called from `Get()`, `Test()`, and `Set()`. The method `Assert()`
    also calls the method `AssertProperties()`. The method `Assert()` is not
    meant to be overridden, but can if there is a reason not to run
    `Assert-Module` and or `AssertProperties()`.
- Integration tests
  - Added commands in the DnsRecord* integration tests to wait for the LCM
    before moving to the next test.
- DnsServerCache
  - Moved to the same coding pattern as _DnsServerRecursion_.
- DnsServerEDns
  - Moved to the same coding pattern as _DnsServerRecursion_.
- DnsServerScavenging
  - Moved to the same coding pattern as _DnsServerRecursion_.
- DnsServerSetting
  - Changed to use `Get-DnsServerSetting` and `Set-DnsServerSetting`
    ([issue #185](https://github.com/dsccommunity/xDnsServer/issues/185)).
  - BREAKING CHANGE: The property `DisableAutoReverseZones` have been renamed
    to `DisableAutoReverseZone`.
  - BREAKING CHANGE: The property `ListenAddresses` have been renamed
    to `ListeningIPAddress`.
  - BREAKING CHANGE: The property `AllowUpdate` was changed to a boolean
    value (`$true` or `$false`) since that is what the cmdlet `Set-DnsServerSetting`
    is expecting (related to [issue #101](https://github.com/dsccommunity/xDnsServer/issues/101)).
  - BREAKING CHANGE: The property `EnableDnsSec` was changed to a boolean
    value (`$true` or `$false`) since that is what the cmdlet `Set-DnsServerSetting`
    is expecting.
  - BREAKING CHANGE: The property `ForwardDelegations` was changed to a boolean
    value (`$true` or `$false`) since that is what the cmdlet `Set-DnsServerSetting`
    is expecting.

### Fixed

- Logic bug in DnsRecordPtr.expandIPv6String($string) (#255)
  - Supporting tests added

'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}




