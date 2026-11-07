param(
    [string]$SourceDirectory,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($SourceDirectory)) {
    $SourceDirectory = Join-Path $projectRoot 'SourceAssets\HUD\Icons\Generated\Originals'
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot 'SourceAssets\HUD\Icons\ReadyForImport'
}

$assets = @(
    @{ Source = 'T_HUD_Status_Lotus_Source.png';  Output = 'T_HUD_Status_Lotus_256.png';  Width = 256; Height = 256; Padding = 20 },
    @{ Source = 'T_HUD_Status_Food_Source.png';   Output = 'T_HUD_Status_Food_256.png';   Width = 256; Height = 256; Padding = 20 },
    @{ Source = 'T_HUD_Status_Balance_Source.png'; Output = 'T_HUD_Status_Balance_256.png'; Width = 256; Height = 256; Padding = 20 },
    @{ Source = 'T_HUD_Status_Sun_Source.png';    Output = 'T_HUD_Status_Sun_256.png';    Width = 256; Height = 256; Padding = 20 },
    @{ Source = 'T_HUD_Health_Cross_Source.png';  Output = 'T_HUD_Health_Cross_256.png';  Width = 256; Height = 256; Padding = 24 },
    @{ Source = 'T_HUD_Health_ECG_Source.png';    Output = 'T_HUD_Health_ECG_512x128.png'; Width = 512; Height = 128; Padding = 8 }
)

function Get-AlphaBounds {
    param(
        [Parameter(Mandatory)]
        [System.Drawing.Bitmap]$Bitmap,

        [byte]$AlphaThreshold = 2
    )

    $rectangle = [System.Drawing.Rectangle]::new(0, 0, $Bitmap.Width, $Bitmap.Height)
    $bitmapData = $Bitmap.LockBits(
        $rectangle,
        [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )

    try {
        $stride = [Math]::Abs($bitmapData.Stride)
        $bytes = [byte[]]::new($stride * $Bitmap.Height)
        [System.Runtime.InteropServices.Marshal]::Copy($bitmapData.Scan0, $bytes, 0, $bytes.Length)

        $minX = $Bitmap.Width
        $minY = $Bitmap.Height
        $maxX = -1
        $maxY = -1

        for ($y = 0; $y -lt $Bitmap.Height; $y++) {
            $rowStart = $y * $stride

            for ($x = 0; $x -lt $Bitmap.Width; $x++) {
                $alpha = $bytes[$rowStart + ($x * 4) + 3]

                if ($alpha -le $AlphaThreshold) {
                    continue
                }

                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }

        if ($maxX -lt 0 -or $maxY -lt 0) {
            throw 'The source image has no visible pixels.'
        }

        return [System.Drawing.Rectangle]::FromLTRB($minX, $minY, $maxX + 1, $maxY + 1)
    }
    finally {
        $Bitmap.UnlockBits($bitmapData)
    }
}

function Export-HudTexture {
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter(Mandatory)]
        [int]$Width,

        [Parameter(Mandatory)]
        [int]$Height,

        [Parameter(Mandatory)]
        [int]$Padding
    )

    $source = [System.Drawing.Bitmap]::new($SourcePath)

    try {
        $bounds = Get-AlphaBounds -Bitmap $source
        $usableWidth = $Width - ($Padding * 2)
        $usableHeight = $Height - ($Padding * 2)
        $scale = [Math]::Min($usableWidth / $bounds.Width, $usableHeight / $bounds.Height)
        $drawWidth = [Math]::Max(1, [int][Math]::Round($bounds.Width * $scale))
        $drawHeight = [Math]::Max(1, [int][Math]::Round($bounds.Height * $scale))
        $drawX = [int][Math]::Floor(($Width - $drawWidth) / 2)
        $drawY = [int][Math]::Floor(($Height - $drawHeight) / 2)

        $output = [System.Drawing.Bitmap]::new(
            $Width,
            $Height,
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

                $destinationRectangle = [System.Drawing.Rectangle]::new($drawX, $drawY, $drawWidth, $drawHeight)
                $graphics.DrawImage(
                    $source,
                    $destinationRectangle,
                    $bounds.X,
                    $bounds.Y,
                    $bounds.Width,
                    $bounds.Height,
                    [System.Drawing.GraphicsUnit]::Pixel
                )
            }
            finally {
                $graphics.Dispose()
            }

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

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

foreach ($asset in $assets) {
    $sourcePath = Join-Path $SourceDirectory $asset.Source
    $outputPath = Join-Path $OutputDirectory $asset.Output

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Missing source image: $sourcePath"
    }

    Export-HudTexture `
        -SourcePath $sourcePath `
        -OutputPath $outputPath `
        -Width $asset.Width `
        -Height $asset.Height `
        -Padding $asset.Padding

    Write-Host "Prepared $($asset.Output)"
}
