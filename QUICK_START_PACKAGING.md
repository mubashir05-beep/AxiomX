# 📦 Quick Start: Package & Distribute

**Goal**: Make AxiomX easy for recruiters to download and run - zero costs!

This guide covers **Option 2** from the DEPLOYMENT_GUIDE: Publishing Docker images and creating a GitHub Release.

---

## 🎯 What You'll Achieve

✅ Docker images published to GitHub Container Registry (free, unlimited public images)  
✅ GitHub Release with downloadable package  
✅ Professional presentation for recruiters  
✅ Easy one-command setup for anyone  
✅ **Total cost: $0**

---

## ⏱️ Time Required

- **Total**: ~20 minutes  
- **Docker publish**: ~10 minutes  
- **GitHub release**: ~10 minutes

---

## 📋 Prerequisites

Before you start, make sure you have:

- [ ] Docker Desktop running
- [ ] Git configured
- [ ] GitHub account
- [ ] Repository pushed to GitHub
- [ ] All services tested locally (`docker-compose up -d` works)

---

## 🚀 Step 1: Create GitHub Personal Access Token (5 min)

You need this to publish Docker images.

1. **Go to GitHub Settings**:
   ```
   https://github.com/settings/tokens
   ```

2. **Click**: "Generate new token" → "Generate new token (classic)"

3. **Configure**:
   - Note: `AxiomX Docker Publishing`
   - Expiration: `90 days` (or your preference)
   - Scopes: Check these boxes:
     - ✅ `write:packages`
     - ✅ `read:packages`
     - ✅ `delete:packages`

4. **Click**: "Generate token"

