function Invoke-WindowsImageUpdate
{
    <#
            .Synopsis
            Starts the process of applying updates to all (or selected) images in a Windows Image Tools BaseImages Folder
            .DESCRIPTION
            This Command updates all (or selected) the images created via Add-UpdateImage in a Windows Image Tools BaseImages folder 
            New-WindowsImageToolsExample can be use to create the structrure
            .EXAMPLE
            Invoke-WindowsImageUpdate -Path C:\WITExample
            Update all the Images created with Add-UpdateImage located in C:\WITExample\BaseImages and place the resulting VHD and WIM in c:\WITExample\UpdatedImageShare
            .EXAMPLE
            Invoke-WindowsImageUpdate -Path C:\WITExample -Name 2012r2Wmf5
            Update Image named 2012r2Wmf5_Base.vhdx  in C:\WITExample\BaseImages and place the resulting VHD and WIM in c:\WITExample\UpdatedImageShare
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([bool])]
    Param
    (
        # Path to the Windows Image Tools Update Folders (created via New-WindowsImageToolsExample)
        [Parameter(Mandatory = $true, 
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    if (Test-Path $_) 
                    {
                        $true
                    }
                    else 
                    {
                        throw "Path $_ does not exist"
                    }
        })]
        [Alias('FullName')] 
        $Path,
        # Name of the Image to update
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('FriendlyName')]
        [string[]]
        $ImageName,
        
        # Reduce output file by removing feature sources
        [switch]
        $ReduceImageSize,

        # what files to export if upates are added : NONE, WIM, Both (wim and vhdx) default = both
        [ValidateSet('NONE', 'WIM', 'Both')]
        [string]
        $output = 'Both'

    )

    $ParametersToPass = @{}
    foreach ($key in ('Whatif', 'Verbose', 'Debug'))
    {
        if ($PSBoundParameters.ContainsKey($key)) 
        {
            $ParametersToPass[$key] = $PSBoundParameters[$key]
        }
    }

    #region validate input
    try
    {
        $null = Test-Path -Path "$Path\BaseImage" -ErrorAction Stop
        $null = Test-Path -Path "$Path\Resource" -ErrorAction Stop
        $null = Test-Path -Path "$Path\UpdatedImageShare" -ErrorAction Stop
        $null = Test-Path -Path "$Path\config.xml" -ErrorAction Stop
    }
    catch
    {
        throw "$Path folder structure incorrect, see New-WindowsImageToolsExample for an example"
    }
    
    if ($ImageName)
    {
        foreach ($testpath in $ImageName) 
        {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Validateing [$testpath]"
            if (-not (Test-Path -Path "$Path\BaseImage\$($testpath)_base.vhdx" ))
            
            {
                throw "$Path\BaseImage\$($testpath)_base.vhdx"
            }
        }
        $ImageList = $ImageName
    }
    else 
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Colecting List of Images"
        $ImageList = (Get-ChildItem -Path $Path\BaseImage\*_Base.vhdx).Name -replace '_Base.vhdx', ''
    }

    $configData = Import-Clixml -Path "$Path\config.xml"

    try
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Validateing VM switch config"
        $null = Get-VMSwitch -Name $configData.VmSwitch -ErrorAction Stop
    }
    catch
    {
        throw "VM Switch Configuration in $Path incorrect Set-UpdateConfig"
    }

    #endregion
    
    #region update resorces folder
    if ($pscmdlet.ShouldProcess('PowerShell Gallery', 'Download required Modules'))
    {
        if (-not (Test-Path -Path $Path\Resource\Modules)) 
        {
            $null = mkdir -Path $Path\Resource\Modules
        }
        if (-not (Get-Command Save-Module))
        {
            Write-Warning -Message 'PowerShellGet missing. you will need to download required modules from PowerShell Gallery manualy'
            Write-Warning -Message 'Required Modules : PSWindowsUpdate'
        }
        else 
        {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Geting latest PSWindowsUpdate"
            try 
            {
                # if nuget needs updating this prompts 
                ### To-Do find a way to silenty update nuget ###
                $null = Save-Module -Name PSWindowsUpdate -Path $Path\Resource\Modules -Force -ErrorAction Stop @ParametersToPass
            }
            catch 
            {
                if (Test-Path -Path $Path\Resource\Modules\PSWindowsUpdate)
                {
                    Write-Warning -Message "[$($MyInvocation.MyCommand)] : PSwindowsUpdate present, but unable to download latest"
                }
                else 
                {
                    throw "unable to download PSWindowsUpdate from PowerShellGalary.com, download manualy and place in $Path\Resource\Modules "
                }
            }
        }
    }
    #endregion

    #region Process Images
    foreach ($TargetImage in $ImageList)
    { 
        if ($pscmdlet.ShouldProcess($TargetImage, 'Invoke Windows Updates on Image'))
        {
            #region setup enviroment
            $BaseImage = "$Path\BaseImage\$($TargetImage)_base.vhdx"
            $UpdateImage = "$Path\BaseImage\$($TargetImage)_Update.vhdx"
            $SysprepImage = "$Path\BaseImage\$($TargetImage)_Sysprep.vhdx"
            $OutputVhd = "$Path\UpdatedImageShare\$($TargetImage).vhdx"
            $OutputWim = "$Path\UpdatedImageShare\$($TargetImage).wim"

            $vmGeneration = 1
            $PartitionStyle = GetVHDPartitionStyle -vhd $BaseImage
            if ($PartitionStyle -eq 'GPT') 
            {
                $vmGeneration = 2
            }
            $configData = Get-UpdateConfig -Path $Path

            $vhdData = Get-VHD -Path $BaseImage
            #endregion

            #region create Diff disk
            try 
            { 
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Windows Update : New Diff Disk : Creating $UpdateImage from $BaseImage"
                $null = New-VHD -Path $UpdateImage -ParentPath $BaseImage -ErrorAction Stop @ParametersToPass
            }
            catch 
            {
                throw "error creating differencing disk $UpdateImage from $BaseImage"
            }
            #endregion

            #region Inject files
            $RunWindowsUpdateAtStartup = {
                Start-Transcript -Path $PSScriptRoot\AtStartup.log -Append
                
                $IpType = 'IPTYPEPLACEHOLDER'
                $IPAddress = 'IPADDRESSPLACEHOLDER'
                $SubnetMask = 'SUBNETMASKPLACEHOLDER'
                $Gateway = 'GATEWAYPLACEHOLDER'
                $DnsServer = 'DNSPLACEHOLDER'
                
                if (-not ($IpType -eq 'DHCP'))
                {
                    Write-Verbose -Message 'Set Network : Getting network adaptor' -Verbose
                    $adapter = Get-NetAdapter | Where-Object -FilterScript {
                        $_.Status -eq 'up'
                    }
                    
                    Write-Verbose -Message "Set Network : removing existing config on $($adaptor.Name)" -Verbose
                    If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) 
                    {
                        $adapter | Remove-NetIPAddress -AddressFamily $IpType -Confirm:$false
                    }
                    If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) 
                    {
                        $adapter | Remove-NetRoute -AddressFamily $IpType -Confirm:$false
                    }
                    
                    $params = {
                        AddressFamily = $IpType
                        IPAddress = $IPAddress
                        PrefixLength = $SubnetMask
                        DefaultGateway = $Gateway
                    }
                    Write-Verbose -Message 'Set Network : Adding settings to adaptor'
                    Write-Verbose -Message $params -Verbose
                    $adapter | New-NetIPAddress @params
                    
                    Write-Verbose "Set Network : Set DNS to $DnsServer" -Verbose
                    $adapter | Set-DnsClientServerAddress -ServerAddresses $DnsServer  
                }

                try 
                {
                    Import-Module "$env:SystemDrive\PsTemp\Modules\PSWindowsUpdate" -Force -ErrorAction Stop
                }
                catch
                {
                    Write-Error 'Unable to import update module'
                    Stop-Transcript
                    Stop-Computer -Force
                }
                
                # Run pre-update script if it exists
                if (Test-Path "$env:SystemDrive\PsTemp\PreUpdateScript.ps1") 
                {
                    Write-Verbose "Pre-Upate script : found $env:SystemDrive\PsTemp\PreUpdateScript.ps1"
                    & "$env:SystemDrive\PsTemp\PreUpdateScript.ps1"
                }

                if ((Get-WUList -verbose -NotCategory 'Language packs').Count -gt 0)
                {
                    Write-Verbose 'Windows updates : Updates needed, flaging drive as changed' -Verbose
                    Get-Date | Out-File $env:SystemDrive\PsTemp\changesMade.txt -Force
                }
                else 
                {
                    Write-Verbose 'Windows updates : No further updates' -Verbose
                
                    if(-not ($IpType -eq 'DHCP')) 
                    {
                        $adapter = Get-NetAdapter | Where-Object {
                            $_.Status -eq 'up'
                        }
                        $interface = $adapter | Get-NetIPInterface -AddressFamily $IpType

                        Write-Verbose 'Set Network : Removing static config' -Verbose
                        If ($interface.Dhcp -eq 'Disabled') 
                        {
                            If (($interface | Get-NetIPConfiguration).Ipv4DefaultGateway) 
                            {
                                $interface | Remove-NetRoute -Confirm:$false
                            }
                            $interface | Set-NetIPInterface -Dhcp Enabled
                            $interface | Set-DnsClientServerAddress -ResetServerAddresses
                        }
                    }
                    Write-Verbose 'Shuting down' -Verbose
                    ## remove self so as to not triger updates if manual mantinance required
                    Remove-Item "$env:SystemDrive\PsTemp\AtStartup.ps1"
                    Stop-Transcript
                    Stop-Computer 
                }
 
                # Apply all non-language updates
                Write-Verbose 'Windows updates : installing updates' -Verbose
                Get-WUInstall -AcceptAll -IgnoreReboot -IgnoreUserInput -NotCategory 'Language packs' -Verbose

                # Run post-update script if it exists
                if (Test-Path "$env:SystemDrive\PsTemp\PostUpdateScript.ps1") 
                {
                    Write-Verbose "Post-Update script : found $env:SystemDrive\PsTemp\PostUpdateScript.ps1"
                    & "$env:SystemDrive\PsTemp\PostUpdateScript.ps1"
                }

 
                if (Get-WURebootStatus -Silent) 
                {
                    Write-Verbose 'Windows updates : Reboot required to finish restarting' -Verbose
                } 
                else
                {
                    Write-Verbose 'Windows updates : Restarting to check for additional updates' -Verbose
                }
                Stop-Transcript
                Restart-Computer -Force
            }

            #region add configuration data into block
            $block = $RunWindowsUpdateAtStartup | Out-String -Width 400
    
            $block = $block.Replace('IPTYPEPLACEHOLDER', $configData.IpType)
            $block = $block.Replace('IPADDRESSPLACEHOLDER', $configData.IPAddress)
            $block = $block.Replace('SUBNETMASKPLACEHOLDER', $configData.SubnetMask)
            $block = $block.Replace('GATEWAYPLACEHOLDER', $configData.Gateway)
            $block = $block.Replace('DNSPLACEHOLDER', $configData.DnsServer)
            
            $RunWindowsUpdateAtStartup = [scriptblock]::Create($block)
            #endregion
            
            $CopyInUpdateFilesBlock = {
                if (-not (Test-Path -Path "$($driveLetter):\PsTemp"))
                {
                    $null = mkdir -Path "$($driveLetter):\PsTemp"
                }
                if (-not (Test-Path -Path "$($driveLetter):\PsTemp\Modules"))
                {
                    $null = mkdir -Path "$($driveLetter):\PsTemp\Modules"
                }
                $null = New-Item -Path "$($driveLetter):\PsTemp" -Name AtStartup.ps1 -ItemType 'file' -Value $RunWindowsUpdateAtStartup -Force
                cleanupFile "$($driveLetter):\PsTemp\Modules\*"
                $null = Copy-Item -Path "$Path\Resource\Modules\*" -Destination "$($driveLetter):\PsTemp\Modules\" -Recurse

                if ((Get-ChildItem "$($driveLetter):\PsTemp\Modules\PSWindowsUpdate" -File).count -eq 0)
                {
                    Write-Verbose -Message 'Sidebyside detected in PSWindowsUpdate : switching to v4 compatability'
                    $newest = (Get-ChildItem "$($driveLetter):\PsTemp\Modules\PSWindowsUpdate" -Directory | Sort-Object LastWriteTime)[0] 
                    Copy-Item -Path $newest.fullname -Destination "$($driveLetter):\PsTemp\Modules\PSWindowsUpdate_temp" -Recurse
                    cleanupFile "$($driveLetter):\PsTemp\Modules\PSWindowsUpdate"
                    Rename-Item -Path "$($driveLetter):\PsTemp\Modules\PSWindowsUpdate_temp" -NewName "$($driveLetter):\PsTemp\Modules\PSWindowsUpdate" 
                }
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Windows Update : Adding PSWindowsUpdate Module to $UpdateImage"
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Windows Update : updateting AtStartup script"
            MountVHDandRunBlock -vhd $UpdateImage -block $CopyInUpdateFilesBlock 
            #endregion

            #region create vm and run updates
            createRunAndWaitVM -vhdPath $UpdateImage -vmGeneration $vmGeneration -configData $configData @ParametersToPass
            #endregion

            #region Detect results - Merge or discard.
            $checkresultsBlock = {
                Test-Path -Path "$($driveLetter):\PsTemp\ChangesMade.txt"
                Remove-Item "$($driveLetter):\PsTemp\ChangesMade.txt" -ErrorAction SilentlyContinue
            }
            $ChangesMade = MountVHDandRunBlock -vhd $UpdateImage -block $checkresultsBlock
            if ($ChangesMade)
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Windows Update : Changes detected : Merging $UpdateImage into $BaseImage"
                Merge-VHD -Path $UpdateImage -DestinationPath $BaseImage @ParametersToPass
            }
            else 
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Windows Update : No changes, discarding $UpdateImage" 
                cleanupFile $UpdateImage
            }
            #endregion
      
            if ($output -ne 'none')
            { 
                #region Sysprep if changes or missing output vhd
                if (($ChangesMade) -or (-not (Test-Path $OutputVhd)))
                {
                    try 
                    { 
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SysPrep : New Diff Disk : Creating $SysprepImage from $BaseImage"
                        cleanupFile $SysprepImage
                        $null = New-VHD -Path $SysprepImage -ParentPath $BaseImage -ErrorAction Stop @ParametersToPass
                    }
                    catch 
                    {
                        throw "error creating differencing disk $SysprepImage from $BaseImage"
                    }
                
      
                    $sysprepAtStartup = {
                        Start-Transcript -Path $PSScriptRoot\AtStartup.log -Append
                        # Run pre-sysprep script if it exists
                        if (Test-Path "$env:SystemDrive\PsTemp\PreSysprepScript.ps1") 
                        {
                            & "$env:SystemDrive\PsTemp\PreSysprepScript.ps1"
                        }
                    
      
                        # Remove Scedualed task
                        Write-Verbose -Message 'SysPrep : Removeing AtStartup task' -Verbose
                        if (Get-Command -Name Unregister-ScheduledTask -ErrorAction SilentlyContinue)
                        {
                            Unregister-ScheduledTask -TaskName AtStartup -Confirm:$false -Verbose
                        }
                        else 
                        {
                            schtasks.exe /delete /TN 'AtStartup' /f
                        }
                        $params = @{
                            'FilePath'             = "$ENV:SystemRoot\System32\Sysprep\Sysprep.exe"
                            'ArgumentList'         = '/generalize', '/oobe', '/shutdown'
                            'NoNewWindow'          = $true
                            'Wait'                 = $true
                            'RedirectStandardOutput' = "$($env:temp)\$($exeName)-StandardOutput.txt"
                            'RedirectStandardError' = "$($env:temp)\$($exeName)-StandardError.txt"
                            'PassThru'             = $true
                        }
      
                        Write-Verbose -Message 'SysPrep : starting Sysprep' -Verbose
                        $ret = Start-Process @params
                        Start-Sleep -Seconds 30
                        Get-Date | Out-File c:\sysprepfail.txt
                    }
      
                    $CopyInSysprepFilesBlock = {
                        $null = New-Item -Path "$($driveLetter):\PsTemp" -Name AtStartup.ps1 -ItemType 'file' -Value $sysprepAtStartup -Force
                    }
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SysPrep : updateting AtStartup script"
                    MountVHDandRunBlock -vhd $SysprepImage -block $CopyInSysprepFilesBlock 
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SysPrep : Creating temp vm and waiting"
                    createRunAndWaitVM -vhdPath $SysprepImage -vmGeneration $vmGeneration -configData $configData @ParametersToPass
             
                    MountVHDandRunBlock -vhd $SysprepImage -block {
                        if (Test-Path "$($driveLetter):\sysprepfail.txt")
                        {
                            throw 'Sysprep Failed!'
                        }
                    }
                
                    $CleanupVhdBlock = {
                        cleanupFile "$($driveLetter):\Unattend.xml"
                        cleanupFile "$($driveLetter):\PsTemp"
                        attrib.exe -s -h "$($driveLetter):\pagefile.sys"
                        cleanupFile "$($driveLetter):\pagefile.sys"
                        if ($ReduceImageSize)
                        { 
                            $null = Dism.exe /image:$($driveLetter):\ /Cleanup-Image /StartComponentCleanup /ResetBase
                            $null = Get-WindowsOptionalFeature -Path "$($driveLetter):\" |
                            Where-Object State -EQ -Value 'Disabled' |
                            Disable-WindowsOptionalFeature -Remove -Path "$($driveLetter):\" @ParametersToPass
                        }
                    }
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SysPrep : Removing PageFile and PsTemp"
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SysPrep : Cleaning SxS"
                    MountVHDandRunBlock -vhd $SysprepImage -block $CleanupVhdBlock
                }
                #endregion
      
                #region export WIM
                if (($ChangesMade) -or (-not (Test-Path $OutputWim)) -or (-not (Test-Path $OutputVhd)))
                { 
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : WIM : Creating $OutputWim"
                    cleanupFile $OutputWim
                    MountVHDandRunBlock -ReadOnly $SysprepImage -block {
                        $nul = New-WindowsImage -CapturePath "$($driveLetter):" -ImagePath $OutputWim -Name "$TargetImage Updated $(Get-Date)" @ParametersToPass
                    }
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : WIM : removing $SysprepImage"
                    cleanupFile $SysprepImage
                }
            
                #endregion
      
                #region create output VHD
                if ((($ChangesMade) -or (-not (Test-Path $OutputVhd))) -and $output -eq 'both')
                {
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : VHD : Creating $OutputVhd from $OutputWim"
                    cleanupFile $OutputVhd
                    $layout = 'BIOS'
                    if ($PartitionStyle -eq 'GPT')
                    {
                        $layout = 'UEFI'
                    }
                    $dynamic = $false
                    if ($vhdData.VhdType -eq 'Dynamic')
                    {
                        $dynamic = $true
                    }
                    $param = @{
                        Path       = "$OutputVhd"
                        Size       = $vhdData.Size
                        dynamic    = $dynamic
                        DiskLayout = $layout
                        force      = $true
                        SourcePath = "$OutputWim"
                    }
                    $nul = Convert-Wim2VHD @param @ParametersToPass 
                }
                #endregion
            }
        }
    }
    #endregion
}
