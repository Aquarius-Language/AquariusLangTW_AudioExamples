param([string]$編譯器 = '', [switch]$略過桌面,
    [switch]$Android, [switch]$APK
)
$ErrorActionPreference = 'Stop'
if (-not $編譯器) {
    $本機編譯器 = Join-Path (Split-Path $PSScriptRoot) 'AquariusLangTW/AquariusCli/bin/Debug/net8.0/aqua.dll'
    $已安裝 = Get-Command aqua -ErrorAction SilentlyContinue
    $編譯器 = if (Test-Path -LiteralPath $本機編譯器) { $本機編譯器 } elseif ($已安裝) { $已安裝.Source } else { throw '請指定支援音訊的星泉編譯器：-編譯器 完整路徑。' }
}
$編譯器 = (Resolve-Path -LiteralPath $編譯器).Path
$執行階段 = 'dotnet'
if ($編譯器.EndsWith('.dll')) {
    $本機執行階段 = Join-Path $env:USERPROFILE '.dotnet/dotnet.exe'
    if (Test-Path -LiteralPath $本機執行階段) { $執行階段 = $本機執行階段 }
}
function 執行編譯器([string[]]$參數) {
    if ($編譯器.EndsWith('.dll')) { $輸出 = & $執行階段 $編譯器 @參數 2>&1 } else { $輸出 = & $編譯器 @參數 2>&1 }
    $結束碼 = $LASTEXITCODE; $輸出 | ForEach-Object { Write-Host $_ }
    if ($結束碼 -ne 0 -or ($輸出 -join "`n") -match '(?m)^ERROR:') { throw '星泉建置或驗證失敗。' }
    return ($輸出 -join "`n")
}
$原編碼 = [Console]::OutputEncoding
Push-Location $PSScriptRoot
try {
    [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
    New-Item -ItemType Directory -Path dist -Force | Out-Null
    執行編譯器 @('build','音訊驗證.aqua','--root','.','--assets','音色','-o','dist/音訊驗證.wasm') | Out-Null
    $驗證 = 執行編譯器 @('run','dist/音訊驗證.wasm')
    if ($驗證 -notmatch '音訊驗證全部通過') { throw '音訊驗證未通過。' }
    執行編譯器 @('build','星泉聲音工坊.aqua','中文介面.aqua','音訊驗證.aqua','--root','.','--assets','音色','--entry','星泉聲音工坊.aqua','-o','dist/星泉聲音工坊.wasm') | Out-Null
    執行編譯器 @('build','dist/星泉聲音工坊.wasm','--target','web','-o','web') | Out-Null
    $首頁 = Join-Path $PSScriptRoot 'web/index.html'
    $內容 = [IO.File]::ReadAllText($首頁).Replace('lang="en"','lang="zh-Hant"').Replace('<title>Aquarius WebAssembly</title>','<title>星泉聲音工坊</title>')
    [IO.File]::WriteAllText($首頁, $內容, [Text.UTF8Encoding]::new($false))
    if (-not $略過桌面) { 執行編譯器 @('build','dist/星泉聲音工坊.wasm','--target','windows','-o','dist/星泉聲音工坊.exe') | Out-Null }
    Write-Host '完成：星泉聲音工坊、音訊驗證與網頁版本。'

    if ($Android -or $APK) {
        $AndroidOutput = if ($APK) { 'dist/android.apk' } else { ('dist/android-project-' + [Guid]::NewGuid().ToString('N').Substring(0,8)) }
        執行編譯器 @('build','dist/星泉聲音工坊.wasm','--target','android','-o',$AndroidOutput) | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Android 建置失敗。' }
    }
} finally { [Console]::OutputEncoding = $原編碼; Pop-Location }
