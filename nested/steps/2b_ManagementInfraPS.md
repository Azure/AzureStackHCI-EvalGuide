Deploy management infrastructure with PowerShell
==============
Overview
-----------

With your Hyper-V host up and running, either in Azure, or on a local physical system, it's now time to deploy the core management infrastructure to support the Azure Stack HCI deployment in a future step.

### Important Note ###
In this step, you'll be using PowerShell to create resources.  If you prefer to use a GUI (Graphical User Interface, such as Hyper-V Manager, Server Manager etc), which may allow faster completion, head on over to the [GUI guide](/nested/steps/2a_ManagementInfraGUI.md).

Architecture
-----------

As shown on the architecture graphic below, the core management infrastructure consists of a Windows Server 2019 domain controller VM, along with a Windows 10 Enterprise VM, which will run the Windows Admin Center.  In this step, you'll deploy both of those key components.

![Architecture diagram for Azure Stack HCI nested with management infra highlighted](/media/nested_virt_mgmt.png)

However, before you deploy your management infrastructure, first, you need to download the necessary software components required to complete this evalution.

Download artifacts
-----------
In order to deploy our nested virtual machines on AzSHCIHost001, we'll first need to download the appropriate ISOs and files for the following operating systems:

* Windows Server 2019 Evaluation
* Windows 10 Enterprise Evaluation
* Azure Stack HCI Public Preview
* Windows Admin Center

Before downloading, create a new folder on your AzSHCIHost001 machine, to contain the downloaded ISO files

```powershell
# Create a new folder to hold the downloaded ISO files
New-Item -Path "C:\" -Name "ISO" -ItemType "directory"
```
#### For Windows Server 2019 Hyper-V hosts ####
If you're running Windows Server 2019 as your Hyper-V host, it doesn't ship with the new Microsoft Edge by default, so unless you've chosen to install an alternative web browser, you'll have to use Internet Explorer initially.  Out of the box, Windows Server 2019 also has **Internet Explorer Protected Mode** enabled, which helps to protect users when browsing the internet. To streamline the download of the ISO files, we'll disable IE Protected Mode for the administrator account, by running the following script in PowerShell **as administrator**:

```powershell
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer
```
#### Download the files ####
Next, in order to download the ISO files, **open your web browser** and follow the steps below.

1. Visit https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019, complete the registration form, and download the ISO.  Save the file as **WS2019.iso** to C:\ISO
2. Visit https://www.microsoft.com/en-us/evalcenter/evaluate-windows-10-enterprise, complete the registration form, and download the ISO.  Save the file as **W10.iso** to C:\ISO
3. Visit --link--, complete the registration form, and download the ISO.  Save the file as **AzSHCI.iso** to C:\ISO
4. Visit --link--, complete any necessary registration, and download the executables for the Windows Admin Center, storing them in C:\ISO

![All files have been downloaded onto your Hyper-V host](/media/download_files.png)

With all files downloaded, proceed on to creating your management infrastructure.

Create your domain controller
-----------
There are 3 main steps to create the virtualized domain controller on our Hyper-V host:

1. Create the DC01 VM using PowerShell
2. Complete the Out of Box Experience (OOBE)
3. Configure the domain controller with AD, DNS and DHCP roles, all using PowerShell

For speed, we'll use PowerShell to configure as much as we can, but if you have experience with creating virtualized domain controllers using the Hyper-V Manager GUI, feel free to take that approach.

### Create the DC01 VM using PowerShell ###
On your AzSHCIHost001 VM, **open PowerShell as administrator**.  Make any changes that you require, to the script below, and then run it:

```powershell
# Define the characteristics of the VM, and create
New-VM `
    -Name "DC01" `
    -MemoryStartupBytes 4GB `
    -SwitchName "InternalNAT" `
    -Path "C:\VMs\" `
    -NewVHDPath "C:\VMs\DC01\Virtual Hard Disks\DC01.vhdx" `
    -NewVHDSizeBytes 30GB `
    -Generation 2
