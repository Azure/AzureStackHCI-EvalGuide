function Convert-Wim2VHD
{
    <#
            .Synopsis
            Create a VHDX and populate it from a WIM
            .DESCRIPTION
            This command will create a VHD or VHDX formated for UEFI (Gen 2/GPT) or BIOS (Gen 1/MBR)
            You must supply the path to the VHD/VHDX file and a valid WIM/ISO. You should also
            include the index number for the Windows Edition to install.
            .EXAMPLE
            Convert-WIM2VHDX -Path c:\windows8.vhdx -WimPath d:\Source\install.wim -Recovery -DiskLayout UEFI
            .EXAMPLE
            Convert-WIM2VHDX -Path c:\windowsServer.vhdx -WimPath d:\Source\install.wim -index 3 -Size 40GB -force -DiskLayout UEFI
    #>
    [CmdletBinding(SupportsShouldProcess = $true, 
            PositionalBinding = $false,
    ConfirmImpact = 'Medium')]
    Param
    (
        # Path to the new VHDX file (Must end in .vhdx)
        [Parameter(Position = 0,Mandatory = $true,
        HelpMessage = 'Enter the path for the new VHDX file')]
        [ValidateNotNullorEmpty()]
        [ValidatePattern(".\.vhdx?$")]
        [ValidateScript({
                    if (Get-FullFilePath -Path $_ |
                        Split-Path  |
                    Resolve-Path ) 
                    {
                        $true
                    }
                    else 
                    {
                        Throw "Parent folder for $_ does not exist."
                    }
        })]
        [string]$Path,
        
        # Size in Bytes (Default 40B)
        [ValidateRange(25GB,64TB)]
        [long]$Size = 40GB,
        
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

        # Create the Recovery Environment Tools Partition. Only valid on UEFI layout
        [switch]$RecoveryTools,

        # Create the Recovery Environment Tools and Recovery Image Partitions. Only valid on UEFI layout
        [switch]$RecoveryImage,

        # Force the overwrite of existing files
        [switch]$force,
        
        # Path to WIM or ISO used to populate VHDX
        [parameter(Position = 1,Mandatory = $true,
        HelpMessage = 'Enter the path to the WIM/ISO file')]
        [ValidateScript({
                    Test-Path -Path (Get-FullFilePath -Path $_ )
        })]
        [string]$SourcePath,
        
        # Index of image inside of WIM (Default 1)
        [int]$Index = 1,
        
        # Path to file to copy inside of VHD(X) as C:\unattent.xml
        [ValidateScript({
                    if ($_)
                    {
                        Test-Path -Path $_
                    }
                    else 
                    {
                        $true
                    }
        })]
        [string]$Unattend,

        # Native Boot does not have the boot code inside the VHD(x) it must exist on the physical disk. 
        [switch]$NativeBoot,

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
        [string]$FeatureSource,

        # Feature Source index. If the source is a .wim provide an index Default =1 
        [int]$FeatureSourceIndex = 1,

        # Path to drivers to inject
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    Test-Path -Path $(Resolve-Path $_)
        })]
        [string[]]$Driver,

        # Add payload for all removed features
        [switch]$AddPayloadForRemovedFeature,

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
        [string[]]$filesToInject

    )
    $Path = $Path | Get-FullFilePath 
    $SourcePath = $SourcePath | Get-FullFilePath

    $VhdxFileName = Split-Path -Leaf -Path $Path

    if ($pscmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions inside [$Path] with content of [$SourcePath]",
            "Overwrite partitions inside [$Path] with contentce of [$SourcePath]? ",
    'Overwrite WARNING!'))
    {
        if((-not (Test-Path $Path)) -Or $force -Or $pscmdlet.ShouldContinue('Are you sure? Any existin data will be lost!', 'Warning')) 
        {
            $ParametersToPass = @{}
            foreach ($key in ('Whatif', 'Verbose', 'Debug'))
            {
                if ($PSBoundParameters.ContainsKey($key)) 
                {
                    $ParametersToPass[$key] = $PSBoundParameters[$key]
                }
            }
        
            $InitializeVHDPartitionParam = @{
                'Size'     = $Size
                'Path'     = $Path
                'force'    = $true
                'DiskLayout' = $DiskLayout
            }
            if ($RecoveryTools)
            {
                $InitializeVHDPartitionParam.add('RecoveryTools', $true)
            }
            if ($RecoveryImage)
            {
                $InitializeVHDPartitionParam.add('RecoveryImage', $true)
            }
            if ($Dynamic)
            {
                $InitializeVHDPartitionParam.add('Dynamic', $true)
            }
            $SetVHDPartitionParam = @{
                'SourcePath' = $SourcePath
                'Path'     = $Path
                'Index'    = $Index
                'force'    = $true
                'Confirm'  = $false
            }
            if ($Unattend)
            {
                $SetVHDPartitionParam.add('Unattend', $Unattend)
            }
            if ($NativeBoot)
            {
                $SetVHDPartitionParam.add('NativeBoot', $NativeBoot)
            }
            if ($Feature)
            {
                $SetVHDPartitionParam.add('Feature', $Feature)
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
            if ($AddPayloadForRemovedFeature)
            {
                $SetVHDPartitionParam.add('AddPayloadForRemovedFeature', $AddPayloadForRemovedFeature)
            }
            if ($Driver)
            {
                $SetVHDPartitionParam.add('Driver', $Driver)
            }
            if ($Package)
            {
                $SetVHDPartitionParam.add('Package', $Package)
            }
            if ($filesToInject)
            {
                $SetVHDPartitionParam.add('filesToInject', $filesToInject)
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : InitializeVHDPartitionParam"
            Write-Verbose -Message ($InitializeVHDPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SetVHDPartitionParam"
            Write-Verbose -Message ($SetVHDPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : ParametersToPass"
            Write-Verbose -Message ($ParametersToPass | Out-String)
            
            Try
            {
                Initialize-VHDPartition @InitializeVHDPartitionParam @ParametersToPass 
                Set-VHDPartition @SetVHDPartitionParam @ParametersToPass
            }
            Catch
            {
                throw "$($_.Exception.Message) at $($_.Exception.InvocationInfo.ScriptLineNumber)"
            }
        }
    }
}


