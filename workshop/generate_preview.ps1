param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "TeamPingHud-preview.png")
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$bitmap = New-Object System.Drawing.Bitmap 512, 512
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$background = [System.Drawing.ColorTranslator]::FromHtml("#09070f")
$panel = [System.Drawing.ColorTranslator]::FromHtml("#171021")
$cyan = [System.Drawing.ColorTranslator]::FromHtml("#40d1ed")
$yellow = [System.Drawing.ColorTranslator]::FromHtml("#f4c93f")
$white = [System.Drawing.ColorTranslator]::FromHtml("#f1edf5")
$muted = [System.Drawing.ColorTranslator]::FromHtml("#a89bb5")

$graphics.Clear($background)
$panelBrush = New-Object System.Drawing.SolidBrush $panel
$graphics.FillRectangle($panelBrush, 28, 28, 456, 456)

$cyanPen = New-Object System.Drawing.Pen $cyan, 14
$cyanPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Square
$cyanPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Square
$graphics.DrawLines($cyanPen, [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point 80, 175),
    (New-Object System.Drawing.Point 154, 256),
    (New-Object System.Drawing.Point 80, 337)
))

$yellowPen = New-Object System.Drawing.Pen $yellow, 12
$yellowPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Miter
$graphics.DrawPolygon($yellowPen, [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point 384, 190),
    (New-Object System.Drawing.Point 450, 256),
    (New-Object System.Drawing.Point 384, 322),
    (New-Object System.Drawing.Point 318, 256)
))

$titleFont = New-Object System.Drawing.Font "Segoe UI", 46, ([System.Drawing.FontStyle]::Bold)
$subtitleFont = New-Object System.Drawing.Font "Segoe UI", 15, ([System.Drawing.FontStyle]::Bold)
$smallFont = New-Object System.Drawing.Font "Segoe UI", 12, ([System.Drawing.FontStyle]::Regular)
$whiteBrush = New-Object System.Drawing.SolidBrush $white
$mutedBrush = New-Object System.Drawing.SolidBrush $muted
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center

$graphics.DrawString("TEAM PING", $titleFont, $whiteBrush, (New-Object System.Drawing.RectangleF 0, 58, 512, 62), $format)
$graphics.DrawString("HUD", $titleFont, $whiteBrush, (New-Object System.Drawing.RectangleF 0, 112, 512, 62), $format)
$graphics.DrawString("DOME KEEPER CO-OP MOD", $subtitleFont, $mutedBrush, (New-Object System.Drawing.RectangleF 0, 366, 512, 30), $format)
$graphics.DrawString("TEAMMATES  |  PINGS  |  SPLIT SCREEN", $smallFont, $mutedBrush, (New-Object System.Drawing.RectangleF 0, 431, 512, 26), $format)

$bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$format.Dispose()
$mutedBrush.Dispose()
$whiteBrush.Dispose()
$smallFont.Dispose()
$subtitleFont.Dispose()
$titleFont.Dispose()
$yellowPen.Dispose()
$cyanPen.Dispose()
$panelBrush.Dispose()
$graphics.Dispose()
$bitmap.Dispose()

Write-Host "Generated: $OutputPath"
