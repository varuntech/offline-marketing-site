# 🚀 Quick Start Guide - Get Your Site Live in 30 Minutes

This is the **absolute simplest** path to get your site online. No prior hosting experience needed.

---

## What You Need

- [ ] GitHub account (free)
- [ ] Credit card for hosting (but we'll use free tiers where possible)
- [ ] Your website files (you already have these!)
- [ ] 30 minutes of time

**Total Cost to Start:** $0-5/month (Railway has $5/month free credit)

---

## Step-by-Step Instructions

### Part 1: Setup Your Code Repository (5 minutes)

1. **Create GitHub Account**
   - Go to https://github.com/signup
   - Enter email, create password, choose username
   - Verify email

2. **Create New Repository**
   - Click green "New" button (top left)
   - Repository name: `offline-marketing-site`
   - Choose "Public" (or Private if you prefer)
   - Click "Create repository"

3. **Upload Your Files**
   - Click "uploading an existing file"
   - Drag and drop ALL your files:
     - `server.js`
     - `schema.sql`
     - `package.json`
     - `.env.example`
     - `index.html`
     - `README.md`
   - Click "Commit changes"

✅ Your code is now on GitHub!

---

### Part 2: Deploy Backend (10 minutes)

We'll use **Railway** because it's the easiest.

1. **Sign Up for Railway**
   - Go to https://railway.app
   - Click "Login with GitHub"
   - Authorize Railway to access your GitHub

2. **Create New Project**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your `offline-marketing-site` repository
   - Railway starts building automatically

3. **Add Database**
   - In your project, click "+ New"
   - Select "Database" → "PostgreSQL"
   - Railway creates a database for you
   - **Important:** Copy the database connection string (we'll need this)

4. **Set Up Database Tables**
   - Click on the PostgreSQL service
   - Go to "Data" tab
   - Click "Query"
   - Open your `schema.sql` file from your computer
   - Copy ALL the SQL code
   - Paste it into the Railway query box
   - Click "Execute Query"
   - You should see "Query executed successfully"

5. **Configure Environment Variables**
   - Click on your web service (not the database)
   - Go to "Variables" tab
   - Click "RAW Editor"
   - Paste this (replace the values):

```
NODE_ENV=production
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=REPLACE_WITH_SENDGRID_KEY
FROM_EMAIL=hello@yourcompany.com
INTERNAL_EMAIL=team@yourcompany.com
ADMIN_API_KEY=REPLACE_WITH_RANDOM_STRING_AT_LEAST_32_CHARS
HUBSPOT_API_KEY=REPLACE_WITH_HUBSPOT_KEY_OR_DELETE_THIS_LINE
ALLOWED_ORIGINS=*
```

   **Quick SendGrid Setup (for email):**
   - Go to https://sendgrid.com/free
   - Sign up for free account
   - Go to Settings → API Keys → Create API Key
   - Copy the key and paste it as `SMTP_PASS` above

   **For ADMIN_API_KEY:**
   - Go to https://passwordsgenerator.net/
   - Generate a 32-character password
   - Copy and paste it

6. **Get Your API URL**
   - Go to "Settings" tab in your Railway service
   - Find "Domains" section
   - You'll see something like: `offline-marketing-site-production.up.railway.app`
   - **Copy this URL** - you'll need it for the frontend

✅ Your backend is live!

---

### Part 3: Deploy Frontend (10 minutes)

We'll use **Vercel** because it's free and super easy.

1. **Sign Up for Vercel**
   - Go to https://vercel.com/signup
   - Click "Continue with GitHub"
   - Authorize Vercel

2. **Import Project**
   - Click "Add New" → "Project"
   - Find your `offline-marketing-site` repository
   - Click "Import"

3. **Configure Project**
   - Framework Preset: Select "Other"
   - Root Directory: Leave as `./`
   - Build Command: Leave empty
   - Output Directory: Leave as `./`
   - Install Command: Leave empty

4. **Update API Connection**
   
   **IMPORTANT:** Before deploying, you need to update your `index.html` file:
   
   - Go back to your GitHub repository
   - Click on `index.html`
   - Click the pencil icon (Edit)
   - Find this line (around line 1063):
   
   ```javascript
   const API_BASE_URL = 'http://localhost:3000/api';
   ```
   
   - Change it to (use YOUR Railway URL):
   
   ```javascript
   const API_BASE_URL = 'https://YOUR-RAILWAY-APP.up.railway.app/api';
   ```
   
   - Click "Commit changes"

5. **Deploy**
   - Back in Vercel, click "Deploy"
   - Wait 30-60 seconds
   - You'll see "Congratulations!" when done
   - Click "Visit" to see your site

✅ Your website is live!

---

### Part 4: Test Everything (5 minutes)

1. **Visit Your Site**
   - Vercel gives you a URL like: `your-site.vercel.app`
   - Open it in your browser

2. **Test the Contact Form**
   - Scroll to "Launch Your Offline Pilot"
   - Fill out the form
   - Click "Request a Pilot Plan"
   - You should see a success message

3. **Check Your Email**
   - Look for the confirmation email (check spam folder)
   - You should also receive an internal notification

4. **Check Database**
   - Go back to Railway
   - Click PostgreSQL service → Data
   - Click "Query"
   - Run: `SELECT * FROM pilot_requests;`
   - You should see your test submission

✅ Everything works!

---

## Your Live URLs

After completing these steps, you'll have:

- **Website:** `https://your-site.vercel.app`
- **API:** `https://your-app.up.railway.app`

---

## Use Your Own Domain (Optional)

### Buy a Domain
1. Go to https://namecheap.com
2. Search for your domain (e.g., `offlinemarketing.com`)
3. Purchase (~$10/year)

### Connect to Vercel
1. In Vercel, go to your project → Settings → Domains
2. Add your domain (e.g., `offlinemarketing.com`)
3. Vercel gives you DNS records
4. Go to Namecheap → Domain List → Manage → Advanced DNS
5. Add the records Vercel provided
6. Wait 10-60 minutes for DNS to update

### Update API URL
1. In Vercel Settings → Domains, also add `api.offlinemarketing.com`
2. Point it to your Railway backend
3. Update `index.html` to use `https://api.offlinemarketing.com/api`

---

## Common Issues & Fixes

### "Form submission failed"
- Check your Railway logs (Deployments → View Logs)
- Make sure all environment variables are set correctly
- Verify database migration ran successfully

### "Email not sending"
- Verify SendGrid API key is correct
- Check SendGrid dashboard for sending stats
- Look for emails in spam folder
- Make sure `FROM_EMAIL` is verified in SendGrid

### "CORS error"
- In Railway, update `ALLOWED_ORIGINS`:
  ```
  ALLOWED_ORIGINS=https://your-site.vercel.app,https://offlinemarketing.com
  ```
- Redeploy the backend

### "Database connection error"
- Railway auto-configures `DATABASE_URL`
- Make sure PostgreSQL service is running
- Check Railway logs for specific error

---

## Monitoring Your Site

### Check if site is up
- Use https://uptimerobot.com (free)
- Add your Vercel URL
- Get alerts if site goes down

### View submissions
Railway PostgreSQL → Data → Query:
```sql
SELECT * FROM pilot_requests ORDER BY submitted_at DESC;
```

### View logs
Railway → Your Service → Deployments → View Logs

---

## What's Next?

Now that your site is live, you should:

1. ✅ **Set up a professional email** (not gmail)
   - Use your domain: hello@offlinemarketing.com
   - Google Workspace ($6/month) or Zoho Mail (free)

2. ✅ **Add Google Analytics**
   - Go to https://analytics.google.com
   - Create property
   - Add tracking code to `index.html` before `</head>`:
   ```html
   <!-- Google Analytics -->
   <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
   <script>
     window.dataLayer = window.dataLayer || [];
     function gtag(){dataLayer.push(arguments);}
     gtag('js', new Date());
     gtag('config', 'G-XXXXXXXXXX');
   </script>
   ```

3. ✅ **Set up HubSpot** (optional, for CRM)
   - Create free HubSpot account
   - Get API key
   - Add to Railway environment variables
   - Leads will auto-sync to HubSpot

4. ✅ **Add more cities**
   Railway PostgreSQL → Query:
   ```sql
   INSERT INTO cities (city_name, state, active, launch_date) 
   VALUES ('Chicago', 'IL', true, CURRENT_DATE);
   ```

5. ✅ **Customize the design**
   - Edit `index.html` 
   - Change colors, text, images
   - Commit to GitHub
   - Vercel auto-deploys

---

## Costs Breakdown

| Service | Purpose | Cost |
|---------|---------|------|
| Railway | Backend + Database | $5/month (after free credits) |
| Vercel | Frontend hosting | Free |
| SendGrid | Email sending | Free (100/day) |
| Domain | offlinemarketing.com | $10/year |
| **TOTAL** | | **~$5-10/month** |

---

## Get Help

- **Railway Discord:** https://discord.gg/railway
- **Vercel Discord:** https://vercel.com/discord
- **Stack Overflow:** Tag questions with `node.js`, `postgresql`, `express`

---

## Checklist

- [ ] GitHub repository created
- [ ] Railway backend deployed
- [ ] PostgreSQL database created
- [ ] Database schema imported
- [ ] Environment variables configured
- [ ] SendGrid API key added
- [ ] Vercel frontend deployed
- [ ] API URL updated in frontend
- [ ] Test form submission works
- [ ] Test email delivery works
- [ ] (Optional) Custom domain connected
- [ ] (Optional) Google Analytics added

---

**Congratulations! Your experiential marketing agency website is now live!** 🎉

Total time: ~30 minutes  
Total cost: $0-5/month to start