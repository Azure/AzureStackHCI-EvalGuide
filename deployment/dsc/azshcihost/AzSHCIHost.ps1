configuration AzSHCIHost
{
    param 
    ( 
        [Parameter(Mandatory)]
        [string]$DomainName,
        [Parameter(Mandatory)]
        [string]$environment,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,
        [Parameter(Mandatory)]
        [string]$enableDHCP,
        [Parameter(Mandatory)]
        [string]$customRdpPort,
        [string]$vSwitchNameHost = "InternalNAT",
        [String]$targetDrive = "V",
        [String]$sourcePath = "$targetDrive" + ":\Source",
        [String]$updatePath = "$sourcePath\Updates",
        [String]$ssuPath = "$updatePath\SSU",
        [String]$cuPath = "$updatePath\CU",
        [String]$targetVMPath = "$targetDrive" + ":\VMs",
        [String]$witnessPath = "$targetDrive" + ":\Witness",
        [String]$targetADPath = "$targetDrive" + ":\ADDS",
        [String]$baseVHDFolderPath = "$targetVMPath\Base",
        [String]$azsHCIIsoUri = "https://aka.ms/2CNBagfhSZ8BM7jyEV8I",
        [String]$azsHciVhdPath = "$baseVHDFolderPath\AzSHCI.vhdx",
        [String]$azsHCIISOLocalPath = "$sourcePath\AzSHCI.iso",
        [Int]$azsHostCount = 2,
        [Int]$azsHostDataDiskCount = 4,
        [Int64]$dataDiskSize = 250GB
    )
    
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'xHyper-v'
    Import-DscResource -ModuleName 'cHyper-v'
    Import-DscResource -ModuleName 'StorageDSC'
    Import-DscResource -ModuleName 'NetworkingDSC'
    Import-DscResource -ModuleName 'xDHCpServer' 
    Import-DscResource -ModuleName 'DnsServerDsc'
    Import-DscResource -ModuleName 'cChoco'
    Import-DscResource -ModuleName 'DSCR_Shortcut'
    Import-DscResource -ModuleName 'xCredSSP'
    Import-DscResource -ModuleName 'ActiveDirectoryDsc'

    $aszhciHostsMofUri = "https://raw.githubusercontent.com/Azure/AzureStackHCI-EvalGuide/main/deployment/helpers/Install-AzsRolesandFeatures.ps1"
    $updateAdUri = "https://raw.githubusercontent.com/Azure/AzureStackHCI-EvalGuide/main/deployment/helpers/Update-AD.ps1"
    $regHciUri = "https://raw.githubusercontent.com/Azure/AzureStackHCI-EvalGuide/main/deployment/helpers/Register-AzSHCI.ps1"

    if ($enableDHCP -eq "Enabled") {
        $dhcpStatus = "Active"
    }
    else { $dhcpStatus = "Inactive" }

    #[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $ipConfig = (Get-NetAdapter -Physical | Where-Object { $_.InterfaceDescription -like "*Hyper-V*" } | Get-NetIPConfiguration | Where-Object IPv4DefaultGateway)
    $netAdapters = Get-NetAdapter -Name ($ipConfig.InterfaceAlias) | Select-Object -First 1
    $InterfaceAlias = $($netAdapters.Name)

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
            ActionAfterReboot  = 'ContinueConfiguration'
            ConfigurationMode  = 'ApplyOnly'
        }

        #### CREATE STORAGE SPACES V: & VM FOLDER ####

        Script StoragePool {
            SetScript  = {
                New-StoragePool -FriendlyName AzSHCIPool -StorageSubSystemFriendlyName '*storage*' -PhysicalDisks (Get-PhysicalDisk -CanPool $true)
            }
            TestScript = {
                (Get-StoragePool -ErrorAction SilentlyContinue -FriendlyName AzSHCIPool).OperationalStatus -eq 'OK'
            }
            GetScript  = {
                @{Ensure = if ((Get-StoragePool -FriendlyName AzSHCIPool).OperationalStatus -eq 'OK') { 'Present' } Else { 'Absent' } }
            }
        }
        Script VirtualDisk {
            SetScript  = {
                $disks = Get-StoragePool -FriendlyName AzSHCIPool -IsPrimordial $False | Get-PhysicalDisk
                $diskNum = $disks.Count
                New-VirtualDisk -StoragePoolFriendlyName AzSHCIPool -FriendlyName AzSHCIDisk -ResiliencySettingName Simple -NumberOfColumns $diskNum -UseMaximumSize
            }
            TestScript = {
                (Get-VirtualDisk -ErrorAction SilentlyContinue -FriendlyName AzSHCIDisk).OperationalStatus -eq 'OK'
            }
            GetScript  = {
                @{Ensure = if ((Get-VirtualDisk -FriendlyName AzSHCIDisk).OperationalStatus -eq 'OK') { 'Present' } Else { 'Absent' } }
            }
            DependsOn  = "[Script]StoragePool"
        }
        Script FormatDisk {
            SetScript  = {
                $vDisk = Get-VirtualDisk -FriendlyName AzSHCIDisk
                if ($vDisk | Get-Disk | Where-Object PartitionStyle -eq 'raw') {
                    $vDisk | Get-Disk | Initialize-Disk -Passthru | New-Partition -DriveLetter $Using:targetDrive -UseMaximumSize | Format-Volume -NewFileSystemLabel AzSHCIData -AllocationUnitSize 64KB -FileSystem NTFS
                }
                elseif ($vDisk | Get-Disk | Where-Object PartitionStyle -eq 'GPT') {
                    $vDisk | Get-Disk | New-Partition -DriveLetter $Using:targetDrive -UseMaximumSize | Format-Volume -NewFileSystemLabel AzSHCIData -AllocationUnitSize 64KB -FileSystem NTFS
                }
            }
            TestScript = { 
                (Get-Volume -ErrorAction SilentlyContinue -FileSystemLabel AzSHCIData).FileSystem -eq 'NTFS'
            }
            GetScript  = {
                @{Ensure = if ((Get-Volume -FileSystemLabel AzSHCIData).FileSystem -eq 'NTFS') { 'Present' } Else { 'Absent' } }
            }
            DependsOn  = "[Script]VirtualDisk"
        }

        File "VMfolder" {
            Type            = 'Directory'
            DestinationPath = $targetVMPath
            DependsOn       = "[Script]FormatDisk"
        }

        File "Witnessfolder" {
            Type            = 'Directory'
            DestinationPath = $witnessPath
            DependsOn       = "[Script]FormatDisk"
        }

        if ($environment -eq "AD Domain") {
            File "ADfolder" {
                Type            = 'Directory'
                DestinationPath = $targetADPath
                DependsOn       = "[Script]FormatDisk"
            }
        }

        File "Source" {
            DestinationPath = $sourcePath
            Type            = 'Directory'
            Force           = $true
            DependsOn       = "[Script]FormatDisk"
        }

        File "Updates" {
            DestinationPath = $updatePath
            Type            = 'Directory'
            Force           = $true
            DependsOn       = "[File]Source"
        }

        File "CU" {
            DestinationPath = $cuPath
            Type            = 'Directory'
            Force           = $true
            DependsOn       = "[File]Updates"
        }

        File "SSU" {
            DestinationPath = $ssuPath
            Type            = 'Directory'
            Force           = $true
            DependsOn       = "[File]Updates"
        }

        File "VM-base" {
            Type            = 'Directory'
            DestinationPath = $baseVHDFolderPath
            DependsOn       = "[File]VMfolder"
        }

        script "Download DSC Config for AzsHci Hosts" {
            GetScript  = {
                $result = Test-Path -Path "$using:sourcePath\Install-AzsRolesandFeatures.ps1"
                return @{ 'Result' = $result }
            }

            SetScript  = {
                Start-BitsTransfer -Source "$using:aszhciHostsMofUri" -Destination "$using:sourcePath\Install-AzsRolesandFeatures.ps1"          
            }

            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result
            }
            DependsOn  = "[File]Source"
        }

        script "Download Update-AD" {
            GetScript  = {
                $result = Test-Path -Path "$using:sourcePath\Update-AD.ps1"
                return @{ 'Result' = $result }
            }

            SetScript  = {
                Start-BitsTransfer -Source "$using:updateAdUri" -Destination "$using:sourcePath\Update-AD.ps1"          
            }

            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result
            }
            DependsOn  = "[File]Source"
        }

        script "Download Register-AzSHCI" {
            GetScript  = {
                $result = Test-Path -Path "$using:sourcePath\Register-AzSHCI.ps1"
                return @{ 'Result' = $result }
            }

            SetScript  = {
                Start-BitsTransfer -Source "$using:regHciUri" -Destination "$using:sourcePath\Register-AzSHCI.ps1"
            }

            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result
            }
            DependsOn  = "[File]Source"
        }

        script "Download AzureStack HCI bits" {
            GetScript  = {
                $result = Test-Path -Path $using:azsHCIISOLocalPath
                return @{ 'Result' = $result }
            }

            SetScript  = {
                Start-BitsTransfer -Source $using:azsHCIIsoUri -Destination $using:azsHCIISOLocalPath            
            }

            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result
            }
            DependsOn  = "[File]Source"
        }

        script "Download AzSHCI SSU" {
            GetScript  = {
                $result = Test-Path -Path "$using:ssuPath\*" -Include "*.msu"
                return @{ 'Result' = $result }
            }

            SetScript  = {
                $ssuSearchString = "Servicing Stack Update for Azure Stack HCI, version 21H2 for x64-based Systems"
                $ssuID = "Azure Stack HCI"
                $ssuUpdate = Get-MSCatalogUpdate -Search $ssuSearchString | Where-Object Products -eq $ssuID | Select-Object -First 1
                $ssuUpdate | Save-MSCatalogUpdate -Destination $using:ssuPath
            }

            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result
            }
            DependsOn  = "[File]SSU"
        }

        script "Download AzSHCI CU" {
            GetScript  = {
                $result = Test-Path -Path "$using:cuPath\*" -Include "*.msu"
                return @{ 'Result' = $result }
            }

            SetScript  = {
                $cuSearchString = "Cumulative Update for Azure Stack HCI, version 21H2"
                $cuID = "Azure Stack HCI"
                $cuUpdate = Get-MSCatalogUpdate -Search $cuSearchString | Where-Object Products -eq $cuID | Where-Object Title -like "*$($cuSearchString)*" | Select-Object -First 1
                $cuUpdate | Save-MSCatalogUpdate -Destination $using:cuPath
            }

            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result
            }
            DependsOn  = "[File]CU"
        }

        #### SET WINDOWS DEFENDER EXCLUSION FOR VM STORAGE ####

        Script defenderExclusions {
            SetScript  = {
                $exclusionPath = "$Using:targetDrive" + ":\"
                Add-MpPreference -ExclusionPath "$exclusionPath"               
            }
            TestScript = {
                $exclusionPath = "$Using:targetDrive" + ":\"
                (Get-MpPreference).ExclusionPath -contains "$exclusionPath"
            }
            GetScript  = {
                $exclusionPath = "$Using:targetDrive" + ":\"
                @{Ensure = if ((Get-MpPreference).ExclusionPath -contains "$exclusionPath") { 'Present' } Else { 'Absent' } }
            }
            DependsOn  = "[File]VMfolder"
        }

        #### REGISTRY & SCHEDULED TASK TWEAKS ####

        Registry "Disable Internet Explorer ESC for Admin" {
            Key       = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
            Ensure    = 'Present'
            ValueName = "IsInstalled"
            ValueData = "0"
            ValueType = "Dword"
        }

        Registry "Disable Internet Explorer ESC for User" {
            Key       = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
            Ensure    = 'Present'
            ValueName = "IsInstalled"
            ValueData = "0"
            ValueType = "Dword"
        }
        
        Registry "Disable Server Manager WAC Prompt" {
            Key       = "HKLM:\SOFTWARE\Microsoft\ServerManager"
            Ensure    = 'Present'
            ValueName = "DoNotPopWACConsoleAtSMLaunch"
            ValueData = "1"
            ValueType = "Dword"
        }

        Registry "Disable Network Profile Prompt" {
            Key       = 'HKLM:\System\CurrentControlSet\Control\Network\NewNetworkWindowOff'
            Ensure    = 'Present'
            ValueName = ''
        }

        if ($environment -eq "Workgroup") {
            Registry "Set Network Private Profile Default" {
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\010103000F0000F0010000000F0000F0C967A3643C3AD745950DA7859209176EF5B87C875FA20DF21951640E807D7C24'
                Ensure    = 'Present'
                ValueName = "Category"
                ValueData = "1"
                ValueType = "Dword"
            }
    
            Registry "SetWorkgroupDomain" {
                Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
                Ensure    = 'Present'
                ValueName = "Domain"
                ValueData = "$DomainName"
                ValueType = "String"
            }
    
            Registry "SetWorkgroupNVDomain" {
                Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
                Ensure    = 'Present'
                ValueName = "NV Domain"
                ValueData = "$DomainName"
                ValueType = "String"
            }
    
            Registry "NewCredSSPKey" {
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly'
                Ensure    = 'Present'
                ValueName = ''
            }
    
            Registry "NewCredSSPKey2" {
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation'
                ValueName = 'AllowFreshCredentialsWhenNTLMOnly'
                ValueData = '1'
                ValueType = "Dword"
                DependsOn = "[Registry]NewCredSSPKey"
            }
    
            Registry "NewCredSSPKey3" {
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly'
                ValueName = '1'
                ValueData = "*.$DomainName"
                ValueType = "String"
                DependsOn = "[Registry]NewCredSSPKey2"
            }
        }

        ScheduledTask "Disable Server Manager at Startup" {
            TaskName = 'ServerManager'
            Enable   = $false
            TaskPath = '\Microsoft\Windows\Server Manager'
        }


        Script Shortcuts {
            SetScript  = {   
                $WshShell = New-Object -comObject WScript.Shell
                $dt = "C:\Users\Public\Desktop\"

                $links = @(
                    @{site = "%windir%\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe"; name = "PowerShell ISE"; icon = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell_ise.exe, 0" },
                    @{site = "%SystemRoot%\system32\ServerManager.exe"; name = "Server Manager"; icon = "%SystemRoot%\system32\ServerManager.exe, 0" },
                    @{site = "%SystemRoot%\system32\gpmc.msc"; name = "Group Policy Management"; icon = "%SystemRoot%\system32\gpoadmin.dll, 0" },
                    @{site = "%SystemRoot%\system32\dsa.msc"; name = "AD Users and Computers"; icon = "%SystemRoot%\system32\dsadmin.dll, 0" },
                    @{site = "%SystemRoot%\system32\domain.msc"; name = "AD Domains and Trusts"; icon = "%SystemRoot%\system32\domadmin.dll, 0" },
                    @{site = "%SystemRoot%\system32\dnsmgmt.msc"; name = "DNS"; icon = "%SystemRoot%\system32\dnsmgr.dll, 0" },
                    @{site = "%windir%\system32\services.msc"; name = "Services"; icon = "%windir%\system32\filemgmt.dll, 0" }
                )

                foreach ($link in $links) {
                    $Shortcut = $WshShell.CreateShortcut("$($dt)$($link.name).lnk")
                    $Shortcut.TargetPath = $link.site
                    $Shortcut.IconLocation = $link.icon
                    $Shortcut.Save()
                }
            }
            GetScript  = { @{ } }
            TestScript = { 
                return $false
            }
        }
        #### Enable TLS 1.2 
        Script EnableTLS12 {
            SetScript  = {
                New-Item 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Force | Out-Null
                
                New-ItemProperty -path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -name 'SystemDefaultTlsVersions' -value '1' -PropertyType 'DWord' -Force | Out-Null
                
                New-ItemProperty -path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -name 'SchUseStrongCrypto' -value '1' -PropertyType 'DWord' -Force | Out-Null
                
                New-Item 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Force | Out-Null
                
                New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -name 'SystemDefaultTlsVersions' -value '1' -PropertyType 'DWord' -Force | Out-Null
                
                New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -name 'SchUseStrongCrypto' -value '1' -PropertyType 'DWord' -Force | Out-Null
                
                New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Force | Out-Null
                
                New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
                
                New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
                
                New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Force | Out-Null
                
                New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
                
                New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
                Write-Host 'TLS 1.2 has been enabled.'
            }

            GetScript  = { @{ } }
            TestScript = { 
                $test = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -ErrorAction Ignore
                return ($test -ine $null)
            }
        }

        #### CUSTOM FIREWALL BASED ON ARM TEMPLATE ####

        if ($customRdpPort -ne "3389") {

            Registry "Set Custom RDP Port" {
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
                ValueName = "PortNumber"
                ValueData = "$customRdpPort"
                ValueType = 'Dword'
            }
        
            Firewall AddFirewallRule {
                Name        = 'CustomRdpRule'
                DisplayName = 'Custom Rule for RDP'
                Ensure      = 'Present'
                Enabled     = 'True'
                Profile     = 'Any'
                Direction   = 'Inbound'
                LocalPort   = "$customRdpPort"
                Protocol    = 'TCP'
                Description = 'Firewall Rule for Custom RDP Port'
            }
        }

        #### ENABLE ROLES & FEATURES ####

        WindowsFeature DNS { 
            Ensure = "Present" 
            Name   = "DNS"		
        }

        WindowsFeature "Enable Deduplication" { 
            Ensure = "Present" 
            Name   = "FS-Data-Deduplication"		
        }

        Script EnableDNSDiags {
            SetScript  = { 
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = "[WindowsFeature]DNS"
        }

        WindowsFeature DnsTools {
            Ensure    = "Present"
            Name      = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }

        DnsServerAddress "DnsServerAddress for $InterfaceAlias"
        { 
            Address        = '127.0.0.1'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn      = "[WindowsFeature]DNS"
        }

        if ($environment -eq "AD Domain") {

            WindowsFeature ADDSInstall { 
                Ensure    = "Present" 
                Name      = "AD-Domain-Services"
                DependsOn = "[WindowsFeature]DNS" 
            } 

            WindowsFeature ADDSTools {
                Ensure    = "Present"
                Name      = "RSAT-ADDS-Tools"
                DependsOn = "[WindowsFeature]ADDSInstall"
            }

            WindowsFeature ADAdminCenter {
                Ensure    = "Present"
                Name      = "RSAT-AD-AdminCenter"
                DependsOn = "[WindowsFeature]ADDSInstall"
            }
         
            ADDomain FirstDS {
                DomainName                    = $DomainName
                Credential                    = $DomainCreds
                SafemodeAdministratorPassword = $DomainCreds
                DatabasePath                  = "$targetADPath" + "\NTDS"
                LogPath                       = "$targetADPath" + "\NTDS"
                SysvolPath                    = "$targetADPath" + "\SYSVOL"
                DependsOn                     = @("[File]ADfolder", "[WindowsFeature]ADDSInstall")
            }
        }

        WindowsFeature "RSAT-Clustering" {
            Name   = "RSAT-Clustering"
            Ensure = "Present"
        }

        WindowsFeature "Install DHCPServer" {
            Name   = 'DHCP'
            Ensure = 'Present'
        }

        WindowsFeature DHCPTools {
            Ensure    = "Present"
            Name      = "RSAT-DHCP"
            DependsOn = "[WindowsFeature]Install DHCPServer"
        }

        Registry "DHCpConfigComplete" {
            Key       = 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12'
            ValueName = "ConfigurationState"
            ValueData = "2"
            ValueType = 'Dword'
            DependsOn = "[WindowsFeature]DHCPTools"
        }

        if ($environment -eq "AD Domain") {
            WindowsFeature "Hyper-V" {
                Name   = "Hyper-V"
                Ensure = "Present"
            }
        }
        else {
            WindowsFeature "Hyper-V" {
                Name      = "Hyper-V"
                Ensure    = "Present"
                DependsOn = "[Registry]NewCredSSPKey3"
            }
        }

        WindowsFeature "RSAT-Hyper-V-Tools" {
            Name      = "RSAT-Hyper-V-Tools"
            Ensure    = "Present"
            DependsOn = "[WindowsFeature]Hyper-V" 
        }

        #### HYPER-V vSWITCH CONFIG ####

        xVMHost "hpvHost"
        {
            IsSingleInstance          = 'yes'
            EnableEnhancedSessionMode = $true
            VirtualHardDiskPath       = $targetVMPath
            VirtualMachinePath        = $targetVMPath
            DependsOn                 = "[WindowsFeature]Hyper-V"
        }

        xVMSwitch "$vSwitchNameHost"
        {
            Name      = $vSwitchNameHost
            Type      = "Internal"
            DependsOn = "[WindowsFeature]Hyper-V"
        }

        IPAddress "New IP for vEthernet $vSwitchNameHost"
        {
            InterfaceAlias = "vEthernet `($vSwitchNameHost`)"
            AddressFamily  = 'IPv4'
            IPAddress      = '192.168.0.1/16'
            DependsOn      = "[xVMSwitch]$vSwitchNameHost"
        }

        NetIPInterface "Enable IP forwarding on vEthernet $vSwitchNameHost"
        {   
            AddressFamily  = 'IPv4'
            InterfaceAlias = "vEthernet `($vSwitchNameHost`)"
            Forwarding     = 'Enabled'
            DependsOn      = "[IPAddress]New IP for vEthernet $vSwitchNameHost"
        }

        NetAdapterRdma "EnableRDMAonvEthernet"
        {
            Name      = "vEthernet `($vSwitchNameHost`)"
            Enabled   = $true
            DependsOn = "[NetIPInterface]Enable IP forwarding on vEthernet $vSwitchNameHost"
        }

        DnsServerAddress "DnsServerAddress for vEthernet $vSwitchNameHost" 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = "vEthernet `($vSwitchNameHost`)"
            AddressFamily  = 'IPv4'
            DependsOn      = "[IPAddress]New IP for vEthernet $vSwitchNameHost"
        }

        if ($environment -eq "AD Domain") {

            xDhcpServerAuthorization "Authorize DHCP" {
                IsSingleInstance='Yes' 
                Ensure    = 'Present'
                DependsOn = @('[WindowsFeature]Install DHCPServer')
                DnsName   = [System.Net.Dns]::GetHostByName($env:computerName).hostname
                IPAddress = '192.168.0.1'      
            }
        }

        if ($environment -eq "Workgroup") {
            NetConnectionProfile SetProfile
            {
                InterfaceAlias  = "$InterfaceAlias"
                NetworkCategory = 'Private'
            }
        }

        #### PRIMARY NIC CONFIG ####

        NetAdapterBinding DisableIPv6Host
        {
            InterfaceAlias = "$InterfaceAlias"
            ComponentId    = 'ms_tcpip6'
            State          = 'Disabled'
        }

        #### CONFIGURE InternaNAT NIC

        script NAT {
            GetScript  = {
                $nat = "AzSHCINAT"
                $result = if (Get-NetNat -Name $nat -ErrorAction SilentlyContinue) { $true } else { $false }
                return @{ 'Result' = $result }
            }
        
            SetScript  = {
                $nat = "AzSHCINAT"
                New-NetNat -Name $nat -InternalIPInterfaceAddressPrefix "192.168.0.0/16"          
            }
        
            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result
            }
            DependsOn  = "[IPAddress]New IP for vEthernet $vSwitchNameHost"
        }

        NetAdapterBinding DisableIPv6NAT
        {
            InterfaceAlias = "vEthernet `($vSwitchNameHost`)"
            ComponentId    = 'ms_tcpip6'
            State          = 'Disabled'
            DependsOn      = "[Script]NAT"
        }

        #### CONFIGURE DHCP SERVER

        xDhcpServerScope "AzSHCIDhcpScope" { 
            Ensure        = 'Present'
            IPStartRange  = '192.168.0.10'
            IPEndRange    = '192.168.0.149' 
            ScopeId       = '192.168.0.0'
            Name          = 'AzSHCI Lab Range'
            SubnetMask    = '255.255.0.0'
            LeaseDuration = '01.00:00:00'
            State         = "$dhcpStatus"
            AddressFamily = 'IPv4'
            DependsOn     = @("[WindowsFeature]Install DHCPServer", "[IPAddress]New IP for vEthernet $vSwitchNameHost")
        }
            # Setting scope gateway
        DhcpScopeOptionValue 'ScopeOptionGateway'
        {
            OptionId      = 3
            Value         = '192.168.0.1'
            ScopeId       = '192.168.0.0'
            VendorClass   = ''
            UserClass     = ''
            AddressFamily = 'IPv4'
            DependsOn          = "[xDhcpServerScope]AzSHCIDhcpScope"
        }

        # Setting scope DNS servers
        DhcpScopeOptionValue 'ScopeOptionDNS'
        {
            OptionId      = 6
            Value         = @('192.168.0.1')
            ScopeId       = '192.168.0.0'
            VendorClass   = ''
            UserClass     = ''
            AddressFamily = 'IPv4'
            DependsOn          = @("[xDhcpServerScope]AzSHCIDhcpScope","[DhcpScopeOptionValue] 'ScopeOptionGateway'" )
        }

        # Setting scope DNS domain name
        DhcpScopeOptionValue 'ScopeOptionDNSDomainName'
        {
            OptionId      = 15
            Value         = "$DomainName"
            ScopeId       = '192.168.0.0'
            VendorClass   = ''
            UserClass     = ''
            AddressFamily = 'IPv4'
            DependsOn          = @("[xDhcpServerScope]AzSHCIDhcpScope","[DhcpScopeOptionValue] 'ScopeOptionGateway'","[DhcpScopeOptionValue] 'ScopeOptionDNS'")
        }

