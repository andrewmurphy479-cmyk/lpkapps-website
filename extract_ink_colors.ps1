[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Drawing

$picks = @("Trillion","Emerald","Princess","Fyrestrike","Lyra","Dreamfyre","Seasmoke","Electric Eel","Yellow Tang","Moonrise Pink Tetra","Rosie - Freedom Glitter x WC Inks","Microchip - Freedom Glitter x WC Inks","Candy Apple Red","Mermaid Sapphire","Champagne Toast","Gold Rush")

$r = Invoke-RestMethod -Uri "https://www.wcinks.com/products.json?limit=250" -UseBasicParsing
$tmp = "$env:TEMP\wcinks_imgs"
New-Item -ItemType Directory -Force $tmp | Out-Null

function Get-DominantColors($path) {
    $src = [System.Drawing.Image]::FromFile($path)
    $bmp = New-Object System.Drawing.Bitmap(72, 72)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($src, 0, 0, 72, 72)
    $g.Dispose(); $src.Dispose()

    # hue histogram over saturated, mid-brightness pixels
    $bins = @{}
    for ($x = 0; $x -lt 72; $x++) {
        for ($y = 0; $y -lt 72; $y++) {
            $px = $bmp.GetPixel($x, $y)
            $mx = [Math]::Max($px.R, [Math]::Max($px.G, $px.B)) / 255.0
            $mn = [Math]::Min($px.R, [Math]::Min($px.G, $px.B)) / 255.0
            if ($mx -lt 0.12 -or $mx -gt 0.97) { continue }
            $sat = if ($mx -eq 0) { 0 } else { ($mx - $mn) / $mx }
            if ($sat -lt 0.3) { continue }
            $hue = [int]($px.GetHue() / 15) # 24 bins
            if (-not $bins.ContainsKey($hue)) { $bins[$hue] = @(0, 0, 0, 0) }
            $v = $bins[$hue]
            $bins[$hue] = @(($v[0] + 1), ($v[1] + [int]$px.R), ($v[2] + [int]$px.G), ($v[3] + [int]$px.B))
        }
    }
    $bmp.Dispose()
    $top = $bins.GetEnumerator() | Sort-Object { -$_.Value[0] } | Select-Object -First 2
    $cols = foreach ($t in $top) {
        $v = $t.Value
        "#{0:x2}{1:x2}{2:x2}" -f [int]($v[1] / $v[0]), [int]($v[2] / $v[0]), [int]($v[3] / $v[0])
    }
    ($cols -join ' ') + " (px: " + (($top | ForEach-Object { $_.Value[0] }) -join '/') + ")"
}

foreach ($name in $picks) {
    $p = $r.products | Where-Object { $_.title -eq $name } | Select-Object -First 1
    if (-not $p) { "$name : NOT FOUND"; continue }
    $imgUrl = $p.images[0].src
    $file = "$tmp\" + ($p.handle) + ".jpg"
    if (-not (Test-Path $file)) { Invoke-WebRequest -Uri $imgUrl -OutFile $file -UseBasicParsing }
    "{0} : {1} | img: {2}" -f $name, (Get-DominantColors $file), (Split-Path $imgUrl -Leaf)
}