5. **Copy token** (you'll need it in next step)
   ⚠️ Save it somewhere safe - you won't see it again!

---

## 🐳 Step 2: Publish Docker Images (10 min)

### Option A: Using the Script (Recommended)

Run the automated script:

```powershell
cd AxiomX
.\scripts\publish-docker.ps1 -GitHubUsername "yourusername" -Version "1.0.0"
```

**What it does**:
1. Checks Docker is running
2. Builds the API image
3. Logs you into GitHub Container Registry
4. Tags images (latest + v1.0.0)
5. Pushes to registry

**When prompted for password**: Paste your GitHub token (not your GitHub password)

### Option B: Manual Steps

If the script doesn't work:

```powershell
# 1. Login to GitHub Container Registry
# Username: your GitHub username
# Password: your Personal Access Token from Step 1
docker login ghcr.io -u yourusername

# 2. Build image
docker-compose build api

# 3. Tag images
docker tag axiomx-api:latest ghcr.io/yourusername/axiomx-api:latest
docker tag axiomx-api:latest ghcr.io/yourusername/axiomx-api:v1.0.0

# 4. Push images
docker push ghcr.io/yourusername/axiomx-api:latest
docker push ghcr.io/yourusername/axiomx-api:v1.0.0
```

### Make Package Public

1. Go to: `https://github.com/users/yourusername/packages/container/axiomx-api/settings`
2. Scroll to "Danger Zone"
3. Click "Change visibility"
4. Select "Public"
5. Type package name to confirm
6. Click "I understand, change package visibility"

**Result**: Anyone can now pull your image:
```bash
docker pull ghcr.io/yourusername/axiomx-api:latest
```

---

## 📦 Step 3: Create GitHub Release (10 min)

### Option A: Using the Script (Easiest)

```powershell
.\scripts\create-release.ps1 -Version "1.0.0"
```

**What it does**:
1. Commits any changes
2. Creates git tag `v1.0.0`
3. Pushes to GitHub
4. Generates release notes
5. (Optional) Creates release via GitHub CLI

### Option B: Manual Steps

1. **Create and push tag**:
   ```powershell
   git add .
   git commit -m "chore: prepare release v1.0.0"
   git tag -a v1.0.0 -m "Production-ready: 1000+ orders/sec, sub-5ms latency"
   git push origin main
   git push origin v1.0.0
   ```

2. **Go to GitHub Releases**:
   ```
   https://github.com/yourusername/AxiomX/releases/new
   ```

3. **Fill in the form**:
   - **Choose a tag**: `v1.0.0`
   - **Release title**: `AxiomX v1.0.0 - Production Ready`
   - **Description**: Copy from `RELEASE_NOTES_v1.0.0.md` (created by script)
     
     Or use this template:
     ```markdown
     # 🎉 AxiomX v1.0.0 - Production Ready
     
     High-performance cryptocurrency matching engine handling **1,000+ orders/second** with **sub-5ms P95 latency**.
     
     ## ⚡ Quick Start
     
     ```bash
     docker-compose up -d
     ```
     
     Then visit http://localhost:8081/health
     
     ## 📊 Performance
     
     - **Throughput**: 1,056 req/s
     - **P95 Latency**: 4.15ms
     - **Error Rate**: 0.00%
     
     See [RECRUITER_GUIDE.md](RECRUITER_GUIDE.md) for details.
     ```

4. **Attach files**:
   - Click "Attach binaries by dropping them here"
   - Drag and drop:
     - `docker-compose.yml`
     - `RECRUITER_GUIDE.md`
     - `scripts/k6-heavy-summary.json`

5. **Click**: "Publish release"

**Result**: Your release is now live!
```
https://github.com/yourusername/AxiomX/releases/tag/v1.0.0
```

---

## ✅ Step 4: Update README (2 min)

Update your README to reference the published image:

Add this near the Quick Start section:

```markdown
## 🐳 Pre-built Docker Image

No build required! Pull the pre-built image:

\`\`\`bash
docker pull ghcr.io/yourusername/axiomx-api:latest
\`\`\`

Or use our docker-compose file which is configured to use the published image.
```

---

## 🎯 Step 5: Configure GitHub Repository (5 min)

Make your repo shine for recruiters!

### Update Repository Settings

1. **Go to repository**: `https://github.com/yourusername/AxiomX`

2. **Click** the ⚙️ icon next to "About"

3. **Fill in**:
   - **Description**: 
     ```
     High-performance cryptocurrency matching engine built with Go, Kafka & Kubernetes. 1000+ orders/sec, sub-5ms latency.
     ```
   
   - **Website**: (your portfolio URL if you have one)
   
   - **Topics** (click + to add each):
     ```
     cryptocurrency, trading-engine, golang, kafka, kubernetes, 
     high-performance, postgresql, redis, observability, 
     prometheus, grafana, docker, microservices, event-driven,
     fintech, low-latency, distributed-systems, portfolio-project
     ```
   
   - **Include in home page**: Check ✅ Releases and ✅ Packages

4. **Click**: "Save changes"

### Pin to Your Profile

1. Go to your GitHub profile
2. Click "Customize your pins"
3. Select "AxiomX"
4. Drag it to the top
5. Click "Save pins"

---

## 🎉 You're Done!

Your project is now beautifully packaged and ready for recruiters!

### What You Can Share Now

**GitHub Release**:
```
https://github.com/yourusername/AxiomX/releases/tag/v1.0.0
```

**One-liner for recruiters**:
```
Pull and run my trading engine: docker pull ghcr.io/yourusername/axiomx-api:latest
```

**For job applications**:
```
I built AxiomX, a production-ready trading engine processing 1,000+ orders/sec.
GitHub: https://github.com/yourusername/AxiomX

It demonstrates my experience with distributed systems, Go, Kafka, and Kubernetes.
Full details in the RECRUITER_GUIDE.md.
```

---

## 📈 Track Success

### GitHub Insights (check weekly)

Go to: `Repository → Insights → Traffic`

Watch for:
- **Views**: How many times people looked
- **Clones**: How many downloaded it
- **Stars**: Social proof
- **Referrers**: Where traffic came from

### Docker Image Stats

Go to: `https://github.com/users/yourusername/packages/container/axiomx-api`

See:
- **Total pulls**
- **Recent downloads**
- **Storage used** (should be minimal)

---

## 🚀 Next Steps (Optional)

### Week 1
- [ ] Add project to LinkedIn Featured section
- [ ] Create a demo video (Loom/YouTube)
- [ ] Take screenshots for portfolio

### Week 2
- [ ] Share on LinkedIn with technical post
- [ ] Add to portfolio website
- [ ] Update resume with project

### When Applying
- [ ] Customize RECRUITER_GUIDE for specific company
- [ ] Reference relevant technologies from job posting
- [ ] Offer to walk through architecture in interview

---

## 🆘 Troubleshooting

**Docker login failed**:
- Use GitHub username (not email)
- Use Personal Access Token (not password)
- Check token has `write:packages` permission

**Image push denied**:
- Verify you're logged in: `docker logout ghcr.io && docker login ghcr.io`
- Check repository name: must be lowercase
- Ensure token hasn't expired

**Tag already exists**:
- Delete local tag: `git tag -d v1.0.0`
- Delete remote tag: `git push origin :refs/tags/v1.0.0`
- Create new tag with script

**Release creation failed**:
- Ensure tag is pushed: `git push origin v1.0.0`
- Verify you have write access to repository
- Try creating manually on GitHub web interface

---

## 💡 Pro Tips

1. **Update regularly**: Create new releases (v1.1.0, v1.2.0) as you add features
2. **Keep it simple**: Recruiters want "clone and run" simplicity
3. **Screenshots matter**: Add Grafana dashboard screenshots to README
4. **Video helps**: 3-minute demo on Loom is powerful
5. **Track engagement**: Watch GitHub Insights to see when recruiters visit

---

**🎯 Your project is now recruiter-ready!**

Cost: **$0/month** • Setup time: **20 minutes** • Recruiter visibility: **⭐⭐⭐⭐⭐**

---

**Questions?** Check [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for more options or [RECRUITER_GUIDE.md](RECRUITER_GUIDE.md) for how recruiters see this project.
