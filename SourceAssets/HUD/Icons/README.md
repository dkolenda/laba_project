# HUD icon set

This folder contains six transparent PNG assets recreated from the supplied HUD reference.

## Ready for import

Import files from `ReadyForImport` into an Unreal Engine `/Game/UI/HUD/Icons` folder:

- `T_HUD_Status_Lotus_256.png`
- `T_HUD_Status_Food_256.png`
- `T_HUD_Status_Balance_256.png`
- `T_HUD_Status_Sun_256.png`
- `T_HUD_Health_Cross_256.png`
- `T_HUD_Health_ECG_512x128.png`

The high-resolution generated masters are retained under `Generated/Originals`.

## Recommended Unreal Engine import settings

- Texture Group: `UI`
- Compression Settings: `UserInterface2D (RGBA)`
- sRGB: enabled
- Mip Gen Settings: `NoMipmaps` for fixed-size HUD elements
- Address X / Address Y: `Clamp`
- Alpha mode in UMG material: use the PNG alpha directly

For the amber status icons, use white image tint in UMG to preserve their authored color. The white cross can be tinted freely. The cyan ECG graphic can be placed in a `SizeBox` at an aspect ratio of 4:1.

## Rebuilding the import-sized files

Run from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Prepare-HudIcons.ps1
```

The script trims transparent margins from each generated master, then centers and downsamples the artwork with transparent padding.

## Generation prompt set

All images used the supplied gameplay screenshot as a reference, with `stylized-concept` / `game UI icon` intent and a genuinely transparent background.

- Lotus: symmetrical open lotus, thin amber-gold line art, restrained warm glow.
- Food: shallow domed serving dish or stylized loaf with three circular details, thin amber-gold line art.
- Balance: symmetrical classical balance scales with two hanging pans, thin amber-gold line art.
- Sun: circular sun disc with short evenly spaced rays, thin amber-gold line art.
- Cross: compact equal-armed white medical plus, subtle cool-white glow.
- ECG: one horizontal mint-cyan heartbeat trace with one tall spike and a long baseline.

Every prompt excluded text, numbers, bars, frames, additional symbols, opaque backgrounds, and watermarks.
