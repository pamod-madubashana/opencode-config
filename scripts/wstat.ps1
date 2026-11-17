param([string]$Action = 'stat')
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WS2 {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
    [StructLayout(LayoutKind.Sequential)] public struct R { public int L, T, Rr, B; }
}
"@
$proc = Get-Process xd-store -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $proc) { Write-Output 'NO_WINDOW'; exit 1 }
$h = $proc.MainWindowHandle
if ($Action -eq 'stat') {
    $r = New-Object WS2+R
    [WS2]::GetWindowRect($h, [ref]$r) | Out-Null
    Write-Output "rect L=$($r.L) T=$($r.T) W=$($r.Rr-$r.L) H=$($r.B-$r.T) iconic=$([WS2]::IsIconic($h)) zoomed=$([WS2]::IsZoomed($h))"
} elseif ($Action -eq 'restore') {
    [WS2]::ShowWindow($h, 9) | Out-Null
    Start-Sleep -Milliseconds 400
    [WS2]::SetForegroundWindow($h) | Out-Null
    Write-Output 'restored'
} elseif ($Action -eq 'drag') {
    # drag from window-rel (x1,y1) to (x2,y2)
    $x1 = [int]$args[0]; $y1 = [int]$args[1]; $x2 = [int]$args[2]; $y2 = [int]$args[3]
    [WS2]::ShowWindow($h, 9) | Out-Null
    [WS2]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 300
    $r = New-Object WS2+R
    [WS2]::GetWindowRect($h, [ref]$r) | Out-Null
    $sx = $r.L + $x1; $sy = $r.T + $y1
    [WS2]::SetCursorPos($sx, $sy) | Out-Null
    Start-Sleep -Milliseconds 120
    [WS2]::mouse_event(0x02, 0, 0, 0, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 120
    # move in steps so the OS drag loop engages
    for ($i = 1; $i -le 8; $i++) {
        $cx = $sx + [int](($x2-$x1) * $i / 8)
        $cy = $sy + [int](($y2-$y1) * $i / 8)
        [WS2]::SetCursorPos($cx, $cy) | Out-Null
        Start-Sleep -Milliseconds 60
    }
    [WS2]::mouse_event(0x04, 0, 0, 0, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 300
    [WS2]::GetWindowRect($h, [ref]$r) | Out-Null
    Write-Output "dragged rect L=$($r.L) T=$($r.T) W=$($r.Rr-$r.L) H=$($r.B-$r.T)"
} elseif ($Action -eq 'dbl') {
    $x1 = [int]$args[0]; $y1 = [int]$args[1]
    [WS2]::ShowWindow($h, 9) | Out-Null
    [WS2]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 300
    $r = New-Object WS2+R
    [WS2]::GetWindowRect($h, [ref]$r) | Out-Null
    [WS2]::SetCursorPos(($r.L + $x1), ($r.T + $y1)) | Out-Null
    Start-Sleep -Milliseconds 120
    foreach ($n in 1..2) {
        [WS2]::mouse_event(0x02, 0, 0, 0, [IntPtr]::Zero)
        Start-Sleep -Milliseconds 60
        [WS2]::mouse_event(0x04, 0, 0, 0, [IntPtr]::Zero)
        Start-Sleep -Milliseconds 220
    }
    Start-Sleep -Milliseconds 400
    [WS2]::GetWindowRect($h, [ref]$r) | Out-Null
    Write-Output "dbl rect L=$($r.L) T=$($r.T) W=$($r.Rr-$r.L) H=$($r.B-$r.T) zoomed=$([WS2]::IsZoomed($h))"
} elseif ($Action -eq 'rclick') {
    $x1 = [int]$args[0]; $y1 = [int]$args[1]
    [WS2]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 250
    $r = New-Object WS2+R
    [WS2]::GetWindowRect($h, [ref]$r) | Out-Null
    [WS2]::SetCursorPos(($r.L + $x1), ($r.T + $y1)) | Out-Null
    Start-Sleep -Milliseconds 100
    [WS2]::mouse_event(0x08, 0, 0, 0, [IntPtr]::Zero)   # right down
    Start-Sleep -Milliseconds 60
    [WS2]::mouse_event(0x10, 0, 0, 0, [IntPtr]::Zero)   # right up
    Start-Sleep -Milliseconds 300
    Write-Output 'right-clicked'
} elseif ($Action -eq 'move') {
    $x1 = [int]$args[0]; $y1 = [int]$args[1]
    $r = New-Object WS2+R
    [WS2]::GetWindowRect($h, [ref]$r) | Out-Null
    [WS2]::SetCursorPos(($r.L + $x1), ($r.T + $y1)) | Out-Null
    Start-Sleep -Milliseconds 150
    Write-Output 'moved'
}
