# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
RoleNotFound            = Please ensure that the PowerShell module for role {0} is installed
InvalidIPAddressFormat  = Value of {0} property is not in a valid IP address format. Specify a valid IP address format and try again.
InvalidIPAddressFamily = The IP address {0} is not a valid {1} address. Specify a valid IP address in {1} format and try again.
InvalidTimeSpanFormat  = Value of {0} property is not in a valid timespan format. Specify the timespan in days.hrs:mins:secs format and try again.
InvalidScopeIdSubnetMask = Value of byte {0} in {1} ({2}) is not valid. Binary AND with byte {0} in SubnetMask ({3}) should be equal to byte {0} in ScopeId ({4}).
InvalidStartAndEndRangeMessage = Value of IPStartRange ({0}) and IPEndRange ({1}) are not valid. Start should be lower than end.
'@
}

# Internal function to throw terminating error with specified ErrorCategory, ErrorId and ErrorMessage
function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ErrorId,
        
        [Parameter(Mandatory = $true)]
        [String]
        $ErrorMessage,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )
    
    $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $ErrorId, $ErrorCategory, $null
    throw $errorRecord
}

# Internal function to translate a string to valid IPAddress format
function Get-ValidIPAddress
{
    [CmdletBinding()]
    [OutputType([System.Net.IPAddress])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $IpString,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [String]
        $AddressFamily,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterName
    )

    $ipAddressFamily = ''
    if($AddressFamily -eq 'IPv4')
    {
        $ipAddressFamily = 'InterNetwork'
    }
    else
    {
        $ipAddressFamily = 'InterNetworkV6'
    }

    [System.Net.IPAddress]$ipAddress = $null
    $result = [System.Net.IPAddress]::TryParse($IpString, [ref]$ipAddress)
    if(-not $result)
    {
        $errorMsg = $($LocalizedData.InvalidIPAddressFormat) -f $ParameterName
        New-TerminatingError -ErrorId 'NotValidIPAddress' -ErrorMessage $errorMsg -ErrorCategory InvalidType
    }

    if($ipAddress.AddressFamily -ne $ipAddressFamily)
    {
        $errorMsg = $($LocalizedData.InvalidIPAddressFamily) -f $ipAddress,$AddressFamily
        New-TerminatingError -ErrorId 'InvalidIPAddressFamily' -ErrorMessage $errorMsg -ErrorCategory SyntaxError
    } 
    
    $ipAddress
}

# Internal function to assert if the role specific module is installed or not
function Assert-Module
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [String]
        $ModuleName = 'DHCPServer'
    )

    if(! (Get-Module -Name $ModuleName -ListAvailable))
    {
        $errorMsg = $($LocalizedData.RoleNotFound) -f $ModuleName
        New-TerminatingError -ErrorId 'ModuleNotFound' -ErrorMessage $errorMsg -ErrorCategory ObjectNotFound
    }
}

<#
    .SYNOPSIS
        Internal function to assert if values of ScopeId/SubnetMask/IPStartRange/IPEndRange make sense.

    .DESCRIPTION
        Internal function used to assert if value of following parameters are correct:
        - ScopeID
        - SubnetMask
        - IPStartRange
        - IPEndRange

        It validates them against simple rules:
        - Has to be correct (IPv4) address
        - Anything but SubnetMask has to follow the rule that:
        (TokenFromParameter) -band (TokenFromSubnetMask) = (TokenFromScopeId)
        - IPStartRange has to be before IPEndRange
        Implementation for IPv4.

    .PARAMETER ScopeId
    String version of ScopeId.

    .PARAMETER SubnetMask
    String version of SubnetMask.

    .PARAMETER IPStartRange
    String version of StartRange.

    .PARAMETER IPEndRange
    String version of EndRange.

    .PARAMETER AddressFamily
    AddressFamily that IPs should validate against.

    .EXAMPLE
    Assert-ScopeParameter -ScopeId 192.168.1.0 -SubnetMask 255.255.255.0 -IPStartRange 192.168.1.1 -IPEndRange 192.168.1.254 -AddressFamily IPv4
    Validates all parameters against rules and returns nothing (all parameters are correct).

    .EXAMPLE
    Assert-ScopeParameter -ScopeId 192.168.1.0 -SubnetMask 255.255.240.0 -IPStartRange 192.168.1.1 -IPEndRange 192.168.1.254 -AddressFamily IPv4
    Returns error informing that using specified SubnetMask with specified ScopeId is incorrect:
    Value of byte 3 in ScopeId (1) is not valid. Binary AND with byte 3 in SubnetMask (240) should be equal to byte 3 in ScopeId (1).
