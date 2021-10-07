Configuration HyperVHostPaths
{
    param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateScript({Test-Path $_})]
        $VirtualHardDiskPath,

        [Parameter(Mandatory=$true, Position=1)]
        [ValidateScript({Test-Path $_})]
        $VirtualMachinePath
    )

    Import-DscResource -moduleName xHyper-V

    xVMHost HyperVHostPaths
    {
        IsSingleInstance    = 'Yes'
        VirtualHardDiskPath = $VirtualHardDiskPath
        VirtualMachinePath  = $VirtualMachinePath
    }
}
