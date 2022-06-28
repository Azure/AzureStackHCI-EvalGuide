function Set-TempSecurityProtocol {
    [CmdletBinding()]
    param (
        [switch] $ResetToDefault
    )

    if (($null -ne $Script:MSCatalogSecProt) -and $ResetToDefault) {
        [Net.ServicePointManager]::SecurityProtocol = $Script:MSCatalogSecProt
    } else {
        [array] $Script:MSCatalogSecProt = [Net.ServicePointManager]::SecurityProtocol -Split ", "
        $TempSecProt = ($Script:MSCatalogSecProt + "Tls11", "Tls12") | Select-Object -Unique
        [Net.ServicePointManager]::SecurityProtocol = $TempSecProt
    }
}