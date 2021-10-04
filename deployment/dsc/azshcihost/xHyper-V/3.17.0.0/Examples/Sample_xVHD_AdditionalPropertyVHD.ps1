configuration Sample_xVHD_AdditionalPropertyVHD
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $ParentPath,

        [Parameter(Mandatory = $true)]
        [string]
        $MaximumSizeBytes,

        [Parameter()]
        [ValidateSet('Vhd', 'Vhdx')]
        [string]
        $Generation = 'Vhd',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [string]
        $Ensure = 'Present'
    )

    Import-DscResource -ModuleName xHyper-V

    Node localhost
    {
        xVHD WrongVHD
        {
            Ensure           = $Ensure
            Name             = $Name
            Path             = $Path
            ParentPath       = $ParentPath
            MaximumSizeBytes = $MaximumSizeBytes
            Generation       = $Generation
        }
    }
}
