<#
.SYNOPSIS
    Downloads ANY Roblox game as .rbxm using full browser session cookies.
    Forces download regardless of copy permissions.
#>

$ErrorActionPreference = "Continue"

Write-Host "Setting up session..." -ForegroundColor Cyan

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36"

function Add-Cookie($n, $v) {
    try { $session.Cookies.Add((New-Object System.Net.Cookie($n, $v, "/", ".roblox.com"))) } catch {}
}
Add-Cookie "GuestData" "UserID=-506171368"
Add-Cookie "RBXcb" "RBXViralAcquisition%3Dfalse%26RBXSource%3Dfalse%26GoogleAnalytics%3Dfalse"
Add-Cookie "__stripe_mid" "348cd71f-9752-4275-b34f-482364168472076506"
Add-Cookie "_ga" "GA1.2.1392294312.1780346420"
Add-Cookie "_ga_BK4ZY0C59K" "GS2.1.s1781126753`$o3`$g0`$t1781126753`$j60`$l0`$h0"
Add-Cookie ".ROBLOSECURITY" "_|WARNING:-DO-NOT-SHARE-THIS.--Sharing-this-will-allow-someone-to-log-in-as-you-and-to-steal-your-ROBUX-and-items.|_CAEaAhADIhsKBGR1aWQSEzgyMzMwODkxMjk3MTUwOTkyNTIoAw.cdPMYHOtt4fxJ23qKXVO7J64MOaZAKcBaY1XpGZDMY0Zefyd5sYTtziJRmbZUnIomheyUJhzflBqEYblWyDXRx5cRlQQtcVtgvM5EpyB5ss-eEfjqlebNuMv4oDurVyJ0CEhCOaltI15IM0TYFhWRs-VqXSJZAtk1fboiBxyoVqoxqb40P6bIPZv9iBjxApvgAHHywI6h6K1Fzlubyhjx-TCGDA-9uXrTENGQMRuoxU2exrU2QcgV8wyO49S3mlWCIdcO3iPa_PxfQF1UBCeA72jV4A9v2aeUGjQ6jwAKc34m5eDgWd4L52xgxGm_7pr0IOmWZau-fVN6Rqte5a1-qGtS6_NSIYdgWghUvSxEn5kn0KiwIR_S2aQC5yiDF2gjyfgWQDc-4Q_wbfie7kgVy_3hJaJpAZw_q-9BoEGsAEZKGn0UwcG4dlFrLom8AfKAWEBdo068eLjpJ3WKeXrBKFN-eRaTJfcw1KLGZPXKzOpkJE98GGfcmXaWal-t55RzDyDc8Uxpga8suBgzyS0Q2lM8ppGIJ2vi7N7wjfu5AOfBwnBOWU_Sq6Iz80eAc6LhIoP3prxMNnCuVp3N1FkC40JBrlCeI6aPz1NBeAMRw9ujb_22FCcaHTEwQ00JWnt3WQzy9tMAh3bIHYSod0rIBp2IbL_Uq1ciJPWIqg_Vc-O6aZs_oYGwCc7NhjJCr99yjWbqhd3IMloKjY24_pZZnwm_KjAdKvWDU1CSpRfuR7VsA1Ym_EIt4lCv49zf6f0vDiNNtEED7_bpzgER_kLfmfT98Uek1zRRiFIUbBxYcSLXmvWXA163h5Rmkcxd1ox-dir9qWJ5H4QbNaDVYKqPy1lRx2mIjiiDjekcc9SK-pRFyv0FFNw2nRtMp1t0OiOhpzfoEooOe52XsHzgdYTip2srGRfGMyCK7ZS6svED4UtxrhRKNT_NZfCyBrjgK3zXWUT0g"
Add-Cookie "RBXSessionTracker" "sessionid=e0d092f1-3c69-4f2c-b61f-7ad8dbf9e019"
Add-Cookie "RBXEventTrackerV2" "CreateDate=05/31/2026 12:08:32&rbxuid=4401835339&browserid=1780244277165001&rbxid=4393472073"
Add-Cookie "rbx-ip2" "1"
Add-Cookie "UnifiedLoggerSession" "CreatorHub%3D%7B%22sessionId%22%3A%22f3625a5b-d847-4ddb-bcd2-f36122eae696%22%2C%22lastActivity%22%3A1781287341304%7D"
Add-Cookie "rbxas" "2108d528b273b029ad108e494eaedd055dd0cd27232c02ef58a10e02aea9d9e2"

Write-Host "Cookies loaded." -ForegroundColor Green

