Function Get-VhdPartitionStyle
{
    <#
            .Synopsis
            Gets partition style of a VHD(x)
            .DESCRIPTION
            Returns the partition Style of the provided VHD(x) ei. GPT or MBR
            .EXAMPLE
            $partitionStyle = Get-VhdPartitionStyle -Vhd C:\win10.vhdx
    #>
    param
    (
        # Path to VHD(x) file
        [Parameter(Mandatory,HelpMessage = 'Path to VHD(x)')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $vhd 
    )
    $PartitionStyle = (Mount-VHD -Path $vhd -ReadOnly -Passthru | Get-Disk).PartitionStyle
    Dismount-VHD $vhd
    Start-Sleep -Seconds 2
    return $PartitionStyle
}         
