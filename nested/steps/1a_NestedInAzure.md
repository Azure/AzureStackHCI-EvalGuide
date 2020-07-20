Evaluate Azure Stack HCI using Nested Virtualization in Azure
==============
Overview
-----------
With the introduction of [nested virtualization support in Azure](https://azure.microsoft.com/en-us/blog/nested-virtualization-in-azure/ "Nested virtualization announcement blog post") back in 2017, Microsoft opened the door to a number of new and interesting scenarios.  Nested virtualization in Azure is particularly useful for validating configurations that would require additional hardware in your environment, such as running Hyper-V hosts and clusters.

In this guide, you'll walk through the steps to stand up an Azure Stack HCI configuration, and key dependencies.  At a high level, this will consist of the following:

* Deploy an Azure VM, running Windows Server 2019, to act as your main Hyper-V host
* Inside the Windows Server 2019 VM, enable the Hyper-V role and accompanying management tools
* On the Windows Server 2019 VM, deploy a Windows Server 2019 domain controller, and a Windows 10 management VM, running the Windows Admin Center
* On the Windows Server 2019 VM, deploy 2-4 nested Azure Stack HCI nodes
* On the Windows 10 management VM, configure your Azure Stack HCI cluster

Contents
-----------
[Architecture](#architecture)
[Get an Azure subscription](#get-an-azure-subscription)
[Azure VM Size Considerations](#azure-vm-size-considerations)
[Deploying the Azure VM](#deploying-the-azure-vm)
[Prepare your Azure VM](#prepare-your-azure-vm)
[Next steps](#next-steps)

Architecture
-----------

From an architecture perspective, the following graphic showcases the different layers and interconnections between the different components:

![Architecture diagram for Azure Stack HCI nested in Azure](/media/nested_virt_arch.png)

Get an Azure subscription
-----------
To evaluate Azure Stack HCI, you'll need an Azure subscription.  If you already have one provided by your company, you can skip this step, but if not, you have a couple of options.

The first option would apply to Visual Studio subscribers, where you can use Azure at no extra charge. With your monthly Azure DevTest individual credit, Azure is your personal sandbox for dev/test. You can provision virtual machines, cloud services, and other Azure resources. Credit amounts vary by subscription level, but if you manage your Azure Stack HCI VM run time efficiently, you can test the scenario well within your subscription limits.

The second option would be to sign up for a [free trial](https://azure.microsoft.com/en-us/free/ "Azure free trial link"), which gives you $200 credit for the first 30 days, and 12 months of popular services for free.  The credit for the first 30 days will give you plenty of headroom to validate Azure Stack HCI.

You can also use this same Azure subscription to register your Azure Stack HCI cluster, once the deployment is completed.

Azure VM Size Considerations
-----------

Now, before you deploy the VM in Azure, it's important to choose a **size** that's appropriate for your needs for this evaluation, along with a preferred region. This deployment, by default, recommends using a **Standard_D16s_v4**, which is a general purpose VM size, with 16 vCPUs, 64 GiB memory, and no temporary SSD storage. The OS drive is 127 GiB in size. Realistically, with this size of host VM, you could nest the following:

* Windows Server 2019 Domain Controller - 2 vCPU, 2 GB memory
* Windows 10 management VM - 2 vCPU, 4 GB memory
* 2-4 Azure Stack HCI nodes, each with 4-8 vCPUs, 12-24 GB memory depending on the number of nodes you choose

These are just example numbers, and you can adjust accordingly to suit your needs, even after deployment.  The point here is, think about how many Azure Stack HCI nodes you'd like to nest inside this Azure VM, and select an Azure VM size from there.  Some good examples would be:

**D-series VMs (General purpose)**

| Size | vCPU | Memory: GiB | Temp storage (SSD): GiB | Premium Storage |
|:--|---|---|---|---|
| Standard_D8_v3  | 8  | 32   | 200   | No  |
| Standard_D8s_v3  | 8  | 32  | 64  | Yes  |
| Standard_D8_v4  | 8  | 32  | 0  | No |
| **Standard_D8s_v4**  | **8**  | **32**  | **0**  | **Yes** |
| Standard_D8d_v4 | 8 | 32  | 300  | No |
| Standard_D8ds_v4 | 8 | 32 | 300  | Yes |
| Standard_D16_v3  | 16 | 64 | 400 | No |
| Standard_D16s_v3  | 16  | 64 | 128 | Yes |
| Standard_D16_v4  | 16  | 64 | 0 | No |
| **Standard_D16s_v4**  | **16**  | **64**  | **0**  | **Yes** |
| Standard_D16d_v4 | 16 | 64  | 600 | No |
| Standard_D16ds_v4 | 16 | 64 | 600 | Yes |

For reference, the Standard_D8s_v3 VM size costs approximately US $0.38 per hour, and the Standard_D8ds_v4 VM size costs approximately US $0.45 per hour, based on East US region, under a Visual Studio subscription.

**E-series VMs (Memory optimized)**

| Size | vCPU | Memory: GiB | Temp storage (SSD): GiB | Premium Storage |
|:--|---|---|---|---|
| Standard_E8_v3  | 8  | 64   | 200   | No  |
| Standard_E8s_v3  | 8  | 64  | 128  | Yes  |
| Standard_E8_v4  | 8  | 64  | 0  | No |
| **Standard_E8s_v4**  | **8**  | **64**  | **0**  | **Yes** |
| Standard_E8d_v4 | 8 | 64  | 300  | No |
| Standard_E8ds_v4 | 8 | 64 | 300  | Yes |
| Standard_E16_v3  | 16 | 128 | 400 | No |
| Standard_E16s_v3  | 16  | 128 | 256 | Yes |
| Standard_E16_v4  | 16  | 128 | 0 | No |
| **Standard_E16s_v4**  | **16**  | **128**  | **0**  | **Yes** |
| Standard_E16d_v4 | 16 | 128  | 600 | No |
| Standard_E16ds_v4 | 16 | 128 | 600 | Yes |

For reference, the Standard_E8s_v3 VM size costs approximately US $0.50 per hour, and the Standard_E8ds_v4 VM size costs approximately US $0.58 per hour, based on East US region, under a Visual Studio subscription.

**NOTE 1** - Many of these VM sizes include temp storage, which offers high performance, but is not persistent through reboots, Azure host migrations and more. It's therefore advisable, that if you are going to be running the Azure VM for a period of time, but shutting down frequently, that you choose a VM size with no temp storage, and store your nested VMs on the local storage of the OS disk (128 GiB) or, ensure you don't store important files on the temp drive inside the VM.

**NOTE 2** - It's strongly recommended that you choose a VM size that supports **premium storage** - when running nested virtual machines, increasing the number of available IOPS can have a significant impact on performance, hence choosing **premium storage** over Standard HDD or Standard SSD, is strongly advised.  Refer to the table above to make the most appropriate selection.

Ensure that whichever VM size you choose, it [supports nested virtualization](https://docs.microsoft.com/en-us/azure/virtual-machines/acu "Nested virtualization support") and is [available in your chosen region](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=virtual-machines "Virtual machines available by region").

Deploying the Azure VM
-----------
The guidance below provides 2 main options for deploying the Azure VM.

1. The first option, is to perform a deployment via a [custom Azure Resource Manager template](#option-1---creating-the-vm-with-an-azure-resource-manager-json-template). This option can be launched quickly, directly from the button within the documentation, and after completing a simple form, your VM will be deployed.
2. The second option, is a [deployment directly from PowerShell](#option-2---creating-the-azure-vm-with-powershell), which is fast, but still requires some additional steps if you wish to enable auto-shutdown of the VM.

### Option 1 - Creating the VM with an Azure Resource Manager JSON Template ###
To keep things simple, and graphical to begin with, we'll show you how to deploy your VM via an Azure Resource Manager template.  To simplify things further, we'll use the following buttons.

Firstly, the **Visualize** button will launch the ARMVIZ designer view, where you will see a graphic representing the core components of the deployment, including the VM, NIC, disk and more. If you want to open this in a new tab, **hold CTRL** when you click the button.

[![Visualize your template deployment](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzureStackHCI-EvalGuide%2Fmain%2Fnested%2Fjson%2Fazshcilabvm.json)

Secondly, the **Deploy to Azure** button, when clicked, will take you directly to the Azure portal, and upon login, provide you with a form to complete. If you want to open this in a new tab, **hold CTRL** when you click the button.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzureStackHCI-EvalGuide%2Fmain%2Fnested%2Fjson%2Fazshcilabvm.json)

Upon clicking the **Deploy to Azure** button, enter the details, which should look something similar to those shown below, and click **Purchase**.

![Custom template deployment in Azure](/media/azure_vm_custom_template.png)

**NOTE** - For customers with Software Assurance, Azure Hybrid Benefit for Windows Server allows you to use your on-premises Windows Server licenses and run Windows virtual machines on Azure at a reduced cost. By selecting **Yes** for the "Already have a Windows Server License", **you confirm I have an eligible Windows Server license with Software Assurance or Windows Server subscription to apply this Azure Hybrid Benefit** and have reviewed the [Azure hybrid benefit compliance](http://go.microsoft.com/fwlink/?LinkId=859786 "Azure hybrid benefit compliance document")

The custom template will be validated, and if all of your entries are correct, you can click **Create**. Within a few minutes, your VM will be created.

![Custom template deployment in Azure completed](/media/azure_vm_custom_template_complete.png)

If you chose to **enable** the auto-shutdown for the VM, and supplied a time, and time zone, but want to also add a notification alert, simply click on the **Go to resource group** button and then perform the following steps:

1. In the **Resource group** overview blade, click the **AzSHCIHost001** virtual machine
2. Once on the overview blade for your VM, **scroll down on the left-hand navigation**, and click on **Auto-shutdown**
3. Ensure the Enabled slider is still set to **On** and that your **time** and **time zone** information is correct
4. Click **Yes** to enable notifications, and enter a Webhook URL, or Email address
5. Click **Save**

You'll now be notified when the VM has been successfully shut down as the requested time.

### Option 2 - Creating the Azure VM with PowerShell ###
For simplicity and speed, can also use PowerShell on our local workstation to deploy the Windows Server 2019 VM to Azure.  As an alternative, you can take the following commands, edit them, and run them directly in [PowerShell in Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart-powershell "PowerShell in Azure Cloud Shell").  For the purpose of this guide, we'll assume you're using the PowerShell console/ISE or Windows Terminal locally on your workstation.

#### Update the Execution Policy ####
In this step, you'll update your PowerShell execution policy to RemoteSigned

```powershell
# Get the Execution Policy on the system, and make note of it before making changes
Get-Execution Policy
# Set the Execution Policy for this process only
if ((Get-ExecutionPolicy) -ne "RemoteSigned") { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force }
```

#### Download the Azure PowerShell modules ####
In order for us to create a new VM in Azure, we'll need to ensure we have the latest Azure PowerShell modules

> [!WARNING]
> We do not support having both the AzureRM and Az modules installed for PowerShell 5.1 on Windows at the same time. If you need to keep AzureRM available on your system, install the Az module for > PowerShell 6.2.4 or later.

```powershell
# Install latest NuGet provider
Install-PackageProvider -Name NuGet -Force

# Check if the AzureRM PowerShell modules are installed - if so, present a warning
if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
        'Az modules installed at the same time is not supported.')
} else {
    # If no AzureRM PowerShell modules are detected, install the Azure PowerShell modules
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}
```
By default, the PowerShell gallery isn't configured as a trusted repository for PowerShellGet so you may be prompted to allow installation from this source, and trust the repository. Answer **(Y) Yes** or **(A) Yes to All** to continue with the installation.  The installation will take a few moments to complete, depending on your download speeds.

#### Sign into Azure ####
With the modules installed, you can sign into Azure.  By using the Login-AzAccount, you'll be presented with a login screen for you to authenticate with Azure.  Use the credentials that have access to the subscription where you'd like to deploy this VM.

```powershell
# Login to Azure
Login-AzAccount
```

When you've successfully logged in, you will be presented with the default subscription and tenant associated with those credentials.

![Result of Login-AzAccount](/media/Login-AzAccount.png)

If this is the subscription and tenant you wish to use for this evaluation, you can move on to the next step, however if you wish to deploy the VM to an alternative subscription, you will need to run the following commands:

```powershell
# Optional - if you wish to switch to a different subscription
# First, get all available subscriptions as the currently logged in user
$context = Get-AzContext -ListAvailable
# Display those in a grid, select the chosen subscription, then press OK.
if (($context).count -gt 1) {
    $context | Out-GridView -OutputMode Single | Set-AzContext
}
```

With login successful, and the target subscription confirmed, you can move on to deploy the VM.

#### Deploy the VM with PowerShell ####
In order to keep things as streamlined and quick as possible, we're going to be deploying the VM that will host Azure Stack HCI, using PowerShell.  As an alternative option, we will provide an alternative method using the Azure Portal and an Azure Resource Manager Template, in JSON format.

In the below script, feel free to change the VM Name, along with other parameters.  The public DNS name for this VM will be generated by combining your VM name, with a random guid, to ensure it is unique, and the deployment completes without conflicts.

```powershell
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
    -SecurityGroupName "AzSHCILabNSG" `
    -PublicIpAddressName "AzSHCILabPubIP" `
    -DomainNameLabel "$dnsName"
    -OpenPorts 3389 `
    -ImageName Win2019Datacenter `
    -Size Standard_D16s_v3 `
    -Credential (Get-Credential) `
    # -LicenseType "Windows_Server" ` # Only used if you have existing Windows Server licenses with Software Assurance (See below)
    -Verbose
```

**NOTE 1** - You'll be prompted to supply a credential for the VM - simply enter a username of your choice, and strong password.

**NOTE 2** - When running the above script, if your VM size contains an 's', such as 'Standard_E16**s**_v4' it will use **Premium LRS storage**. If it does not contain an 's', it will deploy with a Standard HDD, which will impact performance. Refer to the [table earlier](#azure-vm-size-considerations) to determine the appropriate size for your deployment.

**NOTE 3** - For customers with Software Assurance, Azure Hybrid Benefit for Windows Server allows you to use your on-premises Windows Server licenses and run Windows virtual machines on Azure at a reduced cost. By removing the comment in the script above, for the -LicenseType parameter, **you confirm you have an eligible Windows Server license with Software Assurance or Windows Server subscription to apply this Azure Hybrid Benefit** and have reviewed the [Azure hybrid benefit compliance document](http://go.microsoft.com/fwlink/?LinkId=859786 "Azure hybrid benefit compliance document")

Once you've made your size and region selection, based on the information provided earlier, run the PowerShell script and wait a few moments for your VM deployment to complete.

![Virtual machine successfully deployed with PowerShell](/media/powershell_vm_deployed.png)

With the VM successfully deployed, make a note of the fully qualified domain name, as you'll use that to connect to the VM shortly.



#### OPTIONAL - Enable Auto-Shutdown for your VM ####
One way to control costs, is to ensure your VM automatically shuts down at the end of each day.  Enabling this feature requires you to log into the Azure portal, and perform a few steps:

Firstly, visit https://portal.azure.com/, and login with the same credentials used earlier.  Once logged in, using the search box on the dashboard, enter "azshci" and once the results are returned, click on your AzSHCIHost virtual machine.

![Virtual machine located in Azure](/media/azure_vm_search.png)

1. Once on the overview blade for your VM, **scroll down on the left-hand navigation**, and click on **Auto-shutdown**
2. Click the Enabled slider to **On**
3. Enter your **scheduled shutdown time**, **time zone** and **notification information**
4. Click **Save**

![Enable VM auto-shutdown in Azure](/media/auto_shutdown.png)

Prepare your Azure VM
-----------

With your Azure VM (AzSHCIHost001) successfully deployed, you're ready to configure the VM to allow creation of the the Windows Server 2019 domain controller, the Windows 10 management VM, and the Azure Stack HCI nodes.

### Update your Azure VM ###
Firstly, you'll need to connect into the VM, with the easiest approach being via Remote Desktop.  If you're not already logged into the Azure portal, visit https://portal.azure.com/, and login with the same credentials used earlier.  Once logged in, using the search box on the dashboard, enter "**azshci**" and once the results are returned, **click on your AzSHCIHost001 virtual machine**.

![Virtual machine located in Azure](/media/azure_vm_search.png)

Once you're on the Overview blade for your VM, along the top of the blade, click on **Connect** and from the drop-down options.

![Connect to a virtual machine in Azure](/media/connect_to_vm.png)

Select **RDP**. On the newly opened Connect blade, ensure the **Public IP** is selected, and the port is **3389**, click **Download RDP File** and select a suitable folder to store the .rdp file.

![Configure RDP settings for Azure VM](/media/connect_to_vm_properties.png)

Once downloaded, locate the .rdp file on your local machine, and double-click to open it. Click **connect** and when prompted, enter the credentials you supplied when creating the VM earlier. Accept any certificate prompts, and within a few moments, you should be successfully logged into the Windows Server 2019 VM.

Now that you're successfully connected to the VM, it's a good idea to ensure your OS is running the latest security updates and patches. VMs deployed from marketplace images in Azure, should already contain most of the latest updates, however it's worthwhile checking for any additional updates, and applying them as necessary.

1. Open the **Start Menu** and search for **Update**
2. In the results, select **Check for Updates**
3. In the Updates window, click **Check for updates**. If any are required, ensure they are downloaded and installed.
4. Restart if required, and once completed, re-connect your RDP session using the steps earlier.

With the OS updated, and back online after any required reboot, it's now time to enable the Hyper-V role and accompanying PowerShell management modules.

### Configure the Hyper-V host ###
In order to run our nested workloads, you first need to enable the Hyper-V role within Windows Server 2019, and the accompanying PowerShell modules. In addition, you'll create a special NAT switch, to ensure that your nested workloads can access the internet, using the Windows Server 2019 host as the NAT gateway.

The quickest, and easiest way to enable the required Hyper-V role and accompanying management tools, is using PowerShell.  Firstly, open PowerShell **as an administrator** and run the following command:

```powershell
# Install the Hyper-V role and management tools, including PowerShell
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
```

>[!WARNING]
>
>This command restarts the Azure VM. You will lose your RDP connection during the restart process.

Once the Azure VM has fully restarted, which may take a few minutes, reconnect to your VM using the previously downloaded .rdp file.  Once connected, the next step is to configure the NAT virtual switch on the VM, to enable your VMs to access the internet.

#### Configure Internal NAT vSwitch ####
Both Windows 10 Hyper-V, and Windows Server 2019 Hyper-V allow native network address translation (NAT) for a virtual network. NAT gives a virtual machine access to network resources using the host computer's IP address and a port through an internal Hyper-V Virtual Switch.  It doesn't require you to expose the sandbox VMs directly onto your physical network, or in this case, your Azure vNET.

If you're not familiar, Network Address Translation (NAT) is a networking mode designed to conserve IP addresses by mapping an external IP address and port to a much larger set of internal IP addresses. Basically, a NAT uses a flow table to route traffic from an external (host) IP Address and port number to the correct internal IP address associated with an endpoint on the network (virtual machine, computer, container, etc.)

To configure the network switch, open PowerShell **as an administrator** and run the following command:

```powershell
# Create a new internal virtual switch on the host
New-VMSwitch -Name "InternalNAT" -SwitchType Internal
# Create an IP address for the NAT Gateway
New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceAlias "vEthernet (InternalNAT)"
# Create the new NAT network
New-NetNat -Name "AzSHCINAT" -InternalIPInterfaceAddressPrefix 192.168.0.0/24
# Check the NAT configuration
Get-NetNat
```
The **Get-NetNat** cmdlet gets Network Address Translation (NAT) objects configured on a computer. NAT modifies IP address and port information in packet headers. Your configuration should look similar to the configuration below:

![Result of Get-NetNat PowerShell command](/media/get_net_nat.png)

The final part of the process is to enable Enhanced Session mode.  Enhanced Session mode can be useful to enhance the user experience, particularly when using the Windows 10 VM later, when connecting to a VM over VMConnect.  To enable Enhanced Session Mode with PowerShell, run the following on AzSHCIHost001:

```powershell
Set-VMhost -EnableEnhancedSessionMode $True
```

Next Steps
-----------
In this step, you've successfully created your Azure VM, and configured Windows Server 2019 with the Hyper-V role, and core networking to support the nested scenario.  You're now ready to start creating your virtual machines as part of deploying your management infrastructure. You have 2 choices on how to proceed, either a more graphical way, using a GUI (Graphical User Interface, such as Hyper-V Manager, Server Manager etc), or via PowerShell.  Make your choice below:

* [**Part 2a** - Deploy your management infrastructure with the GUI](/nested/steps/2a_ManagementInfraGUI.md "Deploy your management infrastructure with the GUI")
* [**Part 2b** - Deploy your management infrastructure with PowerShell](/nested/steps/2b_ManagementInfraPS.md "Deploy your management infrastructure with PowerShell")
