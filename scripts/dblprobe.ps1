param([int]$Rx = 508, [int]$Ry = 37)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class DP {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
    [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
    [StructLayout(LayoutKind.Sequential)] public struct R { public int L, T, Rr, B; }
}
"@
$proc = Get-Process xd-store -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $proc) { Write-Output 'NO_WINDOW'; exit 1 }
$h = $proc.MainWindowHandle
function St([string]$tag) {
    $r = New-Object DP+R
    [DP]::GetWindowRect($h, [ref]$r) | Out-Null
    Write-Output ("{0}: L={1} T={2} zoomed={3}" -f $tag, $r.L, $r.T, [DP]::IsZoomed($h))
}
[DP]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 300
$r = New-Object DP+R
[DP]::GetWindowRect($h, [ref]$r) | Out-Null
$sx = $r.L + $Rx; $sy = $r.T + $Ry
[DP]::SetCursorPos($sx, $sy) | Out-Null
Start-Sleep -Milliseconds 150
St 'before'
[DP]::mouse_event(0x02,0,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 120
St 'after-down1'
[DP]::mouse_event(0x04,0,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 200
St 'after-up1'
[DP]::mouse_event(0x02,0,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 120
St 'after-down2'
[DP]::mouse_event(0x04,0,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 300
St 'after-up2'
