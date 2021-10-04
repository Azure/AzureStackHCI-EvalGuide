# Import ShellLink class
$ShellLinkPath = Join-Path $PSScriptRoot '..\..\Libs\ShellLink\ShellLink.cs'
if (Test-Path -LiteralPath $ShellLinkPath -PathType Leaf) {
    Add-Type -TypeDefinition (Get-Content -LiteralPath $ShellLinkPath -Raw -Encoding UTF8) -Language 'CSharp' -ErrorAction Stop
}

# Import VKeyUtil class
$VKeyUtilPath = Join-Path $PSScriptRoot '..\..\Libs\VKeyUtil\VKeyUtil.cs'
if (Test-Path -LiteralPath $VKeyUtilPath -PathType Leaf) {
    Add-Type -TypeDefinition (Get-Content -LiteralPath $VKeyUtilPath -Raw -Encoding UTF8) -Language 'CSharp' -ErrorAction Stop -ReferencedAssemblies System.Windows.Forms
}

Enum Ensure {
    Absent
    Present
}

Enum WindowStyle {
    undefined = 0
    normal = 1
    maximized = 3
    minimized = 7
}

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [string]
        $Ensure = [Ensure]::Present,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $Target,

        [Parameter()]
        [string]
        $WorkingDirectory,

        [Parameter()]
        [string]
        $Arguments,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $Icon,

        [Parameter()]
        [string]
        $HotKey,

        [Parameter()]
        [uint16]
        $HotKeyCode = 0x0000,

        [ValidateSet('normal', 'maximized', 'minimized')]
        [string]
        $WindowStyle = [WindowStyle]::normal,

        [Parameter()]
        [string]$AppUserModelID
    )

    if (-not $Path.EndsWith('.lnk')) {
        Write-Verbose ("File extension is not 'lnk'. Automatically add extension")
        $Path = $Path + '.lnk'
    }

    $Ensure = [Ensure]::Present

    try {
        # check file exists
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            Write-Verbose 'File not found.'
            $Ensure = [Ensure]::Absent
        }
        else {
            $Shortcut = Get-Shortcut -Path $Path -ReadOnly -ErrorAction Continue
        }
        $returnValue = @{
            Ensure           = $Ensure
            Path             = $Path
            Target           = $Shortcut.TargetPath
            WorkingDirectory = $Shortcut.WorkingDirectory
            Arguments        = $Shortcut.Arguments
            Description      = $Shortcut.Description
            Icon             = $Shortcut.IconLocation
            HotKey           = ConvertTo-HotKeyString -HotKeyCode $Shortcut.Hotkey
            HotKeyCode       = $Shortcut.Hotkey
            WindowStyle      = [WindowStyle]::undefined
            AppUserModelID   = $Shortcut.AppUserModelID
        }

        if ($Shortcut.WindowStyle -as [WindowStyle]) {
            $returnValue.WindowStyle = [WindowStyle]$Shortcut.WindowStyle
        }

        $returnValue
    }
    finally {
        if ($Shortcut -is [IDisposable]) {
            $Shortcut.Dispose()
            $Shortcut = $null
        }
    }
} # end of Get-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [string]
        $Ensure = [Ensure]::Present,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $Target,

        [Parameter()]
        [string]
        $WorkingDirectory,

        [Parameter()]
        [string]
        $Arguments,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $Icon,

        [Parameter()]
        [string]
        $HotKey,

        [Parameter()]
        [uint16]
        $HotKeyCode = 0x0000,

        [ValidateSet('normal', 'maximized', 'minimized')]
        [string]
        $WindowStyle = [WindowStyle]::normal,

        [Parameter()]
        [string]$AppUserModelID
    )

    $arg = [HashTable]$PSBoundParameters

    if (-not $Path.EndsWith('.lnk')) {
        Write-Verbose ("File extension is not 'lnk'. Automatically add extension")
        $arg.Path = $Path + '.lnk'
    }

    if ($Icon -and ($Icon -notmatch ',\d+$')) {
        $arg.Icon = $Icon + ',0'
    }

    # Ensure = "Absent"
    if ($Ensure -eq [Ensure]::Absent) {
        Write-Verbose ('Remove shortcut file "{0}"' -f $arg.Path)
        Remove-Item -LiteralPath $arg.Path -Force
    }
    else {
        # Ensure = "Present"
        $null = $arg.Remove('Ensure')
        Update-Shortcut @arg -Force
    }

} # end of Set-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [string]
        $Ensure = [Ensure]::Present,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $Target,

        [Parameter()]
        [string]
        $WorkingDirectory,

        [Parameter()]
        [string]
        $Arguments,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $Icon = ',0',

        [Parameter()]
        [string]
        $HotKey,

        [Parameter()]
        [uint16]
        $HotKeyCode = 0x0000,

        [ValidateSet('normal', 'maximized', 'minimized')]
        [string]
        $WindowStyle = [WindowStyle]::normal,

        [Parameter()]
        [string]$AppUserModelID
    )

    <#  想定される状態パターンと返却するべき値
        1. ショートカットがあるべき(Present)
            1-A. ショートカットなし => 更新の必要あり($false)
            1-B. ショートカットはあるがプロパティが正しくない => 更新の必要あり($false)
            1-C. ショートカットあり、プロパティ一致 => 何もする必要なし($true)
        2. ショートカットはあるべきではない(Absent)
            2-A. ショートカットなし => 何もする必要なし($true)
            2-B. ショートカットあり => 削除の必要あり($false)
    #>

    # 拡張子つける
    if (-not $Path.EndsWith('.lnk')) {
        Write-Verbose ("File extension is not 'lnk'. Automatically add extension")
        $Path = $Path + '.lnk'
    }

    if ($Icon -and ($Icon -notmatch ',\d+$')) {
        $Icon = $Icon + ',0'
    }

    # HotKey文字列からHotKeyCode（数値表現）を取得
    if ($HotKey) {
        # $HotKeyStr = Format-HotKeyString $HotKey
        $HotKeyCode = ConvertFrom-HotKeyString -HotKey $HotKey
    }
    else {
        # $HotKeyStr = [string]::Empty
        $HotKeyCode = 0x0000
    }

    $ReturnValue = $false
    switch ($Ensure) {
        'Absent' {
            # ファイルがなければ$true あれば$false
            $ReturnValue = (-not (Test-Path -LiteralPath $Path -PathType Leaf))
        }
        'Present' {
            $Info = Get-TargetResource -Ensure $Ensure -Path $Path -Target $Target
            if ($Info.Ensure -eq [Ensure]::Absent) {
                $ReturnValue = $false
            }
            else {
                # Tests whether the shortcut property is the same as the specified parameter.
                $NotMatched = @()
                if ($Info.Target -ne $Target) {
                    $NotMatched += 'Target'
                }

                if ($PSBoundParameters.ContainsKey('WorkingDirectory') -and ($Info.WorkingDirectory -ne $WorkingDirectory)) {
                    $NotMatched += 'WorkingDirectory'
                }

                if ($PSBoundParameters.ContainsKey('Arguments') -and ($Info.Arguments -ne $Arguments)) {
                    $NotMatched += 'Arguments'
                }

                if ($PSBoundParameters.ContainsKey('Description') -and ($Info.Description -ne $Description)) {
                    $NotMatched += 'Description'
                }

                if ($PSBoundParameters.ContainsKey('Icon') -and ($Info.Icon -ne $Icon)) {
                    $NotMatched += 'Icon'
                }

                if ($PSBoundParameters.ContainsKey('HotKey') -and ($Info.HotKeyCode -ne $HotKeyCode)) {
                    $NotMatched += 'HotKey'
                }

                if ($PSBoundParameters.ContainsKey('WindowStyle') -and ($Info.WindowStyle -ne $WindowStyle)) {
                    $NotMatched += 'WindowStyle'
                }

                if ($PSBoundParameters.ContainsKey('AppUserModelID') -and ($Info.AppUserModelID -ne $AppUserModelID)) {
                    $NotMatched += 'AppUserModelID'
                }

                $ReturnValue = ($NotMatched.Count -eq 0)
                if (-not $ReturnValue) {
                    $NotMatched | ForEach-Object {
                        Write-Verbose ('{0} property does not match!' -f $_)
                    }
                }
            }
        }
    }
    Write-Verbose "Test returns $ReturnValue"
    return $ReturnValue
} # end of Test-TargetResource


