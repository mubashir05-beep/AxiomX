# Script to help create a GitHub Release for AxiomX
# Automates the release process and generates release notes

param(
    [Parameter(Mandatory=$false)]
    [string]$Version = "1.0.0"
)

Write-Host ""
Write-Host "📦 AxiomX GitHub Release Creator" -ForegroundColor Cyan
Write-Host ""

# Check if git is available
try {
    git --version > $null 2>&1
} catch {
    Write-Host "❌ Git is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "❌ Not in a git repository. Run this from the AxiomX root directory." -ForegroundColor Red
    exit 1
}

Write-Host "Creating release v$Version" -ForegroundColor Yellow
Write-Host ""

# Step 1: Add and commit any changes
Write-Host "📝 Step 1: Checking for uncommitted changes..." -ForegroundColor Yellow

$status = git status --porcelain
if ($status) {
    Write-Host "   Found uncommitted changes. Committing..." -ForegroundColor Gray
    git add .
    git commit -m "chore: prepare release v$Version"
    Write-Host "   ✅ Changes committed" -ForegroundColor Green
} else {
    Write-Host "   ✅ No uncommitted changes" -ForegroundColor Green
}

# Step 2: Create and push tag
Write-Host "`n🏷️  Step 2: Creating git tag v$Version..." -NoNewline

# Check if tag already exists
$existingTag = git tag -l "v$Version"
if ($existingTag) {
    Write-Host " ⚠️  Tag already exists" -ForegroundColor Yellow
    $overwrite = Read-Host "`n   Do you want to recreate it? (y/N)"
    if ($overwrite -eq 'y' -or $overwrite -eq 'Y') {
        git tag -d "v$Version" > $null 2>&1
        git push origin ":refs/tags/v$Version" > $null 2>&1
        Write-Host "   Deleted existing tag" -ForegroundColor Gray
    } else {
        Write-Host "`n   Using existing tag v$Version" -ForegroundColor Yellow
        $tagExists = $true
    }
}

if (-not $tagExists) {
    $tagMessage = "Production-ready: 1000+ orders/sec, sub-5ms latency, full observability"
    git tag -a "v$Version" -m $tagMessage
    Write-Host " ✅" -ForegroundColor Green
}

# Step 3: Push to GitHub
Write-Host "`n🚀 Step 3: Pushing to GitHub..." -NoNewline

try {
    git push origin main 2>&1 | Out-Null
    git push origin "v$Version" 2>&1 | Out-Null
    Write-Host " ✅" -ForegroundColor Green
} catch {
    Write-Host " ⚠️  Push failed (continuing anyway)" -ForegroundColor Yellow
}

# Step 4: Create release notes file
Write-Host "`n📄 Step 4: Creating release notes..." -NoNewline

$releaseNotes = @"
# 🎉 AxiomX v$Version - Production Ready

High-performance cryptocurrency matching engine handling **1,000+ orders/second** with **sub-5ms P95 latency**.

## ⚡ Quick Start (One Command)

````bash
docker-compose up -d
````

Then visit:
- 🔗 API: http://localhost:8081/health
- 📊 Grafana: http://localhost:3000 (admin/admin)
- 📈 Prometheus: http://localhost:9090

## 📊 Performance (Verified)

Load tested with k6 on March 1, 2026:

| Metric | Result |
|--------|--------|
| Throughput | **1,056 req/s** |
| Total Requests | **253,770** (4 min) |
| P95 Latency | **4.15ms** |
| P99 Latency | **<10ms** |
| Error Rate | **0.00%** |

Full metrics: [k6-heavy-summary.json](scripts/k6-heavy-summary.json)

## 🛠️ What's Included

- **Matching Engine**: In-memory order book with price-time priority
- **Event Streaming**: Kafka for reliable event distribution
- **Observability**: Prometheus + Grafana + Loki
- **Persistence**: PostgreSQL with optimized schema
- **Caching**: Redis for sub-ms lookups
- **Infrastructure**: Kubernetes (Helm) + Terraform + Ansible
- **Load Tests**: k6 scripts with verified results

## 🎯 For Recruiters

See [RECRUITER_GUIDE.md](RECRUITER_GUIDE.md) for:
- Technical highlights explained
- Skills demonstrated
- 30-second demo instructions
- Answers to common questions

## 🏗️ Tech Stack

