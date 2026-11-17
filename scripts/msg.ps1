param([int]$ClickX = -1, [int]$ClickY = -1, [int]$Wheel = 0, [int]$MoveX = -1, [int]$MoveY = -1)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class IM {
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out R r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref P p);
    [StructLayout(LayoutKind.Sequential)] public struct R { public int L, T, Rr, B; }
    [StructLayout(LayoutKind.Sequential)] public struct P { public int X, Y; }
}
"@
$proc = Get-Process xd-store -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $proc) { Write-Output 'NO_WINDOW'; exit 1 }
$h = $proc.MainWindowHandle
$cr = New-Object IM+R
[IM]::GetClientRect($h, [ref]$cr) | Out-Null
Write-Output "client $($cr.Rr)x$($cr.B)"
function Pack([int]$x, [int]$y) { [IntPtr]([int64]($x -band 0xFFFF) -bor ([int64]($y -band 0xFFFF) -shl 16)) }
if ($MoveX -ge 0) {
    [IM]::PostMessage($h, 0x0200, [IntPtr]::Zero, (Pack $MoveX $MoveY)) | Out-Null
    Start-Sleep -Milliseconds 80
}
if ($Wheel -ne 0) {
    $pt = New-Object IM+P
    $pt.X = if ($MoveX -ge 0) { $MoveX } else { [int]($cr.Rr / 2) }
    $pt.Y = if ($MoveY -ge 0) { $MoveY } else { [int]($cr.B / 2) }
    [IM]::ClientToScreen($h, [ref]$pt) | Out-Null
    $lp = [IntPtr]([int64]($pt.X -band 0xFFFF) -bor ([int64]($pt.Y -band 0xFFFF) -shl 16))
    $w = [IntPtr]([uint32](0x10000 + $Wheel) -shl 16)
    [IM]::PostMessage($h, 0x020A, $w, $lp) | Out-Null
    Write-Output "wheel $Wheel at screen $($pt.X),$($pt.Y)"
}
if ($ClickX -ge 0) {
    [IM]::PostMessage($h, 0x0200, [IntPtr]::Zero, (Pack $ClickX $ClickY)) | Out-Null
    Start-Sleep -Milliseconds 60
    [IM]::PostMessage($h, 0x0201, [IntPtr]::new(1), (Pack $ClickX $ClickY)) | Out-Null
    Start-Sleep -Milliseconds 50
    [IM]::PostMessage($h, 0x0202, [IntPtr]::Zero, (Pack $ClickX $ClickY)) | Out-Null
    Write-Output "click $ClickX,$ClickY"
}
