Deploy management infrastructure with the GUI
==============
Overview
-----------

With your Hyper-V host up and running, either in Azure, or on a local physical system, it's now time to deploy the core management infrastructure to support the Azure Stack HCI deployment in a future step.

### Important Note ###
In this step, you'll be using the GUI (Graphical User Interface, such as Hyper-V Manager, Server Manager etc) to create resources.  If you prefer to use PowerShell, which may allow faster completion, head on over to the [PowerShell guide](/nested/steps/2b_ManagementInfraPS.md).

Architecture
-----------

As shown on the architecture graphic below, the core management infrastructure consists of a Windows Server 2019 domain controller VM, along with a Windows 10 Enterprise VM, which will run the Windows Admin Center.  In this step, you'll deploy both of those key components.

![Architecture diagram for Azure Stack HCI nested with management infra highlighted](/media/nested_virt_mgmt.png)

However, before you deploy your management infrastructure, first, you need to download the necessary software components required to complete this evalution.

Download artifacts
-----------
In order to deploy our nested virtual machines on AzSHCIHost001, we'll first need to download the appropriate ISOs and files for the following operating systems:

* Windows Server 2019 Evaluation
* Windows 10 Enterprise Evaluation (x64)
* Azure Stack HCI Public Preview
* Windows Admin Center

Before downloading, create a new folder on your AzSHCIHost001 machine, to contain the downloaded ISO files.

1. Open **File Explorer** and navigate to **This PC** and double-click on your **C:**
2. **Right-click** in the white-space and select **New** then **Folder**
3. Name the folder **ISO** and close File Explorer.


#### For Windows Server 2019 Hyper-V hosts ####
If you're running Windows Server 2019 as your Hyper-V host, it doesn't ship with the new Microsoft Edge by default, so unless you've chosen to install an alternative web browser, you'll have to use Internet Explorer initially.  Out of the box, Windows Server 2019 also has **Internet Explorer Protected Mode** enabled, which helps to protect users when browsing the internet. To streamline the download of the ISO files, we'll disable IE Protected Mode for the administrator account.

1. Click **Start** and open **Server Manager**
2. On the main dashboard, click on **Configure this local server**
3. In the **Properties** view, find the **IE Enhanced Security Configuration** item, and click on **On**
4. In the **Internet Explorer Enhanced Security Configuration** window, under **Administrators**, click **Off** and click **OK**

![Setting the Internet Explorer Enhanced Security Configuration to Off](/media/ie_enhanced.png)

5. Close **Server Manager**

#### Download the files ####
Next, in order to download the ISO files, **open your web browser** and follow the steps below.

1. Visit https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019, complete the registration form, and download the ISO.  Save the file as **WS2019.iso** to C:\ISO
2. Visit https://www.microsoft.com/en-us/evalcenter/evaluate-windows-10-enterprise, complete the registration form, and download the x64 ISO.  Save the file as **W10.iso** to C:\ISO
3. Visit --link--, complete the registration form, and download the ISO.  Save the file as **AzSHCI.iso** to C:\ISO
4. Visit --link--, complete any necessary registration, and download the executables for the Windows Admin Center, storing them in C:\ISO

![All files have been downloaded onto your Hyper-V host](/media/download_files.png)

With all files downloaded, proceed on to creating your management infrastructure.

Create your domain controller
-----------
There are 3 main steps to create the virtualized domain controller on our Hyper-V host:

1. Create the DC01 VM using Hyper-V Manager
2. Complete the Out of Box Experience (OOBE)
3. Configure the domain controller with AD and DNS roles

### Create the DC01 VM using Hyper-V Manager ###
In this step, you'll be using Hyper-V Manager to deploy a Windows Server 2019 domain controller. With this being the GUI guide, you'll be deploying Windows Server with the Desktop Experience.

1. On your Hyper-V host, **open Hyper-V Manager**.
2. In the top right-corner, under **Actions**, click **New**, then **Virtual Machine**. The **New Virtual Machine Wizard** should open.
3. On the **Before you begin** page, click **Next**
4. On the **Specify Name and Location** page, enter **DC01**
5. Tick the box for **Store the virtual machine in a different location** and click **Browse**
6. In the **Select Folder** window, click on **This PC**, navigate to **C:**, click on **New Folder**, name it **VMs** then click **Select Folder** and click **Next**