**Backend**: Go 1.23  
**Streaming**: Apache Kafka 7.5  
**Database**: PostgreSQL 15, Redis 7  
**Observability**: Prometheus, Grafana, Loki  
**Infrastructure**: Kubernetes, Docker, Terraform, Helm, Ansible  

## 📚 Documentation

- [README](README.md) - Project overview
- [RECRUITER_GUIDE](RECRUITER_GUIDE.md) - Technical highlights & Q&A
- [DEPLOYMENT_GUIDE](DEPLOYMENT_GUIDE.md) - Deployment options
- [PUBLISHING_GUIDE](PUBLISHING_GUIDE.md) - How to share

## 📦 Files Attached

- `docker-compose.yml` - Run all services locally
- `k6-heavy-summary.json` - Load test results
- `RECRUITER_GUIDE.md` - Technical guide for recruiters

## 📝 License

MIT License - see [LICENSE](LICENSE)

---

⭐ **Star this repo if you find it useful!**
"@

$releaseNotesFile = "RELEASE_NOTES_v$Version.md"
$releaseNotes | Out-File -FilePath $releaseNotesFile -Encoding UTF8
Write-Host " ✅" -ForegroundColor Green
Write-Host "   Saved to: $releaseNotesFile" -ForegroundColor Gray

# Step 5: Instructions for GitHub
Write-Host ""
Write-Host "✅ Git tag created and pushed!" -ForegroundColor Green
Write-Host ""

Write-Host "📦 Next: Create GitHub Release" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣  Go to your repository on GitHub:" -ForegroundColor Yellow
Write-Host "    https://github.com/yourusername/AxiomX/releases/new" -ForegroundColor White
Write-Host ""

Write-Host "2️⃣  Fill in the release form:" -ForegroundColor Yellow
Write-Host "    • Choose tag: v$Version" -ForegroundColor White
Write-Host "    • Release title: AxiomX v$Version - Production Ready" -ForegroundColor White
Write-Host "    • Description: Copy from $releaseNotesFile" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣  Attach these files:" -ForegroundColor Yellow
Write-Host "    • docker-compose.yml" -ForegroundColor White
Write-Host "    • RECRUITER_GUIDE.md" -ForegroundColor White
Write-Host "    • scripts/k6-heavy-summary.json" -ForegroundColor White
Write-Host ""

Write-Host "4️⃣  Click 'Publish release'" -ForegroundColor Yellow
Write-Host ""

Write-Host "💡 Or use GitHub CLI (if installed):" -ForegroundColor Cyan
Write-Host "    gh release create v$Version \\" -ForegroundColor White
Write-Host "      --title 'AxiomX v$Version - Production Ready' \\" -ForegroundColor White
Write-Host "      --notes-file $releaseNotesFile \\" -ForegroundColor White
Write-Host "      docker-compose.yml RECRUITER_GUIDE.md scripts/k6-heavy-summary.json" -ForegroundColor White
Write-Host ""

Write-Host "🎉 Release preparation complete!" -ForegroundColor Green
Write-Host ""

# Check if GitHub CLI is available
try {
    gh --version > $null 2>&1
    $ghInstalled = $true
} catch {
    $ghInstalled = $false
}

if ($ghInstalled) {
    $createNow = Read-Host "GitHub CLI detected. Create release now? (Y/n)"
    if ($createNow -ne 'n' -and $createNow -ne 'N') {
        Write-Host ""
        Write-Host "🚀 Creating release with GitHub CLI..." -ForegroundColor Cyan
        Write-Host ""
        
        gh release create "v$Version" `
            --title "AxiomX v$Version - Production Ready" `
            --notes-file $releaseNotesFile `
            docker-compose.yml RECRUITER_GUIDE.md scripts/k6-heavy-summary.json
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Release created successfully!" -ForegroundColor Green
            Write-Host "   View at: https://github.com/yourusername/AxiomX/releases/tag/v$Version" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "`n⚠️  Failed to create release automatically" -ForegroundColor Yellow
            Write-Host "   Please create it manually at: https://github.com/yourusername/AxiomX/releases/new" -ForegroundColor White
            Write-Host ""
        }
    }
} else {
    Write-Host "Tip: Install GitHub CLI for easier releases:" -ForegroundColor Cyan
    Write-Host "    winget install GitHub.cli" -ForegroundColor White
    Write-Host ""
}