```

To optimize the VM's use of available memory, especially on physical systems with lower physical memory, you can optionally configure the VM with Dynamic Memory, which will allow Hyper-V to allocate memory to the VM, based on it's requirements, and remove memory when idle.  This can help to free up valuable host resources in memory-constrained environments.

```powershell
# Optionally configure the VM with Dynamic Memory
Set-VMMemory DC01 -DynamicMemoryEnabled $true -MinimumBytes 1GB -StartupBytes 4GB -MaximumBytes 4GB
```
Once the VM is successfully created, you should connect the Windows Server 2019 ISO file, downloaded earlier.

```powershell
# Add the DVD drive, attach the ISO to DC01 and set the DVD as the first boot device
$DVD = Add-VMDvdDrive -VMName DC01 -Path C:\ISO\WS2019.iso -Passthru
Set-VMFirmware -VMName DC01 -FirstBootDevice $DVD
```
With the VM configured correctly, you can use the following commands to connect to the VM using VM Connect, and at the same time, start the VM.  To boot from the ISO, you'll need to click on the VM and quickly press a key to trigger the boot from the DVD inside the VM.  If you miss the prompt to press a key to boot from CD or DVD, simply reset the VM and try again.

```powershell
# Open a VM Connect window, and start the VM
vmconnect.exe localhost DC01
Start-VM -Name DC01
```

![Booting the VM and triggering the boot from DVD](/media/boot_from_dvd.png)

### Complete the Out of Box Experience (OOBE) ###
With the VM running, and the boot process initiated, you should be in a position to start the deployment of the Windows Server 2019 OS.

![Initiate setup of the Windows Server 2019 OS](/media/ws_setup.png)

Proceed through the process, making the following selections:

1. On the initial screen, select your **Language to install**, **Time and currency format**, and **Keyboard or input method**, then press **Next**
2. Click **Install now**
3. On the **Select the operating system** screen, choose **Windows Server 2019 Datacenter Evaluation** and click **Next**
4. On the **Applicable notices and license terms** screen, read the information, **tick I accept the license terms** and click **Next**
5. On the **What type of installation do you want** screen, select **Custom: Install Windows only (advanced)** and click **Next**
6. On the **Where do you want to install Windows?** screen, select the **30GB Drive 0** and click **Next**

Installation will then begin, and will take a few minutes, automatically rebooting as part of the process.

![Initiate setup of the Windows Server 2019 OS](/media/ws_install_complete.png)

With the installation complete, you'll be prompted to change the password before logging in.  Enter a password, and once complete, you should be at the **C:\Users\Administrator** screen.  You can **close** the VM Connect window, as we will continue configuring the domain controller using PowerShell, from AzSHCIHost001.

### Configure the domain controller with AD, DNS and DHCP roles ###
With the VM successfully deployed, you can now configure the Windows Server 2019 OS to become the core domain infrastructure for your sandbox environment. To simplify the process, you'll use PowerShell, but from the Hyper-V host, into the VM, using PowerShell Direct.

#### Configure the networking and host name on DC01 ####
Firstly, configure the networking inside the VM, rename, before rebooting the OS.

```powershell
# Provide a password for the VM that you set in the previous step
$dcCreds = Get-Credential -UserName "Administrator" -Message "Enter the password used when you deployed Windows Server 2019"
Invoke-Command -VMName "DC01" -Credential $dcCreds -ScriptBlock {
    # Configure new IP address for DC01 NIC
    New-NetIPAddress -IPAddress "192.168.0.2" -DefaultGateway "192.168.0.1" -InterfaceAlias "Ethernet" -PrefixLength "24" | Out-Null
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("1.1.1.1")
    $dcIP = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet" | Select-Object IPAddress
    Write-Verbose "The currently assigned IPv4 address for DC01 is $($dcIP.IPAddress)" -Verbose 
    # Update Hostname to DC01
    Write-Verbose "Updating Hostname for DC01" -Verbose
    Rename-Computer -NewName "DC01"
}

Write-Verbose "Rebooting DC01 for hostname change to take effect" -Verbose
Stop-VM -Name DC01
Start-VM -Name DC01

