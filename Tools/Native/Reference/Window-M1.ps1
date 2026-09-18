[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunFile,
    [ValidateSet('ModelViewer2','DCS')][string]$ProcessName = 'ModelViewer2',
    [ValidateSet('Info','Activate','FitViewport','Capture','Key','ScanKey','Move','Click','Close')][string]$Action = 'Info',
    [string]$Keys,
    [ValidateRange(480,3840)][int]$ViewportWidth = 1280,
    [ValidateRange(360,2160)][int]$ViewportHeight = 720,
    [ValidateRange(1,127)][int]$ScanCode = 1,
    [switch]$Control,
    [switch]$Shift,
    [switch]$Alt,
    [switch]$RightControl,
    [switch]$RightAlt,
    [switch]$RightShift,
    [switch]$Extended,
    [string]$OutputPath,
    [int]$X,
    [int]$Y,
    [switch]$DesktopCapture
)

$ErrorActionPreference = 'Stop'
function Get-MouseMotion([int]$ScreenX, [int]$ScreenY, $Screen) {
    if ($Screen.Width -le 1 -or $Screen.Height -le 1 -or $ScreenX -lt $Screen.Left -or $ScreenX -ge $Screen.Right -or
        $ScreenY -lt $Screen.Top -or $ScreenY -ge $Screen.Bottom) { throw 'Mouse target is outside the visible desktop.' }
    return [pscustomobject]@{
        X=[uint32][Math]::Round(($ScreenX - $Screen.Left) * 65535.0 / ($Screen.Width - 1))
        Y=[uint32][Math]::Round(($ScreenY - $Screen.Top) * 65535.0 / ($Screen.Height - 1))
    }
}

