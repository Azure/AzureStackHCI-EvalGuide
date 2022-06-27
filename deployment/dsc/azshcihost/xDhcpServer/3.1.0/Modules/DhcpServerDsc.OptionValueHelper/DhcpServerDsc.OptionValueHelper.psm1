$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DscResource.Common'

Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Helper function to get a DHCP option value.

    .PARAMETER ApplyTo
        Specify where to get the DHCP option from.

    .PARAMETER OptionId
        The option ID.

    .PARAMETER VendorClass
        The option vendor class. Use an empty string for standard class.

    .PARAMETER UserClass
        The option user class.

    .PARAMETER ScopeId
        If used, the option scope ID.

    .PARAMETER PolicyName
        If used, the option policy name.

    .PARAMETER ReservedIP
        If used, the option reserved IP.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.
#>
function Get-TargetResourceHelper
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Server', 'Scope', 'Policy', 'ReservedIP')]
        [System.String]
        $ApplyTo,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.UInt32]
        $OptionId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $UserClass,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $ScopeId,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $PolicyName,

        [Parameter()]
        [AllowNull()]
        [System.Net.IPAddress]
        $ReservedIP,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily
    )

    #region Input Validation

    # Check for DhcpServer module/role.
    Assert-Module -ModuleName 'DHCPServer'

    #endregion Input Validation

    # Checking if option needs to be configured for server, DHCP scope, Policy or reservedIP
    switch ($ApplyTo)
    {
        'Server'
        {
            # Getting the dhcp server option Value
            $serverGettingValueMessage = $script:localizedData.ServerGettingValueMessage -f $OptionId, $VendorClass, $UserClass
            Write-Verbose $serverGettingValueMessage

            $parameters = @{
                OptionId    = $OptionId
                VendorClass = $VendorClass
                userClass   = $UserClass
            }
            $currentConfiguration = Get-DhcpServerv4OptionValue @parameters -ErrorAction 'SilentlyContinue'
        }

        'Scope'
        {
            # Getting the dhcp server option Value
            $scopeGettingValueMessage = $script:localizedData.ScopeGettingValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId
            Write-Verbose $scopeGettingValueMessage

            $parameters = @{
                OptionId    = $OptionId
                ScopeId     = $ScopeId
                VendorClass = $VendorClass
                UserClass   = $UserClass
            }
            $currentConfiguration = Get-DhcpServerv4OptionValue @parameters -ErrorAction 'SilentlyContinue'
        }

        'Policy'
        {
            # Getting the dhcp policy option Value
            $policyGettingValueMessage = $script:localizedData.PolicyGettingValueMessage -f $OptionId, $VendorClass, $ScopeId, $PolicyName
            Write-Verbose $policyGettingValueMessage

            # Policy can exist on server or scope level, so we need to address both cases
            if ($ScopeId)
            {
                $parameters = @{
                    PolicyName  = $PolicyName
                    OptionId    = $OptionId
                    VendorClass = $VendorClass
                    ScopeId     = $ScopeId
                }
                $currentConfiguration = Get-DhcpServerv4OptionValue @parameters -ErrorAction 'SilentlyContinue'
            }
            else
            {
                $parameters = @{
                    PolicyName  = $PolicyName
                    OptionId    = $OptionId
                    VendorClass = $VendorClass
                }
                $currentConfiguration = Get-DhcpServerv4OptionValue @parameters -ErrorAction 'SilentlyContinue'
            }
        }

        'ReservedIP'
        {
            # Getting the dhcp reserved IP option Value
            $reservedIPGettingValueMessage = $script:localizedData.ReservedIPGettingValueMessage -f $OptionId, $VendorClass, $PolicyName, $ReservedIP
            Write-Verbose $reservedIPGettingValueMessage

            $parameters = @{
                ReservedIP  = $ReservedIP
                OptionId    = $OptionId
                VendorClass = $VendorClass
                UserClass   = $UserClass
            }
            $currentConfiguration = Get-DhcpServerv4OptionValue @parameters -ErrorAction 'SilentlyContinue'
        }
    }

    # Testing for null
    if ($currentConfiguration)
    {
        $hashTable = @{
            ApplyTo       = $ApplyTo
            OptionId      = $currentConfiguration.OptionID
            Value         = $currentConfiguration.Value
            VendorClass   = $currentConfiguration.VendorClass
            UserClass     = $currentConfiguration.UserClass
            ScopeId       = $currentConfiguration.ScopeId
            PolicyName    = $currentConfiguration.PolicyName
            ReservedIP    = $currentConfiguration.ReservedIP
            AddressFamily = $AddressFamily
            Ensure        = 'Present'
        }
    }
    else
    {
        $hashTable = @{
            ApplyTo       = $null
            OptionId      = $null
            Value         = $null
            VendorClass   = $null
            UserClass     = $null
            ScopeId       = $null
            PolicyName    = $null
            ReservedIP    = $null
            AddressFamily = $null
            Ensure        = 'Absent'
        }
    }

    $hashTable
}

