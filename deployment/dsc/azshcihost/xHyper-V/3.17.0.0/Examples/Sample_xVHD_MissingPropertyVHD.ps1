configuration Sample_xVHD_MissingPropertyVHD
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter()]
        [ValidateSet('Vhd', 'Vhdx')]
        [string]
        $Generation = 'Vhd',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [string]
        $Ensure = 'Present'
    )

    Import-DscResource -module xHyper-V

    Node localhost
    {
        xVHD WrongVHD
        {
            Ensure     = $Ensure
            Name       = $Name
            Path       = $Path
            Generation = $Generation
        }
    }
}
