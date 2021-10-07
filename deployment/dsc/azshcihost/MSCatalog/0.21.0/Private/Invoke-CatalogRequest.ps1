function Invoke-CatalogRequest {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [string] $Uri,

        [Parameter(Mandatory = $false)]
        [string] $Method = "Get",

        [Parameter(Mandatory = $false)]
        [string] $EventArgument,

        [Parameter(Mandatory = $false)]
        [string] $EventTarget,

        [Parameter(Mandatory = $false)]
        [string] $EventValidation,

        [Parameter(Mandatory = $false)]
        [string] $ViewState,

        [Parameter(Mandatory = $false)]
        [string] $ViewStateGenerator
    )

    try {
        if ($Method -eq "Post") {
            $ReqBody = @{
                "__EVENTARGUMENT" = $EventArgument
                "__EVENTTARGET" = $EventTarget
                "__EVENTVALIDATION" = $EventValidation
                "__VIEWSTATE" = $ViewState
                "__VIEWSTATEGENERATOR" = $ViewStateGenerator
            }
        }
        $Params = @{
            Uri = [Uri]::EscapeUriString($Uri)
            Method = $Method
            Body = $ReqBody
            ContentType = "application/x-www-form-urlencoded"
            UseBasicParsing = $true
            ErrorAction = "Stop"
        }
        $Results = Invoke-WebRequest @Params
        $HtmlDoc = [HtmlAgilityPack.HtmlDocument]::new()
        $HtmlDoc.LoadHtml($Results.RawContent.ToString())
        $NoResults = $HtmlDoc.GetElementbyId("ctl00_catalogBody_noResultText")
        if ($null -eq $NoResults) {
            [MSCatalogResponse]::new($HtmlDoc)
        } else {
            throw "No results found."
        }
    } catch {
        if ($_.Exception.Message -eq "No results found.") {
            Write-Warning "$($NoResults.InnerText)$($Uri.Split("q=")[-1])"
            break
        } else {
            throw $_
        }
    }
}