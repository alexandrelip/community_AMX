[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
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
$samples=@([AMXDENIS.HotasReader]::Read())
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
    ApiLimits='WinMM exposes at most six axes and 32 buttons per device; not a complete HID inventory'
    FullPhysicalTravelVerified=$false
    AllButtonsExercised=$false
    NativeDcsMappingApproved=$false
}