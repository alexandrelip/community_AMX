[CmdletBinding()]
param([switch]$IncludeHid,[switch]$ValidateOnly)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function New-HotasPhysicalPlan([object[]]$Devices) {
    $plan=[Collections.Generic.List[object]]::new()
    $blockers=[Collections.Generic.List[string]]::new()
    foreach($device in $Devices){
        if($device.Error){$blockers.Add('HID descriptor unavailable: '+$device.Error);continue}
        if($device.Capabilities.UsagePage -ne 1 -or $device.Capabilities.Usage -notin @(4,5)){continue}
        $controls=[Collections.Generic.List[object]]::new()
        $seen=@{}
        foreach($button in $device.Buttons){
            if($button.IsAlias){continue}
            $last=if($button.IsRange){$button.UsageMaximum}else{$button.UsageMinimum}
            if($last -lt $button.UsageMinimum -or $last-$button.UsageMinimum -gt 1023){throw 'Invalid HID button range.'}
            foreach($usage in $button.UsageMinimum..$last){
                $id=('{0:X4}:R{1}:L{2}:P{3}:U{4}' -f $device.Product,$button.ReportId,$button.LinkCollection,$button.UsagePage,$usage)
                if($seen.ContainsKey($id)){continue};$seen[$id]=$true
                $controls.Add([ordered]@{Id=$id;Kind='Button';ReportId=$button.ReportId;LinkCollection=$button.LinkCollection;
                    UsagePage=$button.UsagePage;Usage=$usage;PhysicalRole=$null;Expected='press, hold, release; no unrelated input';Status='PENDING'})
            }
        }
        foreach($value in $device.Values){
            if($value.IsAlias){continue}
            if($value.ReportCount -ne 1 -or $value.IsRange){$blockers.Add('Value array requires a separate exercise definition.');continue}
            $usage=$value.UsageMinimum
            $id=('{0:X4}:R{1}:L{2}:P{3}:U{4}' -f $device.Product,$value.ReportId,$value.LinkCollection,$value.UsagePage,$usage)
            if($seen.ContainsKey($id)){continue};$seen[$id]=$true
            $kind=if($value.UsagePage -eq 1 -and $usage -eq 57){'Pov'}elseif($value.UsagePage -eq 1 -and $usage -ge 48 -and $usage -le 56){'Axis'}else{'Value'}
            $controls.Add([ordered]@{Id=$id;Kind=$kind;ReportId=$value.ReportId;LinkCollection=$value.LinkCollection;
                UsagePage=$value.UsagePage;Usage=$usage;LogicalMinimum=$value.LogicalMinimum;LogicalMaximum=$value.LogicalMaximum;
                HasNull=[bool]$value.HasNull;PhysicalRole=$null;Expected=$(if($kind -eq 'Pov'){'each declared direction and neutral'}else{'both endpoints; identify neutral/centering behavior; no duplicate axis'});Status='PENDING'})
        }
        $plan.Add([ordered]@{DevicePath=$device.DevicePath;Vendor=$device.Vendor;Product=$device.Product;
            InputBytes=$device.Capabilities.InputBytes;Controls=$controls.ToArray();
            AxisCount=@($controls | Where-Object Kind -eq 'Axis').Count;ButtonCount=@($controls | Where-Object Kind -eq 'Button').Count;
            PovCount=@($controls | Where-Object Kind -eq 'Pov').Count})
    }
    foreach($product in @(0x2221,0xA221)){
        if(@($plan | Where-Object Product -eq $product).Count -ne 1){$blockers.Add(('Expected exactly one X56 joystick collection for PID {0:X4}' -f $product))}
    }
    return [ordered]@{Schema='AMXDENIS_X56_PHYSICAL_PLAN_1';InventoryComplete=($blockers.Count -eq 0);Blockers=$blockers.ToArray();
        Devices=$plan.ToArray();SessionsRequired=2;ReconnectBetweenSessions=$true;NativeDcsCorrelationRequired=$true;
        FullHidStateCaptureAvailable=$false;OperatorRoleAssignmentRequired=$true;AllPhysicalChecksPassed=$false;
        Status='PREPARED_NOT_EXECUTED';Scope='Descriptor inventory only; WinMM cannot record all throttle controls'}
}
if(-not ('AMXDENIS.HotasReader' -as [type])){
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace AMXDENIS {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct JoystickCapabilities {
        public ushort Manufacturer, Product;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string Name;
        public uint XMin, XMax, YMin, YMax, ZMin, ZMax;
        public uint Buttons, PeriodMin, PeriodMax;
        public uint RMin, RMax, UMin, UMax, VMin, VMax;
        public uint Capabilities, MaxAxes, Axes, MaxButtons;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string RegistryKey;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string OemDriver;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct JoystickState {
        public uint Size, Flags, X, Y, Z, R, U, V, Buttons, ButtonNumber, Pov, Reserved1, Reserved2;
    }
    public sealed class JoystickSample {
        public uint Id, Result;
        public JoystickCapabilities Capabilities;
        public JoystickState State;
    }
    public static class HotasReader {
        [DllImport("winmm.dll")] private static extern uint joyGetNumDevs();
        [DllImport("winmm.dll", CharSet = CharSet.Unicode)]
        private static extern uint joyGetDevCapsW(UIntPtr id, out JoystickCapabilities capabilities, uint size);
        [DllImport("winmm.dll")] private static extern uint joyGetPosEx(uint id, ref JoystickState state);
        public static JoystickSample[] Read() {
            if (Marshal.SizeOf(typeof(JoystickCapabilities)) != 728 || Marshal.SizeOf(typeof(JoystickState)) != 52)
                throw new InvalidOperationException("Unexpected WinMM structure size");
            var samples = new List<JoystickSample>();
            uint count = joyGetNumDevs();
            for (uint device = 0; device < count; device++) {
                JoystickCapabilities capabilities;
                if (joyGetDevCapsW(new UIntPtr(device), out capabilities, 728) != 0) continue;
                var state = new JoystickState { Size = 52, Flags = 255 };
                uint result = joyGetPosEx(device, ref state);
                samples.Add(new JoystickSample { Id = device, Result = result, Capabilities = capabilities, State = state });
            }
            return samples.ToArray();
        }
    }
}
'@
}
if($IncludeHid -and -not ('AMXDENIS.HotasHidInventory' -as [type])){
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

namespace AMXDENIS {
    [StructLayout(LayoutKind.Sequential)]
    public struct RawHidDevice { public IntPtr Handle; public uint Type; }
    [StructLayout(LayoutKind.Explicit, Size = 32)]
    public struct RawHidInfo {
        [FieldOffset(0)] public uint Size;
        [FieldOffset(4)] public uint Type;
        [FieldOffset(8)] public uint Vendor;
        [FieldOffset(12)] public uint Product;
        [FieldOffset(16)] public uint Version;
        [FieldOffset(20)] public ushort UsagePage;
        [FieldOffset(22)] public ushort Usage;
    }
    [StructLayout(LayoutKind.Explicit, Size = 64)]
    public struct HidCapabilities {
        [FieldOffset(0)] public ushort Usage;
        [FieldOffset(2)] public ushort UsagePage;
        [FieldOffset(4)] public ushort InputBytes;
        [FieldOffset(46)] public ushort InputButtonCaps;
        [FieldOffset(48)] public ushort InputValueCaps;
        [FieldOffset(50)] public ushort InputDataIndices;
    }
    [StructLayout(LayoutKind.Explicit, Size = 72)]
    public struct HidButtonCapability {
        [FieldOffset(0)] public ushort UsagePage;
        [FieldOffset(2)] public byte ReportId;
        [FieldOffset(3)] public byte IsAlias;
        [FieldOffset(6)] public ushort LinkCollection;
        [FieldOffset(12)] public byte IsRange;
        [FieldOffset(56)] public ushort UsageMinimum;
        [FieldOffset(58)] public ushort UsageMaximum;
    }
    [StructLayout(LayoutKind.Explicit, Size = 72)]
    public struct HidValueCapability {
        [FieldOffset(0)] public ushort UsagePage;
        [FieldOffset(2)] public byte ReportId;
        [FieldOffset(3)] public byte IsAlias;
        [FieldOffset(6)] public ushort LinkCollection;
        [FieldOffset(12)] public byte IsRange;
        [FieldOffset(15)] public byte IsAbsolute;
        [FieldOffset(16)] public byte HasNull;
        [FieldOffset(18)] public ushort BitSize;
        [FieldOffset(20)] public ushort ReportCount;
        [FieldOffset(40)] public int LogicalMinimum;
        [FieldOffset(44)] public int LogicalMaximum;
        [FieldOffset(56)] public ushort UsageMinimum;
        [FieldOffset(58)] public ushort UsageMaximum;
    }
    public sealed class HidInventoryDevice {
        public string DevicePath, Error;
        public uint Vendor, Product, Version;
        public HidCapabilities Capabilities;
        public HidButtonCapability[] Buttons = new HidButtonCapability[0];
        public HidValueCapability[] Values = new HidValueCapability[0];
    }
    public static class HotasHidInventory {
        [DllImport("user32.dll", SetLastError=true, EntryPoint="GetRawInputDeviceList")]
        private static extern uint DeviceCount(IntPtr devices, ref uint count, uint size);
        [DllImport("user32.dll", SetLastError=true, EntryPoint="GetRawInputDeviceList")]
        private static extern uint DeviceList([Out] RawHidDevice[] devices, ref uint count, uint size);
        [DllImport("user32.dll", SetLastError=true, EntryPoint="GetRawInputDeviceInfoW")]
        private static extern uint DeviceInfo(IntPtr device, uint command, ref RawHidInfo info, ref uint size);
        [DllImport("user32.dll", SetLastError=true, EntryPoint="GetRawInputDeviceInfoW")]
        private static extern uint DeviceData(IntPtr device, uint command, IntPtr data, ref uint size);
        [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Unicode, EntryPoint="GetRawInputDeviceInfoW")]
        private static extern uint DeviceName(IntPtr device, uint command, StringBuilder data, ref uint size);
        [DllImport("hid.dll")] private static extern int HidP_GetCaps(IntPtr preparsed, out HidCapabilities caps);
        [DllImport("hid.dll")] private static extern int HidP_GetButtonCaps(int type, [Out] HidButtonCapability[] caps, ref ushort count, IntPtr preparsed);
        [DllImport("hid.dll")] private static extern int HidP_GetValueCaps(int type, [Out] HidValueCapability[] caps, ref ushort count, IntPtr preparsed);
        private static void RequireStatus(int status) {
            if (status != 0x00110000) throw new InvalidOperationException("HID parser status: " + status.ToString("X8"));
        }
        public static int[] ValidateLayout() {
            int[] actual = {Marshal.SizeOf(typeof(RawHidDevice)), Marshal.SizeOf(typeof(RawHidInfo)),
                Marshal.SizeOf(typeof(HidCapabilities)), Marshal.SizeOf(typeof(HidButtonCapability)), Marshal.SizeOf(typeof(HidValueCapability))};
            int[] expected = {IntPtr.Size == 8 ? 16 : 8, 32, 64, 72, 72};
            for (int index=0; index<actual.Length; index++) {
                if (actual[index] != expected[index]) throw new InvalidOperationException("Unexpected HID ABI size");
            }
            return actual;
        }
        public static HidInventoryDevice[] Read() {
            uint size = (uint)ValidateLayout()[0], count = 0;
            if (DeviceCount(IntPtr.Zero, ref count, size) == uint.MaxValue) throw new Win32Exception();
            if (count > 4096) throw new InvalidOperationException("Unexpected raw device count");
            var results = new List<HidInventoryDevice>();
            if (count == 0) return results.ToArray();
            var devices = new RawHidDevice[count];
            uint read = DeviceList(devices, ref count, size);
            if (read == uint.MaxValue || read > devices.Length) throw new Win32Exception();
            for (int index=0; index<read; index++) {
                RawHidDevice device = devices[index];
                if (device.Type != 2) continue;
                var info = new RawHidInfo {Size=32};
                uint infoSize = 32;
                if (DeviceInfo(device.Handle, 0x2000000b, ref info, ref infoSize) == uint.MaxValue) throw new Win32Exception();
                if (info.Vendor != 0x0738 || (info.Product != 0x2221 && info.Product != 0xa221)) continue;
                var result = new HidInventoryDevice {Vendor=info.Vendor, Product=info.Product, Version=info.Version};
                IntPtr preparsed = IntPtr.Zero;
                try {
                    uint nameSize = 0;
                    if (DeviceData(device.Handle, 0x20000007, IntPtr.Zero, ref nameSize) == uint.MaxValue || nameSize == 0 || nameSize > 32768) throw new Win32Exception();
                    var name = new StringBuilder((int)nameSize+1);
                    if (DeviceName(device.Handle, 0x20000007, name, ref nameSize) == uint.MaxValue) throw new Win32Exception();
                    result.DevicePath = name.ToString();
                    uint bytes = 0;
                    if (DeviceData(device.Handle, 0x20000005, IntPtr.Zero, ref bytes) == uint.MaxValue || bytes == 0 || bytes > 1048576) throw new Win32Exception();
                    preparsed = Marshal.AllocHGlobal((int)bytes);
                    if (DeviceData(device.Handle, 0x20000005, preparsed, ref bytes) == uint.MaxValue) throw new Win32Exception();
                    RequireStatus(HidP_GetCaps(preparsed, out result.Capabilities));
                    ushort buttonCount=result.Capabilities.InputButtonCaps, valueCount=result.Capabilities.InputValueCaps;
                    if (buttonCount > 4096 || valueCount > 4096) throw new InvalidOperationException("Unexpected HID capability count");
                    if (buttonCount > 0) {
                        result.Buttons = new HidButtonCapability[buttonCount];
                        RequireStatus(HidP_GetButtonCaps(0, result.Buttons, ref buttonCount, preparsed));
                        Array.Resize(ref result.Buttons, buttonCount);
                    }
                    if (valueCount > 0) {
                        result.Values = new HidValueCapability[valueCount];
                        RequireStatus(HidP_GetValueCaps(0, result.Values, ref valueCount, preparsed));
                        Array.Resize(ref result.Values, valueCount);
                    }
                } catch (Exception error) { result.Error=error.Message; }
                finally { if (preparsed != IntPtr.Zero) Marshal.FreeHGlobal(preparsed); }
                results.Add(result);
            }
            return results.ToArray();
        }
    }
}
'@
}
if($ValidateOnly){
    return [pscustomobject]@{Schema='AMXDENIS_HOTAS_ABI_1';ReadOnly=$true;
        WinMmSizes=@([Runtime.InteropServices.Marshal]::SizeOf([type][AMXDENIS.JoystickCapabilities]),[Runtime.InteropServices.Marshal]::SizeOf([type][AMXDENIS.JoystickState]));
        HidSizes=$(if($IncludeHid){[AMXDENIS.HotasHidInventory]::ValidateLayout()});DevicesRead=$false}
}
$samples=@([AMXDENIS.HotasReader]::Read())
$hidDevices=@(if($IncludeHid){[AMXDENIS.HotasHidInventory]::Read()})
[pscustomobject]@{
    Schema='AMXDENIS_HOTAS_PASSIVE_1'
    RecordedUtc=[DateTime]::UtcNow.ToString('o')
    Backend='WinMM read-only; current physical positions, no injected input'
    CapabilitiesBytes=728
    StateBytes=52
    Devices=@(foreach($sample in $samples){
        [pscustomobject]@{
            Id=$sample.Id
            Name=$sample.Capabilities.Name
            ManufacturerId=$sample.Capabilities.Manufacturer
            ProductId=$sample.Capabilities.Product
            CapabilityFlags=$sample.Capabilities.Capabilities
            HasPov=($sample.Capabilities.Capabilities -band 16) -ne 0
            ReadResult=$sample.Result
            Readable=$sample.Result -eq 0
            AxisCount=$sample.Capabilities.Axes
            ButtonCount=$sample.Capabilities.Buttons
            Axes=[ordered]@{X=$sample.State.X;Y=$sample.State.Y;Z=$sample.State.Z;R=$sample.State.R;U=$sample.State.U;V=$sample.State.V}
            Buttons=$sample.State.Buttons
            Pov=$sample.State.Pov
        }
    })
    HidInventoryRequested=[bool]$IncludeHid
    HidDevices=$hidDevices
    PhysicalTestPlan=$(if($IncludeHid){New-HotasPhysicalPlan $hidDevices})
    HidScope='Input report descriptor only; HID capabilities do not prove physical movement or DCS mapping'
    ApiLimits='WinMM exposes at most six axes and 32 buttons per device; not a complete HID inventory'
    FullPhysicalTravelVerified=$false
    AllButtonsExercised=$false
    NativeDcsMappingApproved=$false
}