![Specify VM name and location](/media/new_vm_name.png)

7. On the **Specify Generation** page, select **Generation 2** and click **Next**
8. On the **Assign Memory** page, assign 4GB memory by entering **4096** for Startup memory and tick the **Use Dynamic Memory for this virtual machine**, then click **Next**

![Assign VM memory](/media/new_vm_dynamicmem.png)

9. On the **Configure Networking** page, select **InternalNAT** and click **Next**
10. On the **Connect Virtual Hard Disk** page, change **size** to **30** and click **Next**

![Connect Virtual Hard Disk](/media/new_vm_vhd.png)

11. On the **Installation Options** page, select **Install an operating system from a bootable image file**, and click **Browse**
12. Navigate to **C:\ISO** and select your **WS2019.iso** file, and click **Open**.  Then click **Next**
13. On the **Completing the New Virtual Machine Wizard** page, review the information and click **Finish**

Your new DC01 virtual machine will now be created.  Once created, we need to make a few final modifications. To optimize the VM's use of available memory, especially on physical systems with lower physical memory, you can optionally configure the VM with Dynamic Memory, which will allow Hyper-V to allocate memory to the VM, based on it's requirements, and remove memory when idle.  This can help to free up valuable host resources in memory-constrained environments.

1. In **Hyper-V Manager**, right-click **DC01** and click **Settings**
2. In the **Settings** window, under **Memory**, in the **Dynamic Memory** section, enter the following figures, then click **OK**
   * Minimum RAM: 1024
   * Maximum RAM: 4096

![Updating memory for DC01](/media/dynamicmem.png)

With the VM configured correctly, in **Hyper-V Manager**, double-click DC01.  This should open the VM Connect window.

![Starting up DC01](/media/startvm.png)

In the center of the window, there is a message explaining the VM is currently switched off.  Click on **Start** and then quickly **press any key** inside the VM to boot from the ISO file. If you miss the prompt to press a key to boot from CD or DVD, simply reset the VM and try again.

![Booting the VM and triggering the boot from DVD](/media/boot_from_dvd.png)

### Complete the Out of Box Experience (OOBE) ###
With the VM running, and the boot process initiated, you should be in a position to start the deployment of the Windows Server 2019 OS.

![Initiate setup of the Windows Server 2019 OS](/media/ws_setup.png)

Proceed through the process, making the following selections:

1. On the initial screen, select your **Language to install**, **Time and currency format**, and **Keyboard or input method**, then press **Next**
2. Click **Install now**
3. On the **Select the operating system** screen, choose **Windows Server 2019 Datacenter Evaluation (Desktop Experience)** and click **Next**
4. On the **Applicable notices and license terms** screen, read the information, **tick I accept the license terms** and click **Next**
5. On the **What type of installation do you want** screen, select **Custom: Install Windows only (advanced)** and click **Next**
6. On the **Where do you want to install Windows?** screen, select the **30GB Drive 0** and click **Next**

Installation will then begin, and will take a few minutes, automatically rebooting as part of the process.

With the installation complete, you'll finish on the **Customize settings** screen.  Provide a password and click **Finish**.  Once at the login screen, click on the **Ctrl + Alt + Delete button** in the top-left-hand corner of the VM Connect window, and login to DC01.

### Configure the domain controller with AD and DNS roles ###
With the VM successfully deployed, you can now configure the Windows Server 2019 OS to become the core domain infrastructure for your sandbox environment.

#### Configure the networking and host name on DC01 ####
Firstly, you will configure the networking inside the VM and rename the OS, before rebooting.

1. In **Server Manager**, from the **Dashboard**, click on **Configure this local server**
2. In the **Properties** window, next to **Computer name**, click on your current randomly generated computer name
3. In the **System properties** window, click **Change** and change the computer name to **DC01**, then click **OK**
4. Click **OK** again to close the notification, then click **Close**, and choose **Restart Later**
5. Back in the **Properties** window, next to **Ethernet**, click on **IPv4 address assigned by DHCP, IPv6 enabled**
6. In the **Network Connections** window, right-click on the **Ethernet** adapter and select **Properties**
7. Click on **Internet Protocol Version 4 (TCP/IPv4)**, and click **Properties**
8. Enter the following information, then click **OK**, and then **Close**

   * IP address: 192.168.0.2
   * Subnet mask: 255.255.255.0
   * Default gateway: 192.168.0.1
   * Preferred DNS server: 1.1.1.1
   * Alternate DNS server: 1.0.0.1

