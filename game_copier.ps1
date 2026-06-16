<#
.SYNOPSIS
    Roblox Game Copier - Downloads Roblox games as .rbxm files using .ROBLOSECURITY cookie.
.DESCRIPTION
    Uses PowerShell to authenticate with Roblox and download game place files.
#>

$ErrorActionPreference = "Stop"

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

function Get-XCSRFToken {
    param($WebSession)
    $r = Invoke-WebRequest -Uri "https://auth.roblox.com/v2/logout" `
        -Method POST -WebSession $WebSession -UseBasicParsing -SkipHttpErrorCheck
    return $r.Headers["x-csrf-token"]
}

function Invoke-RobloxAPI {
    param($Uri, $WebSession, $Method = "GET", $Body = $null)
    $headers = @{}
    $tries = 0
    do {
        $tries++
        try {
            $params = @{
                Uri = $Uri
                Method = $Method
                WebSession = $WebSession
                UseBasicParsing = $true
                SkipHttpErrorCheck = $true
                ContentType = "application/json"
            }
            if ($Method -eq "POST" -and $Body) {
                $params.Body = ($Body | ConvertTo-Json -Compress)
            }
            $r = Invoke-WebRequest @params
            if ($r.StatusCode -eq 200) {
                return ($r.Content | ConvertFrom-Json)
            }
            if ($r.StatusCode -eq 403) {
                $token = Get-XCSRFToken -WebSession $WebSession
                if ($token) {
                    $WebSession.Headers["x-csrf-token"] = $token
                    continue
                }
            }
            return $null
        } catch {
            if ($tries -ge 2) { return $null }
            Start-Sleep -Milliseconds 200
        }
    } while ($tries -lt 2)
}

function Login-Roblox {
    param($CookieValue, $WebSession)
    $cookie = New-Object System.Net.Cookie(".ROBLOSECURITY", $CookieValue, "/", ".roblox.com")
    $WebSession.Cookies.Add($cookie)

    $r = Invoke-WebRequest -Uri "https://users.roblox.com/v1/users/authenticated" `
        -WebSession $WebSession -UseBasicParsing -SkipHttpErrorCheck
    if ($r.StatusCode -eq 200) {
        $data = $r.Content | ConvertFrom-Json
        Write-Host "Logged in as: $($data.name) (ID: $($data.id))" -ForegroundColor Green
        $token = Get-XCSRFToken -WebSession $WebSession
        if ($token) {
            $WebSession.Headers["x-csrf-token"] = $token
        }
        return $true
    }
    Write-Host "Login failed (HTTP $($r.StatusCode))" -ForegroundColor Red
    return $false
}

function Main {
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "      ROBLOX GAME COPIER (rbxm)" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan

    # === COOKIE ===
    Write-Host "`n[1] .ROBLOSECURITY cookie:" -ForegroundColor Yellow
    Write-Host "    (Get it from Chrome > F12 > Application > Cookies > .roblox.com)" -ForegroundColor DarkGray
    $cookie = Read-Host "    Paste cookie here"

    if ([string]::IsNullOrWhiteSpace($cookie)) {
        Write-Host "No cookie provided." -ForegroundColor Red
        exit 1
    }

    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    if (-not (Login-Roblox -CookieValue $cookie -WebSession $session)) {
        exit 1
    }

    # === GAME ID ===
    Write-Host "`n[2] Game / Place / Universe ID:" -ForegroundColor Yellow
    Write-Host "    (Get from URL: roblox.com/games/1234567/Game-Name)" -ForegroundColor DarkGray
    $raw = Read-Host "    Enter ID"
    $raw = $raw.Trim()
    if ($raw -notmatch '^\d+$') {
        Write-Host "Invalid ID (must be numbers only)." -ForegroundColor Red
        exit 1
    }
    $gid = [long]$raw

    # === RESOLVE ===
    Write-Host "`n[*] Resolving ID: $gid" -ForegroundColor Cyan
    $placeId = $null
    $universeId = $null

    $d = Invoke-RobloxAPI -Uri "https://apis.roblox.com/universes/v1/places/$gid" -WebSession $session
    if ($d -and $d.universeId) {
        $placeId = $gid
        $universeId = $d.universeId
        Write-Host "  Place ID: $placeId -> Universe ID: $universeId" -ForegroundColor Green
    } else {
        $d = Invoke-RobloxAPI -Uri "https://games.roblox.com/v1/games?universeIds=$gid" -WebSession $session
        if ($d -and $d.data -and $d.data.Count -gt 0) {
            $universeId = $gid
            $placeId = $d.data[0].rootPlaceId
            Write-Host "  Universe ID: $universeId -> Root Place ID: $placeId" -ForegroundColor Green
        }
    }

    if (-not $placeId) {
        Write-Host "Could not resolve game ID." -ForegroundColor Red
        exit 1
    }

    # === FETCH DETAILS ===
    Write-Host "`n[*] Fetching game info..." -ForegroundColor Cyan
    $game = Invoke-RobloxAPI -Uri "https://games.roblox.com/v1/games?universeIds=$universeId" -WebSession $session
    $details = Invoke-RobloxAPI -Uri "https://games.roblox.com/v1/games/multiget-place-details?placeIds=$placeId" -WebSession $session

    $name = "Unknown"
    $copying = $false
    $creator = ""

    if ($game -and $game.data -and $game.data.Count -gt 0) {
        $gd = $game.data[0]
        if ($gd.name) { $name = $gd.name }
        if ($gd.creator -and $gd.creator.name) { $creator = $gd.creator.name }
        if ($gd.copyingAllowed -eq $true) { $copying = $true }
    }

    if ($details -and $details.Count -gt 0) {
        if ($details[0].isCopyable -eq $true) { $copying = $true }
        if ($details[0].isCopyable -eq $false) { $copying = $false }
        if ($details[0].name) { $name = $details[0].name }
        if ($details[0].creatorName) { $creator = $details[0].creatorName }
    }

    # === SAVE INFO ===
    $sname = ($name -replace '[^\w\s\-\.]', '_').Trim()
    $odir = "Roblox_${sname}_${placeId}"
    New-Item -ItemType Directory -Path $odir -Force | Out-Null

    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss UTC")
    $txt = @"
Game: $name
Place ID: $placeId
Universe ID: $universeId
Creator: $creator
Copying Allowed: $copying
Fetched: $timestamp
"@

    $txt | Out-File -FilePath "$odir\game_info.txt" -Encoding utf8
    Write-Host "[*] Saved info to: $odir\game_info.txt" -ForegroundColor Cyan

    # === DOWNLOAD .rbxm ===
    if ($copying) {
        Write-Host "`n[*] Downloading $placeId as .rbxm..." -ForegroundColor Yellow
        $url = "https://assetdelivery.roblox.com/v1/asset?id=$placeId"
        try {
            $r = Invoke-WebRequest -Uri $url -WebSession $session -UseBasicParsing `
                -SkipHttpCheckError -OutFile "$odir\$sname`_$placeId.rbxm"
            if ($?) {
                $size = (Get-Item "$odir\$sname`_$placeId.rbxm").Length
                Write-Host "  Saved: $odir\$sname`_$placeId.rbxm ($(Format-Bytes $size))" -ForegroundColor Green
            }
        } catch {
            Write-Host "  Download failed: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "`n  Copying not allowed for this game. Info saved only." -ForegroundColor DarkYellow
    }

    Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
    Write-Host "  DONE - output in: $odir" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Cyan
}

try {
    Main
} catch {
    Write-Host "`nError: $_" -ForegroundColor Red
    exit 1
}