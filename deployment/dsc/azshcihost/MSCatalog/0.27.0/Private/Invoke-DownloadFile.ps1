function Invoke-DownloadFile {
    [CmdLetBinding()]
    param (
        [uri] $Uri,
        [string] $Path,
        [switch] $UseBits
    )
    
    try {
        Set-TempSecurityProtocol

        if ($UseBits) {
            Start-BitsTransfer -Source $Uri -Destination $Path
        } else {
            $WebClient = [System.Net.WebClient]::new()
            $WebClient.DownloadFile($Uri, $Path)
            $WebClient.Dispose()
        }
        Set-TempSecurityProtocol -ResetToDefault
    } catch {
        $Err = $_
        if ($WebClient) {
            $WebClient.Dispose()
        }
        throw $Err
    }
}