![Network settings for DC01](/media/dc_nic.png)

#### Optional - Update DC01 with latest Windows Updates ####
If you'd like to ensure DC01 is fully updated, click on **Start**, search for **Updates** and select **Check for Updates** in the results.  Check for any new updates and install any that are required.  This may take a few minutes.

Once complete, proceed to **reboot DC01**.

#### Configure the Active Directory role on DC01 ####
With the OS configured, you can now move on to configuring the Windows Server 2019 OS with the appropriate roles and features to support the domain infrastructure.

First, you'll configure Active Directory:

1. If not already open, open **Server Manager**, and after it has finished refreshing, click on **Manage**, then **Add Roles and Features**
2. On the **Before you begin** page, click **Next**
3. On the **Select installation type** page, click **Next**
4. On the **Select destination server** page, click **Next**
5. On the **Select server roles** page, click **Active Directory Domain Services**
6. In the **Add Roles and Features wizard** popup, click **Add Features**
7. On the **Select server roles** page, click **DNS Server**
8. In the **Add Roles and Features wizard** popup, click **Add Features**, then click **Next**
9. On the **Select features** page, click **Next**
10. On the **Active Directory Domain Services** page, click **Next**
11. On the **DNS Server** page, click **Next**
12. On the **Confirmation** page, review the information and click **Install**

![Active Directory Domain Services installation progress](/media/dc_install_progress.png)

The installation of Active Directory Domain Services will begin, and take a few moments to complete.  Once complete, click **Promote this server to a domain controller** to continue the configuration of DC01. The **Active Directory Domain Services Configuration Wizard** should open.

1. On the **Deployment configuration** page, select **Add a new forest**, enter **azshci.local** as the Root domain name, and click **Next**

![Active Directory Domain Services configuration wizard](/media/adds_wizard.png)

2. On the **Domain Controller options** page, leave the defaults, provide a **Directory Services Restore Mode (DSRM) password**, then click **Next**
3. On the **DNS Options** page, click **Next**
4. On the **Additional Options** page, click **Next**
5. On the **Paths** page, leave the defaults and click **Next**
6. On the **Review Options** page, validate your selections, then click **Next**

The prerequisites will then be checked, and once completed, click **Install**. This will take a few moments.

![Active Directory Domain Services configuration wizard prerequisites check](/media/adds_prereq.png)

Once completed, DC01 should reboot automatically, but if not, ensure you reboot it yourself.

#### Add additional domain administrative account ####

Rather than use the main domain admin account, we'll add an additional administrative user to work with going forward. Once DC01 has finished rebooting, log in with the new domain admin account:

* Username: azshci.local\administrator
* Password: admin-password-you-entered-earlier

1. Once logged into DC01 with the domain admin account, click **Start** and search for "users"
2. In the results, click on **Active Directory Users and Computers**
3. In the **Active Directory Users and Computers** window, expand the **azshci.local domain** right-click on the **Users** OU, select **New** then **User**.  Enter the following details, then click **Next**

   * First name: Lab
   * Last name: Admin
   * Full name: Lab Admin
   * User logon name: labadmin

![Active Directory Domain Services New Object wizard - adding a user](/media/adds_new_user.png)

4. Provide a password for this new account, and **tick the Password never expires** box, then click **Next**, then click **Finish**
5. Click on the **Users** OU, and find the new **Lab Admin** account
6. Right-click the **Lab Admin** account, and click **Add to a group...**
7. In the **Select Groups** window, in the **Enter the object names to select** box, enter **Domain Admins**, **Schema Admins** and **Enterprise Admins**, clicking **Check Names** after each one, then click **OK**, then **OK** to close the confirmation popup

![Active Directory Domain Services New Object wizard - adding a user to groups](/media/adds_group.png)

8. Close the **Active Directory Users and Computers** window

