#requires -RunAsAdministrator

# Check for New-VHD
$VHDCmdlets = $true
if (-not (Get-Module -Name hyper-v -ListAvailable))
{
    $VHDCmdlets = $false
    Write-Warning -Message '[Module : WindowsImageTools] Hyper-V Module Not Installed: '
}
if ([environment]::OSVersion.Version.Major -ge 10 -and 
(Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Services).state -eq 'Disabled')
{
    $VHDCmdlets = $false
    Write-Warning -Message '[Module : WindowsImageTools] Hyper-v Services on windows 10 not installed'
}

if (-not ($VHDCmdlets))
{
    Write-Warning -Message '[Module : WindowsImageTools] *-VHD cmdlets not avalible '
    Write-Warning -Message '                             Loading WIN2VHD Class'    
    . $PSScriptRoot\Functions\Wim2VHDClass.ps1
    Write-Warning -Message '                             Windows Image Update function not loaded'
}

# Import Basic functions
. $PSScriptRoot\Functions\HelperFunctions.ps1
. $PSScriptRoot\Functions\Convert-Wim2VHD.ps1
. $PSScriptRoot\Functions\Initialize-VHDPartition.ps1
. $PSScriptRoot\Functions\Set-VHDPartition.ps1
. $PSScriptRoot\Functions\New-Unattend.ps1

if ($VHDCmdlets) #only import if depended functions avalible
{ 
    . $PSScriptRoot\Functions\New-WindowsImageToolsExample.ps1
    . $PSScriptRoot\Functions\Set-UpdateConfig.ps1
    . $PSScriptRoot\Functions\Add-UpdateImage.ps1
    . $PSScriptRoot\Functions\Update-WindowsImageWMF.ps1
    . $PSScriptRoot\Functions\Invoke-WindowsImageUpdate.ps1
    . $PSScriptRoot\Functions\Mount-VhdAndRunBlock.ps1
    . $PSScriptRoot\Functions\Invoke-CreateVmRunAndWait.ps1
    . $PSScriptRoot\Functions\Get-VhdPartitionStyle.ps1
}