# Test for the DC01 to be back online and responding
while ((Invoke-Command -VMName DC01 -Credential $dcCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
}
Write-Verbose "DC01 is now online. Proceed to the next step...." -Verbose
```

Once the DC01 VM is back online and responding, we will move on to configuring the domain controller.

#### Optional - Update DC01 with latest Windows Updates ####
If you'd like to ensure DC01 is fully updated, you can run the following PowerShell command that will invoke Windows Update using WMI/CIM methods. The alternative is to connect to the VM via vmconnect.exe, launch **sconfig** and run the update manually from that interface.  Whilst you're free to do that, going via PowerShell Direct is straightforward and quick, however the update process may take a few minutes.

**NOTE** the code below is specific to Windows Server 2019.

```powershell
$dcCreds = Get-Credential -UserName "Administrator" -Message "Enter the password used when you deployed Windows Server 2019"
Invoke-Command -VMName "DC01" -Credential $dcCreds -ScriptBlock {
    # Scane for updates
    $ScanResult = Invoke-CimMethod -Namespace "root/Microsoft/Windows/WindowsUpdate" -ClassName "MSFT_WUOperations" `
    -MethodName ScanForUpdates -Arguments @{SearchCriteria = "IsInstalled=0" }
    # Apply updates (if not empty)
    if ($ScanResult.Updates) {
        Invoke-CimMethod -Namespace "root/Microsoft/Windows/WindowsUpdate" -ClassName "MSFT_WUOperations" `
        -MethodName InstallUpdates -Arguments @{Updates = $ScanResult.Updates }
    }
}

Write-Verbose "Rebooting DC01 to finish installing updates" -Verbose
Stop-VM -Name DC01
Start-VM -Name DC01