<#
        xDhcpServerOption "AzSHCIDhcpServerOption" { 
            Ensure             = 'Present' 
            ScopeID            = '192.168.0.0' 
            DnsDomain          = "$DomainName"
            DnsServerIPAddress = '192.168.0.1'
            AddressFamily      = 'IPv4'
            Router             = '192.168.0.1'
            DependsOn          = "[xDhcpServerScope]AzSHCIDhcpScope"
        }
#>
        if ($environment -eq "Workgroup") {

            DnsServerPrimaryZone SetPrimaryDNSZone {
                Name          = "$DomainName"
                Ensure        = 'Present'
                DependsOn     = "[script]NAT"
                ZoneFile      = "$DomainName" + ".dns"
                DynamicUpdate = 'NonSecureAndSecure'
            }
    
            DnsServerPrimaryZone SetReverseLookupZone {
                Name          = '0.168.192.in-addr.arpa'
                Ensure        = 'Present'
                DependsOn     = "[DnsServerPrimaryZone]SetPrimaryDNSZone"
                ZoneFile      = '0.168.192.in-addr.arpa.dns'
                DynamicUpdate = 'NonSecureAndSecure'
            }
        }
        elseif ($environment -eq "AD Domain") {

            DnsServerPrimaryZone SetReverseLookupZone {
                Name      = '0.168.192.in-addr.arpa'
                Ensure    = 'Present'
                DependsOn = "[ADDomain]FirstDS"
                ZoneFile  = '0.168.192.in-addr.arpa.dns'
            }
        }

        #### FINALIZE DHCP

        Script SetDHCPDNSSetting {
            SetScript  = { 
                Set-DhcpServerv4DnsSetting -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True -UpdateDnsRRForOlderClients $True -DisableDnsPtrRRUpdate $false
                Write-Verbose -Verbose "Setting server level DNS dynamic update configuration settings"
            }
            GetScript  = { @{} 
            }
            TestScript = { $false }
            DependsOn  = @("[xDhcpServerScope]AzSHCIDhcpScope","[DhcpScopeOptionValue] 'ScopeOptionGateway'","[DhcpScopeOptionValue] 'ScopeOptionDNS'", "[DhcpScopeOptionValue] 'ScopeOptionDNSDomainName'")
            #DependsOn  = "[xDhcpServerScope] 'AzSHCIDhcpScope'" 
        }

        if ($environment -eq "Workgroup") {

            DnsConnectionSuffix AddSpecificSuffixHostNic
            {
                InterfaceAlias           = "$InterfaceAlias"
                ConnectionSpecificSuffix = "$DomainName"
                DependsOn                = "[DnsServerPrimaryZone]SetPrimaryDNSZone"
            }
    
            DnsConnectionSuffix AddSpecificSuffixNATNic
            {
                InterfaceAlias           = "vEthernet `($vSwitchNameHost`)"
                ConnectionSpecificSuffix = "$DomainName"
                DependsOn                = "[DnsServerPrimaryZone]SetPrimaryDNSZone"
            }

            #### CONFIGURE CREDSSP & WinRM

            xCredSSP Server {
                Ensure         = "Present"
                Role           = "Server"
                DependsOn      = "[DnsConnectionSuffix]AddSpecificSuffixNATNic"
                SuppressReboot = $true
            }
            xCredSSP Client {
                Ensure         = "Present"
                Role           = "Client"
                DelegateComputers = "$env:COMPUTERNAME" + ".$DomainName"
                DependsOn      = "[xCredSSP]Server"
                SuppressReboot = $true
            }

            #### CONFIGURE WinRM

            Script ConfigureWinRM {
                SetScript  = {
                    Set-Item WSMan:\localhost\Client\TrustedHosts "*.$Using:DomainName" -Force
                }
                TestScript = {
                    (Get-Item WSMan:\localhost\Client\TrustedHosts).Value -contains "*.$Using:DomainName"
                }
                GetScript  = {
                    @{Ensure = if ((Get-Item WSMan:\localhost\Client\TrustedHosts).Value -contains "*.$Using:DomainName") { 'Present' } Else { 'Absent' } }
                }
                DependsOn  = "[xCredSSP]Client"
            }
        }

        #### Start AzSHCI Node Creation ####

        script "prepareVHDX" {
            GetScript  = {
                $result = Test-Path -Path $using:azsHciVhdPath
                return @{ 'Result' = $result }
            }

            SetScript  = {
                # Create Azure Stack HCI Host Image from ISO
                
                $scratchPath = "$using:targetVMPath\Scratch"
                New-Item -ItemType Directory -Path "$scratchPath" -Force | Out-Null
                
                # Determine if any SSUs are available
                $ssu = Test-Path -Path "$using:ssuPath\*" -Include "*.msu"

                if ($ssu) {
                    Convert-WindowsImage -SourcePath $using:azsHCIISOLocalPath -SizeBytes 100GB -VHDPath $using:azsHciVhdPath `
                        -VHDFormat VHDX -VHDType Dynamic -VHDPartitionStyle GPT -Package $using:ssuPath -TempDirectory $using:targetVMPath -Verbose
                }
                else {
                    Convert-WindowsImage -SourcePath $using:azsHCIISOLocalPath -SizeBytes 100GB -VHDPath $using:azsHciVhdPath `
                        -VHDFormat VHDX -VHDType Dynamic -VHDPartitionStyle GPT -TempDirectory $using:targetVMPath -Verbose
                }

                <#
                Convert-Wim2Vhd -DiskLayout UEFI -SourcePath $using:azsHCIISOLocalPath -Path $using:azsHciVhdPath `
                   -Package $using:ssuPath -Size 100GB -Dynamic -Index 1 -ErrorAction SilentlyContinue
                   #>

                # Need to wait for disk to fully unmount
                While ((Get-Disk).Count -gt 2) {
                    Start-Sleep -Seconds 5
                }

                Start-Sleep -Seconds 5

                Mount-VHD -Path $using:azsHciVhdPath -Passthru -ErrorAction Stop -Verbose
                Start-Sleep -Seconds 2

                $disks = Get-CimInstance -ClassName Win32_DiskDrive | Where-Object Caption -eq "Microsoft Virtual Disk"            
                foreach ($disk in $disks) {            
                    $vols = Get-CimAssociatedInstance -CimInstance $disk -ResultClassName Win32_DiskPartition             
                    foreach ($vol in $vols) {            
                        $updatedrive = Get-CimAssociatedInstance -CimInstance $vol -ResultClassName Win32_LogicalDisk |            
                        Where-Object VolumeName -ne 'System Reserved'          
                    }            
                }
                $updatepath = $updatedrive.DeviceID + "\"

                $updates = get-childitem -path $using:cuPath -Recurse | Where-Object { ($_.extension -eq ".msu") -or ($_.extension -eq ".cab") } | Select-Object fullname
                foreach ($update in $updates) {
                    write-debug $update.fullname
                    $command = "dism /image:" + $updatepath + " /add-package /packagepath:'" + $update.fullname + "'"
                    write-debug $command
                    Invoke-Expression $command
                }
            
                $command = "dism /image:" + $updatepath + " /Cleanup-Image /spsuperseded"
                Invoke-Expression $command

                Dismount-VHD -path $using:azsHciVhdPath -confirm:$false

                Start-Sleep -Seconds 5

                # Enable Hyper-V role on the Azure Stack HCI Host Image
                Install-WindowsFeature -Vhd $using:azsHciVhdPath -Name Hyper-V
            }

            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result
            }
            DependsOn  = "[file]VM-Base", "[script]Download AzureStack HCI bits", "[script]Download AzSHCI SSU", "[script]Download AzSHCI CU"
        }

        for ($i = 1; $i -lt $azsHostCount + 1; $i++) {
            $suffix = '{0:D2}' -f $i
            $vmname = $("AZSHCINODE" + $suffix)
            $memory = 24gb

            file "VM-Folder-$vmname" {
                Ensure          = 'Present'
                DestinationPath = "$targetVMPath\$vmname"
                Type            = 'Directory'
                DependsOn       = "[File]VMfolder"
            }
            
            xVhd "NewOSDisk-$vmname"
            {
                Ensure     = 'Present'
                Name       = "$vmname-OSDisk.vhdx"
                Path       = "$targetVMPath\$vmname"
                Generation = 'vhdx'
                ParentPath = $azsHciVhdPath
                Type       = 'Differencing'
                DependsOn  = "[xVMSwitch]$vSwitchNameHost", "[script]prepareVHDX", "[file]VM-Folder-$vmname"
            }

            xVMHyperV "VM-$vmname"
            {
                Ensure         = 'Present'
                Name           = $vmname
                VhdPath        = "$targetVMPath\$vmname\$vmname-OSDisk.vhdx"
                Path           = $targetVMPath
                Generation     = 2
                StartupMemory  = $memory
                ProcessorCount = 8
                DependsOn      = "[xVhd]NewOSDisk-$vmname"
            }

            xVMProcessor "Enable NestedVirtualization-$vmname"
            {
                VMName                         = $vmname
                ExposeVirtualizationExtensions = $true
                DependsOn                      = "[xVMHyperV]VM-$vmname"
            }

            script "remove default Network Adapter on VM-$vmname" {
                GetScript  = {
                    $VMNetworkAdapter = Get-VMNetworkAdapter -VMName $using:vmname -Name 'Network Adapter' -ErrorAction SilentlyContinue
                    $result = if ($VMNetworkAdapter) { $false } else { $true }
                    return @{
                        VMName = $VMNetworkAdapter.VMName
                        Name   = $VMNetworkAdapter.Name
                        Result = $result
                    }
                }
    
                SetScript  = {
                    $state = [scriptblock]::Create($GetScript).Invoke()
                    Remove-VMNetworkAdapter -VMName $state.VMName -Name $state.Name                 
                }
    
                TestScript = {
                    # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                    $state = [scriptblock]::Create($GetScript).Invoke()
                    return $state.Result
                }
                DependsOn  = "[xVMHyperV]VM-$vmname"
            }

            for ($k = 1; $k -le 1; $k++) {
                $ipAddress = $('192.168.0.' + ($i + 1))
                $mgmtNicName = "$vmname-Management$k"
                xVMNetworkAdapter "New Network Adapter $mgmtNicName $vmname DHCP"
                {
                    Id         = $mgmtNicName
                    Name       = $mgmtNicName
                    SwitchName = $vSwitchNameHost
                    VMName     = $vmname
                    NetworkSetting = xNetworkSettings {
                        IpAddress      = $ipAddress
                        Subnet         = "255.255.0.0"
                        DefaultGateway = "192.168.0.1"
                        DnsServer      = "192.168.0.1"
                    }
                    Ensure     = 'Present'
                    DependsOn  = "[xVMHyperV]VM-$vmname"
                }

                cVMNetworkAdapterSettings "Enable $vmname $mgmtNicName Mac address spoofing and Teaming"
                {
                    Id                 = $mgmtNicName
                    Name               = $mgmtNicName
                    SwitchName         = $vSwitchNameHost
                    VMName             = $vmname
                    AllowTeaming       = 'on'
                    MacAddressSpoofing = 'on'
                    DependsOn          = "[xVMNetworkAdapter]New Network Adapter $mgmtNicName $vmname DHCP"
                }
            }

            for ($l = 1; $l -le 3; $l++) {
                $ipAddress = $('10.10.1' + $l + '.' + $i)
                $nicName = "$vmname-ConvergedNic$l"

                xVMNetworkAdapter "New Network Adapter Converged $vmname $nicName $ipAddress"
                {
                    Id         = $nicName
                    Name       = $nicName
                    SwitchName = $vSwitchNameHost
                    VMName     = $vmname
                    NetworkSetting = xNetworkSettings {
                        IpAddress = $ipAddress
                        Subnet    = "255.255.255.0"
                    }
                    Ensure     = 'Present'
                    DependsOn  = "[xVMHyperV]VM-$vmname"
                }
                
                cVMNetworkAdapterSettings "Enable $vmname $nicName Mac address spoofing and Teaming"
                {
                    Id                 = $nicName
                    Name               = $nicName
                    SwitchName         = $vSwitchNameHost
                    VMName             = $vmname
                    AllowTeaming       = 'on'
                    MacAddressSpoofing = 'on'
                    DependsOn          = "[xVMNetworkAdapter]New Network Adapter Converged $vmname $nicName $ipAddress"
                }
            }

            for ($j = 1; $j -lt $azsHostDataDiskCount + 1 ; $j++) { 
                xvhd "$vmname-DataDisk$j"
                {
                    Ensure           = 'Present'
                    Name             = "$vmname-DataDisk$j.vhdx"
                    Path             = "$targetVMPath\$vmname"
                    Generation       = 'vhdx'
                    Type             = 'Dynamic'
                    MaximumSizeBytes = $dataDiskSize
                    DependsOn        = "[xVMHyperV]VM-$vmname"
                }
            
                xVMHardDiskDrive "$vmname-DataDisk$j"
                {
                    VMName             = $vmname
                    ControllerType     = 'SCSI'
                    ControllerLocation = $j
                    Path               = "$targetVMPath\$vmname\$vmname-DataDisk$j.vhdx"
                    Ensure             = 'Present'
                    DependsOn          = "[xVMHyperV]VM-$vmname"
                }
            }

            script "UnattendXML for $vmname" {
                GetScript  = {
                    $name = $using:vmname
                    $result = Test-Path -Path "$using:targetVMPath\$name\Unattend.xml"
                    return @{ 'Result' = $result }
                }

                SetScript  = {
                    try {
                        $name = $using:vmname
                        $mount = Mount-VHD -Path "$using:targetVMPath\$name\$name-OSDisk.vhdx" -Passthru -ErrorAction Stop -Verbose
                        Start-Sleep -Seconds 2
                        $driveLetter = $mount | Get-Disk | Get-Partition | Get-Volume | Where-Object DriveLetter | Select-Object -ExpandProperty DriveLetter
                        
                        New-Item -Path $("$driveLetter" + ":" + "\Temp") -ItemType Directory -Force -ErrorAction Stop
                        Copy-Item -Path "$using:sourcePath\Install-AzsRolesandFeatures.ps1" -Destination $("$driveLetter" + ":" + "\Temp") -Force -ErrorAction Stop
                        
                        New-BasicUnattendXML -ComputerName $name -LocalAdministratorPassword $($using:Admincreds).Password -Domain $using:DomainName -Username $using:Admincreds.Username `
                            -Password $($using:Admincreds).Password -JoinDomain $using:DomainName -AutoLogonCount 1 -OutputPath "$using:targetVMPath\$name" -Force `
                            -PowerShellScriptFullPath 'c:\temp\Install-AzsRolesandFeatures.ps1' -ErrorAction Stop

                        Copy-Item -Path "$using:targetVMPath\$name\Unattend.xml" -Destination $("$driveLetter" + ":" + "\Windows\system32\SysPrep") -Force -ErrorAction Stop

                        Start-Sleep -Seconds 2
                    }
                    finally {
                        Dismount-VHD -Path "$using:targetVMPath\$name\$name-OSDisk.vhdx"
                    }
                    Start-VM -Name $name
                }

                TestScript = {
                    # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                    $state = [scriptblock]::Create($GetScript).Invoke()
                    return $state.Result
                }
                DependsOn  = "[xVhd]NewOSDisk-$vmname", "[script]Download DSC Config for AzsHci Hosts"
            }
        }

        #### Update AD with Cluster Info ####

        script "UpdateAD" {
            GetScript  = {
                $result = Test-Path -Path "$using:sourcePath\UpdateAD.txt"
                return @{ 'Result' = $result }
            }

            SetScript  = {
                Set-Location "$using:sourcePath\"
                .\Update-AD.ps1
                New-item -Path "$using:sourcePath\" -Name "UpdateAD.txt" -ItemType File -Force
            }

            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result
            }
            DependsOn  = "[script]UnattendXML for $vmname", '[ADDomain]FirstDS'  
        }

        #### Update WAC Extensions ####

        script "WACupdater" {
            GetScript  = {
                # Specify the WAC gateway
                $wac = "https://$env:COMPUTERNAME"

                # Add the module to the current session
                $module = "$env:ProgramFiles\Windows Admin Center\PowerShell\Modules\ExtensionTools\ExtensionTools.psm1"

                Import-Module -Name $module -Verbose -Force
                
                # List the WAC extensions
                $extensions = Get-Extension $wac | Where-Object { $_.isLatestVersion -like 'False' }
                
                $result = if ($extensions.count -gt 0) { $false } else { $true }

                return @{
                    Wac        = $WAC
                    extensions = $extensions
                    result     = $result
                }
            }
            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result
            }
            SetScript  = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                $date = get-date -f yyyy-MM-dd
                $logFile = Join-Path -Path "C:\Users\Public" -ChildPath $('WACUpdateLog-' + $date + '.log')
                New-Item -Path $logFile -ItemType File -Force
                ForEach ($extension in $state.extensions) {    
                    Update-Extension $state.wac -ExtensionId $extension.Id -Verbose | Out-File -Append -FilePath $logFile -Force
                }
            }
        }

        #### INSTALL CHOCO, DEPLOY EDGE and Shortcuts

        cChocoInstaller InstallChoco {
            InstallDir = "c:\choco"
        }
            
        cChocoFeature allowGlobalConfirmation {
            FeatureName = "allowGlobalConfirmation"
            Ensure      = 'Present'
            DependsOn   = '[cChocoInstaller]installChoco'
        }
        
        cChocoFeature useRememberedArgumentsForUpgrades {
            FeatureName = "useRememberedArgumentsForUpgrades"
            Ensure      = 'Present'
            DependsOn   = '[cChocoInstaller]installChoco'
        }
        
        cChocoPackageInstaller "Install Chromium Edge" {
            Name        = 'microsoft-edge'
            Ensure      = 'Present'
            AutoUpgrade = $true
            DependsOn   = '[cChocoInstaller]installChoco'
        }

        cShortcut "Wac Shortcut"
        {
            Path      = 'C:\Users\Public\Desktop\Windows Admin Center.lnk'
            Target    = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
            Arguments = "https://$env:computerName"
            Icon      = 'shell32.dll,34'
        }

        #### STAGE 3c - Update Firewall

        Firewall WACInboundRule {
            Name        = 'WACInboundRule'
            DisplayName = 'Allow Windows Admin Center'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = 'Any'
            Direction   = 'Inbound'
            LocalPort   = "443"
            Protocol    = 'TCP'
            Description = 'Allow Windows Admin Center'
        }

        Firewall WACOutboundRule {
            Name        = 'WACOutboundRule'
            DisplayName = 'Allow Windows Admin Center'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = 'Any'
            Direction   = 'Outbound'
            LocalPort   = "443"
            Protocol    = 'TCP'
            Description = 'Allow Windows Admin Center'
        }
    }
}
<#
$Configdata=@{
    allnodes=@(
        @{
            nodename="AzSHCIHost"
            PSDSCAllowPlainTextPassword=$true
            PSDSCAllowDomainUser=$true
            
        }
    )
    }
    
    AzSHCIHost -ConfigurationData $configdata 

#>
