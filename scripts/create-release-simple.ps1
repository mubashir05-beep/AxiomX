# Script to create a GitHub Release for AxiomX
# Simple version without encoding issues

param(
    [string]$Version = "1.0.0"
)

Write-Host "Creating release v$Version for AxiomX" -ForegroundColor Cyan
Write-Host ""

# Check git
try {
    git --version > $null 2>&1
} catch {
    Write-Host "ERROR: Git not found" -ForegroundColor Red
    exit 1
}

# Step 1: Commit any changes
Write-Host "Step 1: Committing changes..." -ForegroundColor Yellow
$status = git status --porcelain
if ($status) {
    git add .
    git commit -m "chore: prepare release v$Version"
    Write-Host "  Changes committed" -ForegroundColor Green
} else {
    Write-Host "  No changes to commit" -ForegroundColor Green
}

# Step 2: Create tag
Write-Host ""
Write-Host "Step 2: Creating git tag..." -ForegroundColor Yellow

$existingTag = git tag -l "v$Version"
if ($existingTag) {
    Write-Host "  Tag v$Version already exists" -ForegroundColor Yellow
    $overwrite = Read-Host "  Recreate it? (y/N)"
    if ($overwrite -eq 'y') {
        git tag -d "v$Version" 2>&1 | Out-Null
        git push origin ":refs/tags/v$Version" 2>&1 | Out-Null
        Write-Host "  Deleted existing tag" -ForegroundColor Gray
    }
}

$tagMessage = "Production-ready: 1000+ orders/sec, sub-5ms latency"
git tag -a "v$Version" -m $tagMessage 2>&1 | Out-Null
Write-Host "  Tag created" -ForegroundColor Green

# Step 3: Push
Write-Host ""
Write-Host "Step 3: Pushing to GitHub..." -ForegroundColor Yellow
git push origin main 2>&1 | Out-Null
git push origin "v$Version" 2>&1 | Out-Null
Write-Host "  Pushed to GitHub" -ForegroundColor Green

# Step 4: Create release notes
Write-Host ""
Write-Host "Step 4: Creating release notes..." -ForegroundColor Yellow

$releaseNotes = @"
# AxiomX v$Version - Production Ready

High-performance cryptocurrency matching engine handling 1,000+ orders/second with sub-5ms P95 latency.

## Quick Start

``````bash
docker-compose up -d
``````

Then visit:
- API: http://localhost:8081/health
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090

## Performance (Verified)

Load tested with k6 on March 1, 2026:

| Metric | Result |
|--------|--------|
| Throughput | 1,056 req/s |
| Total Requests | 253,770 (4 min) |
| P95 Latency | 4.15ms |
| Error Rate | 0.00% |

Full metrics: [k6-heavy-summary.json](scripts/k6-heavy-summary.json)

## What's Included

- Matching Engine: In-memory order book with price-time priority
- Event Streaming: Kafka for reliable event distribution
- Observability: Prometheus + Grafana + Loki
- Persistence: PostgreSQL with optimized schema
- Caching: Redis for sub-ms lookups
- Infrastructure: Kubernetes (Helm) + Terraform + Ansible
- Load Tests: k6 scripts with verified results

## For Recruiters

See [RECRUITER_GUIDE.md](RECRUITER_GUIDE.md) for technical highlights and Q&A.

## Tech Stack

Backend: Go 1.23 | Streaming: Apache Kafka 7.5 | Database: PostgreSQL 15, Redis 7  
Observability: Prometheus, Grafana, Loki | Infrastructure: Kubernetes, Docker, Terraform

## Documentation

- [README](README.md) - Project overview
- [RECRUITER_GUIDE](RECRUITER_GUIDE.md) - Technical guide
- [DEPLOYMENT_GUIDE](DEPLOYMENT_GUIDE.md) - Deployment options

## License

MIT License - see [LICENSE](LICENSE)
"@

$releaseNotesFile = "RELEASE_NOTES_v$Version.md"
$releaseNotes | Out-File -FilePath $releaseNotesFile -Encoding UTF8
Write-Host "  Saved to: $releaseNotesFile" -ForegroundColor Green

# Step 5: Instructions
Write-Host ""
Write-Host "SUCCESS: Git tag created and pushed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps - Create GitHub Release:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Go to: https://github.com/mubashir05-beep/AxiomX/releases/new"
Write-Host ""
Write-Host "2. Fill in:"
Write-Host "   - Choose tag: v$Version"
Write-Host "   - Title: AxiomX v$Version - Production Ready"
Write-Host "   - Description: Copy from $releaseNotesFile"
Write-Host ""
Write-Host "3. Attach files:"
Write-Host "   - docker-compose.yml"
Write-Host "   - RECRUITER_GUIDE.md"
Write-Host "   - scripts/k6-heavy-summary.json"
Write-Host ""
Write-Host "4. Click 'Publish release'"
Write-Host ""

# Try GitHub CLI if available
try {
    gh --version > $null 2>&1
    $ghInstalled = $true
} catch {
    $ghInstalled = $false
}

if ($ghInstalled) {
    Write-Host "GitHub CLI detected!" -ForegroundColor Green
    $createNow = Read-Host "Create release now with GitHub CLI? (Y/n)"
    if ($createNow -ne 'n') {
        Write-Host ""
        Write-Host "Creating release..." -ForegroundColor Cyan
        
        gh release create "v$Version" `
            --title "AxiomX v$Version - Production Ready" `
            --notes-file $releaseNotesFile `
            docker-compose.yml RECRUITER_GUIDE.md scripts/k6-heavy-summary.json
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "SUCCESS: Release created!" -ForegroundColor Green
            Write-Host "View at: https://github.com/mubashir05-beep/AxiomX/releases/tag/v$Version"
        } else {
            Write-Host ""
            Write-Host "Failed to create release automatically" -ForegroundColor Yellow
            Write-Host "Please create it manually at the GitHub link above"
        }
    }
} else {
    Write-Host "Tip: Install GitHub CLI for easier releases:"
    Write-Host "  winget install GitHub.cli"
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
