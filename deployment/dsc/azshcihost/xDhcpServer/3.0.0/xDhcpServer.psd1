@{
    # Version number of this module.
    moduleVersion     = '3.0.0'

    # ID used to uniquely identify this module
    GUID              = '286890c9-a6c3-4605-9cd5-03c8413c8325'

    # Author of this module
    Author            = 'DSC Community'

    # Company or vendor of this module
    CompanyName       = 'DSC Community'

    # Copyright statement for this module
    Copyright         = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'This module contains DSC resources for deployment and configuration of Microsoft DHCP Server.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Functions to export from this module
    FunctionsToExport = @()

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    DscResourcesToExport = @('DhcpPolicyOptionValue','DhcpReservedIPOptionValue','DhcpScopeOptionValue','DhcpServerOptionValue','xDhcpServerAuthorization','xDhcpServerClass','xDhcpServerOptionDefinition','xDhcpServerReservation','xDhcpServerScope','DhcpServerBinding','DhcpServerExclusionRange')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = ''

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/dsccommunity/xDhcpServer/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/dsccommunity/xDhcpServer'

            # A URL to an icon representing this module.
            IconUri = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [3.0.0] - 2021-01-25

### Added

- xDhcpServer
  - Added automatic release with a new CI pipeline ([issue #59](https://github.com/dsccommunity/xDhcpServer/issues/59)).
  - Conceptual help is now generated for each resource on build.
  - Added new resource DhcpServerBinding ([issue #55](https://github.com/dsccommunity/xDhcpServer/issues/55)).
  - Added new resource DhcpServerExclusionRange ([issue #7](https://github.com/dsccommunity/xDhcpServer/issues/7)).

### Changed

- xDhcpServer
  - BREAKING CHANGE: The minimum PowerShell version is 5.0.
- xDhcpServerAuthorization
  - BREAKING CHANGE: The resource is now a single instance resource so
    that it is only possible to use the resource once in a configuration
    with the parameter `Ensure` set to either `Present` or `Absent`
    ([issue #40](https://github.com/dsccommunity/xDhcpServer/issues/40)).
  - The helper function `Get-IPv4Address` was changed from using `Get-WmiObject`
    to `Get-CimInstance` when fetching the enabled IP addresses.
- xDhcpServerOptionDefinition
  - The logic in `Test-TargetResource` was changed somewhat to remove
    unnecessary evaluation of properties that `Get-TargetResource` already
    did. The function `Get-TargetResource` calls `Get-DhcpServerv4OptionDefinition`
    with `OptionId` and `VendorClass` and if an object is returned the property
    `Ensure` is set to `''Present''`, so there are no point for `Test-TargetResource`
    to evaluate those two properties again.
  - Added unit tests for the function `Test-TargetResource`.
  - Reordered the resources in alphabetical order in the README.md.

### Removed

- BREAKING CHANGE: Removed the deprecated resource xDhcpServerOption which
  has been replaced by other DSC resources ([issue #46](https://github.com/dsccommunity/xDhcpServer/issues/46)).
- Removed the file `TestSampleUsingAzure.ps1` as it was not a working example
  of running integration tests.

#'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}











