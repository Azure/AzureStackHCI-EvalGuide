DSCR_Shortcut
====

PowerShell DSC Resource to create shortcut file (LNK file).

## Install
You can install Resource through [PowerShell Gallery](https://www.powershellgallery.com/packages/DSCR_Shortcut/).
```PowerShell
Install-Module -Name DSCR_Shortcut
```

## Resources
* **cShortcut**
PowerShell DSC Resource to create shortcut file.

## Properties
### cShortcut
+ [string] **Ensure** (Write):
    + Specify whether or not a shortcut file exists
    + The default value is `Present`. { Present | Absent }

+ [string] **Path** (Key):
    + The path of the shortcut file.
    + If the path ends with something other than `.lnk`, The extension will be added automatically to the end of the path

+ [string] **Target** (Required):
    + The target path of the shortcut.

+ [string] **Arguments** (Write):
    + The arguments of the shortcut.

+ [string] **WorkingDirectory** (Write):
    + The working directory of the shortcut.

+ [string] **WindowStyle** (Write):
    + You can select window style. { normal | maximized | minimized }
    + The default value is `normal`

+ [string] **Description** (Write):
    + The description of the shortcut.

+ [string] **Icon** (Write):
    + The path of the icon resource.

+ [string] **HotKey** (Write):
    + HotKey (Shortcut Key) of the shortcut
    + HotKey works only for shortcuts on the desktop or in the Start menu.
    + The syntax is: `"{KeyModifier} + {KeyName}"` ( e.g. `"Alt+Ctrl+Q"`, `"Shift+F9"` )
    + If the hotkey not working after configuration, try to reboot.

+ [string] **AppUserModelID** (Write):
    + Specifies AppUserModelID of the shortcut
    + About AppUserModelID, See Microsoft Docs.  
      https://docs.microsoft.com/en-us/windows/win32/shell/appids


## Examples
+ **Example 1**: Create a shortcut to the Internet Explore InPrivate mode to the Administrator's desktop
```PowerShell
Configuration Example1
{
    Import-DscResource -ModuleName DSCR_Shortcut
    cShortcut IE_Desktop
    {
        Path      = 'C:\Users\Administrator\Desktop\PrivateIE.lnk'
        Target    = "C:\Program Files\Internet Explorer\iexplore.exe"
        Arguments = '-private'
    }
}
```

+ **Example 2**: Specifies All Properties
```PowerShell
Configuration Example2
{
    Import-DscResource -ModuleName DSCR_Shortcut
    cShortcut IE_Desktop
    {
        Path             = 'C:\Users\Administrator\Desktop\PrivateIE.lnk'
        Target           = 'C:\Program Files\Internet Explorer\iexplore.exe'
        Arguments        = '-private'
        WindowStyle      = 'maximized'
        WorkingDirectory = 'C:\work'
        Description      = 'This is a shortcut to the IE'
        Icon             = 'shell32.dll,277'
        HotKey           = 'Ctrl+Shift+U'
        AppUserModelID   = 'Microsoft.InternetExplorer.Default'
    }
}
```

## ChangeLog
### v2.1.1
 #### Improvements :zap:
  - [Regression] Fixed an issue where environment variables in a shortcut file would be unintentionally expanded.

### v2.1.0
 #### Improvements :zap:
  - [Regression] Fixed an issue where environment variables in a shortcut file would be unintentionally expanded.
  - Fixed an issue where `HotKey` would not be determined correctly between multiple different keyboard layouts.
  - You can now specify the Fn-key for `HotKey` by itself. (In previous versions, it had to be combined with modifier keys.)
  - Add Unit & Integration tests.

### v2.0.0
 #### BREAKING CHANGES :boom:
  - v1 of the module initializes properties not specified in the configuration when updating an existing shortcut file, but v2 preserves them.

 #### New Features :sparkles:
  - Add `AppUserModelID` property.  
    You can use this to control the grouping of the taskbar. See Microsoft Docs for more information.  
    https://docs.microsoft.com/en-us/windows/win32/shell/appids

 #### Improvements :zap:
  - For better performance and future scalability, The internal interface has been changed from `WshShortcut` to `IShellLink`.
  - Avoid positional parameters.
  - Fix minor issues.

### v1.3.8
 + Changed not to test for properties not explicitly specified.

### v1.3.7
 + Fix PSSA issues.
 + Remove unnecessary files in the published data.

### v1.3.6
+ Fixed issue that the Test-TargetResource always fails when the Target contains environment variables. #9
+ Fixed issue that the Test-TargetResource may fails when the Icon is specified.

### v1.3.4
+ Fixed issue that the Test-TargetResource always fails when the HotKey is not specified. #8
+ Improved verbose messages.

### v1.3.1
+ Change type of `HotKey` to `[string]`

### v1.3.0
+ Add `Description` property #1
+ Add `HotKey` property #2
+ Add `Icon` property #3
