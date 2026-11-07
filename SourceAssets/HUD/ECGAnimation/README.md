# Animated ECG HUD set

This set contains three horizontally seamless ECG textures with transparent backgrounds:

- `Calm`: one low-amplitude pulse for a relaxed or safe state.
- `Normal`: one standard heartbeat complex for ordinary gameplay.
- `Damage`: three close, high-amplitude pulses for elevated heart rate after taking damage.

## Ready for import

Import the individual textures from `ReadyForImport`:

- `T_HUD_ECG_Calm_Loop_1024x256.png`
- `T_HUD_ECG_Normal_Loop_1024x256.png`
- `T_HUD_ECG_Damage_Loop_1024x256.png`

`T_HUD_ECG_States_Atlas_1024x768.png` is an optional atlas. Its rows are Calm, Normal, and Damage from top to bottom.

## Unreal Engine texture settings

- Texture Group: `UI`
- Compression Settings: `UserInterface2D (RGBA)`
- sRGB: enabled
- Mip Gen Settings: `NoMipmaps`
- Address X: `Wrap`
- Address Y: `Clamp`

## Recommended UI material

Create `M_UI_ECG` with Material Domain `User Interface` and Blend Mode `Translucent`.

Parameters:

- `ECGTexture`: `Texture2D`
- `ScrollSpeed`: scalar
- `LineTint`: vector
- `Opacity`: scalar, default `1.0`

Node logic:

1. Add `Time * ScrollSpeed` to the X component of `TextureCoordinate`.
2. Apply `Frac` to the scrolling X coordinate and sample `ECGTexture`.
3. Use the sampled alpha as the line and glow mask.
4. Connect `LineTint` to Final Color and `Texture Alpha * Opacity` to Opacity.

Using alpha as the mask keeps color fully adjustable. Keep calm and normal cyan; damage can briefly shift toward orange or red without changing the texture.

## Suggested runtime states

| State | Texture | ScrollSpeed | Approximate rhythm | Suggested tint |
| --- | --- | ---: | ---: | --- |
| Calm | `Calm` | `0.75` | 45 BPM | `(0.35, 0.90, 0.82)` |
| Normal | `Normal` | `1.15` | 69 BPM | `(0.45, 1.00, 0.90)` |
| Damage | `Damage` | `0.75` | 135 BPM (3 pulses per loop) | `(1.00, 0.30, 0.12)` or cyan |

The BPM values assume that a UV offset of `1.0` scrolls one complete texture loop.

## UMG / Blueprint switching

1. Put `M_UI_ECG` into an Image widget and obtain its Dynamic Material Instance during widget initialization.
2. Set `ECGTexture`, `ScrollSpeed`, and `LineTint` on that instance.
3. On damage, switch to the Damage texture immediately and keep it for about `0.35-0.60 s`.
4. Interpolate `ScrollSpeed` and `LineTint` back to Normal over about `0.6-1.0 s`.
5. Use Calm when the character is safe, idle, resting, or has not detected danger for the desired delay.

For a softer texture transition, fade `Opacity` down over `0.08 s`, replace `ECGTexture`, then fade it up over `0.08 s`.

## Rebuilding

Run from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Prepare-EcgAnimation.ps1
```

The script creates 1024x256 loop textures, blends their left and right edges into an exact horizontal seam, and builds the optional three-row atlas.

## Generation prompt set

All source images used the existing cyan ECG HUD graphic as the visual reference and requested a genuinely transparent background.

- Calm: one continuous baseline with one small, soft, low-amplitude heartbeat complex.
- Normal: one continuous baseline with a subtle pre-wave, one medium upward spike, a short trough, and a steady return.
- Damage: one continuous baseline with three close, tall, urgent heartbeat complexes.

All prompts required matching edge height for seamless scrolling and excluded text, numbers, grids, frames, medical crosses, opaque backgrounds, and watermarks.
