#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable localizedData -filename cVMSwitch.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable localizedData -filename cVMSwitch.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [String]$Name,

        [parameter(Mandatory)]
        [ValidateSet("External","Internal","Private")]
        [String]$Type
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }
        
    $configuration = @{
        Name = $Name
        Type = $Type
    }

    $switch = Get-VMSwitch -Name $Name -SwitchType $Type -ErrorAction SilentlyContinue
    if ($switch)
    {
        Write-Verbose -Message $localizedData.FoundSwitch
        if ($switch.SwitchType -eq 'External')
        {
            Write-Verbose -Message $localizedData.FoundExternalSwitch

            #SET specific properties for External switch type
            if ($switch.EmbeddedTeamingEnabled)
            {
                Write-Verbose -Message $localizedData.FoundSetTeam
                $switchTeam = Get-VMSwitchTeam -Name $Name

                $netAdapterName = $(
                    $switchTeam.NetAdapterInterfaceDescription | 
                        Foreach-Object { 
                            (Get-NetAdapter -InterfaceDescription $_).Name
                        }
                )               
                $configuration.Add('TeamingMode',$switchTeam.TeamingMode)
                $configuration.Add('LoadBalancingAlgorithm',$switchTeam.LoadBalancingAlgorithm)
            }
            else
            {
                $netAdapterName = $( 
                    if($switch.NetAdapterInterfaceDescription)
                    {
                        (Get-NetAdapter -InterfaceDescription $switch.NetAdapterInterfaceDescription).Name
                    }
                )
            }
        }
        else
        {
            Write-Verbose -Message ($localizedData.FoundIntORPvtSwitch -f $switch.SwitchType)
        }
        
        $configuration.Add('NetAdapterName', $netAdapterName)
        $configuration.Add('NetAdapterInterfaceDescription',$switch.NetAdapterInterfaceDescriptions)
        $configuration.Add('EmbeddedTeamingEnabled',$switch.EmbeddedTeamingEnabled)
        $configuration.Add('AllowManagementOS',$switch.AllowManagementOS)
        $configuration.Add('Id',$switch.Id)
        $configuration.Add('EnableIoV',$switch.IovEnabled)
        $configuration.Add('EnablePacketDirect',$switch.PacketDirectEnabled)
        $configuration.Add('MinimumBandwidthMode',$switch.BandwidthReservationMode)
        $configuration.Add('Ensure','Present')
    }
    else
    {
        Write-Verbose -Message $localizedData.NoSwitchFound
        $configuration.Add('Ensure','Absent')
    }

    return $configuration
}

