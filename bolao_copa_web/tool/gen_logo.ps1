$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path "$PSScriptRoot\..\assets\branding" | Out-Null
Add-Type -AssemblyName System.Drawing
$path = Join-Path $PSScriptRoot '..\assets\branding\logo.png'
$bmp = New-Object System.Drawing.Bitmap 128, 128
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 27, 127, 58))
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush `
  ([System.Drawing.Rectangle]::new(0, 0, 128, 128)), `
  ([System.Drawing.Color]::FromArgb(255, 34, 139, 58)), `
  ([System.Drawing.Color]::FromArgb(255, 15, 90, 35)), 45
$g.FillEllipse($brush, 8, 8, 112, 112)
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$font = [System.Drawing.Font]::new('Segoe UI', 36, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$format.LineAlignment = [System.Drawing.StringAlignment]::Center
$g.DrawString('B', $font, $white, [System.Drawing.RectangleF]::new(0, 0, 128, 128), $format)
$g.Dispose()
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Wrote $path"