# Test for the DC01 to be back online and responding
while ((Invoke-Command -VMName DC01 -Credential $dcCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
}
Write-Verbose "DC01 is now online. Proceed to the next step...." -Verbose
```

#### Configure the Active Directory role on DC01 ####
With the OS configured, you can now move on to configuring the Windows Server 2019 OS with the appropriate roles and features to support the domain infrastructure.

First, you'll configure Active Directory - the following code block will remotely connect to DC01, enable the Active Directory role, and apply a configuration as defined in the script block below.  Firstly, you should optionally set the Directory Services Restore Mode password, or just leave as the default below.

```powershell
# Configure Active Directory on DC01
Invoke-Command -VMName DC01 -Credential $dcCreds -ScriptBlock {
    # Set the Directory Services Restore Mode password
    $DSRMPWord = ConvertTo-SecureString -String "Password01" -AsPlainText -Force
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Install-ADDSForest `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainMode 7 `
        -DomainName "azshci.local" `
        -ForestMode 7 `
        -InstallDns:$true `
        -SafeModeAdministratorPassword $DSRMPWord `
        -LogPath "C:\Windows\NTDS" `
        -NoRebootOnCompletion:$true `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true
}
```

When the process is completed successfully, you should see a message similar to this below. Once validated, you should be able to reboot the domain controller and proceed on through the process.

![Active Directory role successfully install and domain controller configured](/media/dc_created.png)

```powershell
Write-Verbose "Rebooting DC01 to finish installing of Active Directory" -Verbose
Stop-VM -Name DC01
Start-VM -Name DC01

# Set updated domain credentials based on previous credentials
$domainName = "azshci.local"
$domainAdmin = "$domainName\administrator"
$domainCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $domainAdmin, $dcCreds.Password

# Test for the DC01 to be back online and responding
while ((Invoke-Command -VMName DC01 -Credential $domainCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
}
Write-Verbose "DC01 is now online. Proceed to the next step...." -Verbose
```

With DC01 now back online and operational, we need to add an additional administrative user, aside from the core administrator account.

```powershell
Write-Verbose "Creating new administrative User within the azshci.local domain." -Verbose
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
 
Write-Verbose "User: $newUser created." -Verbose
```

You can move on to the next step - enabling the DHCP role.

#### Configure the DHCP role on DC01 ####
In order to simplify network management in the sandboxed environment, you will now enable DHCP on DC01.

```powershell
# Set updated domain credentials based on new credentials
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $domainAdmin, $dcCreds.Password

# Configure the DHCP role on DC01
Invoke-Command -VMName DC01 -Credential $domainCreds -ScriptBlock {
    # Install DHCP Server
    Install-WindowsFeature -Name DHCP -IncludeManagementTools
    # Authorize
    Add-DhcpServerInDC -DnsName DC01
    # Add DHCP scope
    Add-DhcpServerv4Scope -StartRange "192.168.0.3" -EndRange "192.168.0.100" -Name ManagementScope `
    -LeaseDuration "00:08:00" -SubnetMask "255.255.255.0" -State Active
    # Add DHCP scope options
    Set-DhcpServerv4OptionValue -OptionId 6 -Value "192.168.0.2" -ScopeId "192.168.0.0"
    Set-DhcpServerv4OptionValue -OptionId 3 -Value "192.168.0.1" -ScopeId "192.168.0.0"
    Set-DhcpServerv4OptionValue -OptionId 15 -Value "azshci.local" -ScopeId "192.168.0.0"
}
```

When the process is completed successfully, you should see a message similar to this below.

![DHCP role successfully configured on DC01](/media/dhcp_enabled.png)

With Active Directory, DNS and DHCP all configured, you can now move on to deploying the Windows 10 Enterprise VM, that will be used to run the Windows Admin Center.

Create your Windows 10 Management VM
-----------
There are 3 main steps to create the virtualized Windows 10 Management VM on our Hyper-V host:

1. Create the MGMT01 VM using PowerShell
2. Complete the Out of Box Experience (OOBE)
3. Join the domain, and install Windows Admin Center

For speed, we'll use PowerShell to configure as much as we can, but if you prefer to create the Windows 10 Management VM using the Hyper-V Manager GUI, feel free to take that approach.

### Create the MGMT01 VM using PowerShell ###
On your AzSHCIHost001 VM, **open PowerShell as administrator**.  Make any changes that you require, to the script below, and then run it:

```powershell
# Define the characteristics of the VM, and create
New-VM `
    -Name "MGMT01" `
    -MemoryStartupBytes 4GB `
    -SwitchName "InternalNAT" `
    -Path "C:\VMs\" `
    -NewVHDPath "C:\VMs\MGMT01\Virtual Hard Disks\MGMT01.vhdx" `
    -NewVHDSizeBytes 30GB `
    -Generation 2
```

To optimize the VM's use of available memory, especially on physical systems with lower physical memory, you can optionally configure the VM with Dynamic Memory, which will allow Hyper-V to allocate memory to the VM, based on it's requirements, and remove memory when idle.  This can help to free up valuable host resources in memory-constrained environments.

```powershell
# Optionally configure the VM with Dynamic Memory
Set-VMMemory MGMT01 -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes 4GB -MaximumBytes 4GB
```
Once the VM is successfully created, you should connect the Windows 10 Enterprise Evaluation ISO file, downloaded earlier.

```powershell
# Add the DVD drive, attach the ISO to DC01 and set the DVD as the first boot device
$DVD = Add-VMDvdDrive -VMName MGMT01 -Path C:\ISO\W10.iso -Passthru
Set-VMFirmware -VMName MGMT01 -FirstBootDevice $DVD
```
With the VM configured correctly, you can use the following commands to connect to the VM using VM Connect, and at the same time, start the VM.  To boot from the ISO, you'll need to click on the VM and quickly press a key to trigger the boot from the DVD inside the VM.  If you miss the prompt to press a key to boot from CD or DVD, simply reset the VM and try again.

```powershell
# Open a VM Connect window, and start the VM
vmconnect.exe localhost MGMT01
Start-VM -Name MGMT01
```

![Booting the VM and triggering the boot from DVD](/media/boot_from_dvd.png)

### Complete the Out of Box Experience (OOBE) ###
With the VM running, and the boot process initiated, you should be in a position to start the deployment of the Windows 10 OS.

![Initiate setup of Windows 10](/media/w10_setup.png)

Proceed through the process, making the following selections:

1. On the initial screen, select your **Language to install**, **Time and currency format**, and **Keyboard or input method**, then press **Next**
2. Click **Install now**
3. On the **Applicable notices and license terms** screen, read the information, **tick I accept the license terms** and click **Next**
4. On the **What type of installation do you want** screen, select **Custom: Install Windows only (advanced)** and click **Next**
5. On the **Where do you want to install Windows?** screen, select the **30GB Drive 0** and click **Next**

Installation will then begin, and will take a few minutes, automatically rebooting as part of the process.

With the installation complete, you'll be prompted to finish the out of box experience, including **choosing your region**, **keyboard layout** and finally, setting a username and password.

![Initiate setup of the Windows Server 2019 OS](/media/w10_install_complete.png)

1. On the **Sign in with Microsoft** page, select **Domain join instead**
2. On the **Who's going to use this PC** page, enter **LocalAdmin** and click **Next**
3. On the **Create a super memorable password** page, for simplicity, enter a previously used password and click **Next**
4. Enter your password again on the **Confirm your password** page, then click **Next**
5. For the security questions, provide answers for 3 questions, and click **Next**
6. On the **Choose privacy settings for your device** page, make your adjustments and click **Accept**
7. On the next few screens, make your desired selections for the services, and the install process will finish.  This will take a few minutes.

Once complete, you should be logged in on the Windows 10 machine.

#### Optional - Update your Windows 10 OS ####

It's a good idea to ensure your OS is running the latest security updates and patches.

1. On the **Taskbar**, click into the **search box** and enter **Update**
2. In the results, select **Check for Updates**
3. In the Updates window within Settings, click **Check for updates**. If any are required, ensure they are downloaded and installed.  This will take a few minutes.
4. Restart if required

You can then **close** the VM Connect window, as we will continue configuring MGMT01 using PowerShell, from your Hyper-V host.

### Join your Windows 10 VM to the domain ###
To simplify the domain join of the machine to your sandbox domain environment, use the following PowerShell script:

```powershell
# Define local Windows 10 credentials
$w10Creds = Get-Credential -UserName "LocalAdmin" -Message "Enter the password used when you deployed Windows 10"
# Define domain-join credentials
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = Get-Credential -UserName "$domainAdmin" -Message "Enter the password for the LabAdmin account"
Invoke-Command -VMName "MGMT01" -Credential $w10Creds -ScriptBlock {
    param ($domainCreds)
    # Update Hostname to MGMT01
    Write-Verbose "Updating Hostname for MGMT01" -Verbose
    Rename-Computer -NewName "MGMT01"
    Add-Computer –DomainName azshci.local -NewName "MGMT01" –Credential $domainCreds -Force
} -ArgumentList $domainCreds

Write-Verbose "Rebooting MGMT01 for hostname change to take effect" -Verbose
Stop-VM -Name MGMT01
Start-VM -Name MGMT01

# Test for the MGMT01 to be back online and responding
while ((Invoke-Command -VMName MGMT01 -Credential $domainCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
}
Write-Verbose "MGMT01 is now online. Proceed to the next step...." -Verbose
```

### Install Windows Admin Center on Windows 10 ###
With the Windows 10 VM now deployed and configured, the final step in the infrastructure preparation, is to install and configure the Windows Admin Center. Earlier in this guide, you should have downloaded the Windows Admin Center files, along with other ISOs.

Firstly, navigate to C:\ISO, or wherever you chose to store your ISOs and Windows Admin Center executable.  Select the Windows Admin Center executable, **right-click** and select **copy**.

Once located, open a PowerShell console **as administrator** and run the following:

```powershell
vmconnect.exe localhost MGMT01
```

This will open the VM Connect window.  You should be presented with a **Connect to MGMT01** screen.  Ensure that the display size is set to **Full Screen** and using the **Show Options** dropdown, ensure that **Save my settings for future connections to this virtual machine** is ticked, then click **Connect**.

![Establish a VM Connect session to MGMT01](/media/connect_to_mgmt01.png)

When prompted, enter your Lab Admin credentials to log into MGMT01.  When on the desktop, **right-click** and select **paste** to transfer the Windows Admin Center executable onto the desktop of MGMT01.

To install the Windows Admin Center, simply **double-click** the executable on the desktop, and follow the installation steps, making the following selections:

1. Read the license terms, then tick the box next to **I accept these terms**, then click **Next**
2. On the **Use Microsoft update** screen, select to **Use Microsoft Update when i check for updates (recommended)** and click **Next**
3. On the **Install Windows Admin Center on Windows 10** screen, read the installation information, then click **Next**
4. On the **Installing Windows Admin Center** screen, tick the **Create a desktop shortcut...** box, and click **Install**. The install process will take a few minutes, and once completed, you should be presented with some certificate information.

![Windows Admin Center installed](/media/wac_installed.png)

5. Tick the **Open Windows Admin Center** box, and click **Finish**
6. Windows Admin Center will now open on https://localhost:port/
7. Once open, you may receive notifications in the top-right corner, indicating that some extensions may require updating.

![Windows Admin Center extensions available](/media/extension_update.png)

8. If you do require extension updates, click on the notification, then **Go to Extensions**
9. On the **Extensions** page, you'll find a list of installed extensions.  Any that require an update will be listed:

![Windows Admin Center extensions required](/media/extension_update_needed.png)

10. Click on the extension, and click **Update**. This will take a few moments, and will reload the page when complete.  With the extensions updated, navigate back to the Windows Admin Center homepage.

Next Steps
-----------
In this step, you've successfully created your management infrastructure, including a Windows Server 2019 domain controller and a Windows 10 management VM, complete with Windows Admin Center. You can now proceed to [create your nested Azure Stack HCI nodes with PowerShell](/nested/steps/3b_AzSHCINodesPS.md "Create your nested Azure Stack HCI nodes with PowerShell")