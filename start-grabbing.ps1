# 大麦 App 抢票启动器（Windows / PowerShell）
#
# 用法：
#   双击 start-grabbing.bat            交互确认后开始
#   .\start-grabbing.ps1 -y            跳过确认
#
# 它会做四件事：检查环境 -> 打印当前配置 -> 备份输入法 -> 跑脚本 -> 复原输入法

param([switch]$y)

$ErrorActionPreference = 'Continue'
$Root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$Py     = Join-Path $Root '.venv-appium\Scripts\python.exe'
$Config = Join-Path $Root 'damai_appium\config.jsonc'
$Server = 'http://127.0.0.1:4723'
$Adb    = 'D:\Program Files\adb\platform-tools\adb.exe'

# selenium 若走系统代理，会给 Appium 发绝对 URL，导致「selector is not present」
$env:NO_PROXY = '127.0.0.1,localhost,::1'
$env:no_proxy = $env:NO_PROXY
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

if (-not (Test-Path $Py)) {
    Write-Host "✗ 找不到虚拟环境: $Py" -ForegroundColor Red
    Write-Host "  先执行: python -m venv .venv-appium"
    exit 1
}

$status = & curl.exe -s --max-time 3 "$Server/status" 2>$null
if (-not ($status -match '"ready"\s*:\s*true')) {
    Write-Host "✗ Appium 未运行" -ForegroundColor Red
    Write-Host "  先双击 appium-env\start-appium.bat（那个窗口不要关）"
    exit 1
}
Write-Host "✓ Appium 服务正常" -ForegroundColor Green

if (-not (Test-Path $Config)) {
    Write-Host "✗ 配置文件不存在: $Config" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "当前配置:"
try {
    $cfg = Get-Content $Config -Raw -Encoding UTF8 | ConvertFrom-Json
    $devName = if ($cfg.device_name) { $cfg.device_name } else { '(默认 emulator-5554)' }
    $userList = ($cfg.users -join '、')
    Write-Host ("  设备      " + $devName)
    Write-Host ("  城市      " + $cfg.city)
    Write-Host ("  票档序号  " + $cfg.price_index)
    Write-Host ("  观演人    " + $userList + "  （" + $cfg.users.Count + " 张）")
    Write-Host ("  自动提交  " + $cfg.if_commit_order)
}
catch {
    Write-Host "  ⚠ 配置解析失败（jsonc 里可能有注释），请直接检查文件: $Config" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "开始前请确认手机已：打开大麦 → 搜到目标演出 → 进入详情页"
if (-not $y) {
    $reply = Read-Host "确认开始抢票？(y/N)"
    if ($reply -notmatch '^[Yy]') {
        Write-Host "已取消"
        exit 1
    }
}

# 备份默认输入法：Appium 会话异常中断时可能把输入法留在 UnicodeIME 上
$imeBackup = ''
if (Test-Path $Adb) {
    $raw = (& $Adb shell settings get secure default_input_method 2>$null) -join ''
    $imeBackup = $raw.Trim()
    if ($imeBackup -eq 'null' -or $imeBackup -match 'UnicodeIME') { $imeBackup = '' }
}

Push-Location (Join-Path $Root 'damai_appium')
Write-Host ""
Write-Host "🚀 开始抢票..." -ForegroundColor Cyan
$rc = 0
try {
    & $Py damai_app_v2.py
    $rc = $LASTEXITCODE
}
finally {
    if ($imeBackup) {
        $cur = ((& $Adb shell settings get secure default_input_method 2>$null) -join '').Trim()
        if ($cur -ne $imeBackup) {
            & $Adb shell ime set $imeBackup 2>$null | Out-Null
            Write-Host "✓ 输入法已恢复: $imeBackup" -ForegroundColor Green
        }
    }
    Pop-Location
}

Write-Host ""
Write-Host "退出码: $rc"
exit $rc