function Get-Shortcut {
    [CmdletBinding()]
    [OutputType([ShellLink])]
    param
    (
        # Path of shortcut files
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateScript( { Test-Path -LiteralPath $_ -PathType Leaf } )]
        [string]$Path,

        [switch]$ReadOnly
    )

    Begin {
        if ($ReadOnly) {
            [int]$flag = 0x00000000 #STGM_READ
        }
        else {
            [int]$flag = 0x00000002 #STGM_READWRITE
        }
    }

    Process {
        try {
            $Shortcut = New-Object -TypeName ShellLink
            $Shortcut.Load($Path, $flag)
            return $Shortcut
        }
        catch {
            if ($Shortcut -is [IDisposable]) {
                $Shortcut.Dispose()
                $Shortcut = $null
            }

            Write-Error -Exception $_.Exception
            return $null
        }
    }
}


function New-Shortcut {
    [CmdletBinding()]
    [OutputType([System.IO.FileSystemInfo])]
    param
    (
        # set file path to create shortcut. If the path not ends with '.lnk', extension will be add automatically.
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('FilePath')]
        [string]$Path,

        # Set Target full path to create shortcut
        [Parameter(
            Position = 1,
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('Target')]
        [string]$TargetPath,

        # Set Description for shortcut.
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('Comment')]
        [string]$Description,

        # Set Arguments for shortcut.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Arguments,

        # Set WorkingDirectory for shortcut.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$WorkingDirectory,

        # Set IconLocation for shortcut.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Icon,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$HotKey,

        # Set WindowStyle for shortcut.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('normal', 'maximized', 'minimized')]
        [string]$WindowStyle = [WindowStyle]::normal,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$AppUserModelID,

        # set if you want to show create shortcut result
        [switch]$PassThru,

        [switch]$Force
    )

    begin {
        $extension = '.lnk'
    }

    process {
        # Set Path of a Shortcut
        if (-not $Path.EndsWith($extension)) {
            $Path = $Path + $extension
        }

        if ($HotKey) {
            $local:HotKeyCode = ConvertFrom-HotKeyString -HotKey $HotKey -ErrorAction Stop
        }
        else {
            $local:HotKeyCode = 0x0000
        }

        if (-not (Test-Path -LiteralPath (Split-Path $Path -Parent))) {
            Write-Verbose 'Create a parent folder'
            $null = New-Item -Path (Split-Path $Path -Parent) -ItemType Directory -Force -ErrorAction Stop
        }

        $fileName = Split-Path $Path -Leaf  # Filename of shortcut
        $Directory = Resolve-Path -Path (Split-Path $Path -Parent) # Directory of shortcut
        $Path = Join-Path $Directory $fileName  # Fullpath of shortcut

        #Remove existing shortcut (when the Force switch is specified)
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            if ($Force) {
                Write-Verbose 'Remove existing shortcut file'
                Remove-Item $Path -Force -ErrorAction SilentlyContinue
            }
            else {
                Write-Error -Exception ([System.IO.IOException]::new("The file '$Path' is already exists."))
                return
            }
        }

        # Call IShellLink to create Shortcut
        Write-Verbose ("Trying to create Shortcut to '{0}'" -f $Path)
        try {
            $Shortcut = New-Object -TypeName ShellLink
            $Shortcut.TargetPath = $TargetPath
            $Shortcut.Description = $Description
            $Shortcut.WindowStyle = [int][WindowStyle]$WindowStyle
            $Shortcut.Arguments = $Arguments
            $Shortcut.WorkingDirectory = $WorkingDirectory
            if ($PSBoundParameters.ContainsKey('Icon')) {
                $Shortcut.IconLocation = $Icon
            }
            if ($PSBoundParameters.ContainsKey('AppUserModelID')) {
                $Shortcut.AppUserModelID = $AppUserModelID
            }
            if ($PSBoundParameters.ContainsKey('Hotkey')) {
                $Shortcut.Hotkey = $local:HotKeyCode
            }
            $Shortcut.Save($Path)
            Write-Verbose 'Shortcut file created successfully.'
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        finally {
            if ($Shortcut -is [System.IDisposable]) {
                $Shortcut.Dispose()
                $Shortcut = $null
            }
        }

        if ($PassThru) {
            Get-Item -LiteralPath $Path
        }
    }

    end {}
}

