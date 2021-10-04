[![Build status](https://ci.appveyor.com/api/projects/status/29y5yx2vxwjq60ic/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xcredssp/branch/master)

# xCredSSP


The **xCredSSP** module is a part of the Windows PowerShell Desired State Configuration (DSC) Resource Kit, which is a collection of DSC Resources produced by the PowerShell Team.
This module contains the **xCredSSP** resource, which enables or disables Credential Security Support Provider (CredSSP) authentication on a client or on a server computer, and which server or servers the client credentials can be delegated to.


**All of the resources in the DSC Resource Kit are provided AS IS, and are not supported through any Microsoft standard support program or service.
The "x" in xCredSSP stands for experimental**, which means that these resources will be **fix forward** and monitored by the module owner(s).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Installation

To install **xCredSSP** module

*   Unzip the content under $env:ProgramFiles\WindowsPowerShell\Modules folder

To confirm installation:

*   Run **Get-DSCResource** to see that **xCredSSP** is among the DSC Resources listed.


## Requirements

This module requires the latest version of PowerShell (v4.0, which ships in Windows 8.1 or Windows Server 2012R2).
To easily use PowerShell 4.0 on older operating systems, [<span style="color:#0000ff">install WMF 4.0</span>](http://www.microsoft.com/en-us/download/details.aspx?id=40855).
Please read the installation instructions that are present on both the download page and the release notes for WMF 4.0.


## Description

The **xCredSSP** module contains the **xCredSSP** resource, which enables or disables Credential Security Support Provider (CredSSP) authentication on a client or on a server computer, and which server or servers the client credentials can be delegated to.


## Details

**xCredSSP** resource has following properties:

*   **Ensure:** Specifies whether the domain trust is present or absent 
*   **Role**: REQUIRED parameter representing the CredSSP role, and is either "Server" or "Client" 
*   **DelegateComputers**: Array of servers to be delegated to, REQUIRED when Role is set to "Client".
*   **SuppressReboot**: Specifies whether a necessary reboot has to be supressed or not.

## Versions

### Unreleased

### 1.3.0.0
* Added a fix to enable credSSP with a fresh server installation

### 1.2.0.0
* Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.
* Implemented a GPO check to prevent an endless reboot loop when CredSSP is configured via a GPO
* Fixed issue with Test always returning false with other regional settings then english
* Added check to test if Role=Server and DelegateComputers parameter is specified
* Added parameter to supress a reboot, default value is false (reboot server when required)

### 1.1.0.0

*   Made sure DSC reboots if credSS is enabled

### 1.0.1.0

*   Updated with minor bug fixes.


### 1.0.0.0

*   Initial release with the following resources 
    *   <span style="font-family:Calibri; font-size:medium">xADDomain</span> 

## Examples

Enable CredSSP for both server and client roles, and delegate to Server1 and Server2.

```powershell
Configuration EnableCredSSP
{
    Import-DscResource -Module xCredSSP
    Node localhost
    {
        xCredSSP Server
        {
            Ensure = "Present"
            Role = "Server"
        }
        xCredSSP Client
        {
            Ensure = "Present"
            Role = "Client"
            DelegateComputers = "Server1","Server2"
        }
    }
} 
```

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).