With Active Directory and DNS configured, you can now move on to deploying the Windows 10 Enterprise VM, that will be used to run the Windows Admin Center.

Create your Windows 10 Management VM
-----------
There are 3 main steps to create the virtualized Windows 10 Management VM on our Hyper-V host:

1. Create the MGMT01 VM using Hyper-V Manager
2. Complete the Out of Box Experience (OOBE)
3. Join the domain, and install Windows Admin Center

### Create the DC01 VM using Hyper-V Manager ###
In this step, you'll be using Hyper-V Manager to deploy a Windows 10 Enterprise management virtual machine.

1. On your Hyper-V host, **open Hyper-V Manager**.
2. In the top right-corner, under **Actions**, click **New**, then **Virtual Machine**. The **New Virtual Machine Wizard** should open.
3. On the **Before you begin** page, click **Next**
4. On the **Specify Name and Location** page, enter **MGMT01**
5. Tick the box for **Store the virtual machine in a different location** and click **Browse**
6. In the **Select Folder** window, click on **This PC**, navigate to **C:**, click on **VMs**, click **Select Folder** and click **Next**

![Specify VM name and location](/media/new_vm_mgmt01.png)

7. On the **Specify Generation** page, select **Generation 2** and click **Next**
8. On the **Assign Memory** page, assign 4GB memory by entering **4096** for Startup memory and tick the **Use Dynamic Memory for this virtual machine**, then click **Next**

![Assign VM memory](/media/new_vm_dynamicmem.png)

9. On the **Configure Networking** page, select **InternalNAT** and click **Next**
10. On the **Connect Virtual Hard Disk** page, change **size** to **30** and click **Next**

![Connect Virtual Hard Disk](/media/new_vm_mgmt01_vhd.png)

11. On the **Installation Options** page, select **Install an operating system from a bootable image file**, and click **Browse**
12. Navigate to **C:\ISO** and select your **W10.iso** file, and click **Open**.  Then click **Next**
13. On the **Completing the New Virtual Machine Wizard** page, review the information and click **Finish**

Your new MGMT01 virtual machine will now be created.  Once created, we need to make a few final modifications. To optimize the VM's use of available memory, especially on physical systems with lower physical memory, you can optionally configure the VM with Dynamic Memory, which will allow Hyper-V to allocate memory to the VM, based on it's requirements, and remove memory when idle.  This can help to free up valuable host resources in memory-constrained environments.

1. In **Hyper-V Manager**, right-click **MGMT01** and click **Settings**
2. In the **Settings** window, under **Memory**, in the **Dynamic Memory** section, enter the following figures, then click **OK**

   * Minimum RAM: 2048
   * Maximum RAM: 4096

![Updating memory for MGMT01](/media/dynamicmem_mgmt01.png)

With the VM configured correctly, in **Hyper-V Manager**, double-click MGMT01.  This should open the VM Connect window.

![Starting up MGMT01](/media/startvm_mgmt01.png)

In the center of the window, there is a message explaining the VM is currently switched off.  Click on **Start** and then quickly **press any key** inside the VM to boot from the ISO file. If you miss the prompt to press a key to boot from CD or DVD, simply reset the VM and try again.

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

![Initiate setup of the Windows 10 OS](/media/w10_install_complete.png)

1. On the **Sign in with Microsoft** page, select **Domain join instead**
2. On the **Who's going to use this PC** page, enter **LocalAdmin** and click **Next**
3. On the **Create a super memorable password** page, for simplicity, enter a previously used password and click **Next**
4. Enter your password again on the **Confirm your password** page, then click **Next**
5. For the security questions, provide answers for 3 questions, and click **Next**
6. On the **Choose privacy settings for your device** page, make your adjustments and click **Accept**
7. On the next few screens, make your desired selections for the services, and the install process will finish.  This will take a few minutes.

Once complete, you should be logged in on the Windows 10 machine.

### Configure MGMT01 networking ###
With MGMT01 up and running, it's time to configure the networking so it can communicate with DC01.

1. In the bottom-right corner, right-click the NIC icon, and select **Open Network & Internet settings**

![Select NIC](/media/nic_adapter.png)