function Invoke-Request($url, $method="GET", $headers=$null) {
    try {
        $params = @{Uri=$url;Method=$method;WebSession=$session;UseBasicParsing=$true;TimeoutSec=15}
        if ($headers) { $params.Headers = $headers }
        $resp = Invoke-WebRequest @params
        return @{Status=$resp.StatusCode;Content=$resp.Content;Response=$resp}
    } catch {
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
            return @{Status=$status;Content=$null;Error=$_.Exception.Message}
        }
        return @{Status=0;Content=$null;Error=$_.Exception.Message}
    }
}

# Get CSRF token
Write-Host "Getting CSRF token..." -ForegroundColor Cyan
$r = Invoke-Request "https://auth.roblox.com/v2/logout" "POST"
if ($r.Response -and $r.Response.Headers["x-csrf-token"]) {
    $csrf = $r.Response.Headers["x-csrf-token"]
    $session.Headers["x-csrf-token"] = $csrf
    Write-Host "CSRF token obtained." -ForegroundColor Green
}

# Game config
$gameId = "97598239454123"
$gameName = "Grow-a-Garden-2"

# Visit game page
Write-Host "`n[*] Visiting game page..." -ForegroundColor Cyan
$pageHeaders = @{
    "authority"="www.roblox.com"
    "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    "accept-language"="en-US,en;q=0.9"
    "referer"="https://www.roblox.com/home"
    "sec-fetch-dest"="document"
    "sec-fetch-mode"="navigate"
    "sec-fetch-site"="same-origin"
    "sec-fetch-user"="?1"
    "upgrade-insecure-requests"="1"
}
$pageResp = Invoke-Request "https://www.roblox.com/games/$gameId/$gameName" "GET" $pageHeaders
if ($pageResp.Status -eq 200) {
    Write-Host "Game page loaded (HTTP 200)." -ForegroundColor Green
} else {
    Write-Host "Game page: HTTP $($pageResp.Status)" -ForegroundColor DarkYellow
}

# Resolve game ID
Write-Host "`n[*] Resolving game ID: $gameId" -ForegroundColor Cyan
$placeId = $null
$universeId = $null

# Try as Place ID
$resp = Invoke-Request "https://apis.roblox.com/universes/v1/places/$gameId"
if ($resp.Status -eq 200 -and $resp.Content) {
    try {
        $d = $resp.Content | ConvertFrom-Json
        if ($d.universeId) { $placeId = $gameId; $universeId = $d.universeId }
    } catch {}
}

# Try as Universe ID
if (-not $placeId) {
    $resp = Invoke-Request "https://games.roblox.com/v1/games?universeIds=$gameId"
    if ($resp.Status -eq 200 -and $resp.Content) {
        try {
            $d = $resp.Content | ConvertFrom-Json
            if ($d.data -and $d.data.Count -gt 0) { $universeId = $gameId; $placeId = $d.data[0].rootPlaceId }
        } catch {}
    }
}

if (-not $placeId) { $placeId = $gameId }
Write-Host "  Place ID: $placeId | Universe ID: $universeId" -ForegroundColor Green

# Fetch game details for name only
$name = $gameName
if ($universeId) {
    $resp = Invoke-Request "https://games.roblox.com/v1/games?universeIds=$universeId"
    if ($resp.Status -eq 200 -and $resp.Content) {
        try { $gd = ($resp.Content | ConvertFrom-Json).data[0]; if ($gd.name) { $name = $gd.name } } catch {}
    }
}

# Save info
$sname = $name -replace '[^\w\s\-\.]', '_'
$odir = "Roblox_${sname}_${placeId}"
New-Item -ItemType Directory -Path $odir -Force | Out-Null

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss UTC")
$txt = "Game: $name`r`nPlace ID: $placeId`r`nUniverse ID: $universeId`r`nFetched: $timestamp`r`n"
$txt | Out-File -FilePath "$odir\game_info.txt" -Encoding utf8
Write-Host "[*] Saved info to: $odir\game_info.txt" -ForegroundColor Cyan

# === FORCE DOWNLOAD regardless of copy permission ===
Write-Host "`n[*] FORCE DOWNLOADING place file as .rbxm..." -ForegroundColor Yellow

$outputFile = "$odir\${sname}_${placeId}.rbxm"
$downloaded = $false

# Method 1: Standard asset delivery
$urls = @(
    "https://assetdelivery.roblox.com/v1/asset?id=$placeId",
    "https://assetdelivery.roblox.com/v1/asset/?id=$placeId"
)

