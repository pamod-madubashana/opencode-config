param([int]$RelX, [int]$RelY)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W3 {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R3 r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
    [StructLayout(LayoutKind.Sequential)] public struct R3 { public int L, T, Rr, B; }
}
"@
$proc = Get-Process xd-store -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $proc) { Write-Output 'NO_WINDOW'; exit 1 }
$h = $proc.MainWindowHandle
[W3]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 300
$r = New-Object W3+R3
[W3]::ShowWindow($h, 9) | Out-Null
[W3]::GetWindowRect($h, [ref]$r) | Out-Null
$x = $r.L + $RelX; $y = $r.T + $RelY
[W3]::SetCursorPos($x, $y) | Out-Null
Start-Sleep -Milliseconds 80
[W3]::mouse_event(0x02, 0, 0, 0, [IntPtr]::Zero)
Start-Sleep -Milliseconds 60
[W3]::mouse_event(0x04, 0, 0, 0, [IntPtr]::Zero)
Write-Output "clicked $RelX,$RelY screen $x,$y"