2. In the **Settings** window, click on **Ethernet** and then click on the **Ethernet adapter** shown in the central window
3. Under **IP settings**, click **Edit**, then enter the following information, then click **Save** and close **Settings**
   * Manual
   * IPv4: On
   * IP address: 192.168.0.3
   * Subnet prefix length: 24
   * Gateway: 192.168.0.1
   * Preferred DNS: 192.168.0.2

![Setting static NIC settings](/media/ip_settings.png)

#### Optional - Update your Windows 10 OS ####

With the networking all configured and up and running, it's a good idea to ensure your OS is running the latest security updates and patches.

1. On the **Taskbar**, click into the **search box** and enter **Update**
2. In the results, select **Check for Updates**
3. In the Updates window within Settings, click **Check for updates**. If any are required, ensure they are downloaded and installed.  This will take a few minutes.
4. Restart if required

### Join your Windows 10 VM to the domain ###
Before installing the Windows Admin Center, you'll join MGMT01 to the azshci.local domain. The easiest way to do this, and rename the PC in one step with the GUI, is to use **sysdm.cpl**

1. Ensure you're logged into MGMT01, then click on **Start** and enter **sysdm.cpl**, then in the results, select **sysdm.cpl**

![Open the System Properties dialog box](/media/sysdm.png)

2. In the **System Properties** window, click on **Change**, then enter the following details, then click **OK**

    * Computer name: **MGMT01**
    * Member of: **Domain:** **azshci.local**

3. When prompted for credentials, enter the following, and click **OK**

    * Username: **azshci\labadmin**
    * Password: **LabAdmin-password-you-entered-earlier**

This may take a few moments, but should then join the machine to the domain.  **Reboot** the machine when prompted.

#### Optional - Install the new Microsoft Edge ####
It's highly recommended to install the new version of the Microsoft Edge browser, as it gives a much smoother browsing experience, and is more efficient with it's use of limited resources, if you've deployed in a memory-constrained environment.

1. Open the existing **Microsoft Edge** browser, and navigate to https://www.microsoft.com/en-us/edge
2. On the landing page, click on **Download** and when prompted, **read the license terms** then click **Accept and download**
3. Once downloaded, click **Run**
4. The installation will begin, and take a few moments to download, install and configure.  You can accept the **defaults** for the configuration.

### Install Windows Admin Center on Windows 10 ###
With the Windows 10 VM now deployed and configured, the final step in the infrastructure preparation, is to install and configure the Windows Admin Center. Earlier in this guide, you should have downloaded the Windows Admin Center files, along with other ISOs.

Firstly, navigate to C:\ISO, or wherever you chose to store your ISOs and Windows Admin Center executable.  Select the Windows Admin Center executable, **right-click** and select **copy**.

Navigate to **Hyper-V Manager**, locate **MGMT01** and double-click the VM.  This will open the VM Connect window.  If you haven't set this already, you should be presented with a **Connect to MGMT01** screen.  Ensure that the display size is set to **Full Screen** and using the **Show Options** dropdown, ensure that **Save my settings for future connections to this virtual machine** is ticked, then click **Connect**.

![Establish a VM Connect session to MGMT01](/media/connect_to_mgmt01.png)

**NOTE** if you don't see the prompt for **Enhanced Session Mode**, simply click on the **Enhanced Session** button in the VM Connect window to activate it, and define your default settings.

![Enhanced Session Mode button](/media/enhanced_session.png)

When prompted, enter your Lab Admin credentials to log into MGMT01.  When on the desktop, **right-click** and select **paste** to transfer the Windows Admin Center executable onto the desktop of MGMT01.

To install the Windows Admin Center, simply **double-click** the executable on the desktop, and follow the installation steps, making the following selections:

1. Read the license terms, then tick the box next to **I accept these terms**, then click **Next**
2. On the **Use Microsoft update** screen, select to **Use Microsoft Update when i check for updates (recommended)**, and click **Next**
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
In this step, you've successfully created your management infrastructure, including a Windows Server 2019 domain controller and a Windows 10 management VM, complete with Windows Admin Center. You can now proceed to [create your nested Azure Stack HCI nodes with the GUI](/nested/steps/3a_AzSHCINodesGUI.md "Create your nested Azure Stack HCI nodes with the GUI").