$run = Get-Content -LiteralPath $RunFile -Raw | ConvertFrom-Json
$owned = Get-Process -Id $run.ProcessId
if ($owned.ProcessName -ne $ProcessName -or
    $owned.StartTime.ToUniversalTime() -ne ([datetime]$run.Started).ToUniversalTime()) {
    throw 'Owned process/window identity does not match the recorded run.'
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
if (-not ('AMXM1WindowV7' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class AMXM1WindowV7 {
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct Point { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] public struct KeyboardInput { public ushort Vk, Scan; public uint Flags, Time; public UIntPtr Extra; }
    [StructLayout(LayoutKind.Sequential)] public struct MouseInput { public int X, Y; public uint Data, Flags, Time; public UIntPtr Extra; }
    [StructLayout(LayoutKind.Explicit)] public struct InputUnion {
        [FieldOffset(0)] public KeyboardInput Keyboard;
        [FieldOffset(0)] public MouseInput Mouse;
    }
    [StructLayout(LayoutKind.Sequential)] public struct Input { public uint Type; public InputUnion Data; }
    [DllImport("user32.dll", SetLastError=true)] private static extern uint SendInput(uint count, Input[] inputs, int size);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr window, out Rect rectangle);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr window, out Rect rectangle);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool SetWindowPos(IntPtr window, IntPtr insertAfter, int x, int y, int width, int height, uint flags);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr window, IntPtr device, uint flags);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out Point position);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint x, uint y, uint data, UIntPtr extra);
    [DllImport("user32.dll")] private static extern bool SetForegroundWindow(IntPtr window);
    [DllImport("user32.dll")] private static extern bool BringWindowToTop(IntPtr window);
    [DllImport("user32.dll")] private static extern IntPtr SetActiveWindow(IntPtr window);
    [DllImport("user32.dll")] private static extern IntPtr SetFocus(IntPtr window);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window, IntPtr process);
    [DllImport("kernel32.dll")] private static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] private static extern bool AttachThreadInput(uint source, uint target, bool attach);
    [DllImport("user32.dll")] private static extern bool IsIconic(IntPtr window);
    [DllImport("user32.dll")] private static extern bool ShowWindow(IntPtr window, int command);
    [DllImport("user32.dll", SetLastError=true)] private static extern IntPtr OpenInputDesktop(uint flags, bool inherit, uint access);
    [DllImport("user32.dll")] private static extern bool CloseDesktop(IntPtr desktop);
    private delegate bool WindowCallback(IntPtr window, IntPtr argument);
    [DllImport("user32.dll")] private static extern bool EnumWindows(WindowCallback callback, IntPtr argument);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll", EntryPoint="GetWindowThreadProcessId")] private static extern uint WindowProcessId(IntPtr window, out uint process);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] private static extern int GetWindowText(IntPtr window, StringBuilder text, int maximum);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool PostMessage(IntPtr window, uint message, IntPtr first, IntPtr second);
    public static bool IsViewport(int width, int height) { return width >= 480 && height >= 360; }
    public static IntPtr FindViewport(uint process) {
        IntPtr selected = IntPtr.Zero;
        long largest = 0;
        EnumWindows(delegate(IntPtr window, IntPtr argument) {
            uint owner;
            WindowProcessId(window, out owner);
            Rect client;
            if (owner != process || !IsWindowVisible(window) || IsIconic(window) || !GetClientRect(window, out client)) return true;
            int width = client.Right - client.Left, height = client.Bottom - client.Top;
            long area = (long)width * height;
            if (IsViewport(width, height) && area > largest) { selected = window; largest = area; }
            return true;
        }, IntPtr.Zero);
        return selected;
    }
    public static string Title(IntPtr window) {
        StringBuilder text = new StringBuilder(512);
        GetWindowText(window, text, text.Capacity);
        return text.ToString();
    }
    public static Input CreateScan(ushort scanCode, bool release) {
        Input input = new Input();
        input.Type = 1;
        input.Data.Keyboard.Scan = (ushort)(scanCode & 0xFF);
        input.Data.Keyboard.Flags = 8u | (release ? 2u : 0u) | ((scanCode & 0xFF00) == 0xE000 ? 1u : 0u);
        return input;
    }
    public static void Scan(ushort scanCode, bool release) {
        Input input = CreateScan(scanCode, release);
        if (SendInput(1, new Input[] { input }, Marshal.SizeOf(typeof(Input))) != 1)
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
    }
    public static bool Activate(IntPtr window) {
        IntPtr desktop = OpenInputDesktop(0, false, 1);
        if (desktop == IntPtr.Zero) return false;
        CloseDesktop(desktop);
        uint current = GetCurrentThreadId();
        uint foreground = GetWindowThreadProcessId(GetForegroundWindow(), IntPtr.Zero);
        uint target = GetWindowThreadProcessId(window, IntPtr.Zero);
        bool attached = foreground != 0 && foreground != current && AttachThreadInput(current, foreground, true);
        bool targetAttached = target != 0 && target != current && target != foreground && AttachThreadInput(current, target, true);
        try {
            if (IsIconic(window)) ShowWindow(window, 9);
            BringWindowToTop(window);
            SetActiveWindow(window);
            SetForegroundWindow(window);
            SetFocus(window);
            return GetForegroundWindow() == window;
        } finally {
            if (targetAttached) AttachThreadInput(current, target, false);
            if (attached) AttachThreadInput(current, foreground, false);
        }
    }
}
'@
}
[void][AMXM1WindowV7]::SetProcessDPIAware()
$window = [AMXM1WindowV7]::FindViewport([uint32]$owned.Id)
if ($window -eq [IntPtr]::Zero) { throw 'No visible full viewport belongs to the owned process; no capture or input sent.' }
$bounds = [AMXM1WindowV7+Rect]::new()
if (-not [AMXM1WindowV7]::GetWindowRect($window, [ref]$bounds)) {
    throw 'Window bounds unavailable.'
}
$client = [AMXM1WindowV7+Rect]::new()
if (-not [AMXM1WindowV7]::GetClientRect($window, [ref]$client)) { throw 'Client bounds unavailable.' }
if ($Action -eq 'FitViewport') {
    if ($ProcessName -ne 'DCS' -or $run.Profile -notmatch '^DCS\.AMXM1-') { throw 'Viewport changes require a private M1 DCS run.' }
    $workingArea = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $frameWidth = $bounds.Right - $bounds.Left - $client.Right
    $frameHeight = $bounds.Bottom - $bounds.Top - $client.Bottom
    $width = $ViewportWidth + $frameWidth
    $height = $ViewportHeight + $frameHeight
    if ($width -gt $workingArea.Width -or $height -gt $workingArea.Height) { throw 'Requested viewport does not fit the accessible desktop.' }
    if (-not [AMXM1WindowV7]::SetWindowPos($window, [IntPtr]::Zero,
        $workingArea.Left + [int](($workingArea.Width - $width) / 2),
        $workingArea.Top + [int](($workingArea.Height - $height) / 2), $width, $height, 0x0014)) {
        throw 'Private viewport resize failed.'
    }
    Write-Output "M1 private viewport requested: $ViewportWidth x $ViewportHeight; verify actual client dimensions before measurement."
    return
}
if ($Action -eq 'Info') {
    [pscustomobject]@{Id=$owned.Id; Title=[AMXM1WindowV7]::Title($window); Handle=$window.ToInt64(); Left=$bounds.Left; Top=$bounds.Top;
        Width=$bounds.Right-$bounds.Left; Height=$bounds.Bottom-$bounds.Top;
        ClientWidth=$client.Right; ClientHeight=$client.Bottom;
        Foreground=([AMXM1WindowV7]::GetForegroundWindow() -eq $window)}
    return
}
if ($Action -eq 'Close') {
    if ($run.UserOpened -eq $true -or $run.CloseAllowed -eq $false) {
        throw 'This window was opened by the user; it is not owned for shutdown.'
    }
    if (-not [AMXM1WindowV7]::PostMessage($window, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)) { throw 'Owned viewport refused close request.' }
    if (-not $owned.WaitForExit(15000)) { throw 'Owned process still closing; do not change its files.' }
    Write-Output 'M1 owned process closed.'
    return
}
if ($Action -in @('Activate','Key','ScanKey','Move','Click') -or $DesktopCapture) {
    if ($client.Right -lt 480 -or $client.Bottom -lt 360) { throw 'Window is not a full test viewport.' }
    if (-not [AMXM1WindowV7]::Activate($window)) { throw 'Foreground unavailable; no input/capture sent.' }
}
if ($Action -eq 'Activate') { Write-Output 'M1 window activated.'; return }
if ($Action -eq 'ScanKey') {
    if ($ProcessName -ne 'DCS' -or $run.Profile -notmatch '^DCS\.AMXM1-') { throw 'Scan input is restricted to a private M1 DCS run.' }
    $state = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $RunFile) 'run.json') -Raw | ConvertFrom-Json
    if ($state.ProfileName -ne $run.Profile) { throw 'Private input profile mismatch.' }
    $telemetry = Join-Path $state.Profile 'Logs\M1-display.log'
    if (-not (Test-Path -LiteralPath $telemetry)) { throw 'Live private telemetry is required before keyboard input.' }
    $length = (Get-Item -LiteralPath $telemetry).Length
    $watcher = [IO.FileSystemWatcher]::new((Split-Path -Parent $telemetry), (Split-Path -Leaf $telemetry))
    $watcher.NotifyFilter = [IO.NotifyFilters]::LastWrite -bor [IO.NotifyFilters]::Size
    $watcher.EnableRaisingEvents = $true
    $pressed = [Collections.Generic.List[ushort]]::new()
    try {
        $codes = @()
        if ($Control) { $codes += 0x1D }
        if ($Shift) { $codes += 0x2A }
        if ($Alt) { $codes += 0x38 }
        if ($RightControl) { $codes += 0xE01D }
        if ($RightAlt) { $codes += 0xE038 }
        if ($RightShift) { $codes += 0x36 }
        $codes += if ($Extended) { $ScanCode -bor 0xE000 } else { $ScanCode }
        foreach ($code in $codes) {
            if ([AMXM1WindowV7]::GetForegroundWindow() -ne $window) { throw 'Foreground lost during keyboard chord.' }
            [AMXM1WindowV7]::Scan([ushort]$code, $false)
            $pressed.Add([ushort]$code)
        }
        $deadline = [datetime]::UtcNow.AddSeconds(3)
        while ((Get-Item -LiteralPath $telemetry).Length -le $length -and [datetime]::UtcNow -lt $deadline) {
            [void]$watcher.WaitForChanged([IO.WatcherChangeTypes]::Changed, 500)
        }
    } finally {
        for ($index = $pressed.Count - 1; $index -ge 0; $index--) { [AMXM1WindowV7]::Scan($pressed[$index], $true) }
        $watcher.Dispose()
    }
    Write-Output ('M1_SCAN_KEY|scan={0}|ctrl={1}|shift={2}|rctrl={3}|ralt={4}|extended={5}|rshift={6}|alt={7}|released=true' -f
        $ScanCode, [bool]$Control, [bool]$Shift, [bool]$RightControl, [bool]$RightAlt, [bool]$Extended, [bool]$RightShift, [bool]$Alt)
    return
}
if ($Action -in @('Move','Click')) {
    if ($X -lt 0 -or $Y -lt 0 -or $X -ge $bounds.Right-$bounds.Left -or $Y -ge $bounds.Bottom-$bounds.Top) {
        throw 'Requested point is outside the owned window.'
    }
    $screenX = $bounds.Left + $X
    $screenY = $bounds.Top + $Y
    if ($Action -eq 'Move') {
        $screen = [Windows.Forms.SystemInformation]::VirtualScreen
        $motion = Get-MouseMotion $screenX $screenY $screen
        if ([AMXM1WindowV7]::GetForegroundWindow() -ne $window) { throw 'Foreground lost before mouse motion.' }
        [AMXM1WindowV7]::mouse_event(0xC001, $motion.X, $motion.Y, 0, [UIntPtr]::Zero)
        Write-Output 'M1 physical mouse motion sent; no button pressed; Click must verify the final cursor position.'
    } else {
        $cursor = [AMXM1WindowV7+Point]::new()
        if (-not [AMXM1WindowV7]::GetCursorPos([ref]$cursor) -or $cursor.X -ne $screenX -or $cursor.Y -ne $screenY) {
            throw 'Cursor moved since the separate Move action; no click sent.'
        }
        $watcher = $null
        if ($ProcessName -eq 'DCS') {
            if ($run.Profile -notmatch '^DCS\.AMXM1-') { throw 'Mouse input requires a private M1 profile.' }
            $state = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $RunFile) 'run.json') -Raw | ConvertFrom-Json
            if ($state.ProfileName -ne $run.Profile) { throw 'Private mouse input profile mismatch.' }
            $telemetry = Join-Path $state.Profile 'Logs\M1-display.log'
            if (-not (Test-Path -LiteralPath $telemetry)) { throw 'Private mouse input requires live telemetry.' }
            $length = (Get-Item -LiteralPath $telemetry).Length
            $watcher = [IO.FileSystemWatcher]::new((Split-Path -Parent $telemetry), (Split-Path -Leaf $telemetry))
            $watcher.EnableRaisingEvents = $true
        }
        try {
            if ([AMXM1WindowV7]::GetForegroundWindow() -ne $window) { throw 'Foreground lost before mouse press.' }
            [AMXM1WindowV7]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero)
            if ($watcher) {
                $deadline = [datetime]::UtcNow.AddSeconds(3)
                while ((Get-Item -LiteralPath $telemetry).Length -le $length -and [datetime]::UtcNow -lt $deadline) {
                    [void]$watcher.WaitForChanged([IO.WatcherChangeTypes]::Changed, 500)
                }
                if ((Get-Item -LiteralPath $telemetry).Length -le $length) { throw 'No new simulator sample during mouse press.' }
            }
        } finally {
            [AMXM1WindowV7]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
            if ($watcher) { $watcher.Dispose() }
        }
        Write-Output 'M1 click sent at previously positioned cursor.'
    }
    return
}
if ($Action -eq 'Key') {
    if (-not $Keys) { throw 'Keys are required.' }
    [Windows.Forms.SendKeys]::SendWait($Keys)
    Write-Output 'M1 keys sent to owned foreground window.'
    return
}
if ($Action -eq 'Capture') {
    if (-not $OutputPath -or (Test-Path -LiteralPath $OutputPath)) { throw 'Capture requires a new output path.' }
    $width = $bounds.Right-$bounds.Left
    $height = $bounds.Bottom-$bounds.Top
    if (-not [AMXM1WindowV7]::IsViewport($client.Right, $client.Bottom)) { throw 'Capture does not contain a full test viewport.' }
    $bitmap = [Drawing.Bitmap]::new($width, $height)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    try {
        if ($DesktopCapture) {
            $screen = [Windows.Forms.SystemInformation]::VirtualScreen
            if ($bounds.Left -lt $screen.Left -or $bounds.Top -lt $screen.Top -or
                $bounds.Right -gt $screen.Right -or $bounds.Bottom -gt $screen.Bottom) { throw 'Window lies outside visible desktop.' }
            $graphics.CopyFromScreen([Drawing.Point]::new($bounds.Left, $bounds.Top),
                [Drawing.Point]::Empty, [Drawing.Size]::new($width, $height))
        } else {
            $device = $graphics.GetHdc()
            try {
                if (-not [AMXM1WindowV7]::PrintWindow($window, $device, 2)) { throw 'Native capture failed.' }
            } finally { $graphics.ReleaseHdc($device) }
        }
        $bitmap.Save($OutputPath, [Drawing.Imaging.ImageFormat]::Png)
        Write-Output "M1 capture: $OutputPath ($width x $height)"
    } finally { $graphics.Dispose(); $bitmap.Dispose() }
}