param(
    [string]$SourceDirectory,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($SourceDirectory)) {
    $SourceDirectory = Join-Path $projectRoot 'SourceAssets\HUD\ECGAnimation\Generated\Originals'
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot 'SourceAssets\HUD\ECGAnimation\ReadyForImport'
}

$targetWidth = 1024
$targetHeight = 256
$seamWidth = 32

$assets = @(
    @{ Source = 'T_HUD_ECG_Calm_Source.png';   Output = 'T_HUD_ECG_Calm_Loop_1024x256.png' },
    @{ Source = 'T_HUD_ECG_Normal_Source.png'; Output = 'T_HUD_ECG_Normal_Loop_1024x256.png' },
    @{ Source = 'T_HUD_ECG_Damage_Source.png'; Output = 'T_HUD_ECG_Damage_Loop_1024x256.png' }
)

function Get-InterpolatedColor {
    param(
        [Parameter(Mandatory)]
        [System.Drawing.Color]$From,

        [Parameter(Mandatory)]
        [System.Drawing.Color]$To,

        [Parameter(Mandatory)]
        [double]$Amount
    )

    $amountClamped = [Math]::Max(0.0, [Math]::Min(1.0, $Amount))

    return [System.Drawing.Color]::FromArgb(
        [int][Math]::Round($From.A + (($To.A - $From.A) * $amountClamped)),
        [int][Math]::Round($From.R + (($To.R - $From.R) * $amountClamped)),
        [int][Math]::Round($From.G + (($To.G - $From.G) * $amountClamped)),
        [int][Math]::Round($From.B + (($To.B - $From.B) * $amountClamped))
    )
}

function Get-AverageColor {
    param(
        [Parameter(Mandatory)]
        [System.Drawing.Color]$First,

        [Parameter(Mandatory)]
        [System.Drawing.Color]$Second
    )

    return [System.Drawing.Color]::FromArgb(
        [int][Math]::Round(($First.A + $Second.A) / 2.0),
        [int][Math]::Round(($First.R + $Second.R) / 2.0),
        [int][Math]::Round(($First.G + $Second.G) / 2.0),
        [int][Math]::Round(($First.B + $Second.B) / 2.0)
    )
}

function Repair-HorizontalSeam {
    param(
        [Parameter(Mandatory)]
        [System.Drawing.Bitmap]$Bitmap,

        [Parameter(Mandatory)]
        [int]$BlendWidth
    )

    if (($BlendWidth * 2) -ge $Bitmap.Width) {
        throw 'The seam blend region is too wide for this image.'
    }

    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        $leftInterior = $Bitmap.GetPixel($BlendWidth, $y)
        $rightInterior = $Bitmap.GetPixel($Bitmap.Width - 1 - $BlendWidth, $y)
        $seamColor = Get-AverageColor -First $leftInterior -Second $rightInterior

        for ($offset = 0; $offset -lt $BlendWidth; $offset++) {
            $amount = ($offset + 1.0) / $BlendWidth
            $leftColor = Get-InterpolatedColor -From $seamColor -To $leftInterior -Amount $amount
            $rightColor = Get-InterpolatedColor -From $seamColor -To $rightInterior -Amount $amount

            $Bitmap.SetPixel($offset, $y, $leftColor)
            $Bitmap.SetPixel($Bitmap.Width - 1 - $offset, $y, $rightColor)
        }

        $Bitmap.SetPixel(0, $y, $seamColor)
        $Bitmap.SetPixel($Bitmap.Width - 1, $y, $seamColor)
    }
}

function Export-EcgLoopTexture {
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $source = [System.Drawing.Bitmap]::new($SourcePath)

    try {
        $output = [System.Drawing.Bitmap]::new(
            $targetWidth,
            $targetHeight,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )

        try {
            $graphics = [System.Drawing.Graphics]::FromImage($output)

            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.DrawImage($source, 0, 0, $targetWidth, $targetHeight)
            }
            finally {
                $graphics.Dispose()
            }

            Repair-HorizontalSeam -Bitmap $output -BlendWidth $seamWidth
            $output.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $output.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }
}

function Export-StateAtlas {
    param(
        [Parameter(Mandatory)]
        [string[]]$TexturePaths,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $atlas = [System.Drawing.Bitmap]::new(
        $targetWidth,
        $targetHeight * $TexturePaths.Count,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )

    try {
        $graphics = [System.Drawing.Graphics]::FromImage($atlas)

        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

            for ($index = 0; $index -lt $TexturePaths.Count; $index++) {
                $texture = [System.Drawing.Bitmap]::new($TexturePaths[$index])

                try {
                    $graphics.DrawImage($texture, 0, $index * $targetHeight, $targetWidth, $targetHeight)
                }
                finally {
                    $texture.Dispose()
                }
            }
        }
        finally {
            $graphics.Dispose()
        }

        $atlas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $atlas.Dispose()
    }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$preparedTextures = @()

foreach ($asset in $assets) {
    $sourcePath = Join-Path $SourceDirectory $asset.Source
    $outputPath = Join-Path $OutputDirectory $asset.Output

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Missing source image: $sourcePath"
    }

    Export-EcgLoopTexture -SourcePath $sourcePath -OutputPath $outputPath
    $preparedTextures += $outputPath
    Write-Host "Prepared $($asset.Output)"
}

$atlasPath = Join-Path $OutputDirectory 'T_HUD_ECG_States_Atlas_1024x768.png'
Export-StateAtlas -TexturePaths $preparedTextures -OutputPath $atlasPath
Write-Host 'Prepared T_HUD_ECG_States_Atlas_1024x768.png'