function Update-Shortcut {
    [CmdletBinding(DefaultParameterSetName = 'ShellLink')]
    [OutputType([System.IO.FileSystemInfo])]
    param
    (
        # Set file path to update shortcut. If the path not ends with '.lnk', extension will be add automatically.
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'FilePath')]
        [Alias('FilePath')]
        [string]$Path,

        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            ParameterSetName = 'ShellLink')]
        [ShellLink]$InputObject,

        # Set Target full path for shortcut
        [Parameter(ParameterSetName = 'FilePath', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ShellLink')]
        [Alias('Target')]
        [string]$TargetPath,

        # Set Description for shortcut.
        [Parameter(ParameterSetName = 'FilePath', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ShellLink')]
        [Alias('Comment')]
        [string]$Description,

        # Set Arguments for shortcut.
        [Parameter(ParameterSetName = 'FilePath', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ShellLink')]
        [string]$Arguments,

        # Set WorkingDirectory for shortcut.
        [Parameter(ParameterSetName = 'FilePath', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ShellLink')]
        [string]$WorkingDirectory,

        # Set IconLocation for shortcut.
        [Parameter(ParameterSetName = 'FilePath', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ShellLink')]
        [string]$Icon,

        [Parameter(ParameterSetName = 'FilePath', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ShellLink')]
        [string]$HotKey,

        # Set WindowStyle for shortcut.
        [Parameter(ParameterSetName = 'FilePath', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ShellLink')]
        [ValidateSet('normal', 'maximized', 'minimized')]
        [string]$WindowStyle = [WindowStyle]::normal,

        [Parameter(ParameterSetName = 'FilePath', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ShellLink')]
        [string]$AppUserModelID,

        # set if you want to show create shortcut result
        [switch]$PassThru,

        [switch]$Force
    )

    begin {
        $extension = '.lnk'
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'FilePath') {
            if (-not $Path.EndsWith($extension)) {
                $Path = $Path + $extension
            }

            if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
                if ($Force -and $TargetPath) {
                    New-Shortcut @PSBoundParameters
                    return
                }
                else {
                    Write-Error -Exception ([System.IO.FileNotFoundException]::new("The file '$Path' does not exists."))
                    return
                }
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ShellLink') {
            if (-not ($InputObject.FilePath)) {
                Write-Error -Exception ([System.ArgumentException]::new("The InputObject does not valid."))
                return
            }
        }

        if ($HotKey) {
            $local:HotKeyCode = ConvertFrom-HotKeyString -HotKey $HotKey -ErrorAction Stop
        }
        else {
            $local:HotKeyCode = 0x0000
        }

        # Call IShellLink to update Shortcut
        Write-Verbose ("Updating Shortcut for '{0}'" -f $Path)
        try {
            if ($PSCmdlet.ParameterSetName -eq 'FilePath') {
                $InputObject = New-Object -TypeName ShellLink
                $InputObject.Load($Path)
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'ShellLink') {
                $Path = $InputObject.FilePath
            }

            $Shortcut = $InputObject
            if ($PSBoundParameters.ContainsKey('TargetPath')) {
                $Shortcut.TargetPath = $TargetPath
            }
            if ($PSBoundParameters.ContainsKey('Description')) {
                $Shortcut.Description = $Description
            }
            if ($PSBoundParameters.ContainsKey('WindowStyle')) {
                $Shortcut.WindowStyle = [int][WindowStyle]$WindowStyle
            }
            if ($PSBoundParameters.ContainsKey('Arguments')) {
                $Shortcut.Arguments = $Arguments
            }
            if ($PSBoundParameters.ContainsKey('WorkingDirectory')) {
                $Shortcut.WorkingDirectory = $WorkingDirectory
            }
            if ($PSBoundParameters.ContainsKey('Icon')) {
                $Shortcut.IconLocation = $Icon
            }
            if ($PSBoundParameters.ContainsKey('AppUserModelID')) {
                $Shortcut.AppUserModelID = $AppUserModelID
            }
            if ($PSBoundParameters.ContainsKey('Hotkey')) {
                $Shortcut.Hotkey = $local:HotKeyCode
            }

            $Shortcut.Save($Path)
            Write-Verbose 'Shortcut file updated successfully.'
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        finally {
            if ($Shortcut -is [System.IDisposable]) {
                $Shortcut.Dispose()
                $Shortcut = $null
            }
        }

        if ($PassThru) {
            Get-Item -LiteralPath $Path
        }
    }

    end {}
}


function Format-HotKeyString {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyString()]
        [string]$HotKey
    )

    if ([string]::IsNullOrWhiteSpace($HotKey)) {
        return [string]::Empty
    }

    [string[]]$local:HotKeyArray = $HotKey.split('+').Trim()

    if ($local:HotKeyArray.Count -eq 1 -and $local:HotKeyArray[0] -match '^F([1-9]|1[0-9]|2[0-4])$') {
        # F1～F24は修飾キーを伴わず単体でもOK
    }
    elseif ($local:HotKeyArray.Count -notin (2..4)) {
        #最短で修飾+キーの2要素、最長でAlt+Ctrl+Shift+キーの4要素
        Write-Error 'HotKey is not valid format.'
        return [string]::Empty
    }
    elseif ($local:HotKeyArray[0] -notmatch '^(Ctrl|Alt|Shift)$') {
        #修飾キーから始まっていないとダメ
        Write-Error 'HotKey is not valid format.'
        return [string]::Empty
    }

    #優先順位付きソート
    $local:sort = $local:HotKeyArray | ForEach-Object {
        switch ($_) {
            'Ctrl' { 1 }
            'Shift' { 2 }
            'Alt' { 3 }
            Default { 4 }
        }
    }
    [Array]::Sort($local:sort, $local:HotKeyArray)
    $local:HotKeyArray -join '+'
}


function ConvertFrom-HotKeyString {
    [CmdletBinding()]
    [OutputType([uint16])]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$HotKey
    )

    begin {
        [uint16]$HOTKEYF_SHIFT = 0x0100
        [uint16]$HOTKEYF_CONTROL = 0x0200
        [uint16]$HOTKEYF_ALT = 0x0400
        # [uint16]$HOTKEYF_EXT = 0x0800  #?

        Add-Type -AssemblyName System.Windows.Forms
        $KeysConverter = New-Object -TypeName 'System.Windows.Forms.KeysConverter'
    }

    Process {
        if ([string]::IsNullOrWhiteSpace($HotKey)) {
            return 0x0000
        }

        [uint16]$local:HotKeyCode = 0x0000
        $HotKey = Format-HotKeyString -HotKey $HotKey
        [string[]]$local:HotKeyArray = $HotKey.split('+').Trim()

        switch ($local:HotKeyArray) {
            'Shift' {
                $local:HotKeyCode = $local:HotKeyCode -bor $HOTKEYF_SHIFT
                continue
            }

            'Ctrl' {
                $local:HotKeyCode = $local:HotKeyCode -bor $HOTKEYF_CONTROL
                continue
            }

            'Alt' {
                $local:HotKeyCode = $local:HotKeyCode -bor $HOTKEYF_ALT
                continue
            }

            Default {
                $local:KeyString = $_
                $local:KeyCode = $null
                try {
                    $local:KeyCode = $KeysConverter.ConvertFromString($local:KeyString.ToUpper())
                }
                catch [ArgumentException] {
                    try {
                        $local:KeyCode = [VKeyUtil]::GetKeyCodeFromChar($local:KeyString) -band 0x00ff
                    }
                    catch {
                        Write-Error 'HotKey is not valid format.'
                        return
                    }
                }
                catch {
                    Write-Error -Exception $_.Exception
                    return
                }

                if ($null -ne $local:KeyCode) {
                    $local:HotKeyCode = $local:HotKeyCode -bor $local:KeyCode
                }
            }
        }

        $local:HotKeyCode
    }

    End {
        $KeysConverter = $null
    }
}


function ConvertTo-HotKeyString {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [uint16]$HotKeyCode
    )

    begin {
        [uint16]$HOTKEYF_SHIFT = 0x0100
        [uint16]$HOTKEYF_CONTROL = 0x0200
        [uint16]$HOTKEYF_ALT = 0x0400
        # [uint16]$HOTKEYF_EXT = 0x0800  #?

        Add-Type -AssemblyName System.Windows.Forms
        $KeysConverter = New-Object -TypeName 'System.Windows.Forms.KeysConverter'
    }

    Process {
        if ($HotKeyCode -eq 0x0000) {
            return [string]::Empty
        }

        [string[]]$local:HotKeyArray = @()

        # Modifier Keys
        if ($HotKeyCode -band $HOTKEYF_SHIFT) {
            $local:HotKeyArray += 'Shift'
        }
        if ($HotKeyCode -band $HOTKEYF_CONTROL) {
            $local:HotKeyArray += 'Ctrl'
        }
        if ($HotKeyCode -band $HOTKEYF_ALT) {
            $local:HotKeyArray += 'Alt'
        }

        # Key
        [string]$local:Key = $null
        try { $local:Key = [VKeyUtil]::GetCharsFromKeys($HotKeyCode -band 0x00ff) } catch {}

        if ([string]::IsNullOrWhiteSpace($local:Key)) {
            try {
                $local:Key = $KeysConverter.ConvertToString($HotKeyCode -band 0x00ff)
            }
            catch {
                Write-Error -Exception $_.Exception
                return
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($local:Key)) {
            $local:HotKeyArray += $local:Key.ToUpper()
            # return formatted string
            Format-HotKeyString -HotKey ([string]::Join('+', $local:HotKeyArray))
        }
        else {
            [string]::Empty
        }
    }

    End {
        $KeysConverter = $null
    }
}


Export-ModuleMember -Function *-TargetResource