foreach ($url in $urls) {
    if ($downloaded) { break }
    Write-Host "  Trying Method 1 (asset delivery): $url" -ForegroundColor DarkGray
    try {
        Invoke-WebRequest -Uri $url -WebSession $session -UseBasicParsing -OutFile $outputFile -TimeoutSec 60
        if ((Get-Item $outputFile).Length -gt 100) {
            $size = (Get-Item $outputFile).Length
            Write-Host "  SUCCESS: $(Format-Bytes $size)" -ForegroundColor Green
            $downloaded = $true
        }
    } catch {
        try { Remove-Item $outputFile -Force -ErrorAction SilentlyContinue } catch {}
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# Method 2: OpenCloud asset delivery v2
if (-not $downloaded) {
    $url = "https://apis.roblox.com/assets/v1/assets/$placeId/download"
    Write-Host "  Trying Method 2 (OpenCloud): $url" -ForegroundColor DarkGray
    try {
        $headers = @{"accept"="application/octet-stream"}
        $resp = Invoke-WebRequest -Uri $url -WebSession $session -UseBasicParsing -Headers $headers -OutFile $outputFile -TimeoutSec 60 -SkipCertificateCheck 2>$null
        if ((Get-Item $outputFile).Length -gt 100) {
            $size = (Get-Item $outputFile).Length; Write-Host "  SUCCESS: $(Format-Bytes $size)" -ForegroundColor Green; $downloaded = $true
        }
    } catch {
        try { Remove-Item $outputFile -Force -ErrorAction SilentlyContinue } catch {}
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# Method 3: Roblox Studio protocol / raw HTTP with referer
if (-not $downloaded) {
    $url = "https://assetdelivery.roblox.com/v1/asset?id=$placeId"
    Write-Host "  Trying Method 3 (with referer): $url" -ForegroundColor DarkGray
    try {
        $headers = @{"referer"="https://www.roblox.com/games/$placeId/"}
        Invoke-WebRequest -Uri $url -WebSession $session -UseBasicParsing -Headers $headers -OutFile $outputFile -TimeoutSec 60
        if ((Get-Item $outputFile).Length -gt 100) {
            $size = (Get-Item $outputFile).Length; Write-Host "  SUCCESS: $(Format-Bytes $size)" -ForegroundColor Green; $downloaded = $true
        }
    } catch {
        try { Remove-Item $outputFile -Force -ErrorAction SilentlyContinue } catch {}
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# Method 4: Studio API
if (-not $downloaded) {
    $url = "https://www.roblox.com/studio/plugins/download/$placeId"
    Write-Host "  Trying Method 4 (Studio API): $url" -ForegroundColor DarkGray
    try {
        $headers = @{"referer"="https://create.roblox.com/"}
        Invoke-WebRequest -Uri $url -WebSession $session -UseBasicParsing -Headers $headers -OutFile $outputFile -TimeoutSec 60
        if ((Get-Item $outputFile).Length -gt 100) {
            $size = (Get-Item $outputFile).Length; Write-Host "  SUCCESS: $(Format-Bytes $size)" -ForegroundColor Green; $downloaded = $true
        }
    } catch {
        try { Remove-Item $outputFile -Force -ErrorAction SilentlyContinue } catch {}
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# Method 5: Raw download via game URL scraping
if (-not $downloaded) {
    $url = "https://www.roblox.com/games/$placeId/Download"
    Write-Host "  Trying Method 5 (game download): $url" -ForegroundColor DarkGray
    try {
        Invoke-WebRequest -Uri $url -WebSession $session -UseBasicParsing -OutFile $outputFile -TimeoutSec 60
        if ((Get-Item $outputFile).Length -gt 100) {
            $size = (Get-Item $outputFile).Length; Write-Host "  SUCCESS: $(Format-Bytes $size)" -ForegroundColor Green; $downloaded = $true
        }
    } catch {
        try { Remove-Item $outputFile -Force -ErrorAction SilentlyContinue } catch {}
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

if ($downloaded) {
    Write-Host "`n[*] File saved as: $outputFile" -ForegroundColor Green
} else {
    Write-Host "`n[!] All download methods failed." -ForegroundColor Red
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  DONE - output in: $odir" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

function Format-Bytes {
    param([long]$Bytes)
    $units = @("B","KB","MB","GB")
    $val = [double]$Bytes
    foreach ($u in $units) {
        if ($val -lt 1024) { return "{0:N2} $u" -f $val }
        $val /= 1024
    }
    return "{0:N2} TB" -f $val
}