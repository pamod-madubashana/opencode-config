param([string]$OutPng = 'E:\Dev\User\Temp\opencode\app_home.png')
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [StructLayout(LayoutKind.Sequential)] public struct R { public int L, T, Rr, B; }
}
"@
$HWND_TOPMOST = [IntPtr](-1)
$HWND_NOTOPMOST = [IntPtr](-2)
$SWP_NOMOVE = 0x2; $SWP_NOSIZE = 0x1; $SWP_SHOWWINDOW = 0x40
$flags = $SWP_NOMOVE -bor $SWP_NOSIZE -bor $SWP_SHOWWINDOW
$exe = 'E:\User\Documents\Repositories\XD\target\debug\xd-store.exe'
$p = Start-Process -FilePath $exe -PassThru
$ok = $false
foreach ($i in 1..20) {
    Start-Sleep -Milliseconds 800
    $p.Refresh()
    if ($p.MainWindowHandle -ne 0) { $ok = $true; break }
}
if (-not $ok) { Write-Output 'NO WINDOW'; Stop-Process -Id $p.Id -Force; exit 1 }
$h = $p.MainWindowHandle
[W]::ShowWindow($h, 9) | Out-Null   # SW_RESTORE
[W]::SetWindowPos($h, $HWND_TOPMOST, 0, 0, 0, 0, $flags) | Out-Null
[W]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Seconds 4
$fg = [W]::GetForegroundWindow()
Write-Output "foreground_is_app=$($fg -eq $h)"
$r = New-Object W+R
[W]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Rr - $r.L; $ht = $r.B - $r.T
Write-Output "window rect L=$($r.L) T=$($r.T) W=$w H=$ht"
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.L, $r.T, 0, 0, (New-Object System.Drawing.Size($w, $ht)))
$bmp.Save($OutPng, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
[W]::SetWindowPos($h, $HWND_NOTOPMOST, 0, 0, 0, 0, $flags) | Out-Null
Write-Output "saved $OutPng"
Stop-Process -Id $p.Id -Force
Write-Output 'app stopped'