#>
function Assert-ScopeParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [String]
        $SubnetMask,

        [Parameter(Mandatory = $true)]
        [String]
        $IPStartRange,

        [Parameter(Mandatory = $true)]
        [String]
        $IPEndRange,

        [Parameter(Mandatory = $true)]
        [String]
        $AddressFamily
    )

    # Convert the Subnet Mask to be a valid IPAddress
    $netMask = Get-ValidIpAddress -IpString $SubnetMask -AddressFamily $AddressFamily -ParameterName SubnetMask

    # Convert the ScopeID to be a valid IPAddress
    $scope = Get-ValidIPAddress -IpString $ScopeId -AddressFamily $AddressFamily -ParameterName ScopeId

    # Convert the Start Range to be a valid IPAddress
    $startRange = Get-ValidIpAddress -IpString $IPStartRange -AddressFamily $AddressFamily -ParameterName IPStartRange

    # Convert the End Range to be a valid IPAddress
    $endRange = Get-ValidIpAddress -IpString $IPEndRange -AddressFamily $AddressFamily -ParameterName IPEndRange

    # Check to ensure startRange is smaller than endRange
    if($endRange.Address -lt $startRange.Address)
    {
        $errorMsg = $LocalizedData.InvalidStartAndEndRangeMessage -f $IPStartRange, $IPEndRange
        New-TerminatingError -ErrorId RangeNotCorrect -ErrorMessage $errorMsg -ErrorCategory InvalidArgument
    }

    $addressBytes = @{
        ScopeId      = $scope.GetAddressBytes()
        SubnetMask   = $netMask.GetAddressBytes()
        IPStartRange = $startRange.GetAddressBytes()
        IPEndRange   = $endRange.GetAddressBytes()
    }

    foreach ($parameter in $addressBytes.Keys.Where{ $_ -ne 'SubnetMask' })
    {
        foreach ($ipTokenIndex in 0..3)
        {
            $parameterByte = $addressBytes[$parameter][$ipTokenIndex]
            $subnetMaskByte = $addressBytes['SubnetMask'][$ipTokenIndex]
            $scopeIdByte = $addressBytes['ScopeId'][$ipTokenIndex]
            if(($parameterByte -band $subnetMaskByte) -ne $scopeIdByte)
            {
                $errorMsg = $($LocalizedData.InvalidScopeIdSubnetMask) -f ($ipTokenIndex + 1), $parameter, $parameterByte, $subnetMaskByte, $scopeIdByte
                New-TerminatingError -ErrorId ScopeIdOrMaskIncorrect -ErrorMessage $errorMsg -ErrorCategory InvalidArgument
            }
        }
    }
}

# Internal function to write verbose messages for collection of properties
function Write-PropertyMessage
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $Parameters,

        [Parameter(Mandatory = $true)]
        [String[]]
        $KeysToSkip,

        [Parameter(Mandatory = $true)]
        [String]
        $MessageTemplate
    )

    foreach($key in $parameters.keys)
    {
        if($keysToSkip -notcontains $key)
        {
            $msg = $MessageTemplate -f $key,$parameters[$key]
            Write-Verbose -Message $msg
        }
    }
}

# Internal function to translate a string to valid IPAddress format
function Get-ValidTimeSpan
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $TsString,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterName
    )

    [System.TimeSpan]$timeSpan = New-TimeSpan
    $result = [System.TimeSpan]::TryParse($TsString, [ref]$timeSpan)
    if(-not $result)
    {
        $errorMsg = $($LocalizedData.InvalidTimeSpanFormat) -f $ParameterName
        New-TerminatingError -ErrorId 'NotValidTimeSpan' -ErrorMessage $errorMsg -ErrorCategory InvalidType
    }

    $timeSpan
}
