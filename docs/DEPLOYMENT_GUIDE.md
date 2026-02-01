# Complete Hosting & Deployment Guide

This guide covers multiple deployment options from beginner-friendly to production-grade infrastructure.

## Table of Contents

1. [Quick Start (Easiest)](#quick-start-easiest)
2. [Recommended Setup for Production](#recommended-setup-for-production)
3. [Alternative Hosting Options](#alternative-hosting-options)
4. [Domain & DNS Configuration](#domain--dns-configuration)
5. [SSL/HTTPS Setup](#sslhttps-setup)
6. [Environment-Specific Configs](#environment-specific-configs)

---

## Quick Start (Easiest)

### Option 1: Vercel (Frontend) + Railway (Backend + Database)

**Best for:** Getting online in 15 minutes with minimal configuration

#### Step 1: Deploy Backend to Railway

1. **Sign up for Railway**
   - Go to https://railway.app
   - Sign up with GitHub

2. **Create New Project**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Connect your repository
   - Select the repo with your backend code

3. **Add PostgreSQL Database**
   - Click "+ New" → "Database" → "PostgreSQL"
   - Railway automatically provisions a database
   - Connection string is auto-configured

4. **Configure Environment Variables**
   - Go to your backend service → "Variables"
   - Add all variables from `.env.example`:
   ```
   NODE_ENV=production
   PORT=3000
   DATABASE_URL=${{Postgres.DATABASE_URL}}  # Auto-filled by Railway
   SMTP_HOST=smtp.sendgrid.net
   SMTP_USER=apikey
   SMTP_PASS=your_sendgrid_key
   FROM_EMAIL=hello@yourdomain.com
   INTERNAL_EMAIL=team@yourdomain.com
   HUBSPOT_API_KEY=your_key
   ADMIN_API_KEY=generate_random_32_char_string
   ALLOWED_ORIGINS=https://yourdomain.com
   ```

5. **Run Database Migration**
   - Go to PostgreSQL service → "Query"
   - Copy/paste contents of `schema.sql`
   - Click "Execute"

6. **Deploy**
   - Railway auto-deploys on push
   - Get your API URL: `https://your-app.railway.app`

#### Step 2: Deploy Frontend to Vercel

1. **Sign up for Vercel**
   - Go to https://vercel.com
   - Sign up with GitHub

2. **Create New Project**
   - Click "Add New" → "Project"
   - Import your repository

3. **Configure Build Settings**
   - Framework Preset: "Other"
   - Root Directory: `./` (or wherever your `index.html` is)
   - No build command needed for static HTML

4. **Add Environment Variable**
   - Go to Settings → Environment Variables
   - Add: `API_BASE_URL` = `https://your-backend.railway.app/api`

5. **Update Frontend Code**
   - In `index.html`, replace:
   ```javascript
   const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api';
   ```

6. **Deploy**
   - Vercel auto-deploys
   - Get your URL: `https://your-site.vercel.app`

**Cost:** Free tier available (Railway $5/month after free credits)

---

## Recommended Setup for Production

### Option 2: DigitalOcean App Platform (All-in-One)

**Best for:** Production apps with moderate traffic, easy scaling

#### Architecture
```
DigitalOcean App Platform
├── Static Site (Frontend)
├── Web Service (Backend API)
└── Managed Database (PostgreSQL)
```

#### Deployment Steps

1. **Create DigitalOcean Account**
   - Go to https://digitalocean.com
   - Sign up and verify

2. **Create App**
   - Click "Apps" → "Create App"
   - Connect GitHub repository

3. **Configure Components**

   **Frontend (Static Site):**
   - Type: Static Site
   - Source Directory: `/`
   - Output Directory: `/` (no build needed)
   - Routes: Rewrite all to `index.html`

   **Backend (Web Service):**
   - Type: Web Service
   - Source Directory: `/`
   - Build Command: `npm install`
   - Run Command: `npm start`
   - HTTP Port: 3000
   - Environment Variables: (add all from `.env.example`)

4. **Add Database**
   - Click "Add Resource" → "Database"
   - Select PostgreSQL 14
   - Plan: Basic ($15/month)
   - Auto-connects to your backend via `DATABASE_URL`

5. **Run Migration**
   - Once deployed, go to Database → Console
   - Run: `\i schema.sql` (after uploading file)
   - Or manually copy/paste SQL

6. **Custom Domain**
   - Settings → Domains
   - Add your domain
   - Update DNS (instructions provided)

**Cost:** ~$20-30/month (Basic tier)

---

## Alternative Hosting Options

### Option 3: AWS (Enterprise-Grade)

**Best for:** Large-scale production, full control, compliance requirements

#### Services Used
- **Frontend:** S3 + CloudFront
- **Backend:** EC2 or Elastic Beanstalk
- **Database:** RDS PostgreSQL
- **Email:** SES
- **Storage:** S3

#### Quick Setup with Elastic Beanstalk

```bash
# Install EB CLI
pip install awsebcli

# Initialize
eb init -p node.js offline-acquisition

# Create environment
eb create production-env \
  --database \
  --database.engine postgres \
  --database.size 10 \
  --envvars NODE_ENV=production,SMTP_HOST=email-smtp.us-east-1.amazonaws.com

# Deploy
eb deploy

# Set environment variables
eb setenv SMTP_USER=your_ses_user SMTP_PASS=your_ses_pass
```

#### Frontend to S3 + CloudFront

```bash
# Install AWS CLI
pip install awscli

# Create S3 bucket
aws s3 mb s3://your-site-name

# Upload files
aws s3 sync . s3://your-site-name --exclude ".git/*"

# Enable static website hosting
aws s3 website s3://your-site-name --index-document index.html

# Create CloudFront distribution (via AWS Console)
# Point to S3 bucket
# Enable HTTPS with free SSL certificate
```

**Cost:** ~$50-200/month depending on traffic

---

### Option 4: Heroku (Simple, Developer-Friendly)

**Best for:** Quick prototypes, demos, small production apps

```bash
# Install Heroku CLI
curl https://cli-assets.heroku.com/install.sh | sh

# Login
heroku login

# Create app
heroku create your-app-name

# Add PostgreSQL
heroku addons:create heroku-postgresql:mini

# Set environment variables
heroku config:set NODE_ENV=production
heroku config:set SMTP_HOST=smtp.sendgrid.net
heroku config:set SMTP_USER=apikey
heroku config:set SMTP_PASS=your_key
# ... (add all other env vars)

# Deploy
git push heroku main

# Run migration
heroku pg:psql < schema.sql

# View app
heroku open
```

**Frontend:** Use Netlify or Vercel (free)

**Cost:** $7-25/month

---

### Option 5: Self-Hosted VPS (Full Control)

**Best for:** Cost optimization, full control, custom requirements

#### Providers
- **DigitalOcean Droplet:** $6/month (1GB RAM)
- **Linode:** $5/month
- **Vultr:** $6/month
- **Hetzner:** €4/month (EU)

#### Setup Ubuntu 22.04 Server

```bash
# SSH into server
ssh root@your_server_ip

# Update system
apt update && apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install PostgreSQL
apt install -y postgresql postgresql-contrib

# Install nginx (web server)
apt install -y nginx

# Install certbot (SSL certificates)
apt install -y certbot python3-certbot-nginx

# Install PM2 (process manager)
npm install -g pm2

# Create database
sudo -u postgres psql
CREATE DATABASE offline_acquisition;
CREATE USER appuser WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE offline_acquisition TO appuser;
\q

# Clone your repository
cd /var/www
git clone https://github.com/yourusername/your-repo.git
cd your-repo

# Install dependencies
npm install --production

# Create .env file
nano .env
# (paste your environment variables)

# Run database migration
psql -d offline_acquisition -U appuser -f schema.sql

# Start backend with PM2
pm2 start server.js --name "offline-api"
pm2 save
pm2 startup

# Configure nginx
nano /etc/nginx/sites-available/default
```

#### Nginx Configuration

```nginx
# Frontend (static files)
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    root /var/www/your-repo;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}

# Backend API
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
# Test nginx config
nginx -t

# Restart nginx
systemctl restart nginx

# Get SSL certificate
certbot --nginx -d yourdomain.com -d www.yourdomain.com -d api.yourdomain.com

# Auto-renewal is configured automatically
```

**Cost:** $6-12/month

---

## Domain & DNS Configuration

### Purchase Domain
- **Namecheap:** ~$10/year
- **Google Domains:** ~$12/year
- **Cloudflare:** At-cost pricing (~$8/year)

### DNS Setup

#### For Main Site (yourdomain.com)

**If using Vercel/Netlify:**
```
Type: A
Name: @
Value: (provided by platform)

Type: CNAME
Name: www
Value: (provided by platform)
```

**If using custom server:**
```
Type: A
Name: @
Value: your_server_ip

Type: A
Name: www
Value: your_server_ip
```

#### For API Subdomain (api.yourdomain.com)

```
Type: A
Name: api
Value: your_backend_server_ip
```

**Or CNAME (if using Railway/Heroku):**
```
Type: CNAME
Name: api
Value: your-app.railway.app
```

### Update Frontend API URL

In `index.html`:
```javascript
const API_BASE_URL = 'https://api.yourdomain.com/api';
```

---

## SSL/HTTPS Setup

### Free SSL with Let's Encrypt

**If self-hosting:**
```bash
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

**If using platforms:**
- Vercel/Netlify: Auto-configured ✓
- Railway: Auto-configured ✓
- Heroku: Auto-configured ✓

### Force HTTPS

In `server.js`, add:
```javascript
if (process.env.NODE_ENV === 'production') {
    app.use((req, res, next) => {
        if (req.header('x-forwarded-proto') !== 'https') {
            res.redirect(`https://${req.header('host')}${req.url}`);
        } else {
            next();
        }
    });
}
```

---

## Environment-Specific Configs

### Development (.env.development)
```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://localhost:5432/offline_acquisition_dev
API_BASE_URL=http://localhost:3000/api
```

### Staging (.env.staging)
```env
NODE_ENV=staging
PORT=3000
DATABASE_URL=postgresql://staging-db-url
API_BASE_URL=https://staging-api.yourdomain.com/api
```

### Production (.env.production)
```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://production-db-url
API_BASE_URL=https://api.yourdomain.com/api
```

---

## Monitoring & Maintenance

### Recommended Tools

1. **Uptime Monitoring**
   - UptimeRobot (free)
   - Pingdom
   - StatusCake

2. **Error Tracking**
   - Sentry (free tier)
   - Rollbar

3. **Analytics**
   - Google Analytics
   - Plausible (privacy-focused)

4. **Performance**
   - New Relic
   - DataDog

### Backup Strategy

**Database Backups (Daily):**

```bash
# Automated backup script
#!/bin/bash
pg_dump offline_acquisition > backup-$(date +%Y%m%d).sql
aws s3 cp backup-$(date +%Y%m%d).sql s3://your-backup-bucket/

# Add to crontab
0 2 * * * /path/to/backup-script.sh
```

---

## Cost Comparison

| Solution | Frontend | Backend | Database | Total/Month |
|----------|----------|---------|----------|-------------|
| Vercel + Railway | Free | $5 | $10 | **$15** |
| DigitalOcean App | $5 | $12 | $15 | **$32** |
| Heroku + Netlify | Free | $7 | $9 | **$16** |
| AWS (small) | $1 | $20 | $30 | **$51** |
| VPS Self-Hosted | - | - | - | **$6-12** |

---

## My Recommendation

### For Getting Started (MVP)
**Railway + Vercel**
- Fastest deployment
- Free tier available
- Auto-scaling
- Easy to use

### For Production (Real Business)
**DigitalOcean App Platform**
- Reliable infrastructure
- Good balance of features/cost
- Managed database backups
- Easy scaling

### For Scale (High Traffic)
**AWS or Self-Hosted VPS**
- Full control
- Best performance
- Custom optimizations
- Lower per-request costs

---

## Troubleshooting

### "Cannot connect to database"
```bash
# Check DATABASE_URL format
echo $DATABASE_URL
# Should be: postgresql://user:pass@host:5432/dbname

# Test connection
psql $DATABASE_URL -c "SELECT 1"
```

### "CORS errors"
Update `ALLOWED_ORIGINS` in backend:
```env
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### "502 Bad Gateway"
```bash
# Check if backend is running
pm2 list
pm2 logs

# Restart
pm2 restart all
```

### SSL certificate issues
```bash
# Renew certificate
certbot renew

# Test auto-renewal
certbot renew --dry-run
```

---

## Next Steps After Deployment

1. ✅ Set up domain email (hello@yourdomain.com)
2. ✅ Configure SendGrid/Mailgun for transactional emails
3. ✅ Add Google Analytics tracking code
4. ✅ Set up uptime monitoring
5. ✅ Configure automated database backups
6. ✅ Enable error tracking (Sentry)
7. ✅ Test all form submissions
8. ✅ Set up staging environment
9. ✅ Document API for team
10. ✅ Create admin dashboard for managing requests

---

## Support Resources

- **Railway Docs:** https://docs.railway.app
- **Vercel Docs:** https://vercel.com/docs
- **DigitalOcean Docs:** https://docs.digitalocean.com
- **PostgreSQL Docs:** https://www.postgresql.org/docs/
- **Node.js Deployment:** https://nodejs.org/en/docs/guides/
- **Let's Encrypt:** https://letsencrypt.org/docs/

---

Need help with deployment? Most platforms have excellent support channels and Discord communities.