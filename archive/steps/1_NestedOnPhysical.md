Evaluate Azure Stack HCI 20H2 using Nested Virtualization on a single physical system
==============
Overview
-----------
Nested virtualization was first introduced to Hyper-V in the 4th Technical Preview of Windows Server 2016, and primarily unlocked new capabilities for secured, isolated containerized workloads, known as Hyper-V Containers.  However, as a result of this work, IT Pros can now harness the power of nested virtualization to create and run virtualized Hyper-V hosts, in sandboxed environments, without the need for additional hardware.  This is great for training, evaluations and more.

In this guide, you'll walk through the steps to stand up an Azure Stack HCI 20H2 configuration, and key dependencies, all running on a single piece of physical hardware.  At a high level, this will consist of the following:

* Enabling the Hyper-V role and management tools on your Windows Server 2016/2019 or Windows 10 Pro/Enterprise/Education physical system.
* On your Hyper-V host, deploy a Windows Server 2019 domain controller, and a Windows 10 management VM, running the Windows Admin Center
* On your Hyper-V host, deploy 2 Azure Stack HCI 20H2 nodes with nested virtualization enabled
* On the Windows 10 management VM, configure your Azure Stack HCI 20H2 cluster

Contents
-----------
- [Overview](#overview)
- [Contents](#contents)
- [Architecture](#architecture)
- [Will my hardware support this?](#will-my-hardware-support-this)
- [Get an Azure subscription](#get-an-azure-subscription)
- [Configuring your Hyper-V host](#configuring-your-hyper-v-host)
- [Next Steps](#next-steps)
- [Product improvements](#product-improvements)
- [Raising issues](#raising-issues)

Architecture
-----------

From an architecture perspective, the following graphic showcases the different layers and interconnections between the different components:

![Architecture diagram for Azure Stack HCI 20H2 nested on a physical system](/archive/media/nested_virt_physical_ga.png "Architecture diagram for Azure Stack HCI 20H2 nested on a physical system")

Will my hardware support this?
-----------
If you're thinking about running this all on a laptop, it's certainly possible. Many modern laptops ship with powerful multi-core CPUs, and high-performance flash storage.  Neither of these components are likely to be a blocker to your evaluation; most likely memory will be the biggest consideration, but if we optimize accordingly, you can still deploy all of the key components and have a good experience.  Most laptops today support up to 16GB memory, but many ship with less.  For the purpose of this guide, your minimum recommended hardware requirements are:

* 64-bit Processor with Second Level Address Translation (SLAT).
* CPU support for VM Monitor Mode Extension (VT-x on Intel CPU's).
* 16GB memory
* 100GB+ SSD/NVMe Storage

The following items will need to be enabled in the system BIOS:

* Virtualization Technology - may have a different label depending on motherboard manufacturer.
* Hardware Enforced Data Execution Prevention.

### Important note for systems with AMD CPUs ###
For those of you wanting to evaluate Azure Stack HCI 20H2 in a nested configuration, with **AMD-based systems**, the only way this is currently possible is to use **Windows 10 Insider Build 19636 or newer** as your Hyper-V host. Your system should have AMD's 1st generation Ryzen/Epyc or newer CPUs. You can get more information on [nested virtualization on AMD here](https://techcommunity.microsoft.com/t5/virtualization/amd-nested-virtualization-support/ba-p/1434841 "Nested virtualization on AMD-based systems").

If you can't run the Windows 10 Insider builds on your AMD-based system, it may be a better approach to [deploy in Azure instead](/archive/steps/1b_NestedInAzure.md "Deploy in Azure").  We'll be sure to update this guidance as and when new updates to nested virtualization support become available.

### Verify Hardware Compatibility ###
After checking the operating system and hardware requirements above, verify hardware compatibility in Windows by opening a PowerShell session or a command prompt (cmd.exe) window, typing **systeminfo**, and then checking the Hyper-V Requirements section. If all listed Hyper-V requirements have a value of **Yes**, your system can run the Hyper-V role. If any item returns No, check the requirements above and make adjustments where possible.

![Hyper-V requirements](/archive/media/systeminfo_upd.png "Hyper-V requirements")

If you run **systeminfo** on an existing Hyper-V host, the Hyper-V Requirements section reads:

```
Hyper-V Requirements: A hypervisor has been detected. Features required for Hyper-V will not be displayed.
```

With 16GB memory, running on a laptop, we'll need to ensure that we're taking advantage of features in Hyper-V, such as Dynamic Memory, to optimize the memory usage as much as possible, to ensure you can experience as much as possible on the system you have available.

**NOTE** When you configure your nested Azure Stack HCI 20H2 nodes later, they will **require a minimum of 4GB RAM per node**, otherwise, they won't boot, so on a 16GB system, expect 2-3 nodes plus management infrastructure realistically - if you see the screenshot below, on my 16GB laptop, you'll see 2 Azure Stack HCI 20H2 nodes, with DC01/MGMT01, with a little memory left over for the host.

![Azure Stack HCI 20H2 cluster running on a laptop](/archive/media/azshci_laptop.png "Azure Stack HCI 20H2 cluster running on a laptop")

Obviously, if you have a larger physical system, such as a workstation, or server, you'll likely have a greater amount of memory available to you, therefore you can adjust the memory levels for the different resources accordingly.

If your physical system doesn't meet these recommended requirements, you're still free to test, and see if you can proceed with lower numbers, but it may be a better approach to [deploy in Azure instead](/archive/steps/1b_NestedInAzure.md "Deploy in Azure")

#### Reducing memory consumption ####
To reduce the memory requirements of the configuration, you could choose not to deploy in a sandbox envinronment.  By removing the domain controller and management virtual machines, you could free up additional memory that could be used for the nested Azure Stack HCI 20H2 nodes themselves.  However, this will require you to have an existing domain environment accessible, and an alternative location, potentially on the host itself, to install the Windows Admin Center.  This approach will **not** be covered as part of these initial guides, but may be evaluated for later versions.

If you do want to skip deployment of the management infrastructure, install the Windows Admin Center, and jump ahead to [deploy your nested Azure Stack HCI 20H2 nodes](/archive/steps/3a_AzSHCINodesGUI.md "deploying your Azure Stack HCI 20H2 nodes").  Bear in mind, you may need to modify certain steps to account for the different management environment.

Get an Azure subscription
-----------
To evaluate Azure Stack HCI 20H2, you'll need an Azure subscription.  If you already have one provided by your company, you can skip this step, but if not, you have a couple of options.

The first option would apply to Visual Studio subscribers, where you can use Azure at no extra charge. With your monthly Azure DevTest individual credit, Azure is your personal sandbox for dev/test. You can provision virtual machines, cloud services, and other Azure resources. Credit amounts vary by subscription level, but if you manage your Azure Stack HCI 20H2 VM run time efficiently, you can test the scenario well within your subscription limits.

The second option would be to sign up for a [free trial](https://azure.microsoft.com/en-us/free/ "Azure free trial link"), which gives you $200 credit for the first 30 days, and 12 months of popular services for free.  The credit for the first 30 days will give you plenty of headroom to validate Azure Stack HCI 20H2.

You can also use this same Azure subscription to register your Azure Stack HCI 20H2 cluster, once the deployment is completed.

Configuring your Hyper-V host
-----------
For the purpose of this guide, we'll assume you've deployed one of the following operating systems (all of which support Hyper-V) onto a [suitable piece of hardware](#will-my-hardware-support-this)

* Windows Server 2016
* Windows Server 2019
* Windows 10 Pro
* Windows 10 Enterprise
* Windows 10 Education

**NOTE** - The Hyper-V role **cannot** be installed on Windows 10 Home.

We'll also assume that your physical host is fully up to date, but if not, maybe now is a good time to check for updates:

1. Open the **Start Menu** and search for **Update**
2. In the results, select **Check for Updates**
3. In the Updates window, click **Check for updates**. If any are required, ensure they are downloaded and installed.
4. Restart if required, and once completed, log back into your physical system.

With the OS updated, and back online after any required reboot, it's now time to enable the Hyper-V role and accompanying PowerShell management modules.

### Configure the Hyper-V host ###
In order to run our nested workloads, you first need to enable the Hyper-V role within Windows Server 2019, and the accompanying PowerShell modules. In addition, you'll create a special NAT switch, to ensure that your nested workloads can access the internet, using the Windows Server 2019 host as the NAT gateway.

The quickest, and easiest way to enable the required Hyper-V role and accompanying management tools, is using PowerShell.  Firstly, open PowerShell **as an administrator** and run the following command:

### To enable Hyper-V on Windows Server 2016/2019 ###

```powershell
# Install the Hyper-V role and management tools, including PowerShell
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
```

### To enable Hyper-V on Windows 10 ###

```powershell
# Install the Hyper-V role and management tools, including PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

Ensure you **restart the system** after installing Hyper-V, if prompted.

### Configure Internal NAT vSwitch ###
Both Windows 10 Hyper-V, and Windows Server 2019 Hyper-V allow native network address translation (NAT) for a virtual network. NAT gives a virtual machine access to network resources using the host computer's IP address and a port through an internal Hyper-V Virtual Switch.  It doesn't require you to expose the sandbox VMs directly onto your physical network.

If you're not familiar, Network Address Translation (NAT) is a networking mode designed to conserve IP addresses by mapping an external IP address and port to a much larger set of internal IP addresses. Basically, a NAT uses a flow table to route traffic from an external (host) IP Address and port number to the correct internal IP address associated with an endpoint on the network (virtual machine, computer, container, etc.)

Once rebooted and reconnected, the next step is to configure the NAT virtual switch on the Hyper-V host, to enable your VMs to access the internet from within their sandboxed environment.

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

![Result of Get-NetNat PowerShell command](/archive/media/get_net_nat.png "Result of Get-NetNat PowerShell command")

The final part of the process is to enable Enhanced Session mode.  Enhanced Session mode can be useful to enhance the user experience, particularly when using the Windows 10 Management VM later, when connecting to a VM over VMConnect.  To enable Enhanced Session Mode with PowerShell, run the following on your Hyper-V host:

```powershell
Set-VMhost -EnableEnhancedSessionMode $True
```

Next Steps
-----------
In this step, you've successfully configured your Hyper-V host, and the required core networking to support the nested scenario.  You're now ready to start creating your virtual machines as part of deploying your management infrastructure. You have 2 choices on how to proceed, either a more graphical way, using a GUI (Graphical User Interface, such as Hyper-V Manager, Server Manager etc), or via PowerShell.  Make your choice below:

* [**Part 2a** - Deploy your management infrastructure with the GUI](/archive/steps/2a_ManagementInfraGUI.md "Deploy your management infrastructure with the GUI")
* [**Part 2b** - Deploy your management infrastructure with PowerShell](/archive/steps/2b_ManagementInfraPS.md "Deploy your management infrastructure with PowerShell")

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI, Windows Admin Center, or the Azure Arc integration and experience, let us know! We want to hear from you!

For **Azure Stack HCI**, [Head on over to the Azure Stack HCI 21H2 Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Azure Stack HCI 21H2 Q&A"), where you can share your thoughts and ideas about making the technologies better and raise an issue if you're having trouble with the technology.

Raising issues
-----------
If you notice something is wrong with the evaluation guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If however, you're having a problem with Azure Stack HCI 20H2 **outside** of this evaluation guide, make sure you post to [our Microsoft Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Microsoft Q&A Forum"), where Microsoft experts and valuable members of the  community will do their best to help you.