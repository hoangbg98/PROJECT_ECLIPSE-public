# Tool chống gian lận của QTV (M9-2b). Chạy trên máy đang chạy máy chủ. Ví dụ:
#   powershell -ExecutionPolicy Bypass -File server\audit.ps1 -SyncRules                 (đẩy luật: data\config\anti_cheat.json + server\rules\game_rules.json)
#   powershell -ExecutionPolicy Bypass -File server\audit.ps1 -Flags                     (tài khoản bị đánh dấu, nhiều lỗi cứng trước)
#   powershell -ExecutionPolicy Bypass -File server\audit.ps1 -Code 48291735             (chi tiết đánh dấu của một người chơi)
#   powershell -ExecutionPolicy Bypass -File server\audit.ps1 -Code 48291735 -Clear -Operator ten_qtv
#   powershell -ExecutionPolicy Bypass -File server\audit.ps1 -Code 48291735 -Restore -Operator ten_qtv   (khôi phục save trước)
# Lỗi CỨNG: máy chủ đã từ chối save đó (người chơi bị tải lại bản trên máy chủ). Lỗi MỀM: save vẫn được nhận, QTV xem xét.
# Cấm tài khoản: trang quản trị Nakama (Accounts → Ban). Sinh lại game_rules.json khi đổi banner / phần thưởng / trần cấp:
#   C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --script res://tools/export_server_rules.gd
param(
    [switch]$SyncRules,
    [switch]$Flags,
    [string]$Code = "",
    [switch]$Clear,
    [switch]$Restore,
    [string]$Operator = "",
    [string]$ServerUrl = "http://127.0.0.1:7350"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = Split-Path -Parent $PSScriptRoot
$secrets = Get-Content (Join-Path $PSScriptRoot ".runtime\secrets.json") -Raw | ConvertFrom-Json

function Call-Rpc($id, $body) {
    $uri = "$ServerUrl/v2/rpc/$($id)?http_key=$($secrets.http_key)&unwrap"
    $json = $body | ConvertTo-Json -Compress -Depth 10
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)
        return Invoke-RestMethod -Method Post -Uri $uri -Body $bytes -ContentType "application/json; charset=utf-8" -TimeoutSec 15
    } catch {
        $msg = $_.ErrorDetails.Message
        if ($msg) { try { $msg = ($msg | ConvertFrom-Json).message } catch { } }
        if (-not $msg) { $msg = $_.Exception.Message }
        $msg = ($msg -replace '^Error: ', '') -replace ' at \w+ \(index\.js.*$', ''
        Write-Output "LỖI: $msg"
        exit 1
    }
}

function Fmt-Time($ms) { [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$ms).LocalDateTime.ToString("yyyy-MM-dd HH:mm") }

if ($SyncRules) {
    $rules = Get-Content (Join-Path $root "data\config\anti_cheat.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $game = Get-Content (Join-Path $root "server\rules\game_rules.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($p in $game.PSObject.Properties) {
        if ($p.Name -ne "_comment") { $rules | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force }
    }
    $r = Call-Rpc "admin_set_rules" @{ rules = $rules }
    Write-Output "Đã đẩy luật chống gian lận lên máy chủ ($($r.banners) banner)."
    exit 0
}
if ($Flags) {
    $r = Call-Rpc "admin_cheat_flags" @{ limit = 50 }
    if (-not $r.flags -or $r.flags.Count -eq 0) { Write-Output "Không có tài khoản nào bị đánh dấu."; exit 0 }
    foreach ($f in $r.flags) {
        Write-Output ("Mã {0} | {1} | {2} lần (cứng {3}) | gần nhất {4}" -f $f.code, $f.username, $f.count, $f.hard, (Fmt-Time $f.last))
        foreach ($e in $f.entries) { Write-Output ("    {0} {1}: {2}" -f (Fmt-Time $e.t), $e.kind, ($e.reasons -join ", ")) }
    }
    exit 0
}
if (-not $Code) { Write-Output "Dùng: -SyncRules | -Flags | -Code <mã> [-Clear | -Restore] -Operator <tên>. Xem đầu file."; exit 2 }
if ($Clear) {
    if (-not $Operator) { Write-Output "Cần -Operator (tên QTV)."; exit 2 }
    $null = Call-Rpc "admin_cheat_clear" @{ code = $Code; operator = $Operator }
    Write-Output "Đã xóa đánh dấu của mã $Code."
    exit 0
}
if ($Restore) {
    if (-not $Operator) { Write-Output "Cần -Operator (tên QTV)."; exit 2 }
    $null = Call-Rpc "admin_save_restore" @{ code = $Code; operator = $Operator }
    Write-Output "Đã khôi phục save trước của mã $Code (người chơi đăng nhập lại để nhận)."
    exit 0
}
$r = Call-Rpc "admin_cheat_flags" @{ code = $Code }
if (-not $r.flags -or $r.flags.Count -eq 0) { Write-Output "Mã $Code không bị đánh dấu."; exit 0 }
$f = $r.flags[0]
Write-Output ("Mã {0} | {1} | {2} lần (cứng {3})" -f $f.code, $f.username, $f.count, $f.hard)
foreach ($e in $f.entries) { Write-Output ("  {0} {1}: {2}" -f (Fmt-Time $e.t), $e.kind, ($e.reasons -join ", ")) }
