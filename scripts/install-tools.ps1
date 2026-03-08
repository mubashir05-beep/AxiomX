# Manual Tool Installation Script (No Chocolatey Required)
# This script downloads and installs Kind and Helm directly

Write-Host "`n=== Installing Kubernetes Tools ===" -ForegroundColor Cyan

$installDir = "$env:USERPROFILE\bin"
$env:PATH += ";$installDir"

# Create bin directory if it doesn't exist
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
    Write-Host "[OK] Created $installDir" -ForegroundColor Green
}

# Install Kind
Write-Host "`n[1/2] Installing Kind..." -ForegroundColor Yellow
$kindPath = "$installDir\kind.exe"
if (Test-Path $kindPath) {
    Write-Host "  [OK] Kind already installed at $kindPath" -ForegroundColor Green
} else {
    Write-Host "  Downloading Kind..." -ForegroundColor Gray
    $kindUrl = "https://kind.sigs.k8s.io/dl/v0.22.0/kind-windows-amd64"
    try {
        Invoke-WebRequest -Uri $kindUrl -OutFile $kindPath -UseBasicParsing
        Write-Host "  [OK] Kind installed to $kindPath" -ForegroundColor Green
    } catch {
        Write-Host "  [X] Failed to download Kind: $_" -ForegroundColor Red
        exit 1
    }
}

# Install Helm
Write-Host "`n[2/2] Installing Helm..." -ForegroundColor Yellow
$helmPath = "$installDir\helm.exe"
if (Test-Path $helmPath) {
    Write-Host "  [OK] Helm already installed at $helmPath" -ForegroundColor Green
} else {
    Write-Host "  Downloading Helm..." -ForegroundColor Gray
    $helmZip = "$installDir\helm.zip"
    $helmUrl = "https://get.helm.sh/helm-v3.14.0-windows-amd64.zip"
    try {
        Invoke-WebRequest -Uri $helmUrl -OutFile $helmZip -UseBasicParsing
        Write-Host "  Extracting Helm..." -ForegroundColor Gray
        Expand-Archive -Path $helmZip -DestinationPath $installDir -Force
        Move-Item "$installDir\windows-amd64\helm.exe" $helmPath -Force
        Remove-Item $helmZip -Force
        Remove-Item "$installDir\windows-amd64" -Recurse -Force
        Write-Host "  [OK] Helm installed to $helmPath" -ForegroundColor Green
    } catch {
        Write-Host "  [X] Failed to download Helm: $_" -ForegroundColor Red
        exit 1
    }
}

# Add to PATH permanently
Write-Host "`n[3/3] Adding to PATH..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir", "User")
    Write-Host "  [OK] Added $installDir to PATH (restart PowerShell to apply)" -ForegroundColor Green
} else {
    Write-Host "  [OK] $installDir already in PATH" -ForegroundColor Green
}

Write-Host "`n[SUCCESS] Installation complete!" -ForegroundColor Green
Write-Host "`nIMPORTANT: Close this PowerShell window and open a new one to use kind and helm" -ForegroundColor Yellow
Write-Host "Then run: .\local-setup.ps1" -ForegroundColor Cyan
