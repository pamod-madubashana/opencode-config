param([string]$OutPng = 'E:\Dev\User\Temp\opencode\cap.png')
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W2 {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R2 r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [StructLayout(LayoutKind.Sequential)] public struct R2 { public int L, T, Rr, B; }
}
"@
$HWND_TOPMOST = [IntPtr](-1)
$HWND_NOTOPMOST = [IntPtr](-2)
$flags = 0x2 -bor 0x1 -bor 0x40
$proc = Get-Process xd-store -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $proc) { Write-Output 'NO_WINDOW'; exit 1 }
$h = $proc.MainWindowHandle
[W2]::ShowWindow($h, 9) | Out-Null
[W2]::SetWindowPos($h, $HWND_TOPMOST, 0, 0, 0, 0, $flags) | Out-Null
[W2]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 700
$r = New-Object W2+R2
[W2]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Rr - $r.L; $ht = $r.B - $r.T
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.L, $r.T, 0, 0, (New-Object System.Drawing.Size($w, $ht)))
$bmp.Save($OutPng, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
[W2]::SetWindowPos($h, $HWND_NOTOPMOST, 0, 0, 0, 0, $flags) | Out-Null
Write-Output "saved $OutPng rect L=$($r.L) T=$($r.T) W=$w H=$ht fg=$([W2]::GetForegroundWindow() -eq $h)"