<#
    .SYNOPSIS
        Helper function to test a DHCP option value.

    .PARAMETER ApplyTo
        Specify where to test the DHCP option.

    .PARAMETER OptionId
        The option ID.

    .PARAMETER Value
        The option data value.

    .PARAMETER VendorClass
        The option vendor class. Use an empty string for standard class.

    .PARAMETER UserClass
        The option user class.

    .PARAMETER ScopeId
        If used, the option scope ID.

    .PARAMETER PolicyName
        If used, the option policy name.

    .PARAMETER ReservedIP
        If used, the option reserved IP.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.

    .PARAMETER Ensure
        When set to 'Present', the option will be created.
        When set to 'Absent', the option will be removed.
#>
function Test-TargetResourceHelper
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Server', 'Scope', 'Policy', 'ReservedIP')]
        [System.String]
        $ApplyTo,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.UInt32]
        $OptionId,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Value,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $UserClass,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $ScopeId,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $PolicyName,

        [Parameter()]
        [AllowNull()]
        [System.Net.IPAddress]
        $ReservedIP,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    # Checking if option needs to be configured for server, DHCP scope, Policy or reservedIP
    switch ($ApplyTo)
    {
        'Server'
        {
            # Trying to get the option value
            $parameters = @{
                OptionId      = $OptionId
                VendorClass   = $VendorClass
                UserClass     = $UserClass
                AddressFamily = $AddressFamily
            }
            $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Server' @parameters
            # Testing for Ensure = Present
            if ($Ensure -eq 'Present')
            {
                # Since we need to compare an array of strings we need to use the Compare-Object cmdlet
                if (($currentConfiguration.Ensure -eq 'Present') -and (@(Compare-Object -ReferenceObject $currentConfiguration.Value -DifferenceObject $Value -SyncWindow 0 -CaseSensitive).Length -eq 0))
                {
                    # Found an exact match
                    $serverExactMatchValueMessage = $script:localizedData.ServerExactMatchValueMessage -f $OptionId, $VendorClass, $UserClass
                    Write-Verbose $serverExactMatchValueMessage
                    $result = $true
                }
                else
                {
                    # Not found Option Value
                    $serverNotFoundValueMessage = $script:localizedData.ServerNotFoundValueMessage -f $OptionId, $VendorClass, $UserClass
                    Write-Verbose $serverNotFoundValueMessage
                    $result = $false
                }
            }
            # Ensure = 'Absent'
            else
            {
                if ($currentConfiguration.Ensure -eq 'Present')
                {
                    # Found a match, should return $false since it should not be here
                    $serverFoundAndRemoveValueMessage = $script:localizedData.ServerFoundAndRemoveValueMessage -f $OptionId, $VendorClass, $UserClass
                    Write-Verbose $serverFoundAndRemoveValueMessage
                    $result = $false
                }
                else
                {
                    # Not found Option Value, return $true
                    $serverNotFoundDoNothingValueMessage = $script:localizedData.ServerNotFoundDoNothingValueMessage -f $OptionId, $VendorClass, $UserClass
                    Write-Verbose $serverNotFoundDoNothingValueMessage
                    $result = $true
                }
            }
        }

        'Scope'
        {
            # Trying to get the option value
            $parameters = @{
                ScopeId       = $ScopeId
                OptionId      = $OptionId
                VendorClass   = $VendorClass
                UserClass     = $UserClass
                AddressFamily = $AddressFamily
            }
            $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Scope' @parameters
            # Testing for Ensure = Present
            if ($Ensure -eq 'Present')
            {
                if (($currentConfiguration.Ensure -eq 'Present') -and (@(Compare-Object -ReferenceObject $currentConfiguration.Value -DifferenceObject $Value -SyncWindow 0 -CaseSensitive).Length -eq 0))
                {
                    # Found an exact match
                    $scopeExactMatchValueMessage = $script:localizedData.ScopeExactMatchValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId
                    Write-Verbose $scopeExactMatchValueMessage
                    $result = $true
                }
                else
                {
                    # Not found Option Value
                    $scopeNotFoundValueMessage = $script:localizedData.ScopeNotFoundValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId
                    Write-Verbose $scopeNotFoundValueMessage
                    $result = $false
                }
            }

            # Ensure = 'Absent'
            else
            {
                if (($currentConfiguration.Ensure -eq 'Present'))
                {
                    # Found a match, should return $false since it should not be here
                    $scopeFoundAndRemoveValueMessage = $script:localizedData.ScopeFoundAndRemoveValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId
                    Write-Verbose $scopeFoundAndRemoveValueMessage
                    $result = $false
                }
                else
                {
                    # Not found Option Value, return $true
                    $scopeNotFoundDoNothingValueMessage = $script:localizedData.ScopeNotFoundDoNothingValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId
                    Write-Verbose $scopeNotFoundDoNothingValueMessage
                    $result = $true
                }
            }
        }

        'Policy'
        {
            # Trying to get the option value
            $parameters = @{
                PolicyName    = $PolicyName
                OptionId      = $OptionId
                ScopeId       = $ScopeId
                VendorClass   = $VendorClass
                UserClass     = $UserClass
                AddressFamily = $AddressFamily
            }
            $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Policy' @parameters
            # Testing for Ensure = Present
            if ($Ensure -eq 'Present')
            {
                if (($currentConfiguration.Ensure -eq 'Present') -and (@(Compare-Object -ReferenceObject $currentConfiguration.Value -DifferenceObject $Value -SyncWindow 0 -CaseSensitive).Length -eq 0))
                {
                    # Found an exact match
                    $policyExactMatchValueMessage = $script:localizedData.PolicyExactMatchValueMessage -f $OptionId, $VendorClass, $PolicyName
                    Write-Verbose $policyExactMatchValueMessage
                    $result = $true
                }
                else
                {
                    # Not found Option Value
                    $policyNotFoundValueMessage = $script:localizedData.PolicyNotFoundValueMessage -f $OptionId, $VendorClass, $PolicyName
                    Write-Verbose $policyNotFoundValueMessage
                    $result = $false
                }
            }

            # Ensure = 'Absent'
            else
            {
                if (($currentConfiguration.Ensure -eq 'Present'))
                {
                    # Found a match, should return $false since it should not be here
                    $policyFoundAndRemoveValueMessage = $script:localizedData.PolicyFoundAndRemoveValueMessage -f $OptionId, $VendorClass, $PolicyName
                    Write-Verbose $policyFoundAndRemoveValueMessage
                    $result = $false
                }
                else
                {
                    # Not found Option Value, return $true
                    $policyNotFoundDoNothingValueMessage = $script:localizedData.PolicyNotFoundDoNothingValueMessage -f $OptionId, $VendorClass, $PolicyName
                    Write-Verbose $policyNotFoundDoNothingValueMessage
                    $result = $true
                }
            }
        }

        'ReservedIP'
        {
            # Trying to get the option value
            $parameters = @{
                ReservedIP    = $ReservedIP
                OptionId      = $OptionId
                VendorClass   = $VendorClass
                UserClass     = $UserClass
                AddressFamily = $AddressFamily
            }
            $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'ReservedIP' @parameters
            # Testing for Ensure = Present
            if ($Ensure -eq 'Present')
            {
                # Comparing only the data value, since we already found an option ID that matchs the other parameters
                if (($currentConfiguration.Ensure -eq 'Present') -and (@(Compare-Object -ReferenceObject $currentConfiguration.Value -DifferenceObject $Value -SyncWindow 0 -CaseSensitive).Length -eq 0))
                {
                    # Found an exact match
                    $reservedIPExactMatchValueMessage = $script:localizedData.ReservedIPExactMatchValueMessage -f $OptionId, $VendorClass, $UserClass, $ReservedIP
                    Write-Verbose $reservedIPExactMatchValueMessage
                    $result = $true
                }
                else
                {
                    # Not found Option Value
                    $reservedIPNotFoundValueMessage = $script:localizedData.ReservedIPNotFoundValueMessage -f $OptionId, $VendorClass, $UserClass, $ReservedIP
                    Write-Verbose $reservedIPNotFoundValueMessage
                    $result = $false
                }
            }

            # Ensure = 'Absent'
            else
            {
                if ($currentConfiguration.Ensure -eq 'Present')
                {
                    # Found a match, should return $false since it should not be here
                    $reservedIPFoundAndRemoveValueMessage = $script:localizedData.ReservedIPFoundAndRemoveValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId, $ReservedIP
                    Write-Verbose $reservedIPFoundAndRemoveValueMessage
                    $result = $false
                }
                else
                {
                    # Not found Option Value, return $true
                    $reservedIPNotFoundDoNothingValueMessage = $script:localizedData.ReservedIPNotFoundDoNothingValueMessage -f $OptionId, $VendorClass, $UserClass, $scopeId, $ReservedIP
                    Write-Verbose $reservedIPNotFoundDoNothingValueMessage
                    $result = $true
                }
            }
        }
    }

    $result
}

