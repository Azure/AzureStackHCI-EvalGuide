function Mount-VhdAndRunBlock 
{
    <#
            .Synopsis
            Mount a VHD(x), runs a script block and unmounts the VHD(x) driveleter stored in $driveLetter
            .DESCRIPTION
            Us this function to read / write files inside a vhd. Any objects emited by the scriptblock are returned by this function.
            .EXAMPLE
            Mount-VhdAndRunBlock -Vhd c:\win10.vhdx -Block { Copy-Item -Path 'c:\myfiles\unattend.xml' -Destination "$($driveletter):\unattend.xml"}
            .EXAMPLE
            $fileFound = Mount-VhdAndRunBlock -Vhd c:\lab.vhdx -ReadOnly { test-path "$($driveletter):\scripts\changesmade.log" }
    #>
    param
    (
        # Path to VHD(x) file
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $vhd, 

        # Script block to execute (Drive letter stored in $driveletter)
        [Parameter(Mandatory = $true)]
        [scriptblock]
        $block,

        # Mount the VHD(x) readonly, This is faster. Use when only reading files.
        [switch]
        $ReadOnly
    )
     
    # This function mounts a VHD, runs a script block and unmounts the VHD.
    # Drive letter of the mounted VHD is stored in $driveLetter - can be used by script blocks
    if($ReadOnly) 
    {
        $virtualDisk = Mount-VHD -Path $vhd -ReadOnly -Passthru
    }
    else 
    {
        $virtualDisk = Mount-VHD -Path $vhd -Passthru
    }
    # Workarround for new drive letters in script modules                  
    $null = Get-PSDrive
    $global:driveLetter = ($virtualDisk |
        Get-Disk |
        Get-Partition |
    Get-Volume).DriveLetter
    $newScriptBlock = [scriptblock]::Create($block.ToString())
    & $newScriptBlock

    Dismount-VHD $vhd

    # Wait 2 seconds for activity to clean up
    Start-Sleep -Seconds 2
}
