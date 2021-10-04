#
# モジュール 'DSCR_Shortcut' のモジュール マニフェスト
#
# 生成者: mkht
#
# 生成日: 2016/06/18
#

@{

    # このマニフェストに関連付けられているスクリプト モジュール ファイルまたはバイナリ モジュール ファイル。
    # RootModule = ''

    # このモジュールのバージョン番号です。
    ModuleVersion        = '2.1.1'

    # このモジュールを一意に識別するために使用される ID
    GUID                 = 'dc24c0c9-ad6b-4fce-9ce4-2410f9ce4f7f'

    # このモジュールの作成者
    Author               = 'mkht'

    # このモジュールの会社またはベンダー
    CompanyName          = ''

    # このモジュールの著作権情報
    Copyright            = '(c) 2020 mkht. All rights reserved.'

    # このモジュールの機能の説明
    Description          = 'PowerShell DSC Resource to create shortcut file.'

    # このモジュールに必要な Windows PowerShell エンジンの最小バージョン
    PowerShellVersion    = '5.0'

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # RootModule/ModuleToProcess に指定されているモジュールの入れ子になったモジュールとしてインポートするモジュール
    # NestedModules = @()

    # このモジュールからエクスポートする関数です。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートする関数がない場合は、エントリを削除しないで空の配列を使用してください。
    FunctionsToExport    = @()

    # このモジュールからエクスポートするコマンドレットです。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートするコマンドレットがない場合は、エントリを削除しないで空の配列を使用してください。
    CmdletsToExport      = @()

    # このモジュールからエクスポートする変数
    VariablesToExport    = '*'

    # このモジュールからエクスポートするエイリアスです。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートするエイリアスがない場合は、エントリを削除しないで空の配列を使用してください。
    AliasesToExport      = @()

    # このモジュールからエクスポートする DSC リソース
    DscResourcesToExport = @('cShortcut')

    # このモジュールからエクスポートされたコマンドの既定のプレフィックス。既定のプレフィックスをオーバーライドする場合は、Import-Module -Prefix を使用します。
    # DefaultCommandPrefix = ''

    # RootModule/ModuleToProcess に指定されているモジュールに渡すプライベート データ。これには、PowerShell で使用される追加のモジュール メタデータを含む PSData ハッシュテーブルが含まれる場合もあります。
    PrivateData          = @{

        PSData = @{

            # このモジュールに適用されているタグ。オンライン ギャラリーでモジュールを検出する際に役立ちます。
            Tags       = ('DesiredStateConfiguration', 'DSC', 'DSCResource', 'Shortcut')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/mkht/DSCR_Shortcut/blob/master/LICENSE'

            # このプロジェクトのメイン Web サイトの URL。
            ProjectUri = 'https://github.com/mkht/DSCR_Shortcut'

            # このモジュールを表すアイコンの URL。
            # IconUri = ''

            # このモジュールの ReleaseNotes
            # ReleaseNotes = ''

        } # PSData ハッシュテーブル終了

    } # PrivateData ハッシュテーブル終了

}
