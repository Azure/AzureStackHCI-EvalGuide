@{
    # Version number of this module.
    moduleVersion     = '3.1.0'

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
            LicenseUri   = 'https://github.com/dsccommunity/xDhcpServer/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/dsccommunity/xDhcpServer'

            # A URL to an icon representing this module.
            IconUri = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = ''
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
