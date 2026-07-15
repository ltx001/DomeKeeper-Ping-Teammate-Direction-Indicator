param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "Ping-Teammate-Direction-Indicator-preview.png")
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$bitmap = New-Object System.Drawing.Bitmap 512, 512
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$background = [System.Drawing.ColorTranslator]::FromHtml("#09070f")
$panel = [System.Drawing.ColorTranslator]::FromHtml("#15101c")
$border = [System.Drawing.ColorTranslator]::FromHtml("#392a43")
$cyan = [System.Drawing.ColorTranslator]::FromHtml("#40d1ed")
$yellow = [System.Drawing.ColorTranslator]::FromHtml("#f4c93f")
$white = [System.Drawing.ColorTranslator]::FromHtml("#f1edf5")
$muted = [System.Drawing.ColorTranslator]::FromHtml("#a89bb5")

$graphics.Clear($background)
$panelBrush = New-Object System.Drawing.SolidBrush $panel
$borderPen = New-Object System.Drawing.Pen $border, 4
$graphics.FillRectangle($panelBrush, 24, 24, 464, 464)
$graphics.DrawRectangle($borderPen, 24, 24, 463, 463)

$cyanPen = New-Object System.Drawing.Pen $cyan, 12
$cyanPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Square
$cyanPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Square
$graphics.DrawLines($cyanPen, [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point 70, 310),
    (New-Object System.Drawing.Point 124, 360),
    (New-Object System.Drawing.Point 70, 410)
))

$yellowPen = New-Object System.Drawing.Pen $yellow, 10
$yellowPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Miter
$graphics.DrawPolygon($yellowPen, [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point 404, 310),
    (New-Object System.Drawing.Point 454, 360),
    (New-Object System.Drawing.Point 404, 410),
    (New-Object System.Drawing.Point 354, 360)
))

$linePen = New-Object System.Drawing.Pen $border, 4
$linePen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
$graphics.DrawLine($linePen, 151, 360, 327, 360)

$titleFont = New-Object System.Drawing.Font "Segoe UI", 33, ([System.Drawing.FontStyle]::Bold)
$directionFont = New-Object System.Drawing.Font "Segoe UI", 35, ([System.Drawing.FontStyle]::Bold)
$labelFont = New-Object System.Drawing.Font "Segoe UI", 15, ([System.Drawing.FontStyle]::Bold)
$smallFont = New-Object System.Drawing.Font "Segoe UI", 13, ([System.Drawing.FontStyle]::Regular)
$whiteBrush = New-Object System.Drawing.SolidBrush $white
$mutedBrush = New-Object System.Drawing.SolidBrush $muted
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center

$graphics.DrawString("DOME KEEPER CO-OP MOD", $labelFont, $mutedBrush, (New-Object System.Drawing.RectangleF 0, 58, 512, 28), $format)
$graphics.DrawString("PING & TEAMMATE", $titleFont, $whiteBrush, (New-Object System.Drawing.RectangleF 0, 105, 512, 62), $format)
$graphics.DrawString("DIRECTION", $directionFont, $whiteBrush, (New-Object System.Drawing.RectangleF 0, 168, 512, 52), $format)
$graphics.DrawString("INDICATOR", $directionFont, $whiteBrush, (New-Object System.Drawing.RectangleF 0, 216, 512, 52), $format)
$graphics.DrawString("TEAMMATES  |  PINGS  |  SPLIT-SCREEN", $smallFont, $mutedBrush, (New-Object System.Drawing.RectangleF 0, 440, 512, 24), $format)

$bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$format.Dispose()
$mutedBrush.Dispose()
$whiteBrush.Dispose()
$smallFont.Dispose()
$labelFont.Dispose()
$directionFont.Dispose()
$titleFont.Dispose()
$linePen.Dispose()
$yellowPen.Dispose()
$cyanPen.Dispose()
$borderPen.Dispose()
$panelBrush.Dispose()
$graphics.Dispose()
$bitmap.Dispose()

Write-Host "Generated: $OutputPath"
