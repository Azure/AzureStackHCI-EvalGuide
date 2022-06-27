$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DscResource.Common'
$script:moduleHelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DhcpServerDsc.Common'

Import-Module -Name $script:resourceHelperModulePath
Import-Module -Name $script:moduleHelperPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
   .SYNOPSIS
        This function gets a DHCP option definition.

    .PARAMETER Ensure
        When set to 'Present', the option definition will be created.
        When set to 'Absent', the option definition will be removed.

    .PARAMETER OptionId
        The ID of the option definition.

    .PARAMETER Name
        The name of the option definition.

    .PARAMETER VendorClass
        The vendor class of the option definition. Use an empty string for standard class.

    .PARAMETER Type
        The data type of the option definition.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 255)]
        [System.UInt32]
        $OptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Byte', 'Word', 'Dword', 'DwordDword', 'IPv4Address', 'String', 'BinaryData', 'EncapsulatedData')]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily
    )

    # Region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -ModuleName DHCPServer

    # Endregion Input Validation

    $gettingIDMessage = $script:localizedData.GettingOptionDefinitionIDMessage -f $OptionId, $VendorClass
    Write-Verbose -Message $gettingIDMessage

    $dhcpServerOptionDefinition = Get-DhcpServerv4OptionDefinition -OptionId $OptionId -VendorClass $VendorClass -ErrorAction 'SilentlyContinue'

    if ($dhcpServerOptionDefinition)
    {
        $hashTable = @{
            OptionId      = $dhcpServerOptionDefinition.OptionId
            Name          = $dhcpServerOptionDefinition.Name
            AddressFamily = $AddressFamily
            Description   = $dhcpServerOptionDefinition.Description
            Type          = $dhcpServerOptionDefinition.Type
            VendorClass   = $dhcpServerOptionDefinition.VendorClass
            MultiValued   = $dhcpServerOptionDefinition.MultiValued
            DefaultValue  = $dhcpServerOptionDefinition.DefaultValue
            Ensure        = 'Present'
        }
    }
    else
    {
        $hashTable = @{
            OptionId      = $null
            Name          = $null
            AddressFamily = $null
            Description   = $null
            Type          = $null
            VendorClass   = $null
            MultiValued   = $false
            DefaultValue  = $null
            Ensure        = 'Absent'
        }
    }

    $hashTable
}

<#
    .SYNOPSIS
        This function sets the state of a DHCP option definition.

    .PARAMETER Ensure
        When set to 'Present', the option definition will be created.
        When set to 'Absent', the option definition will be removed.

    .PARAMETER OptionId
        The ID of the option definition.

    .PARAMETER Name
        The name of the option definition.

    .PARAMETER Description
        Description of the option definition.

    .PARAMETER VendorClass
        The vendor class of the option definition. Use an empty string for standard class.

    .PARAMETER Type
        The data type of the option definition.

    .PARAMETER MultiValued
        Whether the option definition is multi-valued or not.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.

    .PARAMETER DefaultValue
        Specifies the default value to set for the option definition.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 255)]
        [System.UInt32]
        $OptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $Description,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Byte', 'Word', 'Dword', 'DwordDword', 'IPv4Address', 'String', 'BinaryData', 'EncapsulatedData')]
        [System.String]
        $Type,

        [Parameter()]
        [System.Boolean]
        $MultiValued,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily,

        [Parameter()]
        [System.String]
        $DefaultValue
    )

    # Reading the DHCP option
    $dhcpServerOptionDefinition = Get-TargetResource -OptionId $OptionId -Name $Name -VendorClass $VendorClass -Type $Type -AddressFamily $AddressFamily -ErrorAction 'SilentlyContinue'

    # Testing for present
    if ($Ensure -eq 'Present')
    {
        # Testing if option exists
        if ($dhcpServerOptionDefinition.Ensure -eq 'Present')
        {
            # If it exists and any of multi-valued, type or vendor class is being changed remove then re-add the whole option definition
            if (($dhcpServerOptionDefinition.Type -ne $Type) -or ($dhcpServerOptionDefinition.MultiValued -ne $MultiValued) -or ($dhcpServerOptionDefinition.VendorClass -ne $VendorClass))
            {
                $scopeIDMessage = $script:localizedData.RecreatingOptionDefinitionIDMessage -f $OptionId, $VendorClass
                Write-Verbose -Message $scopeIDMessage

                Remove-DhcpServerv4OptionDefinition -OptionId $OptionId -VendorClass $VendorClass

                $addDhcpServerv4OptionDefinitionParameters = @{
                    OptionId = $OptionId
                    Name = $Name
                    Type = $Type
                    Description = $Description
                    MultiValued = $MultiValued
                    VendorClass = $VendorClass
                }

                if ($PSBoundParameters.ContainsKey('DefaultValue'))
                {
                    $addDhcpServerv4OptionDefinitionParameters.DefaultValue = $DefaultValue
                }

                Add-DhcpServerv4OptionDefinition @addDhcpServerv4OptionDefinitionParameters
            }
            # If option exists we need only to adjust the parameters
            else
            {
                $settingIDMessage = $script:localizedData.SettingOptionDefinitionIDMessage -f $OptionId, $VendorClass
                Write-Verbose -Message $settingIDMessage

                $setDhcpServerv4OptionDefinitionParameters = @{
                    OptionId = $OptionId
                    Name = $Name
                    Description = $Description
                    VendorClass = $VendorClass
                }

                if ($PSBoundParameters.ContainsKey('DefaultValue'))
                {
                    $setDhcpServerv4OptionDefinitionParameters.DefaultValue = $DefaultValue
                }

                Set-DhcpServerv4OptionDefinition @setDhcpServerv4OptionDefinitionParameters
            }
        }
        # If option does not exist we need to add it
        else
        {
            $scopeIDMessage = $script:localizedData.AddingOptionDefinitionIDMessage -f $OptionId, $VendorClass
            Write-Verbose -Message $scopeIDMessage

            $addDhcpServerv4OptionDefinitionParameters = @{
                OptionId = $OptionId
                Name = $Name
                Type = $Type
                Description = $Description
                MultiValued = $MultiValued
                VendorClass = $VendorClass
            }

            if ($PSBoundParameters.ContainsKey('DefaultValue'))
            {
                $addDhcpServerv4OptionDefinitionParameters.DefaultValue = $DefaultValue
            }

            Add-DhcpServerv4OptionDefinition @addDhcpServerv4OptionDefinitionParameters
        }
    }
    # Testing for 'absent'
    else
    {
        if ($dhcpServerOptionDefinition)
        {
            $scopeIDMessage = $script:localizedData.RemovingOptionDefinitionIDMessage -f $OptionId, $VendorClass
            Write-Verbose -Message $scopeIDMessage

            Remove-DhcpServerv4OptionDefinition -OptionId $OptionId -VendorClass $VendorClass
        }
    }
}

