function Add-UpdateImage
{
    <#
            .Synopsis
            Add a Windows Image to a Windows Image Tools Update Directory
            .DESCRIPTION
            This command will convert a .ISO or .WIM into a VHD populated with an unattend.xml and first boot script
            .EXAMPLE
            Add-WitUpdateImage -Path c:\WitTools
            .EXAMPLE
            Another example of how to use this cmdlet
            .INPUTS
            System.IO.DirectoryInfo
            .OUTPUTS
            Custom object containing String -Path and String -Name
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    #[OutputType([String])]
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
 
        # Friendly name for for Base VHD used for filenames and targeting in Invoke-WindwosImageUpdate
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $FriendlyName,

        # Administrator Password for Base VHD
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $AdminCredential,

        # Product Key for sorce image (Not required for volume licence media) 
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    if ($_ -imatch '^[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{5}$') 
                    {
                        $true
                    } 
                    else 
                    {
                        throw "$_ not a valid key format"
                    }
        })]
        [String]
        $ProductKey,

        # Size in Bytes (Default 40B)
        [ValidateRange(25GB,64TB)]
        [uint64]$Size = 40GB,
        
        # Create Dynamic disk
        [switch]$Dynamic,

        # Specifies whether to build the image for BIOS (MBR), UEFI (GPT), or WindowsToGo (MBR).
        # Generation 1 VMs require BIOS (MBR) images.  Generation 2 VMs require UEFI (GPT) images.
        # Windows To Go images will boot in UEFI or BIOS
        [Parameter(Mandatory = $true)]
        [Alias('Layout')]
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('BIOS', 'UEFI', 'WindowsToGo')]
        $DiskLayout,
        
        # Path to WIM or ISO used to populate VHDX
        [parameter(Position = 1,Mandatory = $true,
        HelpMessage = 'Enter the path to the WIM/ISO file')]
        [ValidateScript({
                    Test-Path -Path (Get-FullFilePath -Path $_ )
        })]
        [string]$SourcePath,
        
        # Index of image inside of WIM (Default 1)
        [int]$Index = 1,
        
        # Add payload for all removed features
        [switch]$AddPayloadForRemovedFeature,

        # Features to turn on (in DISM format)
        [ValidateNotNullOrEmpty()]
        [string[]]$Feature,

        # Feature to remove (in DISM format)
        [ValidateNotNullOrEmpty()]
        [string[]]$RemoveFeature,

        # Feature Source path. If not provided, all ISO and WIM images in $sourcePath searched 
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    Test-Path -Path $(Resolve-Path $_)
        })]
        [string[]]$FeatureSource,

        # Feature Source index. If the source is a .wim provide an index Default =1 
        [int]$FeatureSourceIndex,

        # Path to drivers to inject
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    Test-Path -Path $(Resolve-Path $_)
        })]
        [string[]]$Driver,

        # Path of packages to install via DSIM
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    Test-Path -Path $(Resolve-Path $_)
        })]
        [string[]]$Package,

        # Files/Folders to copy to root of Winodws Drive (to place files in directories mimic the direcotry structure off of C:\)
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    foreach ($Path in $_) 
                    {
                        Test-Path -Path $(Resolve-Path $Path)
                    }
        })]
        [string[]]$filesToInject,

        # Force the overwrite of existing Image
        [switch]$force

    )

    $target = "$Path\BaseImage\$($FriendlyName)_base.vhdx"

    if ($pscmdlet.ShouldProcess("$target", 'Add Windows Image Tools Update Image'))
    {
        $ParametersToPass = @{}
        foreach ($key in ('Whatif', 'Verbose', 'Debug'))
        {
            if ($PSBoundParameters.ContainsKey($key)) 
            {
                $ParametersToPass[$key] = $PSBoundParameters[$key]
            }
        }

        #region Validate Input
        try 
        {
            $null = Test-Path -Path "$Path\BaseImage" -ErrorAction Stop
            $null = Test-Path -Path "$Path\Resource" -ErrorAction Stop
        }
        catch
        {
            Throw "$Path missing required folder structure use New-WindowsImagetoolsExample to create example"
        }
        if ((Test-Path -Path "$Path\BaseImage\$($FriendlyName)_Base.vhdx") -and (-not ($force)))
        {
            Throw "BaseImage $Path\BaseImage\$($FriendlyName)_Base.vhdx allready exists. use -force to overwrite "
        }
        #endregion

        #region Unattend
        $unattentParam = @{
            FirstBootScriptPath = 'c:\pstemp\FirstBoot.ps1'
            AdminCredential     = $AdminCredential
            EnableAdministrator = $true
        }
        if ($ProductKey) 
        {
            $unattentParam.add('ProductKey',$ProductKey)
        }
        
        $UnattendPath = New-UnattendXml @unattentParam @ParametersToPass
        #endregion 

                
        #region Create Base VHD
        $convertParm = @{
            DiskLayout = $DiskLayout
            SourcePath = $SourcePath
            Index      = $Index
            Unattend   = $UnattendPath
            Path       = $target
        }
        if ($Dynamic) 
        {
            $convertParm.add('Dynamic',$Dynamic)
        }
        if ($AddPayloadForRemovedFeature)
        {
            $convertParm.add('AddPayloadForRemovedFeature', $AddPayloadForRemovedFeature)
        }
        if ($Feature) 
        {
            $convertParm.add('Feature',$Feature)
        }
        if ($RemoveFeature)
        {
            $SetVHDPartitionParam.add('RemoveFeature', $RemoveFeature)
        }
        if ($FeatureSource)
        {
            $SetVHDPartitionParam.add('FeatureSource', $FeatureSource)
        }
        if ($FeatureSourceIndex)
        {
            $SetVHDPartitionParam.add('FeatureSourceIndex', $FeatureSourceIndex)
        }
        if ($Driver) 
        {
            $convertParm.add('Driver',$Driver)
        }
        if ($Package) 
        {
            $convertParm.add('Package',$Package)
        }
        if ($filesToInject) 
        {
            $convertParm.add('filesToInject',$filesToInject)
        }
        if ($force)
        {
            $convertParm.add('force',$true)
        }
        
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : $target : Creating "
        Convert-Wim2VHD @convertParm  @ParametersToPass
        #endregion

        #region add firstboot script
        $FirstBootContent = {
            Start-Transcript -Path $PSScriptRoot\FirstBoot.log
            
            Get-Service Schedule | Start-Service
            Start-Sleep -Seconds 20
            schtasks.exe /Create /TN 'AtStartup' /RU 'SYSTEM' /SC ONSTART /TR "'%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe' -NoProfile -ExecutionPolicy Bypass -File C:\PsTemp\AtStartup.ps1"
            Start-Sleep -Seconds 20
            
            # Restart-Computer does not have -force in 2008/win7 WMF2
            if ((Get-Command Restart-Computer -Syntax) -like '*[force]*') 
            {
                Restart-Computer -Verbose -Force
            }
            else
            {
                shutdown.exe /r /t 0 /f
            }
            Stop-Transcript
        }
       
        $AddScriptFilesBlock = {
            if (-not (Test-Path "$($driveLetter):\PsTemp"))
            {
                $null = mkdir "$($driveLetter):\PsTemp" -ErrorAction SilentlyContinue
            }
            $null = New-Item -Path "$($driveLetter):\PsTemp" -Name FirstBoot.ps1 -ItemType 'file' -Value $FirstBootContent  
        }

        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : $target : Adding First Boot Script "
        MountVHDandRunBlock -vhd $target -block $AddScriptFilesBlock @ParametersToPass
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : $target : Finished "
        #endregion
    }
}
