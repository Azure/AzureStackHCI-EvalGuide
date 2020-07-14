if ((Get-ExecutionPolicy) -ne "RemoteSigned") { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force }

# Install latest NuGet provider
Install-PackageProvider -Name NuGet -Force

# Check if the AzureRM PowerShell modules are installed - if so, present a warning
if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
        'Az modules installed at the same time is not supported.')
}
else {
    # If no AzureRM PowerShell modules are detected, install the Azure PowerShell modules
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}

# Login to Azure
Login-AzAccount

# Optional - if you wish to switch to a different subscption
$context = Get-AzContext -ListAvailable
if (($context).count -gt 1) {
    $context | Out-GridView -OutputMode Single | Set-AzContext
}

# Enter the desired name for your VM
$vmName = "AzSHCIHost001"
# Generate a random guid to ensure unique public DNS name
$randomGuid = ((New-Guid).ToString()).Substring(0, 6)
# Generate public DNS name
$dnsName = ("$vmName" + "$randomGuid").ToLower()

New-AzVM `
    -ResourceGroupName "AzSHCILab" `
    -Name "$vmName" `
    -Location "westus2" `
    -VirtualNetworkName "AzSHCILabvNet" `
    -SubnetName "AzSHCILabSubnet" `
    -SecurityGroupName "AzSHCILabSG" `
    -PublicIpAddressName "AzSHCILabPubIP" `
    -DomainNameLabel "$dnsName"
    -OpenPorts 3389 `
    -ImageName Win2019Datacenter `
    -Size Standard_D16s_v3 `
    -Credential (Get-Credential) `
    -Verbose

    New-VM `
        -Name "DC01" `
        -MemoryStartupBytes 4GB `
        -SwitchName "InternalNAT" `
        -Path "C:\VMs\DC01\" `
        -NewVHDPath "C:\VMs\DC01\VHD\DC01.vhdx" `
        -NewVHDSizeBytes 30GB `
        -Generation 2

        $DVD = Add-VMDvdDrive -VMName DC01 -Path C:\ISO\WS2019.iso -Passthru
        Set-VMFirmware -VMName DC01 -FirstBootDevice $DVD
        Start-VM -Name DC01
        vmconnect.exe localhost DC01


$dcCreds = Get-Credential -UserName "Administrator" -Message "Enter the password used when you deployed Windows Server 2019"
$domainMode = "7";
$forestMode = "7";
$domainName = "azshci.local";
$domainAdmin = "$domainName\administrator"
$domainCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $domainAdmin, $dcCreds.Password
# Optional - change the Directory Services Restore Mode password
$DSRMPWord = ConvertTo-SecureString -String "Password01" -AsPlainText -Force


$dcCreds = Get-Credential -UserName "Administrator" -Message "Enter the password used when you deployed Windows Server 2019"
Invoke-Command -VMName "DC01" -Credential $dcCreds -ScriptBlock {
    New-NetIPAddress -IPAddress "192.168.0.2" -DefaultGateway "192.168.0.1" -InterfaceAlias "Ethernet 2" -PrefixLength "24" | Out-Null
    $dcIP = Get-NetIPAddress -InterfaceAlias "Ethernet 2" | Select-Object IPAddress
    Write-Verbose "Assigned IPv4 and IPv6 IPs for DC01 are as follows" -Verbose 
    Write-Host $dcIP | Format-List
    Write-Verbose "Updating Hostname for DC01" -Verbose
    Rename-Computer -NewName "DC01"
}
 
Write-Verbose "Rebooting DC01 for hostname change to take effect" -Verbose
Stop-VM -Name DC01
Start-VM -Name DC01

# Test for the DC01 to be back online and responding
while ((Invoke-Command -VMName DC01 -Credential $dcCreds { "Testing Connectivity" } -ErrorAction SilentlyContinue) -ne "Testing Connectivity") {
    Start-Sleep -Seconds 1
}
Write-Verbose "DC01 is now online. Proceed to the next step...." -Verbose


# Set domain name and define credentials based on previous credentials
$domainName = "azshci.local";
$domainAdmin = "$domainName\administrator"
$domainCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $domainAdmin, $dcCreds.Password

# Set the Directory Services Restore Mode password
$DSRMPWord = ConvertTo-SecureString -String "Password01" -AsPlainText -Force
# Configure Active Directory on DC01
Invoke-Command -VMName DC01 -Credential $dcCreds -ScriptBlock {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Install-ADDSForest `
        CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainMode 7 `
        -DomainName "azshci.local" `
        -ForestMode 7 `
        -InstallDns:$true `
        -SafeModeAdministratorPassword $DSRMPWord `
        -LogPath "C:\Windows\NTDS" `
        -NoRebootOnCompletion:$false `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true
}


Invoke-Command -VMName "DC01" -Credential $dcCreds -ScriptBlock {
    $ScanResult = Invoke-CimMethod -Namespace "root/Microsoft/Windows/WindowsUpdate" -ClassName "MSFT_WUOperations" -MethodName ScanForUpdates -Arguments @{SearchCriteria = "IsInstalled=0" }
    #apply updates (if not empty)
    if ($ScanResult.Updates) {
        Invoke-CimMethod -Namespace "root/Microsoft/Windows/WindowsUpdate" -ClassName "MSFT_WUOperations" -MethodName InstallUpdates -Arguments @{Updates = $ScanResult.Updates }
    }
}

#install DHCP Server
Install-WindowsFeature -Name DHCP -IncludeManagementTools
#authorize
Add-DhcpServerInDC -DnsName dc01
#add scope
Add-DhcpServerv4Scope -StartRange 10.0.0.10 -EndRange 10.0.0.254 -Name ManagementScope -LeaseDuration "00:08:00" -SubnetMask "255.255.255.0"
#add Scope options
Set-DhcpServerv4OptionValue -OptionId 6 -Value "10.0.0.1" -ScopeId "10.0.0.0"
Set-DhcpServerv4OptionValue -OptionId 3 -Value "10.0.0.1" -ScopeId "10.0.0.0"
Set-DhcpServerv4OptionValue -OptionId 15 -Value "corp.contoso.com" -ScopeId "10.0.0.0"

$newUser = "LabAdmin"
Invoke-Command -VMName DC01 -Credential $domainCreds -ScriptBlock {
    param ($domainCreds)
    Write-Verbose "Waiting for AD Web Services to be in a running state" -Verbose
    $ADWebSvc = Get-Service ADWS | Select-Object *
    while($ADWebSvc.Status -ne 'Running')
            {
            Start-Sleep -Seconds 1
            }
    Do {
    Start-Sleep -Seconds 30
    Write-Verbose "Waiting for AD to be Ready for User Creation" -Verbose
    New-ADUser -Name "$newUser" -AccountPassword $domainCreds.Password -Enabled $True
    $ADReadyCheck = Get-ADUser -Identity "$newUser"
    }
    Until ($ADReadyCheck.Enabled -eq "True")
    Add-ADGroupMember -Identity "Domain Admins" -Members "$newUser"
    Add-ADGroupMember -Identity "Enterprise Admins" -Members $newUser
    Add-ADGroupMember -Identity "Schema Admins" -Members $newUser
    } -ArgumentList $domainCreds, $newUser
 
Write-Verbose "User: $newUser Created." -Verbose