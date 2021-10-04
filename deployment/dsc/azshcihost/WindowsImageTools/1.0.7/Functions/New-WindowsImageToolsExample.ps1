function New-WindowsImageToolsExample
{
    <#
            .Synopsis
            Create folders and script examples on the use of Windows Image Tools
            .DESCRIPTION
            This Command creates the folders structures and example files needed to use Windows Image Tools to auto update windows images.
            .EXAMPLE
            New-WitExample -Path c:\WitExample
            .NOTES
            This is a work in progress
    #>
    [CmdletBinding(SupportsShouldProcess = $true
    )]
    [OutputType([System.IO.DirectoryInfo])]
    Param
    (
        # Path path to Folder/Directory to create (should not exist)
        [Parameter(Mandatory = $true, 
        Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    If (Test-Path -Path $_) 
                    {
                        throw "$_ allready exist"
                    }
                    else 
                    {
                        $true
                    }
        })]
        [Alias('FullName')] 
        [string]$Path
    )

    if ($pscmdlet.ShouldProcess($Path, 'Create new Windows Image Tools Example'))
    {
        #region File Content
        $DownloadEvalIsoContent = {
            Write-Warning -Message 'Eval copies are only good for a short period then will automaticaly shutdown if not licenced.'
            function BitsDownload 
            {
                [CmdletBinding()]
                param (
                    [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DestinationPath,
                    [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Uri
                )
                $destinationFilename = [System.IO.Path]::GetFileName($DestinationPath)
                $startBitsTransferParams = @{
                    Source       = $Uri
                    Destination  = $DestinationPath
                    TransferType = 'Download'
                    DisplayName  = "Downloading $destinationFilename"
                    Description  = $Uri
                    Priority     = 'Foreground'
                }
                Start-BitsTransfer @startBitsTransferParams #-ErrorAction Stop
            } #end function SetBitsDownload

            $win10Evalx64 = 'http://download.microsoft.com/download/B/B/3/BB3611B6-9781-437F-A293-AB43B85C2190/10586.0.151029-1700.TH2_RELEASE_CLIENTENTERPRISEEVAL_OEMRET_X64FRE_EN-US.ISO'
            $Win10Evalx86 = 'http://download.microsoft.com/download/B/B/3/BB3611B6-9781-437F-A293-AB43B85C2190/10586.0.151029-1700.TH2_RELEASE_CLIENTENTERPRISEEVAL_OEMRET_X86FRE_EN-US.ISO'
            $Win81Evalx64 = 'http://download.microsoft.com/download/B/9/9/B999286E-0A47-406D-8B3D-5B5AD7373A4A/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_ENTERPRISE_EVAL_EN-US-IR3_CENA_X64FREE_EN-US_DV9.ISO'
            $Win81Evalx86 = 'http://download.microsoft.com/download/B/9/9/B999286E-0A47-406D-8B3D-5B5AD7373A4A/9600.17050.WINBLUE_REFRESH.140317-1640_X86FRE_ENTERPRISE_EVAL_EN-US-IR3_CENA_X86FREE_EN-US_DV9.ISO'
            $Srv2016tp4Eval = 'http://download.microsoft.com/download/C/2/5/C257AD1A-45C1-48F9-B31C-5D37D6463123/10586.0.151029-1700.TH2_RELEASE_SERVER_OEMRET_X64FRE_EN-US.ISO'
            $HyperV2016tp4Eval = 'http://download.microsoft.com/download/C/2/5/C257AD1A-45C1-48F9-B31C-5D37D6463123/10586.0.151029-1700.TH2_RELEASE_SERVERHYPERCORE_OEM_X64FRE_EN-US.ISO'
            $Srv2012r2Eval = 'http://download.microsoft.com/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO'
            $HyperV2012r2Eval = 'http://download.microsoft.com/download/F/7/D/F7DF966B-5C40-4674-9A32-D83D869A3244/9600.16384.WINBLUE_RTM.130821-1623_X64FRE_SERVERHYPERCORE_EN-US-IRM_SHV_X64FRE_EN-US_DV5.ISO'

            if (-not (Test-Path -Path $PSScriptRoot\ISO\Win10Evalx64.ISO))
            {
                Write-Verbose -Message 'win10x64' -Verbose
                BitsDownload -Uri $win10Evalx64 -DestinationPath $PSScriptRoot\ISO\Win10Evalx64.ISO
            }
            if (-not (Test-Path -Path $PSScriptRoot\ISO\Win10Evalx86.ISO))
            {
                Write-Verbose -Message 'win10x86' -Verbose
                BitsDownload -Uri $Win10Evalx86 -DestinationPath $PSScriptRoot\ISO\Win10Evalx86.ISO 
            }
            if (-not (Test-Path -Path $PSScriptRoot\ISO\Win81Evalx64.ISO))
            {
                Write-Verbose -Message 'win81x64' -Verbose
                BitsDownload -Uri $Win81Evalx64 -DestinationPath $PSScriptRoot\ISO\Win81Evalx64.ISO 
            }
            if (-not (Test-Path -Path $PSScriptRoot\ISO\Win81Evalx86.ISO))
            {
                Write-Verbose -Message 'win81x86' -Verbose
                BitsDownload -Uri $Win81Evalx86 -DestinationPath $PSScriptRoot\ISO\Win81Evalx86.ISO 
            }
            if (-not (Test-Path -Path $PSScriptRoot\ISO\Srv2016tp4Eval.ISO))
            {
                Write-Verbose -Message 'Srv2016' -Verbose
                BitsDownload -Uri $Srv2016tp4Eval -DestinationPath $PSScriptRoot\ISO\Srv2016tp4Eval.ISO 
            }
            if (-not (Test-Path -Path $PSScriptRoot\ISO\HyperV2016tp4Eval.ISO))
            {
                Write-Verbose -Message 'hv2016' -Verbose
                BitsDownload -Uri $HyperV2016tp4Eval -DestinationPath $PSScriptRoot\ISO\HyperV2016tp4Eval.ISO 
            }
            if (-not (Test-Path -Path $PSScriptRoot\ISO\Srv2012r2Eval.ISO))
            {
                Write-Verbose -Message 'srv2012' -Verbose
                BitsDownload -Uri $Srv2012r2Eval -DestinationPath $PSScriptRoot\ISO\Srv2012r2Eval.ISO 
            }
            if (-not (Test-Path -Path $PSScriptRoot\ISO\HyperV2012r2Eval.ISO))
            {
                Write-Verbose -Message 'hv2012' -Verbose
                BitsDownload -Uri $HyperV2012r2Eval -DestinationPath $PSScriptRoot\ISO\HyperV2012r2Eval.ISO 
            }
        }
        $BasicExampleContent = {
            Write-Warning -Message "You need to edit the configuration in $PSCommandPath and then commend out or delete line 1" 
            break
            # Delete or comment out the above line
            Write-Verbose -Message 'This example creates a no frils updated images of various windows versions' -Verbose
            Write-Verbose -Message 'Win7 if found will be updated to WMF4' -Verbose

            Import-Module -Name WindowsImageTools -Force

            ## Done use plain text plasswords in production
            #$adminCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Administrator', ('P@ssw0rd'|ConvertTo-SecureString -Force -AsPlainText))
            $adminCred = Get-Credential -UserName 'Administrator' -Message 'Local Administrator'

            # Set the values of the VM configuration 
            $switch = 'Bridge' # Must allready exist
            $vLan = 0 # 0 = no vLAN
            $IpType = 'DHCP' # DHCP, IPv4, IPv6
            $IPAddress = '192.168.0.101' # Skiped if using DHCP
            $SubnetMask = 24 # Skiped if using DHCP
            $Gateway = '192.168.0.1' # Skiped if using DHCP
            $DnsServer = '192.168.0.1' # Skiped if using DHCP

            $null = Set-UpdateConfig -Path $PSScriptRoot -VmSwitch $switch -vLAN $vLan -IpType $IpType -IpAddress $IPAddress -SubnetMask $SubnetMask -Gateway $Gateway -DnsServer $DnsServer -Verbose

            $Name = 'Win81Evalx86'
            $Layout = 'BIOS'
            $ISOPath = "$PSScriptRoot\ISO\Win81Evalx86.ISO" 
            if (Test-Path $ISOPath)
            {
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName $Name -DiskLayout $Layout -SourcePath $ISOPath -Verbose -AdminCredential $adminCred
            }
            else 
            {
                Write-Warning -Message "$ISOPath does not exist skipping"
            }

            $Name = 'Win81Evalx64'
            $Layout = 'UEFI'
            $ISOPath = "$PSScriptRoot\ISO\Win81Evalx64.ISO" 
            if (Test-Path $ISOPath)
            {
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName $Name -DiskLayout $Layout -SourcePath $ISOPath -Verbose -AdminCredential $adminCred
            }
            else 
            {
                Write-Warning -Message "$ISOPath does not exist skipping"
            }

            $Name = 'Win10Evalx86'
            $Layout = 'BIOS'
            $ISOPath = "$PSScriptRoot\ISO\Win10Evalx86.ISO" 
            if (Test-Path $ISOPath)
            {
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName $Name -DiskLayout $Layout -SourcePath $ISOPath -Verbose -AdminCredential $adminCred
            }
            else 
            {
                Write-Warning -Message "$ISOPath does not exist skipping"
            }

            $Name = 'Win10Evalx64'
            $Layout = 'UEFI'
            $ISOPath = "$PSScriptRoot\ISO\Win10Evalx64.ISO" 
            if (Test-Path $ISOPath)
            {
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName $Name -DiskLayout $Layout -SourcePath $ISOPath -Verbose -AdminCredential $adminCred
            }
            else 
            {
                Write-Warning -Message "$ISOPath does not exist skipping"
            }

            $Name = 'Srv2016tp4Eval'
            $Layout = 'UEFI'
            $ISOPath = "$PSScriptRoot\ISO\Srv2016tp4Eval.ISO" 
            if (Test-Path $ISOPath)
            { 
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName "$($Name)1" -DiskLayout $Layout -SourcePath $ISOPath -Verbose -AdminCredential $adminCred
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName "$($Name)2" -DiskLayout $Layout -SourcePath $ISOPath -Verbose -Index 2 -AdminCredential $adminCred
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName "$($Name)3" -DiskLayout $Layout -SourcePath $ISOPath -Verbose -Index 3 -AdminCredential $adminCred
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName "$($Name)4" -DiskLayout $Layout -SourcePath $ISOPath -Verbose -Index 4 -AdminCredential $adminCred
            }
            else 
            {
                Write-Warning -Message "$ISOPath does not exist skipping"
            }

            $Name = 'Srv2012r2Eval'
            $Layout = 'UEFI'
            $ISOPath = "$PSScriptRoot\ISO\Srv2012r2Eval.ISO" 
            if (Test-Path $ISOPath)
            { 
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName "$($Name)1" -DiskLayout $Layout -SourcePath $ISOPath -Verbose -AdminCredential $adminCred
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName "$($Name)2" -DiskLayout $Layout -SourcePath $ISOPath -Verbose -Index 2 -AdminCredential $adminCred
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName "$($Name)3" -DiskLayout $Layout -SourcePath $ISOPath -Verbose -Index 3 -AdminCredential $adminCred
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName "$($Name)4" -DiskLayout $Layout -SourcePath $ISOPath -Verbose -Index 4 -AdminCredential $adminCred
            }
            else 
            {
                Write-Warning -Message "$ISOPath does not exist skipping"
            }

            $Name = 'HyperV2016tp4Eval'
            $Layout = 'UEFI'
            $ISOPath = "$PSScriptRoot\ISO\HyperV2016tp4Eval.ISO" 
            if (Test-Path $ISOPath)
            {
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName $Name -DiskLayout $Layout -SourcePath $ISOPath -Verbose -AdminCredential $adminCred
            }
            else 
            {
                Write-Warning -Message "$ISOPath does not exist skipping"
            }

            $Name = 'HyperV2012r2Eval'
            $Layout = 'UEFI'
            $ISOPath = "$PSScriptRoot\ISO\HyperV2012r2Eval.ISO" 
            if (Test-Path $ISOPath)
            {
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName $Name -DiskLayout $Layout -SourcePath $ISOPath -Verbose -AdminCredential $adminCred
            }
            else 
            {
                Write-Warning -Message "$ISOPath does not exist skipping"
            }


            $Name = 'Win7x64'
            $Layout = 'BIOS'
            $ISOPath = "$PSScriptRoot\ISO\Win7ent_x64.ISO" 
            if (Test-Path $ISOPath)
            {
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName $Name -DiskLayout $Layout -SourcePath $ISOPath -Verbose -AdminCredential $adminCred
                Update-WindowsImageWMF -Path $PSScriptRoot -ImageName $Name -Wmf4 -Verbose
            }
            else 
            {
                Write-Warning -Message "$ISOPath does not exist skipping"
            }

            $Name = 'Win7x86'
            $Layout = 'BIOS'
            $ISOPath = "$PSScriptRoot\ISO\Win7ent_x86.ISO" 
            if (Test-Path $ISOPath)
            {
                Add-UpdateImage -Path $PSScriptRoot -FriendlyName $Name -DiskLayout $Layout -SourcePath $ISOPath -Verbose -AdminCredential $adminCred
                Update-WindowsImageWMF -Path $PSScriptRoot -ImageName $Name -Wmf4 -Verbose
            }
            else 
            {
                Write-Warning -Message "$ISOPath does not exist skipping"
            }

            Invoke-WindowsImageUpdate -Path $PSScriptRoot -verbose
        }
        $AdvancedExampleContent = {
            Write-Warning -Message "You need to edit the configuration in $PSCommandPath and then commend out or delete line 1" 
            break
            # Delete or comment out the above line
            Import-Module -Name WindowsImageTools -Force

            #region config

            ## Dont save admin credentials in production
            #$adminCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Administrator', ('P@ssw0rd'|ConvertTo-SecureString -Force -AsPlainText))
            $adminCred = Get-Credential -UserName 'Administrator' -Message 'Local Administrator'

            # Set the values of the VM configuration 
            $switch = 'Bridge' # Must allready exist
            $vLan = 0 # 0 = no vLAN
            $IpType = 'DHCP' # DHCP, IPv4, IPv6
            $IPAddress = '192.168.0.101' # Skiped if using DHCP
            $SubnetMask = 24 # Skiped if using DHCP
            $Gateway = '192.168.0.1' # Skiped if using DHCP
            $DnsServer = '192.168.0.1' # Skiped if using DHCP

            # Set path to Server 2012 R2 Eval Iso
            $ISOPath = "$PSScriptRoot\ISO\Srv2012r2Eval.ISO"
            #endregion

            #region Code
            # Update configuration file with supplied values
            $null = Set-UpdateConfig -Path $PSScriptRoot -VmSwitch $switch -vLAN $vLan -IpType $IpType -IpAddress $IPAddress -SubnetMask $SubnetMask -Gateway $Gateway -DnsServer $DnsServer -Verbose

            # Add 'Source' image to use for adding features to a patched image
            Add-UpdateImage -Path $PSScriptRoot -FriendlyName 'Srv2012r2_Source' -DiskLayout UEFI -SourcePath $ISOPath -AdminCredential $adminCred -Verbose -AddPayloadForRemovedFeature -Index 4
            # Add 'Core' image
            Add-UpdateImage -Path $PSScriptRoot -FriendlyName 'Srv2012r2_Core' -DiskLayout UEFI -SourcePath $ISOPath -AdminCredential $adminCred -Verbose -Index 3

            # update both images to WMF5 Production Preview
            Update-WindowsImageWMF -Path $PSScriptRoot -ImageName Srv2012r2_Core -Wmf5pp -verbose
            Update-WindowsImageWMF -Path $PSScriptRoot -ImageName Srv2012r2_source -Wmf5pp -verbose

            # Update 'Core' image and remove unused feature payloads
            Invoke-WindowsImageUpdate -Path $PSScriptRoot -Verbose -ImageName Srv2012r2_Core -ReduceImageSize
            # Update 'Source' and only create WIM
            Invoke-WindowsImageUpdate -Path $PSScriptRoot -Verbose -ImageName Srv2012r2_source -output WIM

            # create scedualed task to update images once a week on Wednesday night
            # First action solves prompting of nuget updates, and must be in a seporate process.
            $action1 = New-ScheduledTaskAction -ID 1 -Execute '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument " -Command `"& {get-packageprovider -name nuget -forcebootstrap }`"" 
            $action2 = New-ScheduledTaskAction -ID 2 -Execute '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument " -Command `"& {Start-Transcript $env:ALLUSERSPROFILE\WITUpdate.log -Append; import-module WindowsImageTools -erroraction stop; Invoke-WindowsImageUpdate -Path $PSScriptRoot -Verbose -ImageName Srv2012r2_Core -ReduceImageSize ; Invoke-WindowsImageUpdate -Path $PSScriptRoot -Verbose -ImageName Srv2012r2_source -output WIM }`"" 
              
            $Paramaters = @{
                Action   = $action1, $action2
                Trigger  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Wednesday -At 11pm
                Settings = New-ScheduledTaskSettingsSet
            }
            $Name = $PSScriptRoot.Replace('\','-').Replace(':','')
            $TaskObject = New-ScheduledTask @Paramaters 
            $null = Register-ScheduledTask -InputObject $TaskObject -User 'nt authority\system' -Verbose -TaskName "Advanced-ImageUpdate-for-$Name"

            #endregion
        }
        $ConvertExampleContent = {
            Import-Module -Name $PSScriptRoot\WindowsImageTools -Force

            # Example of WIM2VHD conversion

            #Initialize-VHDPartition -Path g:\temp\temp1.vhdx -Dynamic -Verbose -DiskLayout BIOS -RecoveryImage -force -Passthru |  
            #    Set-VHDPartition -SourcePath C:\iso\Win7ent_x64.ISO -Index 1  -Confirm:$false -force -Verbose 

            #Convert-Wim2VHD -Path g:\temp\test2.vhdx -SourcePath C:\iso\Server2012R2.ISO -DiskLayout UEFI -Dynamic -Index 1 -Size 60GB  -Force -Verbose -RecoveryImage
            $commonParams = @{
                'Dynamic'     = $true
                'Verbose'     = $true
                'Force'       = $true
                'Unattend'    = (New-UnattendXml -AdminPassword 'LocalP@ssword' -LogonCount  1)
                'filesToInject' = 'g:\temp\inject\pstemp\'
            }

            $vhds = @(
                @{
                    'SourcePath' = 'C:\iso\server_2016_preview_3.iso'
                    'DiskLayout' = 'UEFI'
                    'index'    = 1
                    'size'     = 40Gb
                    'Path'     = 'G:\temp\2016_CoreStd.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\iso\server_2016_preview_3.iso'
                    'DiskLayout' = 'UEFI'
                    'index'    = 2
                    'size'     = 40Gb
                    'Path'     = 'G:\temp\2016_GUIStd.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\iso\server_2016_preview_3.iso'
                    'DiskLayout' = 'UEFI'
                    'index'    = 3
                    'size'     = 40Gb
                    'Path'     = 'G:\temp\2016_CoreDC.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\iso\server_2016_preview_3.iso'
                    'DiskLayout' = 'UEFI'
                    'index'    = 4
                    'size'     = 40Gb
                    'Path'     = 'G:\temp\2016_GUIDC.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\iso\Svr_2012_R2.ISO'
                    'DiskLayout' = 'UEFI'
                    'index'    = 1
                    'size'     = 40Gb
                    'Path'     = 'G:\temp\2012r2_CoreStd.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\iso\Svr_2012_R2.ISO'
                    'DiskLayout' = 'UEFI'
                    'index'    = 2
                    'size'     = 40Gb
                    'Path'     = 'G:\temp\2012r2_GUIStd.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\iso\Svr_2012_R2.ISO'
                    'DiskLayout' = 'UEFI'
                    'index'    = 3
                    'size'     = 40Gb
                    'Path'     = 'G:\temp\2012r2_CoreDC.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\iso\Svr_2012_R2.ISO'
                    'DiskLayout' = 'UEFI'
                    'index'    = 4
                    'size'     = 40Gb
                    'Path'     = 'G:\temp\2012r2_GUIDC.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\iso\Win10ent_x64.ISO'
                    'DiskLayout' = 'UEFI'
                    'index'    = 1
                    'size'     = 40GB
                    'Path'     = 'G:\temp\Win10E_x64_UEFI.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\iso\Win10ent_x64.ISO'
                    'DiskLayout' = 'BIOS'
                    'index'    = 1
                    'size'     = 40GB
                    'Path'     = 'G:\temp\Win10E_x64_BIOS.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\ISO\Win10ent_x86.ISO'
                    'DiskLayout' = 'BIOS'
                    'index'    = 1
                    'size'     = 40GB
                    'Path'     = 'G:\temp\Win10E_x86_BIOS.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\ISO\Win7ent_x64.ISO'
                    'DiskLayout' = 'BIOS'
                    'index'    = 1
                    'size'     = 40GB
                    'Path'     = 'G:\temp\Win7ent_x64_BIOS.vhdx'
                }, 
                @{
                    'SourcePath' = 'C:\ISO\Win7ent_x86.ISO'
                    'DiskLayout' = 'BIOS'
                    'Index'    = 1
                    'size'     = 40GB
                    'Path'     = 'G:\temp\Win7ent_x86_BIOS.vhdx'
                }
            )

            foreach ($VhdParms in $vhds)
            {
                Convert-Wim2VHD @VhdParms @commonParams #-WhatIf
            }
        }
        #endregion

        #region Creat Directories   
        try 
        { 
            $null = New-Item -ItemType Directory -Path $Path -ErrorAction Stop
            $null = New-Item -ItemType Directory -Path $Path\UpdatedImageShare -ErrorAction Stop
            $null = New-Item -ItemType Directory -Path $Path\BaseImage -ErrorAction Stop
            $null = New-Item -ItemType Directory -Path $Path\ISO -ErrorAction Stop
            $null = New-Item -ItemType Directory -Path $Path\Resource -ErrorAction Stop
        }
        catch
        {
            throw "Error creating Directories in $Path"
        }
        #endregion
      
        #region create Files
        try 
        {      
            $null = Set-UpdateConfig -Path $Path 
            $null = New-Item -Path $Path -Name BasicUpdateExample.ps1 -ItemType 'file' -Value $BasicExampleContent -Force
            $null = New-Item -Path $Path -Name AdvancedUpdateExample.ps1 -ItemType 'file' -Value $AdvancedExampleContent -Force
            $null = New-Item -Path $Path -Name DownloadEvalIso.ps1 -ItemType 'file' -Value $DownloadEvalIsoContent -Force
            $null = New-Item -Path $Path -Name BasicConvertExample.ps1 -ItemType 'file' -Value $ConvertExampleContent -Force
        }
        catch 
        {
            throw "trying to create files in $Path"
        }
        #endregion

        #region Download Modules
        try 
        {
            Find-Module -Name PSWindowsUpdate -ErrorAction Stop | Save-Module -Force -Path $Path\Resource -ErrorAction Stop
        }
        catch
        {
            Write-Warning -Message 'Unable to download PSWindowsUpdate useing PowerShellGet'
        }
        #endregion
    }
    return (Get-Item $Path)
}
