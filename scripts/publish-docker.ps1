# Script to publish AxiomX Docker images to GitHub Container Registry
# This makes your project easy to download and run for recruiters

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubUsername = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Version = "1.0.0"
)

Write-Host "`n🚀 AxiomX Docker Image Publisher`n" -ForegroundColor Cyan

# Check if GitHub username is provided
if ([string]::IsNullOrEmpty($GitHubUsername)) {
    $GitHubUsername = Read-Host "Enter your GitHub username"
}

if ([string]::IsNullOrEmpty($GitHubUsername)) {
    Write-Host "❌ GitHub username is required!" -ForegroundColor Red
    exit 1
}

Write-Host "Publishing to: ghcr.io/$GitHubUsername/axiomx-api`n" -ForegroundColor Yellow

# Step 1: Check Docker is running
Write-Host "📋 Step 1: Checking Docker..." -NoNewline
try {
    docker  info > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not running"
    }
    Write-Host " ✅" -ForegroundColor Green
} catch {
    Write-Host " ❌" -ForegroundColor Red
    Write-Host "`nError: Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Step 2: Build the image
Write-Host "🔨 Step 2: Building image..." -NoNewline
try {
    docker-compose build api > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    Write-Host " ✅" -ForegroundColor Green
} catch {
    Write-Host " ❌" -ForegroundColor Red
    Write-Host "`nError building image. Run 'docker-compose build api' manually to see errors." -ForegroundColor Red
    exit 1
}

# Step 3: Login to GitHub Container Registry
Write-Host "🔐 Step 3: Logging in to GitHub Container Registry..." -ForegroundColor Yellow
Write-Host "    You'll need a GitHub Personal Access Token with 'write:packages' permission" -ForegroundColor Gray
Write-Host "    Create one at: https://github.com/settings/tokens`n" -ForegroundColor Gray

try {
    docker login ghcr.io -u $GitHubUsername
    if ($LASTEXITCODE -ne 0) {
        throw "Login failed"
    }
    Write-Host "✅ Login successful`n" -ForegroundColor Green
} catch {
    Write-Host "❌ Login failed" -ForegroundColor Red
    Write-Host "`nMake sure you:" -ForegroundColor Yellow
    Write-Host "  1. Use your GitHub username (not email)" -ForegroundColor White
    Write-Host "  2. Use a Personal Access Token as password (not your GitHub password)" -ForegroundColor White
    Write-Host "  3. Token has 'write:packages' permission`n" -ForegroundColor White
    exit 1
}

# Step 4: Tag the images
Write-Host "🏷️  Step 4: Tagging images..." -ForegroundColor Yellow

$images = @(
    @{
        source = "axiomx-api:latest"
        targets = @(
            "ghcr.io/$GitHubUsername/axiomx-api:latest",
            "ghcr.io/$GitHubUsername/axiomx-api:v$Version"
        )
    }
)

foreach ($img in $images) {
    foreach ($target in $img.targets) {
        Write-Host "    $($img.source) → $target" -NoNewline
        docker tag $img.source $target 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✅" -ForegroundColor Green
        } else {
            Write-Host " ❌" -ForegroundColor Red
        }
    }
}

# Step 5: Push the images
Write-Host "`n🚀 Step 5: Pushing images to registry..." -ForegroundColor Yellow
Write-Host "    This may take a few minutes...`n" -ForegroundColor Gray

foreach ($img in $images) {
    foreach ($target in $img.targets) {
        Write-Host "    Pushing $target..." -ForegroundColor White
        docker push $target
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    ❌ Failed to push $target" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "`n✅ All images published successfully!`n" -ForegroundColor Green

# Step 6: Instructions
Write-Host "📦 Next Steps:" -ForegroundColor Cyan
Write-Host "`n1️⃣  Make the package public:" -ForegroundColor Yellow
Write-Host "    Visit: https://github.com/users/$GitHubUsername/packages/container/axiomx-api/settings" -ForegroundColor White
Write-Host "    Change 'Package visibility' to 'Public'`n" -ForegroundColor White

Write-Host "2️⃣  Anyone can now pull your image:" -ForegroundColor Yellow
Write-Host "    docker pull ghcr.io/$GitHubUsername/axiomx-api:latest`n" -ForegroundColor White

Write-Host "3️⃣  Update your docker-compose.yml:" -ForegroundColor Yellow
Write-Host "    Change the api service image to:" -ForegroundColor White
Write-Host "    image: ghcr.io/$GitHubUsername/axiomx-api:latest`n" -ForegroundColor White

Write-Host "4️⃣  Create a GitHub Release:" -ForegroundColor Yellow
Write-Host "    Run: .\scripts\create-release.ps1 -Version $Version`n" -ForegroundColor White

Write-Host "🎉 Your project is now packagedand ready for recruiters!" -ForegroundColor Green
Write-Host ""
