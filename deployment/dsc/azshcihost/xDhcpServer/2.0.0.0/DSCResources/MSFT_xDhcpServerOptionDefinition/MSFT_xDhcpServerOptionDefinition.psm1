Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Localized messages
data LocalizedData
{
    # Culture="en-US"
    ConvertFrom-StringData @'
    GettingOptionDefinitionIDMessage     = Getting DHCP server option definition "{0}" with vendor class "{1}".
    TestingOptionDefinitionIDMessage     = Begin testing DHCP server option definition "{0}" with vendor class "{1}".
    RemovingOptionDefinitionIDMessage    = Removing DHCP server option definition "{0}" with vendor class "{1}".
    RecreatingOptionDefinitionIDMessage  = Recreating DHCP server option definition "{0}" with vendor class "{1}".
    AddingOptionDefinitionIDMessage      = Adding DHCP server option definition "{0}" with vendor class "{1}".
    SettingOptionDefinitionIDMessage     = Setting DHCP server option definition "{0}" with vendor class "{1}".
    FoundOptionDefinitionIDMessage       = Found DHCP server option Definition "{0}" with vendor class "{1}".
    NotFoundOptionDefinitionIDMessage    = Cannot find DHCP server option Definition "{0}" with vendor class "{1}".
    ComparingOptionDefinitionIDMessage   = Comparing option definition "{0}", vendor class "{1}" with existing definition.
    ExactMatchOptionDefinitionIDMessage  = Matched option definition "{0}" with vendor class "{1}" with existing definition.
    NotMatchOptionDefinitionIDMessage    = Not matched all parameters in option definition "{0}" with vendor class "{1}", should adjust.
'@
}
  
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
        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [Validaterange(1,255)]
        [UInt32]
        $OptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Byte','Word','Dword','DwordDword','IPv4Address','String','BinaryData','EncapsulatedData')]
        [String]
        $Type,
                
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [String]
        $AddressFamily
    )

    # Region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -ModuleName DHCPServer

    # Endregion Input Validation

    $gettingIDMessage = $localizedData.GettingOptionDefinitionIDMessage -f $OptionId, $VendorClass
    Write-Verbose -Message $gettingIDMessage     
    $dhcpServerOptionDefinition = Get-DhcpServerv4OptionDefinition -OptionId $OptionId -VendorClass $VendorClass -ErrorAction SilentlyContinue
  
    if ($dhcpServerOptionDefinition)
    {
        $hashTable = @{
            OptionId       = $dhcpServerOptionDefinition.OptionId
            Name           = $dhcpServerOptionDefinition.Name
            AddressFamily  = $AddressFamily
            Description    = $dhcpServerOptionDefinition.Description
            Type           = $dhcpServerOptionDefinition.Type
            VendorClass    = $dhcpServerOptionDefinition.VendorClass
            MultiValued    = $dhcpServerOptionDefinition.MultiValued
            Ensure         = 'Present'
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
            MultiValued   = $null
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

    .PARAMETER Multivalued
        Whether the option definition is multivalued or not.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.

#>

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [Validaterange(1,255)]
        [UInt32]
        $OptionId,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,
        
        [Parameter()]
        [AllowEmptyString()]
        [String]
        $Description,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Byte','Word','Dword','DwordDword','IPv4Address','String','BinaryData','EncapsulatedData')]
        [String]
        $Type,

        [Parameter()]
        [Boolean]
        $MultiValued,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [String]
        $AddressFamily
    )
        
    # Reading the DHCP option
    $dhcpServerOptionDefinition = Get-TargetResource -OptionId $OptionId -Name $Name -VendorClass $VendorClass -Type $Type -AddressFamily $AddressFamily -ErrorAction SilentlyContinue

    # Testing for present
    if ($Ensure -eq 'Present')
    {
        # Testing if option exists
        if ($dhcpServerOptionDefinition.Ensure -eq 'Present')
        {
            # If it exists and any of multivalued, type or vendorclass is being changed remove then re-add the whole option definition
            if (($dhcpServerOptionDefinition.Type -ne $Type) -or ($dhcpServerOptionDefinition.MultiValued -ne $MultiValued) -or ($dhcpServerOptionDefinition.VendorClass -ne $VendorClass))
            {
                $scopeIDMessage = $localizedData.RecreatingOptionDefinitionIDMessage -f $OptionId, $VendorClass
                Write-Verbose -Message $scopeIDMessage
                Remove-DhcpServerv4OptionDefinition -OptionId $OptionId -VendorClass $VendorClass
                Add-DhcpServerv4OptionDefinition -OptionId $OptionId -name $Name -Type $Type -Description $Description -MultiValued:$MultiValued -VendorClass $VendorClass
            }
            # If option exists we need only to adjust the parameters
            else
            {
                $settingIDMessage = $localizedData.SettingOptionDefinitionIDMessage -f $OptionId, $VendorClass
                Write-Verbose -Message $settingIDMessage
                Set-DhcpServerv4OptionDefinition -OptionId $OptionId -VendorClass $VendorClass -name $Name -Description $Description
            }
        }
        # If option does not exist we need to add it
        else
        {
            $scopeIDMessage = $localizedData.AddingOptionDefinitionIDMessage -f $OptionId, $VendorClass
            Write-Verbose -Message $scopeIDMessage
            Add-DhcpServerv4OptionDefinition -OptionId $OptionId -name $Name -Type $Type -Description $Description -MultiValued:$MultiValued -VendorClass $VendorClass
        }
    }
    # Testing for 'absent'
    else
    {
        if ($dhcpServerOptionDefinition)
        {
            $scopeIDMessage = $localizedData.RemovingOptionDefinitionIDMessage -f $OptionId,$VendorClass
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

    .PARAMETER Multivalued
        Whether the option definition is multivalued or not.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.

#>

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Ensure = 'Present',
        
        [Parameter(Mandatory = $true)]
        [Validaterange(1,255)]
        [UInt32] $OptionId,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter()]
        [AllowEmptyString()]
        [String]
        $Description,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Byte','Word','Dword','DwordDword','IPv4Address','String','BinaryData','EncapsulatedData')]
        [String]
        $Type,

        [Parameter()]
        [Boolean]
        $MultiValued,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [String]
        $AddressFamily
    )
    
    # Region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -ModuleName DHCPServer
    # Endregion Input Validation

    $testingIDMessage = $localizedData.TestingOptionDefinitionIDMessage -f $OptionId, $VendorClass
    # Geting the dhcp option definition
    Write-Verbose -Message $testingIDMessage

    $currentConfiguration = Get-TargetResource -OptionId $OptionId -Name $Name -VendorClass $VendorClass -Type $Type -AddressFamily $AddressFamily -ErrorAction SilentlyContinue
    
    if ($currentConfiguration.Ensure -eq 'Present')
    {
        $foundIDMessage = $localizedData.FoundOptionDefinitionIDMessage -f $OptionId, $VendorClass
        Write-Verbose $foundIDMessage
    }
    else
    {
        $notFoundIDMessage = $localizedData.NotFoundOptionDefinitionIDMessage -f $OptionId, $VendorClass
        Write-Verbose $notFoundIDMessage
    }


    # Testing for Ensure = Present
    if ($Ensure -eq 'Present')
    {
        # Testing if $OptionId and VendorClass already exist       
        if ($currentConfiguration.Ensure -eq 'Present')
        {
            $comparingIDMessage = $localizedData.ComparingOptionDefinitionIDMessage -f $OptionId, $VendorClass
            Write-Verbose $comparingIDMessage
            
            # Since $OptionId and $VendorClass exist compare all the Values
            if (($currentConfiguration.OptionId -eq $OptionId) -and ($currentConfiguration.Name -eq $Name) -and ($currentConfiguration.Description -eq $Description) -and ($currentConfiguration.VendorClass -eq $VendorClass) -and ($currentConfiguration.Type -eq $Type) -and ($currentConfiguration.MultiValued -eq $MultiValued))
            {
                $exactMatchIDMessage = $localizedData.ExactMatchOptionDefinitionIDMessage -f $OptionId, $VendorClass
                Write-Verbose $exactMatchIDMessage
                $result = $true
            }
            else
            {
                $notMatchIDMessage = $localizedData.NotMatchOptionDefinitionIDMessage -f $OptionId, $VendorClass
                Write-Verbose $notMatchIDMessage
                $result = $false            
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
