# ============================================================
#  APP INSTALLER SCRIPT - Windows 11 Unattended Setup
#  Edit the three lists below, then paste into your autounattend
#  generator's FirstLogon script field (or host and invoke).
# ============================================================

# --- WINGET APPS (add/remove package IDs) -------------------
$WingetApps = @(
    "Malwarebytes.Malwarebytes"
	"LibreWolf.LibreWolf"
    "Microsoft.VisualStudioCode"
    "M2Team.NanaZip"
    "qBittorrent.qBittorrent"
    "Devolutions.UniGetUI"
    "Valve.Steam"
	"Windscribe.Windscribe"
	"KDE.Kdenlive"
	"KDE.KDEConnect"
	"Klocman.BulkCrapUninstaller"
	"VideoLAN.VLC"
	"Microsoft.PowerToys"
	"namazso.OpenHashTab"
	"AppWork.JDownloader"
	"Git.Git"
	"EpicGames.EpicGamesLauncher"
	"HandBrake.HandBrake"
	"WinSCP.WinSCP"
	"Guru3D.Afterburner.Beta"
	"ChemTableSoftware.AutorunOrganizer"
	"File-New-Project.EarTrumpet"
	"RamenSoftware.Windhawk"
)

# --- CHOCOLATEY APPS (add/remove package names) -------------
# Find packages at https://community.chocolatey.org/packages
# Chocolatey will be installed automatically if this list is not empty.
$ChocoApps = @(
    # "firefox"
    # "notepadplusplus"
    # "git"
)

# --- DIRECT DOWNLOAD APPS -----------------------------------
# Two formats supported:
#   URL:    @{ Name="AppName"; Url="https://..."; Args="/S" }
#   GitHub: @{ Name="AppName"; GitHub="owner/repo"; Asset="*.exe"; Args="/VERYSILENT" }
#
# Args = silent install flags for the installer.
# For .msi files, Args are passed to msiexec (e.g., "INSTALL_DIR=C:\App").
$DirectApps = @(
    # @{ Name="ExampleApp";  Url="https://example.com/setup.exe"; Args="/S" }
    # @{ Name="CoolTool";    GitHub="owner/repo"; Asset="*x64*.exe"; Args="/VERYSILENT" }
)

# ============================================================
#  DO NOT EDIT BELOW unless you know what you're doing
# ============================================================

$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Write-Status {
    param([string]$App, [string]$Status, [ConsoleColor]$Color = 'White')
    Write-Host "  [$Status] " -ForegroundColor $Color -NoNewline
    Write-Host $App
}

# --- Wait for winget to become available ---------------------
function Wait-ForWinget {
    Write-Host "`nWaiting for winget to be ready..." -ForegroundColor Cyan
    $attempts = 0
    $maxAttempts = 12
    while ($attempts -lt $maxAttempts) {
        try {
            $null = Get-Command winget -ErrorAction Stop
            Write-Host "winget is ready.`n" -ForegroundColor Green

            # Accept source agreements and refresh package data
            winget source update --accept-source-agreements 2>&1 | Out-Null
            return $true
        }
        catch {
            $attempts++
            Write-Host "  winget not available yet, retrying in 5s ($attempts/$maxAttempts)..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
    Write-Host "winget did not become available after 60s." -ForegroundColor Red
    return $false
}

# --- Install winget apps -------------------------------------
function Install-WingetApps {
    if ($WingetApps.Count -eq 0) { return }

    Write-Host "=== Installing Winget Apps ===" -ForegroundColor Cyan
    $wingetReady = Wait-ForWinget
    if (-not $wingetReady) {
        foreach ($id in $WingetApps) {
            $Results.Add([PSCustomObject]@{ Name = $id; Method = "winget"; Status = "FAILED"; Detail = "winget unavailable" })
        }
        return
    }

    for ($i = 0; $i -lt $WingetApps.Count; $i++) {
        $id = $WingetApps[$i]
        $num = $i + 1
        Write-Host "`n[$num/$($WingetApps.Count)] Installing $id..." -ForegroundColor White

        $process = Start-Process -FilePath "winget" -ArgumentList @(
            "install", "--exact", "--id", $id,
            "--accept-package-agreements", "--accept-source-agreements",
            "--silent"
        ) -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Status $id "OK" Green
            $Results.Add([PSCustomObject]@{ Name = $id; Method = "winget"; Status = "OK"; Detail = "" })
        }
        else {
            Write-Status $id "FAILED (exit $($process.ExitCode))" Red
            $Results.Add([PSCustomObject]@{ Name = $id; Method = "winget"; Status = "FAILED"; Detail = "exit $($process.ExitCode)" })
        }
    }
}

# --- Install Chocolatey and choco apps -----------------------
function Install-Chocolatey {
    Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh PATH so choco is available immediately
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        $null = Get-Command choco -ErrorAction Stop
        Write-Host "Chocolatey installed successfully.`n" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to install Chocolatey: $_" -ForegroundColor Red
        return $false
    }
}

