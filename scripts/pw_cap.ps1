param([string]$OutPng = 'E:\Dev\User\Temp\opencode\app_home.png', [switch]$Resize)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PW2 {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R2 r);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
    [StructLayout(LayoutKind.Sequential)] public struct R2 { public int L, T, Rr, B; }
}
"@
$proc = Get-Process xd-store -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $proc) { Write-Output 'NO_WINDOW'; exit 1 }
$h = $proc.MainWindowHandle
if ($Resize) {
# outer 1376x909 => client 1360x900 (invisible borders L/R/B=8, top=1; no titlebar strip)
[PW2]::SetWindowPos($h, [IntPtr]::Zero, 16, 16, 1376, 909, 0x0 -bor 0x4) | Out-Null
    Start-Sleep -Milliseconds 600
}
# force a compositor present: jiggle size by 1px and back
$r0 = New-Object PW2+R2
[PW2]::GetWindowRect($h, [ref]$r0) | Out-Null
$w0 = $r0.Rr - $r0.L; $h0 = $r0.B - $r0.T
[PW2]::SetWindowPos($h, [IntPtr]::Zero, $r0.L, $r0.T, $w0 - 1, $h0, 0x0 -bor 0x4) | Out-Null
Start-Sleep -Milliseconds 40
[PW2]::SetWindowPos($h, [IntPtr]::Zero, $r0.L, $r0.T, $w0, $h0, 0x0 -bor 0x4) | Out-Null
Start-Sleep -Milliseconds 120
$r = New-Object PW2+R2
[PW2]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Rr - $r.L; $ht = $r.B - $r.T
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
$ok = [PW2]::PrintWindow($h, $hdc, 2)
$g.ReleaseHdc($hdc)
$g.Dispose()
if (-not $ok) { $bmp.Dispose(); Write-Output 'PRINTWINDOW_FAILED'; exit 1 }
$bmp.Save($OutPng, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "saved $OutPng rect L=$($r.L) T=$($r.T) W=$w H=$ht"