<#
    .SYNOPSIS
        This function tests if the DHCP option definition is created.

    .PARAMETER Ensure
        When set to 'Present', the option definition will be created.
        When set to 'Absent', the option definition will be removed.

    .PARAMETER OptionId
        The ID of the option definition.

    .PARAMETER Name
        The name of the option definition.

    .PARAMETER Description
        Description of the option definition.

    .PARAMETER VendorClass
        The vendor class of the option definition. Use an empty string for standard class.

    .PARAMETER Type
        The data type of the option definition.

    .PARAMETER MultiValued
        Whether the option definition is multivalued or not.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.

    .PARAMETER DefaultValue
        Specifies the default value to set for the option definition.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 255)]
        [System.UInt32]
        $OptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $Description,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Byte', 'Word', 'Dword', 'DwordDword', 'IPv4Address', 'String', 'BinaryData', 'EncapsulatedData')]
        [System.String]
        $Type,

        [Parameter()]
        [System.Boolean]
        $MultiValued,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily,

        [Parameter()]
        [System.String]
        $DefaultValue
    )

    # Region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -ModuleName DHCPServer
    # Endregion Input Validation

    $testingIDMessage = $script:localizedData.TestingOptionDefinitionIDMessage -f $OptionId, $VendorClass
    # Geting the dhcp option definition
    Write-Verbose -Message $testingIDMessage

    $currentConfiguration = Get-TargetResource -OptionId $OptionId -Name $Name -VendorClass $VendorClass -Type $Type -AddressFamily $AddressFamily -ErrorAction 'SilentlyContinue'

    if ($currentConfiguration.Ensure -eq 'Present')
    {
        $foundIDMessage = $script:localizedData.FoundOptionDefinitionIDMessage -f $OptionId, $VendorClass
        Write-Verbose $foundIDMessage
    }
    else
    {
        $notFoundIDMessage = $script:localizedData.NotFoundOptionDefinitionIDMessage -f $OptionId, $VendorClass
        Write-Verbose $notFoundIDMessage
    }


    # Testing for Ensure = Present
    if ($Ensure -eq 'Present')
    {
        # Testing if $OptionId and VendorClass already exist
        if ($currentConfiguration.Ensure -eq 'Present')
        {
            $comparingIDMessage = $script:localizedData.ComparingOptionDefinitionIDMessage -f $OptionId, $VendorClass
            Write-Verbose $comparingIDMessage

            <#
                The parameter $OptionId and $VendorClass is in desired state since
                Get-TargetResource returned Ensure property as 'Present'. The rest
                of the parameters need to be evaluated if they that they are in desired
                state.
            #>
            $propertiesToEvaluate = @('Name', 'Description', 'Type', 'MultiValued', 'DefaultValue')

            $result = $true

            foreach ($property in $propertiesToEvaluate)
            {
                # Only evaluate if the configuration passed the parameter.
                if ($PSBoundParameters.ContainsKey($property))
                {
                    $desiredParameterValue = Get-Variable -Name $property -ValueOnly

                    if ($property -eq 'DefaultValue')
                    {
                        # Force string comparison, else get mixed results with DefaultValue property
                        if ([System.String] $currentConfiguration.$property -ne [System.String] $desiredParameterValue)
                        {
                            $result = $false
                        }
                    }
                    else
                    {
                        if ($currentConfiguration.$property -ne $desiredParameterValue)
                        {
                            $result = $false
                        }
                    }
                }
            }

            if ($result)
            {
                $exactMatchIDMessage = $script:localizedData.ExactMatchOptionDefinitionIDMessage -f $OptionId, $VendorClass
                Write-Verbose $exactMatchIDMessage
            }
            else
            {
                $notMatchIDMessage = $script:localizedData.NotMatchOptionDefinitionIDMessage -f $OptionId, $VendorClass
                Write-Verbose $notMatchIDMessage
            }
        }
        else
        {
            # Since $OptionId and $VendorClass do not exist return $false
            $result = $false
        }
    }
    # If Ensure = Absent
    else
    {
        if ($currentConfiguration.Ensure -eq 'Present')
        {
            # Since desired state is 'Absent' and $OptionId and $VendorClass exist return $false
            $result = $false
        }
        else
        {
            # Since desired state is 'Absent' and $OptionId and $VendorClass do not exist return $true
            $result = $true
        }
    }
    $result
}