function Install-ChocoApps {
    if ($ChocoApps.Count -eq 0) { return }

    Write-Host "=== Installing Chocolatey Apps ===" -ForegroundColor Cyan

    # Check if choco is already installed, if not install it
    $chocoReady = $false
    try {
        $null = Get-Command choco -ErrorAction Stop
        $chocoReady = $true
    }
    catch {
        $chocoReady = Install-Chocolatey
    }

    if (-not $chocoReady) {
        foreach ($pkg in $ChocoApps) {
            $Results.Add([PSCustomObject]@{ Name = $pkg; Method = "choco"; Status = "FAILED"; Detail = "chocolatey unavailable" })
        }
        return
    }

    for ($i = 0; $i -lt $ChocoApps.Count; $i++) {
        $pkg = $ChocoApps[$i]
        $num = $i + 1
        Write-Host "`n[$num/$($ChocoApps.Count)] Installing $pkg..." -ForegroundColor White

        $process = Start-Process -FilePath "choco" -ArgumentList @(
            "install", $pkg, "-y", "--no-progress"
        ) -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Status $pkg "OK" Green
            $Results.Add([PSCustomObject]@{ Name = $pkg; Method = "choco"; Status = "OK"; Detail = "" })
        }
        else {
            Write-Status $pkg "FAILED (exit $($process.ExitCode))" Red
            $Results.Add([PSCustomObject]@{ Name = $pkg; Method = "choco"; Status = "FAILED"; Detail = "exit $($process.ExitCode)" })
        }
    }
}

# --- Resolve GitHub latest release asset URL -----------------
function Get-GitHubReleaseUrl {
    param([string]$Repo, [string]$AssetPattern)
    try {
        $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        $asset = $release.assets | Where-Object { $_.name -like $AssetPattern } | Select-Object -First 1
        if ($asset) {
            Write-Host "  Found: $($asset.name)" -ForegroundColor Gray
            return $asset.browser_download_url
        }
        Write-Host "  No asset matching '$AssetPattern'" -ForegroundColor Red
        return $null
    }
    catch {
        Write-Host "  GitHub API error: $_" -ForegroundColor Red
        return $null
    }
}

# --- Install direct-download apps ----------------------------
function Install-DirectApps {
    if ($DirectApps.Count -eq 0) { return }

    Write-Host "`n=== Installing Direct-Download Apps ===" -ForegroundColor Cyan

    for ($i = 0; $i -lt $DirectApps.Count; $i++) {
        $app = $DirectApps[$i]
        $num = $i + 1
        $name = $app.Name
        Write-Host "`n[$num/$($DirectApps.Count)] Installing $name..." -ForegroundColor White

        $downloadUrl = $null
        $method = "direct"

        # Resolve download URL
        if ($app.GitHub) {
            $method = "GitHub"
            $downloadUrl = Get-GitHubReleaseUrl -Repo $app.GitHub -AssetPattern $app.Asset
            if (-not $downloadUrl) {
                Write-Status $name "FAILED - could not resolve GitHub release" Red
                $Results.Add([PSCustomObject]@{ Name = $name; Method = $method; Status = "FAILED"; Detail = "no matching asset or API error" })
                continue
            }
        }
        elseif ($app.Url) {
            $method = "URL"
            $downloadUrl = $app.Url
        }
        else {
            Write-Status $name "FAILED - no Url or GitHub specified" Red
            $Results.Add([PSCustomObject]@{ Name = $name; Method = $method; Status = "FAILED"; Detail = "no source" })
            continue
        }

        # Download
        $fileName = [System.IO.Path]::GetFileName(([Uri]$downloadUrl).LocalPath)
        $filePath = Join-Path $env:TEMP $fileName

        try {
            Write-Host "  Downloading $fileName..." -ForegroundColor Gray
            Invoke-WebRequest -Uri $downloadUrl -OutFile $filePath -UseBasicParsing -ErrorAction Stop
        }
        catch {
            Write-Status $name "FAILED - download error: $_" Red
            $Results.Add([PSCustomObject]@{ Name = $name; Method = $method; Status = "FAILED"; Detail = "download failed" })
            continue
        }

        # Install based on file extension
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()

        try {
            switch ($ext) {
                ".msi" {
                    $msiArgs = "/i `"$filePath`" /qn $($app.Args)"
                    $process = Start-Process -FilePath "msiexec" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
                }
                { $_ -in ".msix", ".msixbundle", ".appx", ".appxbundle" } {
                    Add-AppxPackage -Path $filePath -ErrorAction Stop
                    $process = $null
                }
                default {
                    $process = Start-Process -FilePath $filePath -ArgumentList $app.Args -Wait -PassThru -NoNewWindow
                }
            }

            if ($null -eq $process -or $process.ExitCode -eq 0) {
                Write-Status $name "OK" Green
                $Results.Add([PSCustomObject]@{ Name = $name; Method = $method; Status = "OK"; Detail = "" })
            }
            else {
                Write-Status $name "FAILED (exit $($process.ExitCode))" Red
                $Results.Add([PSCustomObject]@{ Name = $name; Method = $method; Status = "FAILED"; Detail = "exit $($process.ExitCode)" })
            }
        }
        catch {
            Write-Status $name "FAILED - install error: $_" Red
            $Results.Add([PSCustomObject]@{ Name = $name; Method = $method; Status = "FAILED"; Detail = $_.ToString() })
        }
        finally {
            Remove-Item $filePath -Force -ErrorAction SilentlyContinue
        }
    }
}

# --- Main ----------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  App Installer - Windows Unattended"     -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Install-WingetApps
Install-ChocoApps
Install-DirectApps

# --- Summary --------------------------------------------------
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Installation Summary"                     -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$succeeded = ($Results | Where-Object { $_.Status -eq "OK" }).Count
$failed    = ($Results | Where-Object { $_.Status -eq "FAILED" }).Count

$Results | Format-Table -Property Name, Method, Status, Detail -AutoSize

Write-Host "Succeeded: $succeeded  |  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Yellow" } else { "Green" })
Write-Host ""
Read-Host "Press Enter to close"
