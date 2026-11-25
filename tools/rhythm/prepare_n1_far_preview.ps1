Add-Type -AssemblyName System.Drawing

$source = 'C:\Users\<user>\.codex\generated_images\01a1e40b-26a9-7290-8573-33c751886b23\exec-74739320-bf58-46ac-a33e-cb73a9afe876.png'
$output = 'assets/rhythm/_preview/rh_bg_n1_far_preview.png'
$inputBitmap = [System.Drawing.Bitmap]::new($source)
$cropHeight = [int][Math]::Round($inputBitmap.Width * 9.0 / 16.0)
$cropTop = [int](($inputBitmap.Height - $cropHeight) / 2)
$bitmap = [System.Drawing.Bitmap]::new(1920, 1080, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.DrawImage($inputBitmap, [System.Drawing.Rectangle]::new(0, 0, 1920, 1080), [System.Drawing.Rectangle]::new(0, $cropTop, $inputBitmap.Width, $cropHeight), [System.Drawing.GraphicsUnit]::Pixel)
$graphics.Dispose()
$inputBitmap.Dispose()

$edgeWidth = 120
for ($y = 0; $y -lt 1080; $y++) {
    $left = $bitmap.GetPixel(0, $y)
    $right = $bitmap.GetPixel(1919, $y)
    $seam = [System.Drawing.Color]::FromArgb([int](($left.R + $right.R) / 2), [int](($left.G + $right.G) / 2), [int](($left.B + $right.B) / 2))
    for ($x = 0; $x -lt $edgeWidth; $x++) {
        $t = $x / [double]$edgeWidth
        $lx = $bitmap.GetPixel($x, $y)
        $rx = $bitmap.GetPixel(1919 - $x, $y)
        $lc = [System.Drawing.Color]::FromArgb([int]($seam.R * (1 - $t) + $lx.R * $t), [int]($seam.G * (1 - $t) + $lx.G * $t), [int]($seam.B * (1 - $t) + $lx.B * $t))
        $rc = [System.Drawing.Color]::FromArgb([int]($seam.R * (1 - $t) + $rx.R * $t), [int]($seam.G * (1 - $t) + $rx.G * $t), [int]($seam.B * (1 - $t) + $rx.B * $t))
        $bitmap.SetPixel($x, $y, $lc)
        $bitmap.SetPixel(1919 - $x, $y, $rc)
    }
}

New-Item -ItemType Directory -Force -Path (Split-Path $output) | Out-Null
$bitmap.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()
$check = [System.Drawing.Bitmap]::new($output)
$maxDelta = 0
for ($y = 0; $y -lt $check.Height; $y++) {
    $l = $check.GetPixel(0, $y)
    $r = $check.GetPixel($check.Width - 1, $y)
    $maxDelta = [Math]::Max($maxDelta, [Math]::Max([Math]::Abs($l.R - $r.R), [Math]::Max([Math]::Abs($l.G - $r.G), [Math]::Abs($l.B - $r.B))))
}
Write-Output "saved=$output size=$($check.Width)x$($check.Height) mode=RGB edge_delta_max=$maxDelta"
$tile = [System.Drawing.Bitmap]::new(5760, 1080, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$tileGraphics = [System.Drawing.Graphics]::FromImage($tile)
for ($i = 0; $i -lt 3; $i++) {
    $tileGraphics.DrawImage($check, $i * 1920, 0)
}
$tileGraphics.Dispose()
$tilePath = 'assets/rhythm/_preview/rh_bg_n1_far_tilecheck.png'
$tile.Save($tilePath, [System.Drawing.Imaging.ImageFormat]::Png)
$tile.Dispose()
Write-Output "tilecheck=$tilePath size=5760x1080"
$check.Dispose()
