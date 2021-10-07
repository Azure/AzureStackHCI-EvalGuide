function Update-WindowsImageWMF
{
    <#
            .Synopsis
            Updates WMF to 4.0, 5.0 Production Preview or 5.0 (and .NET to 4.6) in a Windows Update Image
            .DESCRIPTION
            This Command downloads WMF 4.0, 5.0PP or 5.0 (Production Preview) and .NET 4.6 offline installer
            Creates a temp VM and updates .NET if needed and WMF
            .EXAMPLE
            Update-UpdateImageWMF -Path C:\WITExample
            Updates every Image in c:\WITExample\BaseImages
            .EXAMPLE
            Update-UpdateImageWMF -Path C:\WitExample -Name Server2012R2Core
            Updates only C:\WitExample\BaseImages\Server2012R2Core_Base.vhdx
    #>
    [CmdletBinding(SupportsShouldProcess)]
    #[OutputType([String])]
    Param
    (
        # Path to the Windows Image Tools Update Folders (created via New-WindowsImageToolsExample)
        [Parameter(Mandatory, 
        ValueFromPipelineByPropertyName)]
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
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('FriendlyName')]
        [string[]]
        $ImageName,

        # Use WMF 4 instead of the default WMF 5
        [switch]
        $Wmf4,

        # Use WMF5 Production Preview instead of the default WMF 5 (overrides -vmf4)
        [switch]
        $Wmf5pp

    )

    foreach ($image in $ImageName) 
    {
        $parentVHD = "$Path\BaseImage\$($image)_Base.vhdx"
        $target = "$Path\BaseImage\$($image)_Update.vhdx"
    
        if ($pscmdlet.ShouldProcess("$parentVHD", 'Update WMF in Windows Image Tools Update Image'))
        {
            $ParametersToPass = @{}
            foreach ($key in ('Whatif', 'Verbose', 'Debug'))
            {
                if ($PSBoundParameters.ContainsKey($key)) 
                {
                    $ParametersToPass[$key] = $PSBoundParameters[$key]
                }
            }
        
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Creating $target from $parentVHD"
            $null = New-VHD -Path $target -ParentPath $parentVHD
                
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
        
            if (-not(Test-Path -Path "$Path\BaseImage\$($ImageName)_Base.vhdx"))
            {
                Throw "BaseImage for $ImageName does not exists. Use Add-UpdateImage first"
            }
            #endregion

            #region Update Resource Folder
            ## download WMF
            $wmfPath = "$Path\Resource\WMF\5"
            $wmfDownloadUrl = 'http://aka.ms/wmf5latest'
        
            if ($Wmf4)
            {
                $wmfPath = "$Path\Resource\WMF\4"
                $wmfDownloadUrl = 'http://www.microsoft.com/en-us/download/details.aspx?id=40855'
            }
            if ($Wmf5pp)
            {
                $wmfPath = "$Path\Resource\WMF\5pp"
                $wmfDownloadUrl = 'https://www.microsoft.com/en-us/download/details.aspx?id=48729'
            }
            try
            { 
                if (-not (Test-Path -Path $wmfPath)) 
                {
                    $null = mkdir -Path $wmfPath
                } 
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Checking for the latest WMF in $wmfPath"
                $confirmationPage = 'http://www.microsoft.com/en-us/download/' +  $((Invoke-WebRequest -Uri $wmfDownloadUrl -UseBasicParsing).links | 
                    Where-Object -Property Class -EQ -Value 'mscom-link download-button dl' |
                ForEach-Object -MemberName href) 
                $directURLs = (Invoke-WebRequest -Uri $confirmationPage -UseBasicParsing).Links | 
                Where-Object -Property Class -EQ -Value 'mscom-link' |
                Where-Object -Property href -Like -Value '*.msu' |
                ForEach-Object -MemberName href
                foreach ($directURL in $directURLs)
                {
                    $filename = $directURL -split '/' | Select-Object -Last 1
                    if (-not (Test-Path -Path "$wmfPath\$filename" ))
                    { 
                        Write-Warning -Message "[$($MyInvocation.MyCommand)] : Checking for the latest WMF : $filename Missing, Downloading"
                        $null = Invoke-WebRequest -Uri $directURL -OutFile "$wmfPath\$filename" 
                    }
                    else
                    {
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Checking for the latest WMF : $wmfPath\$filename : Found"
                    }
                }
            }
            catch 
            {
                if (-not (Test-Path -Path "$wmfPath\*.msu"))
                {
                    throw "Unable to downlaod WMF to $wmfPath. please download WMF manualy and place in $wmfPath "
                }
            }
        

            ## download .NET 4.6
            try
            {
                if (-not (Test-Path -Path $Path\Resource\dotNET)) 
                {
                    mkdir -Path $Path\Resource\dotNET
                } 
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Checking for .NET 4.6"
                $directURL = 'https://download.microsoft.com/download/C/3/A/C3A5200B-D33C-47E9-9D70-2F7C65DAAD94/NDP46-KB3045557-x86-x64-AllOS-ENU.exe'
                $filename = 'dotNet4-6.exe'
                if (-not (Test-Path -Path "$Path\Resource\dotNET\$filename" ))
                { 
                    Write-Warning -Message "[$($MyInvocation.MyCommand)] : Checking for .NET 4.6 : Missing : Downloading"
                    $null = Invoke-WebRequest -Uri $directURL -OutFile "$Path\Resource\dotNET\$filename" 
                }    
            }
            catch 
            {
                if (-not (Test-Path -Path "$Path\Resource\dotNET\$filename"))
                {
                    throw "Unable to downlaod .net 4.6 to $Path\Resource\dotNET\$filename. please download .net 4.6 manualy "
                }
            }
            #endregion
       
            #region Install .NET
            $dotNetInstallAtStartup = {
                Start-Transcript -Path $PSScriptRoot\AtStartup.log -Append
                $currentDotNetVersionv = (Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
                    Get-ItemProperty -Name Version, Release -EA 0 |
                    Where-Object -FilterScript {
                        $_.PSChildName -match '^(?!S)\p{L}'
                    }  | 
                    Sort-Object -Property version -Descending |
                Select-Object -First 1 ).version 
                if ($currentDotNetVersionv -lt 4.6)
                {
                    if (-not (Test-Path -Path c:\PsTemp\dotNET\attempt.txt))
                    {  
                        Get-Date | Out-File -FilePath c:\PsTemp\dotNET\attempt.txt
                        Write-Verbose -Message '.Net 4.6 : Installing' -Verbose
                        Start-Process  -Verb runas -Wait -FilePath 'C:\PsTemp\dotNET\dotNet4-6.exe' -ArgumentList '/q', '/norestart', '/log c:\PsTemp\dotNet\dotNetLog.htm'
                    }
                
                    else 
                    {
                        Write-Error -Message '.Net 4.6 :  install attempted but failed!'
                        Start-Sleep -Seconds 30
                        # Stop-Computer does not have -force in 2008/win7 WMF2
                        if ((Get-Command Stop-Computer -Syntax) -like '*[force]*') 
                        {
                            Stop-Computer -Verbose -Force
                        }
                        else
                        {
                            & "$env:windir\system32\shutdown.exe" /s /t 0 /f
                        }
                        Stop-Transcript
                    }
                }
                else 
                {
                    Get-Date | Out-File -FilePath c:\PsTemp\dotNET\Verified.txt
                    Write-Verbose -Message '.Net 4.6 : detected shuting down' -Verbose
                    # Stop-Computer does not have -force in 2008/win7 WMF2
                    if ((Get-Command Stop-Computer -Syntax) -like '*[force]*') 
                    {
                        Stop-Computer -Verbose -Force
                    }
                    else
                    {
                        & "$env:windir\system32\shutdown.exe" /s /t 0 /f
                    }
                    Stop-Transcript
                }
                Start-Sleep -Seconds 30
                Write-Verbose -Message 'Rebooting computer' -Verbose
                # Restart-Computer does not have -force in 2008/win7 WMF2
                if ((Get-Command Restart-Computer -Syntax) -like '*[force]*') 
                {
                    Restart-Computer -Verbose -Force
                }
                else
                {
                    & "$env:windir\system32\shutdown.exe" /r /t 0 /f
                }
                Stop-Transcript
            }

            $AddDotNetFilesBlock = {
                if (-not (Test-Path -Path "$($driveLetter):\PsTemp"))
                {
                    $null = mkdir -Path "$($driveLetter):\PsTemp"
                }
                if (-not (Test-Path -Path "$($driveLetter):\PsTemp\dotNET"))
                {
                    $null = mkdir -Path "$($driveLetter):\PsTemp\dotNET"
                }
                $null = New-Item -Path "$($driveLetter):\PsTemp" -Name AtStartup.ps1 -ItemType 'file' -Value $dotNetInstallAtStartup -Force
                $null = Copy-Item -Path "$Path\Resource\dotNET\$filename" -Destination "$($driveLetter):\PsTemp\dotNET\$filname"
            }


            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : .NET : Adding installer to $target"
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : .NET : updateting AtStartup script"
            MountVHDandRunBlock -vhd $target -block $AddDotNetFilesBlock
            $vmGeneration = 1
            if ((GetVHDPartitionStyle -vhd $target) -eq 'GPT') 
            {
                $vmGeneration = 2
            }
            $ConfigData = Get-UpdateConfig -Path $Path
            
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : .NET : Creating temp vm and waiting "
            createRunAndWaitVM -vhdPath $target -vmGeneration $vmGeneration -configData $ConfigData @ParametersToPass
            #endregion

            #region Install WMF
            $verifyWmfVersion4 = {
                Start-Transcript -Path $PSScriptRoot\AtStartup.log -Append
                if ($PSVersionTable.PSVersion.Major -ge 4)
                {
                    Write-Verbose -Message 'WMF : version varified'
                    Get-Date | Out-File -FilePath c:\PsTemp\ChangesMade.txt
                }
                else 
                {
                    Write-Warning -Message "WMF : Excpected version 4, found $($PSVersionTable.PSVersion.Major)"
                }
                Stop-Transcript
                Stop-Computer -Force
            }
            $verifyWmfVersion5 = {
                Start-Transcript -Path $PSScriptRoot\AtStartup.log -Append
                if ($PSVersionTable.PSVersion.Major -ge 5)
                {
                    Write-Verbose -Message 'WMF : version varified'
                    Get-Date | Out-File -FilePath c:\PsTemp\ChangesMade.txt
                }
                else 
                {
                    Write-Warning -Message "WMF : Excpected version 4, found $($PSVersionTable.PSVersion.Major)"
                }
                Stop-Transcript
                Stop-Computer -Force
            }
        
            if ($Wmf4)
            {
                $VeirfyWmfAtStartup = $verifyWmfVersion4
            }
            else 
            {
                $VeirfyWmfAtStartup = $verifyWmfVersion5
            }

            $addWmfFilesBlock = {
                foreach ($update in (Get-ChildItem -Path $wmfPath\*.msu ).FullName )
                {
                    Write-Verbose -Message "checking if $update applies to $target"
                    $null = Add-WindowsPackage -PackagePath $update -Path "$($driveLetter):" 
                }
                $null = New-Item -Path "$($driveLetter):\PsTemp" -Name AtStartup.ps1 -ItemType 'file' -Value $VeirfyWmfAtStartup -Force
            }

            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : WMF : Applying WMF to $target and Updating AtStartup script"
            MountVHDandRunBlock -vhd $target -block $addWmfFilesBlock
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : WMF : creating temp VM to finalize install on $target"
            createRunAndWaitVM -vhdPath $target -vmGeneration $vmGeneration -configData $ConfigData @ParametersToPass
            #endregion

            #region check for changes and merge or delete
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : WMF : Checking if changes made"
            $checkresultsBlock = {
                Test-Path -Path "$($driveLetter):\PsTemp\ChangesMade.txt"
                if (Test-Path -Path "$($driveLetter):\PsTemp\ChangesMade.txt")
                {
                    Remove-Item -Path "$($driveLetter):\PsTemp\AtStartup.ps1" -ErrorAction SilentlyContinue
                }
            }
            $ChangesMade = MountVHDandRunBlock -vhd $target -block $checkresultsBlock
            if ($ChangesMade)
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] : WMF : Changes found : Merging $target into $parentVHD"
                Merge-VHD -Path $target -DestinationPath $parentVHD
            }
            else 
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] : WMF : No Changes : Discarding $target"
                Remove-Item $target
            }
            #endregion
        }
    }
}
