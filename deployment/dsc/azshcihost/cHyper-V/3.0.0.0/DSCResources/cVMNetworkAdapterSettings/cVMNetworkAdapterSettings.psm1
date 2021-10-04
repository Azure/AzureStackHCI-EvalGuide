#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename cVMNetworkAdapterSettings.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename cVMNetworkAdapterSettings.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param (
        [Parameter(Mandatory)]
        [String] $Id, 

        [Parameter(Mandatory)]
        [String] $Name,
        
        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [String] $VMName
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    $configuration = @{
        Id = $Id
        Name = $Name
        SwitchName = $SwitchName
    }

    $arguments = @{
        Name = $Name
    }

    if ($VMName -ne 'ManagementOS')
    {
        $arguments.Add('VMName',$VMName)
    } 
    else
    {
        $arguments.Add('ManagementOS', $true)
        $arguments.Add('SwitchName', $SwitchName)
    }

    Write-Verbose $localizedData.GetVMNetAdapter
    $netAdapter = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue

    if ($netAdapter)
    {
        Write-Verbose $localizedData.FoundVMNetAdapter
        $configuration.Add('MacAddressSpoofing', $netAdapter.MacAddressSpoofing)
        $configuration.Add('DhcpGuard', $netAdapter.DhcpGuard)
        $configuration.Add('RouterGuard', $netAdapter.RouterGuard)
        $configuration.Add('AllowTeaming', $netAdapter.AllowTeaming)
        $configuration.Add('VmqWeight', $netAdapter.VmqWeight)
        $configuration.Add('MaximumBandwidth',$netAdapter.BandwidthSetting.MaximumBandwidth)
        $configuration.Add('MinimumBandwidthWeight',$netAdapter.BandwidthSetting.MinimumBandwidthWeight)
        $configuration.Add('MinimumBandwidthAbsolute',$netAdapter.BandwidthSetting.MinimumBandwidthAbsolute)
        $configuration.Add('IeeePriorityTag',$netAdapter.IeeePriorityTag)
        $configuration.Add('PortMirroring',$netAdapter.PortMirroringMode)
        $configuration.Add('DeviceNaming',$netAdapter.DeviceNaming)
    }
    else
    {
        Write-Warning $localizedData.NoVMNetAdapterFound
    }

    return $configuration
}

Function Set-TargetResource
{
    [CmdletBinding()]
    Param (    
        [Parameter(Mandatory)]
        [String] $Id, 

        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $MacAddressSpoofing = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $DhcpGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $IeeePriorityTag = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $RouterGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $AllowTeaming = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $DeviceNaming = 'On',

        [Parameter()]
        [uint64] $MaximumBandwidth = 0,

        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $MinimumBandwidthWeight = 0,

        [Parameter()]
        [uint32] $MinimumBandwidthAbsolute,
        
        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $VmqWeight = 100,        

        [Parameter()]
        [ValidateSet('None','Source','Destination')]
        [String] $PortMirroring = 'None'
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    $arguments = @{
        Name = $Name
    }

    if ($VMName -ne 'ManagementOS')
    {
        $arguments.Add('VMName',$VMName)
    } 
    else 
    {
        $arguments.Add('ManagementOS', $true)
        $arguments.Add('SwitchName', $SwitchName)
    }
    
    Write-Verbose $localizedData.GetVMNetAdapter
    $netAdapter = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue

    $setArguments = @{
        VMNetworkAdapter = $netAdapter
        MacAddressSpoofing = $MacAddressSpoofing
        DhcpGuard = $DhcpGuard
        RouterGuard = $RouterGuard
        VmqWeight = $VmqWeight
        MaximumBandwidth = $MaximumBandwidth
        MinimumBandwidthWeight = $MinimumBandwidthWeight
        MinimumBandwidthAbsolute= $MinimumBandwidthAbsolute
        IeeePriorityTag = $IeeePriorityTag
        AllowTeaming = $AllowTeaming
        PortMirroring = $PortMirroring
        DeviceNaming = $DeviceNaming
    }
    
    Write-Verbose $localizedData.PerformVMNetModify
    Set-VMNetworkAdapter @setArguments -ErrorAction Stop
}

Function Test-TargetResource 
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param (   
        [Parameter(Mandatory)]
        [String] $Id, 
                     
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $MacAddressSpoofing = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $DhcpGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $IeeePriorityTag = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $RouterGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $AllowTeaming = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $DeviceNaming = 'On',

        [Parameter()]
        [uint64] $MaximumBandwidth = 0,

        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $MinimumBandwidthWeight = 0,

        [Parameter()]
        [uint32] $MinimumBandwidthAbsolute,
        
        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $VmqWeight = 100,        

        [Parameter()]
        [ValidateSet('None','Source','Destination')]
        [String] $PortMirroring = 'None'
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    $arguments = @{
        Name = $Name
    }

    if ($VMName -ne 'ManagementOS') 
    {
        $arguments.Add('VMName',$VMName)
    } 
    else 
    {
        $arguments.Add('ManagementOS', $true)
        $arguments.Add('SwitchName', $SwitchName)
    }
    
    Write-Verbose $localizedData.GetVMNetAdapter
    $adapterExists = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue
    
    if ($adapterExists) 
    {
        Write-Verbose $localizedData.FoundVMNetAdapter
        if ($adapterExists.MacAddressSpoofing -eq $MacAddressSpoofing `
            -and $adapterExists.RouterGuard -eq $RouterGuard `
            -and $adapterExists.DhcpGuard -eq $DhcpGuard `
            -and $adapterExists.IeeePriorityTag -eq $IeeePriorityTag `
            -and $adapterExists.AllowTeaming -eq $AllowTeaming `
            -and $adapterExists.BandwidthSetting.MaximumBandwidth -eq $MaximumBandwidth `
            -and $adapterExists.BandwidthSetting.MinimumBandwidthWeight -eq $MinimumBandwidthWeight `
            -and $adapterExists.BandwidthSetting.MinimumBandwidthAbsolute -eq $MinimumBandwidthAbsolute `
            -and $adapterExists.VMQWeight -eq $VMQWeight `
            -and $adapterExists.PortMirroringMode -eq $PortMirroring `
            -and $adapterExists.DeviceNaming -eq $DeviceNaming
        )
        {
            Write-Verbose $localizedData.VMNetAdapterExistsNoActionNeeded
            return $true
        } 
        else 
        {
            Write-Verbose $localizedData.VMNetAdapterExistsWithDifferentConfiguration
            return $false
        }
    } 
    else 
    {
        throw $localizedData.VMNetAdapterDoesNotExist
    }
}

Export-ModuleMember -Function *-TargetResource
