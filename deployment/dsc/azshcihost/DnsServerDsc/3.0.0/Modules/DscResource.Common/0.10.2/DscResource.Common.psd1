@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'DscResource.Common.psm1'

    # Version number of this module.
    ModuleVersion     = '0.10.2'

    # ID used to uniquely identify this module
    GUID              = '9c9daa5b-5c00-472d-a588-c96e8e498450'

    # Author of this module
    Author            = 'DSC Community'

    # Company or vendor of this module
    CompanyName       = 'DSC Community'

    # Copyright statement for this module
    Copyright         = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Common functions used in DSC Resources'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('Assert-BoundParameter','Assert-IPAddress','Assert-Module','Compare-DscParameterState','Compare-ResourcePropertyState','ConvertTo-CimInstance','ConvertTo-HashTable','Get-ComputerName','Get-LocalizedData','Get-TemporaryFolder','New-InvalidArgumentException','New-InvalidDataException','New-InvalidOperationException','New-InvalidResultException','New-NotImplementedException','New-ObjectNotFoundException','Remove-CommonParameter','Set-DscMachineRebootRequired','Set-PSModulePath','Test-DscParameterState','Test-IsNanoServer')

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DSC', 'Localization')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/dsccommunity/DscResource.Common/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/dsccommunity/DscResource.Common'

            # A URL to an icon representing this module.
            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [0.10.2] - 2021-03-24

### Changed

- DscResource.Common
  - Renamed default branch to `main` - fixes [issue #62](https://github.com/dsccommunity/DscResource.Common/issues/62).
  - Changed to use the new GitHub deploy tasks.
- `Assert-Module`
  - Now it possible to forcibly import a module using `-ImportModule -Force`
  - It no longer outputs verbose messages that is normally generated when
    using `Get-Module -ListAvailable` if the module that is asserted is
    already in the session ([issue #66](https://github.com/dsccommunity/DscResource.Common/issues/66)).
- `Compare-DscParameterState`
  - Fix verbose message to only show when using parameter `IncludeInDesiredState`.
    Also made the verbose message more intuitive when the value being compared
    was a `[System.Boolean]`.

'

            Prerelease   = ''
        } # End of PSData hashtable

    } # End of PrivateData hashtable
}




