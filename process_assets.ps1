Add-Type -AssemblyName System.Drawing

$src = "C:\Users\andre\Desktop\Cross Word Puzzle"
$out = "C:\Users\andre\Desktop\LPK APPS WEBSITE\assets"
New-Item -ItemType Directory -Force "$out" | Out-Null
New-Item -ItemType Directory -Force "$out\plants" | Out-Null
New-Item -ItemType Directory -Force "$out\rooty" | Out-Null
New-Item -ItemType Directory -Force "$out\shots" | Out-Null

function Resize-Png($inPath, $outPath, $maxDim) {
    $img = [System.Drawing.Image]::FromFile($inPath)
    $scale = [Math]::Min($maxDim / $img.Width, $maxDim / $img.Height)
    if ($scale -gt 1) { $scale = 1 }
    $w = [int]($img.Width * $scale); $h = [int]($img.Height * $scale)
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($img, 0, 0, $w, $h)
    $g.Dispose()
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose(); $img.Dispose()
    Write-Output ("{0} -> {1}x{2} ({3} KB)" -f (Split-Path $outPath -Leaf), $w, $h, [int]((Get-Item $outPath).Length/1KB))
}

function Save-Jpeg($inPath, $outPath, $targetW, $quality) {
    $img = [System.Drawing.Image]::FromFile($inPath)
    $scale = $targetW / $img.Width
    if ($scale -gt 1) { $scale = 1 }
    $w = [int]($img.Width * $scale); $h = [int]($img.Height * $scale)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($img, 0, 0, $w, $h)
    $g.Dispose()
    $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)
    $bmp.Save($outPath, $enc, $ep)
    $bmp.Dispose(); $img.Dispose()
    Write-Output ("{0} -> {1}x{2} ({3} KB)" -f (Split-Path $outPath -Leaf), $w, $h, [int]((Get-Item $outPath).Length/1KB))
}

function Crop-Resize-Png($inPath, $outPath, $cx, $cy, $cw, $ch, $targetW) {
    $img = [System.Drawing.Image]::FromFile($inPath)
    $scale = $targetW / $cw
    $w = [int]($cw * $scale); $h = [int]($ch * $scale)
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $destRect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $srcRect = New-Object System.Drawing.Rectangle($cx, $cy, $cw, $ch)
    $g.DrawImage($img, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose(); $img.Dispose()
    Write-Output ("{0} -> {1}x{2} ({3} KB)" -f (Split-Path $outPath -Leaf), $w, $h, [int]((Get-Item $outPath).Length/1KB))
}

# 1) App icon
Resize-Png "$src\LOGO\applogo_2.png" "$out\rootword-icon.png" 512

# 2) Rooty poses - crop quadrants from 1536x1024 sheet, inside panel borders
$sheet = "$src\IN-GAME CHARACTERS\name_changed_to_rooty.png"
Crop-Resize-Png $sheet "$out\rooty\welcome.png"     48  78 672 400 560
Crop-Resize-Png $sheet "$out\rooty\thinking.png"   816  78 672 400 560
Crop-Resize-Png $sheet "$out\rooty\excited.png"     48 590 672 400 560
Crop-Resize-Png $sheet "$out\rooty\celebrating.png" 816 590 672 400 560

# 3) Screenshots -> JPEG width 480
foreach ($n in 1..7) {
    $name = "{0:d2}" -f $n
    Save-Jpeg "$src\appstore_listing\polished\iphone\$name.png" "$out\shots\$name.jpg" 480 88
}

# 4) Plants -> PNG max 340
$plants = @("Moonblossom","Embercrown","Dawnpetal","Dewclover","Glowmoss","Cinderleaf","Starweald","Mythicroot","Frostbark","Whisperbirch","Velvetspire","Duskfern")
foreach ($p in $plants) {
    Resize-Png "$src\assets\plant-gallery-plant-images\$p.png" "$out\plants\$($p.ToLower()).png" 340
}

# 5) Sample screenshot background color
$bmpS = New-Object System.Drawing.Bitmap("$src\appstore_listing\polished\iphone\01.png")
$px = $bmpS.GetPixel(20, 20)
Write-Output ("Screenshot bg color: #{0:x2}{1:x2}{2:x2}" -f $px.R, $px.G, $px.B)
$px2 = $bmpS.GetPixel(660, 100)
Write-Output ("Screenshot bg color (top center): #{0:x2}{1:x2}{2:x2}" -f $px2.R, $px2.G, $px2.B)
$bmpS.Dispose()