function Set-TargetResource
{
     [CmdletBinding()]
     param
     (
         [parameter(Mandatory)]
         [String] $Name,

         [parameter(Mandatory)]
         [ValidateSet('External','Internal','Private')]
         [String] $Type,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]] $NetAdapterName,

        [Parameter()]
        [Boolean] $AllowManagementOS,

        [Parameter()]
        [Boolean] $EnableIov,

        [Parameter()]
        [ValidateSet('None', 'Default', 'Weight', 'Absolute')]
        [String] $MinimumBandwidthMode='Absolute',
		
        [parameter()]
        [ValidateSet('SwitchIndependent')]
        [String] $TeamingMode,

        [parameter()]
        [ValidateSet('Dynamic','HyperVPort')]
        [String] $LoadBalancingAlgorithm,

        [Parameter()]
        [Boolean]$EnablePacketDirect,

        [ValidateSet("Present","Absent")]
        [String] $Ensure = "Present"
    )
    
    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    if ((($Type -eq 'Internal') -or ($Type -eq 'Private')) -and $AllowManagementOS)
    {
        throw $localizedData.InternalPrivateWithAllowManagementOS
    }

    if ($Type -eq 'External' -and !($NetAdapterName))
    {
        throw $localizedData.NetAdapterNameForExternal
    }

    if ($Type -ne 'External' -and $NetAdapterName)
    {
        throw $localizedData.NoNetAdapterInternalPrivate
    }

    if (($TeamingMode -or $LoadBalancingAlgorithm) -and ($Type -ne 'External'))
    {
        throw $localizedData.NoSETForInternalPrivate
    }

    if ($EnableIov -and $EnablePacketDirect)
    {
        throw $localizedData.IOVPDTogether
    }

    if ($MinimumBandwidthMode -and ($EnableIov -and ($NetAdapterName.Count -gt 1)))
    {
        throw $localizedData.IOVMBwithSET
    }

    if ($MinimumBandwidthMode -and ($EnablePacketDirect -and ($NetAdapterName.Count -gt 1)))
    {
        throw $localizedData.PDMBwithSET
    }

    if($Ensure -eq 'Present')
    {
        $switch = (Get-VMSwitch -Name $Name -SwitchType $Type -ErrorAction SilentlyContinue)

        # If switch is present and it is external type, that means it doesn't have right properties (TEST code ensures that)
        if($switch)
        {
            Write-Verbose -Message $localizedData.FoundSwitch
            if ($switch.SwitchType -eq 'External')
            {
                Write-Verbose -Message $localizedData.FoundExternalSwitch
                
                #Check if there are multiple network adapters specified; it should be a SET Team
                if ($NetAdapterName.Count -gt 1)
                {
                    #We need a SET Team
                    Write-Verbose -Message $localizedData.NeedASET
                    if (-not $switch.EmbeddedTeamingEnabled)
                    {
                        #We dont have a SET team; delete and re-create the team
                        Write-Verbose -Message $localizedData.ReCreateSET

                        $switch | Remove-VMSwitch -Force
                        $arguments = @{
                            Name = $Name
                            NetAdapterName = $NetAdapterName
                            MinimumBandwidthMode = $MinimumBandwidthMode
                        }
                        
                        if ($PSBoundParameters.ContainsKey('AllowManagementOS'))
                        {
                            $arguments['AllowManagementOS']=$AllowManagementOS
                        }
                        
                        if ($PSBoundParameters.ContainsKey('TeamingMode'))
                        {
                            $arguments['TeamingMode']=$TeamingMode
                        }
                        
                        if ($PSBoundParameters.ContainsKey('LoadBalancingAlgorithm'))
                        {
                            $arguments['LoadBalancingAlgorithm']=$LoadBalancingAlgorithm
                        }
                        
                        if ($PSBoundParameters.ContainsKey("EnableIov"))
                        {
                            $arguments['EnableIov']=$EnableIov
                        }
                        
                        if ($PSBoundParameters.ContainsKey("EnablePacketDirect"))
                        {
                            $arguments['EnablePacketDirect']=$EnablePacketDirect
                        }
                        
                        Write-Verbose -Message $localizedData.CreateSwitch
                        $null = New-VMSwitch @arguments
                    }
                    else
                    {
                        #We have a SET Team; check network adapters and other properties
                        Write-Verbose -Message $localizedData.SETFoundCheckNetAdapter

                        $switchTeam = Get-VMSwitchTeam -VMSwitch $switch
                        $existngNetAdapters = $switchTeam.NetAdapterInterfaceDescription | 
                                ForEach-Object {
                                    (Get-NetAdapter -InterfaceDescription $_).Name
                                }
                        $switchTeamMembers = Compare-Object -ReferenceObject $NetAdapterName -DifferenceObject $existngNetAdapters
                    
                        $setTeamArguments = @{
                            VMSwitch = $switch
                        }

                        if ($null -ne $switchTeamMembers)
                        {
                            #We have a difference in the compared objects
                            Write-Verbose -Message $localizedData.SETMembersDontMatch

                            $setTeamArguments['NetAdapterName'] = $NetAdapterName
                            $updateTeam = $true
                        }

                        #check other propeties of the SET Team as well
                        if ($PSBoundParameters.ContainsKey('TeamingMode'))
                        {
                            if ($switchTeam.TeamingMode -ne $TeamingMode)
                            {
                                $setTeamArguments['TeamingMode']=$TeamingMode
                                $updateTeam = $true
                            }
                        }

                        if ($PSBoundParameters.ContainsKey('LoadBalancingAlgorithm'))
                        {
                            if ($switchTeam.LoadBalancingAlgorithm -ne $LoadBalancingAlgorithm)
                            {
                                $setTeamArguments['LoadBalancingAlgorithm']=$LoadBalancingAlgorithm
                                $updateTeam = $true
                            }
                        }

                        if ($updateTeam)
                        {
                            Write-Verbose -Message $localizedData.UpdateSETTeam
                            $null = Set-VMSwitchTeam @setTeamArguments
                        }

                        #Finally, check if if we need set AllowManagementOS
                        if($PSBoundParameters.ContainsKey("AllowManagementOS"))
                        {
                            Write-Verbose -Message "Checking if Switch $Name has AllowManagementOS set correctly..."
                            if(($switch.AllowManagementOS -ne $AllowManagementOS))
                            {
                                Write-Verbose -Message $localizedData.UpdateSwitch
                                $null = Set-VMSwitch -VMSwitch $switch -AllowManagementOS $AllowManagementOS
                            }
                        }
                    } 
                }
                else
                {
                    #We don't need a SET Team
                    if ($switch.EmbeddedTeamingEnabled)
                    {
                        #We have SET team; need to delete and re-create a normal switch
                        Write-Verbose -Message $localizedData.NeedANormalSwitch
                        Write-Verbose -Message $localizedData.RemovingSwitch
                        $switch | Remove-VMSwitch -Force

                        $switchArguments = @{
                            Name = $Name
                            NetAdapterName = $NetAdapterName
                            MinimumBandwidthMode = $MinimumBandwidthMode
                        }

                        if ($PSBoundParameters.ContainsKey('AllowManagementOS'))
                        {
                            $switchArguments['AllowManagementOS']=$AllowManagementOS
                        }
                    
                        if ($PSBoundParameters.ContainsKey("EnableIov"))
                        {
                            $switchArguments['EnableIov']=$EnableIov
                        }
                        if ($PSBoundParameters.ContainsKey("EnablePacketDirect"))
                        {
                            $switchArguments['EnablePacketDirect']=$EnablePacketDirect
                        }

                        Write-Verbose -Message $localizedData.CreateSwitch
                        $null = New-VMSwitch @switchArguments
                    }
                    else
                    {
                        #We have a normal switch; Check other properties
                        $switchUpdateArguments = @{
                            VMSwitch = $switch                            
                        }

                        if((Get-NetAdapter -Name $NetAdapterName).InterfaceDescription -ne $switch.NetAdapterInterfaceDescription)
                        {
                            #Network Adapter is not matching; we can set this without deleting the switch
                            $switchUpdateArguments['NetAdapterName'] = $NetAdapterName
                            $updateSwitch = $true
                        }
                    
                        if($PSBoundParameters.ContainsKey("AllowManagementOS"))
                        {
                            Write-Verbose -Message "Checking if Switch $Name has AllowManagementOS set correctly..."
                            if(($switch.AllowManagementOS -ne $AllowManagementOS))
                            {
                                $switchUpdateArguments['AllowManagementOS'] = $AllowManagementOS
                                $updateSwitch = $true
                            }
                        }
                    
                        if ($updateSwitch)
                        {
                            Write-Verbose -Message $localizedData.UpdateSwitch
                            $null = Set-VMSwitch @switchUpdateArguments
                        }
                    }
                }
            }
            else
            {
                #We have an internal or private switch; we cannot update any properties
                Write-Verbose -Message $localizedData.WeShouldNeverReachHere
            }
        }
        else
        {
            # If the switch is not present, create one
            $parameters = @{}
            $parameters["Name"] = $Name
            if($NetAdapterName)
            {
                $parameters["NetAdapterName"] = $NetAdapterName
                $parameters["MinimumBandwidthMode"] = $MinimumBandwidthMode
                if($PSBoundParameters.ContainsKey("AllowManagementOS"))
                {
                    $parameters["AllowManagementOS"] = $AllowManagementOS
                }
            }
            else
            { 
                $parameters["SwitchType"] = $Type
            }
            
            Write-Verbose -Message $localizedData.CreateSwitch
            $null = New-VMSwitch @parameters
        }
    }
    # Ensure is set to "Absent", remove the switch
    else
    {
        Write-Verbose -Message $localizedData.RemovingSwitch
        Get-VMSwitch $Name -ErrorAction SilentlyContinue | Remove-VMSwitch -Force
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [String] $Name,

        [parameter(Mandatory)]
        [ValidateSet('External','Internal','Private')]
        [String] $Type,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]] $NetAdapterName,

        [Parameter()]
        [Boolean] $AllowManagementOS,

        [Parameter()]
        [Boolean] $EnableIov,

        [Parameter()]
        [ValidateSet('None', 'Default', 'Weight', 'Absolute')]
        [String] $MinimumBandwidthMode='Absolute',
		
        [parameter()]
        [ValidateSet('SwitchIndependent')]
        [String] $TeamingMode,

        [parameter()]
        [ValidateSet('Dynamic','HyperVPort')]
        [String] $LoadBalancingAlgorithm,

        [Parameter()]
        [Boolean]$EnablePacketDirect,

        [ValidateSet("Present","Absent")]
        [String] $Ensure = "Present"
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    if ((($Type -eq 'Internal') -or ($Type -eq 'Private')) -and $AllowManagementOS)
    {
        throw $localizedData.InternalPrivateWithAllowManagementOS
    }

    if ($Type -eq 'External' -and !($NetAdapterName))
    {
        throw $localizedData.NetAdapterNameForExternal
    }

    if ($Type -ne 'External' -and $NetAdapterName)
    {
        throw $localizedData.NoNetAdapterInternalPrivate
    }

    if (($TeamingMode -or $LoadBalancingAlgorithm) -and ($Type -ne 'External'))
    {
        throw $localizedData.NoSETForInternalPrivate
    }

    if ($EnableIov -and $EnablePacketDirect)
    {
        throw $localizedData.IOVPDTogether
    }

    if ($MinimumBandwidthMode -and ($EnableIov -and ($NetAdapterName.Count -gt 1)))
    {
        throw $localizedData.IOVMBwithSET
    }

    if ($MinimumBandwidthMode -and ($EnablePacketDirect -and ($NetAdapterName.Count -gt 1)))
    {
        throw $localizedData.PDMBwithSET
    }

    try
    {
        $switch = Get-VMSwitch -Name $Name -SwitchType $Type -ErrorAction Stop

        if($switch)
        {
            Write-Verbose -Message $localizedData.FoundSwitch
            if ($Ensure -eq 'Present')
            {
                if ($NetAdapterName.Count -gt 1)
                {
                    Write-Verbose -Message $localizedData.NeedASET
                    #We need a SET team
                    if (-not $switch.EmbeddedTeamingEnabled)
                    {
                        Write-Verbose -Message $localizedData.ReCreateSET
                        return $false
                    }
                    else
                    {
                        #We have a SET team; need to compare the properties
                        $switchTeam = Get-VMSwitchTeam -Name $Name

                        if ($Type -eq 'External')
                        {
                            #Compare network adapters in the SET
                            Write-Verbose -Message $localizedData.SETFoundCheckNetAdapter
                            $existngNetAdapters = $switchTeam.NetAdapterInterfaceDescription | 
                                ForEach-Object { 
                                    (Get-NetAdapter -InterfaceDescription $_).Name 
                                }
                            $switchTeamMembers = Compare-Object -ReferenceObject $NetAdapterName `
                                                 -DifferenceObject $existngNetAdapters

                            if ($null -ne $switchTeamMembers)
                            {
                                #We have a difference in the compared objects
                                Write-Verbose -Message $localizedData.SETMembersDontMatch
                                return $false
                            }
                        }

                        if ($switchTeam.LoadBalancingAlgorithm -ne $LoadBalancingAlgorithm)
                        {
                            Write-Verbose -Message $localizedData.LBDifferent
                            return $false
                        }

                        if ($switchTeam.TeamingMode -ne $TeamingMode)
                        {
                            Write-Verbose -Message $localizedData.TeamingDifferent
                            return $false
                        }
                    }
                }
                else
                {
                    #We need a normal VM switch
                    if ($switch.EmbeddedTeamingEnabled)
                    {
                        Write-Verbose -Message $localizedData.NeedANormalSwitch
                        return $false
                    }

                    if ($Type -eq 'External')
                    {
                        if((Get-NetAdapter -Name $NetAdapterName -ErrorAction SilentlyContinue).InterfaceDescription -ne $switch.NetAdapterInterfaceDescription)
                        {
                            Write-Verbose -Message $localizedData.NetAdapterDifferent
                            return $false
                        }
                    }
                }

                #Check for common properties
                if($PSBoundParameters.ContainsKey("AllowManagementOS") -and $Type -eq 'External')
                {
                    if(($switch.AllowManagementOS -ne $AllowManagementOS))
                    {
                        Write-Verbose -Message $localizedData.AllowMgmtOSDifferent
                        return $false
                    }
                }

                if ($EnablePacketDirect)
                {
                    if (-not $switch.EnablePacketDirect) {
                        Write-Warning -Message $localizedData.EPDCannotChange
                    }                    
                }

                if ($EnableIov)
                {
                    if (-not $switch.EnableIov) {
                        Write-Warning -Message $localizedData.IOVCannotChange
                    } 
                }

                if ($MinimumBandwidthMode -ne $switch.BandwidthReservationMode)
                {
                    Write-Warning -Message $localizedData.MBCannotChange
                }
                
                #If we have reached this far, the switch exists with necessary configuration
                Write-Verbose -Message $localizedData.SwitchExistsNoAction
                return $true
            }
            else
            {
                Write-Verbose -Message $localizedData.SwitchExistsItShouldnot
                return $false       
            }
        }
        else
        {
            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message $localizedData.SwitchShouldExist
                return $false
            }
            else
            {
                Write-Verbose -Message $localizedData.SwitchDoesNotExistNoAction
                return $true
            }
        }
    }

    # If no switch was present
    catch [System.Management.Automation.ActionPreferenceStopException]
    {
        Write-Verbose -Message $localizedData.NoSwitchFound
        return ($Ensure -eq 'Absent')
    }
}

Export-ModuleMember -Function *-TargetResource
