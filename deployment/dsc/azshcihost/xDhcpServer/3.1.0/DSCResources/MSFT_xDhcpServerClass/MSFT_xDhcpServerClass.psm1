$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DscResource.Common'
$script:moduleHelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DhcpServerDsc.Common'

Import-Module -Name $script:resourceHelperModulePath
Import-Module -Name $script:moduleHelperPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Vendor', 'User')]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AsciiData,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $Description = '',

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily
    )

    Write-Verbose -Message (
        $script:localizedData.GetServerClassMessage -f $Name
    )

    #region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

    #endregion Input Validation

    $DhcpServerClass = Get-DhcpServerv4Class -Name $Name -ErrorAction 'SilentlyContinue'

    if ($DhcpServerClass)
    {
        $HashTable = @{
            'Name'          = $DhcpServerClass.Name
            'Type'          = $DhcpServerClass.Type
            'AsciiData'     = $DhcpServerClass.AsciiData
            'Description'   = $DhcpServerClass.Description
            'AddressFamily' = 'IPv4'
        }
    }
    else
    {
        $HashTable = @{
            'Name'          = ''
            'Type'          = ''
            'AsciiData'     = ''
            'Description'   = ''
            'AddressFamily' = ''
        }
    }

    $HashTable
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Vendor', 'User')]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AsciiData,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $Description = '',

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily
    )

    Write-Verbose -Message (
        $script:localizedData.SetServerClassMessage -f $Name
    )

    $DhcpServerClass = Get-DhcpServerv4Class $Name -ErrorAction 'SilentlyContinue'

    #testing for ensure = present
    if ($Ensure -eq 'Present')
    {
        #testing if class exists
        if ($DhcpServerClass)
        {
            #if it exists we use the set verb
            $scopeIDMessage = $script:localizedData.SettingClassIDMessage -f $Name
            Write-Verbose -Message $scopeIDMessage

            set-DhcpServerv4Class -Name $Name -Type $Type -Data $AsciiData -Description $Description
        }
        else
        {
            $scopeIDMessage = $script:localizedData.AddingClassIDMessage -f $Name
            Write-Verbose -Message $scopeIDMessage

            Add-DhcpServerv4Class -Name $Name -Type $Type -Data $AsciiData -Description $Description
        }
    }
    else
    {
        $scopeIDMessage = $script:localizedData.RemovingClassIDMessage -f $Name
        Write-Verbose -Message $scopeIDMessage

        Remove-DhcpServerv4Class -Name $Name -Type $Type
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Vendor', 'User')]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AsciiData,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $Description = '',

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily
    )

    Write-Verbose -Message (
        $script:localizedData.TestServerClassMessage -f $Name
    )

    $DhcpServerClass = Get-DhcpServerv4Class -Name $Name -ErrorAction 'SilentlyContinue'

    # testing for ensure = present
    if ($Ensure -eq 'Present')
    {
        # testing if $DhcpServerClass is not null
        if ($DhcpServerClass)
        {
            # since $DhcpServerClass is not null compare the values
            if (($DhcpServerClass.Type -eq $Type) -and ($DhcpServerClass.asciiData -eq $AsciiData) -and ($DhcpServerClass.Description -eq $Description))
            {
                $result = $true
            }
            else
            {
                $result = $false
            }
        }
        else
        {
            # if $DhcpServerClass return false
            $result = $false
        }
    }
    else
    {
        # testing if $DhcpServerClass is not null, if it exists return false
        if ($DhcpServerClass)
        {
            $result = $false
        }
        else
        {
            # if it not exists return true
            $result = $true
        }
    }

    return $result
}