<#
    .SYNOPSIS
        Helper function to set a DHCP option value.

    .PARAMETER ApplyTo
        Specify where to set the DHCP option.

    .PARAMETER OptionId
        The option ID.

    .PARAMETER Value
        The option data value.

    .PARAMETER VendorClass
        The option vendor class. Use an empty string for standard class.

    .PARAMETER UserClass
        The option user class.

    .PARAMETER ScopeId
        If used, the option scope ID.

    .PARAMETER PolicyName
        If used, the option policy name.

    .PARAMETER ReservedIP
        If used, the option reserved IP.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.

    .PARAMETER Ensure
        When set to 'Present', the option will be created.
        When set to 'Absent', the option will be removed.
#>
function Set-TargetResourceHelper
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Server', 'Scope', 'Policy', 'ReservedIP')]
        [System.String]
        $ApplyTo,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.UInt32]
        $OptionId,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Value,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $UserClass,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $ScopeId,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $PolicyName,

        [Parameter()]
        [AllowNull()]
        [System.Net.IPAddress]
        $ReservedIP,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    # Checking if option needs to be configured for server, DHCP scope, Policy or reservedIP
    switch ($ApplyTo)
    {
        'Server'
        {
            $parameters = @{
                OptionId      = $OptionId
                VendorClass   = $VendorClass
                UserClass     = $UserClass
                AddressFamily = $AddressFamily
            }
            $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Server' @parameters

            # Testing for Ensure = Present
            if ($Ensure -eq 'Present')
            {
                $serverSettingValueMessage = $script:localizedData.ServerSettingValueMessage -f $OptionId, $VendorClass, $UserClass
                Write-Verbose $serverSettingValueMessage
                Set-DhcpServerv4OptionValue -OptionId $OptionId -Value $Value -VendorClass $VendorClass -UserClass $UserClass
            }

            # Ensure = 'Absent'
            else
            {
                # If it exists and Ensure is 'Present' we should remove it
                if ($currentConfiguration.Ensure -eq 'Present')
                {
                    $serverRemoveValueMessage = $script:localizedData.ServerRemoveValueMessage -f $OptionId, $VendorClass, $UserClass
                    Write-Verbose $serverRemoveValueMessage
                    Remove-DhcpServerv4OptionValue -OptionId $OptionId -VendorClass $VendorClass -UserClass $UserClass
                }
            }
        }

        'Scope'
        {
            $parameters = @{
                ScopeId       = $ScopeId
                OptionId      = $OptionId
                VendorClass   = $VendorClass
                UserClass     = $UserClass
                AddressFamily = $AddressFamily
            }
            $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Scope' @parameters

            # Testing for Ensure = Present
            if ($Ensure -eq 'Present')
            {
                # If value should be present we just set it
                $scopeSettingValueMessage = $script:localizedData.ScopeSettingValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId
                Write-Verbose $scopeSettingValueMessage
                Set-DhcpServerv4OptionValue -ScopeId $ScopeId -OptionId $OptionId -Value $Value -VendorClass $VendorClass -UserClass $UserClass
            }

            # Ensure = 'Absent'
            else
            {
                # If it exists and Ensure is 'Present' we should remove it
                if ($currentConfiguration.Ensure -eq 'Present')
                {
                    $scopeRemoveValueMessage = $script:localizedData.ScopeRemoveValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId
                    Write-Verbose $scopeRemoveValueMessage
                    Remove-DhcpServerv4OptionValue -ScopeId $ScopeId -OptionId $currentConfiguration.OptionId -VendorClass $VendorClass -UserClass $UserClass
                }
            }
        }

        'Policy'
        {
            # If $ScopeId exist
            if ($ScopeId)
            {
                $parameters = @{
                    PolicyName    = $PolicyName
                    ScopeId       = $ScopeId
                    OptionId      = $OptionId
                    VendorClass   = $VendorClass
                    UserClass     = $UserClass
                    AddressFamily = $AddressFamily
                }
                $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Policy' @parameters

                # Testing for Ensure = Present
                if ($Ensure -eq 'Present')
                {
                    # If value should be present we just set it
                    $policyWithScopeSettingValueMessage = $script:localizedData.PolicyWithScopeSettingValueMessage -f $OptionId, $VendorClass, $PolicyName, $ScopeId
                    Write-Verbose $policyWithScopeSettingValueMessage
                    Set-DhcpServerv4OptionValue -PolicyName $PolicyName -OptionId $OptionId -ScopeId $ScopeId -Value $Value -VendorClass $VendorClass
                }

                # Ensure = 'Absent'
                else
                {
                    # If it exists and Ensure is 'Present' we should remove it
                    if ($currentConfiguration.Ensure -eq 'Present')
                    {
                        $policyWithScopeRemoveValueMessage = $script:localizedData.policyWithScopeRemoveValueMessage -f $OptionId, $VendorClass, $PolicyName, $ScopeId
                        Write-Verbose $policyWithScopeRemoveValueMessage
                        Remove-DhcpServerv4OptionValue -PolicyName $PolicyName -ScopeId $ScopeId -OptionId $OptionId -VendorClass $VendorClass
                    }
                }
            }
            # If $ScopeId is null
            else
            {
                $parameters = @{
                    PolicyName    = $PolicyName
                    OptionId      = $OptionId
                    VendorClass   = $VendorClass
                    UserClass     = $UserClass
                    AddressFamily = $AddressFamily
                }
                $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Policy' @parameters
                # Testing for Ensure = Present
                if ($Ensure -eq 'Present')
                {
                    # If value should be present we just set it
                    $policySettingValueMessage = $script:localizedData.PolicySettingValueMessage -f $OptionId, $VendorClass, $PolicyName
                    Write-Verbose $policySettingValueMessage
                    Set-DhcpServerv4OptionValue -PolicyName $PolicyName -OptionId $OptionId -Value $Value -VendorClass $VendorClass
                }
                else
                {
                    # If it exists and Ensure is 'Present' we should remove it
                    if ($currentConfiguration.Ensure -eq 'Present')
                    {
                        $policyRemoveValueMessage = $script:localizedData.PolicyRemoveValueMessage -f $OptionId, $VendorClass, $PolicyName
                        Write-Verbose $policyRemoveValueMessage
                        Remove-DhcpServerv4OptionValue -PolicyName $PolicyName -OptionId $OptionId -VendorClass $VendorClass
                    }
                }
            }
        }

        'ReservedIP'
        {
            $parameters = @{
                ReservedIP    = $ReservedIP
                OptionId      = $OptionId
                VendorClass   = $VendorClass
                UserClass     = $UserClass
                AddressFamily = $AddressFamily
            }
            $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'ReservedIP' @parameters

            # Testing for Ensure = Present
            if ($Ensure -eq 'Present')
            {
                # If value should be present we just set it
                $reservedIPSettingValueMessage = $script:localizedData.ReservedIPSettingValueMessage -f $OptionId, $VendorClass, $UserClass, $ReservedIP
                Write-Verbose $reservedIPSettingValueMessage
                Set-DhcpServerv4OptionValue -ReservedIP $ReservedIP -OptionId $OptionId -Value $Value -VendorClass $VendorClass -UserClass $UserClass
            }

            # Ensure = 'Absent'
            else
            {
                # If it exists and Ensure is 'Present' we should remove it
                if ($currentConfiguration.Ensure -eq 'Present')
                {
                    $reservedIPRemoveValueMessage = $script:localizedData.ReservedIPRemoveValueMessage -f $OptionId, $VendorClass, $UserClass, $ReservedIP
                    Write-Verbose $reservedIPRemoveValueMessage
                    Remove-DhcpServerv4OptionValue -ReservedIP $ReservedIP -OptionId $OptionId -VendorClass $VendorClass -UserClass $UserClass
                }
            }
        }
    }
}
