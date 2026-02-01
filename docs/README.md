# Offline Acquisition Platform - Backend

Complete backend infrastructure for an experiential marketing agency platform with lead capture, CRM integration, and campaign management.

## Architecture Overview

```
┌─────────────────┐
│   Frontend      │
│   (HTML/JS)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Express API   │
│   (Node.js)     │
└────────┬────────┘
         │
    ┌────┴────┬──────────┬────────────┐
    ▼         ▼          ▼            ▼
┌────────┐ ┌────────┐ ┌──────┐  ┌─────────┐
│ PostgreSQL│ │ Email  │ │ CRM  │  │ Storage │
│ Database  │ │Service │ │(HubSpot)│ │ (S3)   │
└───────────┘ └────────┘ └──────┘  └─────────┘
```

## Tech Stack

- **Backend**: Node.js + Express
- **Database**: PostgreSQL (easily swappable to MongoDB, MySQL, etc.)
- **Email**: Nodemailer with SendGrid/Mailgun/AWS SES
- **CRM**: HubSpot API (swappable to Salesforce, etc.)
- **Validation**: express-validator
- **Security**: helmet, rate limiting, CORS
- **Payments** (optional): Stripe

## Features

### Core API Endpoints

1. **Pilot Request Form** (`POST /api/pilot-request`)
   - Validates and stores lead information
   - Sends confirmation email to user
   - Notifies internal team
   - Syncs contact to CRM

2. **Cities API** (`GET /api/cities`)
   - Returns list of active cities for dynamic population

3. **Stats API** (`GET /api/stats`)
   - Campaign performance metrics for homepage

4. **Newsletter** (`POST /api/newsletter`)
   - Email list subscription

5. **Contact Form** (`POST /api/contact`)
   - General inquiries

### Admin Endpoints (Protected)

- `GET /api/admin/requests` - List all pilot requests
- `PATCH /api/admin/requests/:id` - Update request status

## Setup Instructions

### 1. Prerequisites

- Node.js 18+ and npm
- PostgreSQL 14+ (or your preferred database)
- SMTP email service account (SendGrid, Mailgun, AWS SES, etc.)
- Optional: HubSpot account for CRM integration

### 2. Installation

```bash
# Clone repository
git clone <your-repo>
cd offline-acquisition-backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env
```

### 3. Database Setup

```bash
# Create database
createdb offline_acquisition

# Run schema
psql -d offline_acquisition -f schema.sql

# Verify tables created
psql -d offline_acquisition -c "\dt"
```

### 4. Configure Environment Variables

Edit `.env` file with your credentials:

```env
DATABASE_URL=postgresql://user:password@localhost:5432/offline_acquisition
SMTP_HOST=smtp.sendgrid.net
SMTP_USER=apikey
SMTP_PASS=your_api_key
FROM_EMAIL=hello@yourcompany.com
INTERNAL_EMAIL=team@yourcompany.com
HUBSPOT_API_KEY=your_hubspot_key
ADMIN_API_KEY=generate_secure_random_key
```

### 5. Start Server

```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

Server will run on `http://localhost:3000`

### 6. Test API

```bash
# Health check
curl http://localhost:3000/api/health

# Test form submission
curl -X POST http://localhost:3000/api/pilot-request \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "brand": "Test Brand",
    "category": "coffee-beverage",
    "city": "New York",
    "email": "john@test.com",
    "goal": "trial"
  }'
```

## Database Schema

### Key Tables

- **pilot_requests** - Lead capture from website forms
- **campaigns** - Active and completed marketing campaigns
- **brands** - Client companies
- **campaign_locations** - Geographic campaign execution
- **leads** - Individual leads captured during campaigns
- **ambassadors** - Field staff database
- **campaign_staffing** - Shift scheduling and performance

### Relationships

```
brands (1) ──→ (N) campaigns
campaigns (1) ──→ (N) campaign_locations
campaigns (1) ──→ (N) leads
ambassadors (N) ──→ (N) campaign_staffing
```

## Email Templates

Email notifications are sent for:

1. **User Confirmation** - Sent to user after pilot request
2. **Internal Notification** - Sent to team when new request arrives
3. **Status Updates** - Can be triggered when request status changes

Customize email templates in `server.js` under the nodemailer sections.

## CRM Integration

### HubSpot

Currently configured to sync contacts to HubSpot. When a pilot request is submitted:

1. Contact is created in HubSpot with custom properties
2. Lead source is automatically tagged
3. Campaign goal and product category are tracked

### Switching to Salesforce

Replace the HubSpot client code with:

```javascript
const jsforce = require('jsforce');
const conn = new jsforce.Connection({
  loginUrl: 'https://login.salesforce.com'
});

await conn.login(username, password);
await conn.sobject('Lead').create({
  FirstName: firstName,
  LastName: lastName,
  Email: email,
  Company: brand,
  // ... other fields
});
```

## Security Features

- **Helmet.js** - Security headers
- **Rate Limiting** - Prevents abuse (100 requests/15min general, 5 forms/hour)
- **Input Validation** - express-validator on all inputs
- **SQL Injection Protection** - Parameterized queries
- **XSS Protection** - Built into helmet
- **CORS** - Configurable allowed origins

## Deployment

### Environment Variables for Production

Ensure these are set in your production environment:

```env
NODE_ENV=production
DATABASE_URL=your_production_db_url
SMTP_HOST=your_smtp_host
# ... all other vars from .env.example
```

### Deployment Platforms

**Heroku:**
```bash
heroku create your-app-name
heroku addons:create heroku-postgresql:hobby-dev
git push heroku main
```

**AWS EC2 / DigitalOcean:**
- Use PM2 for process management
- Set up nginx as reverse proxy
- Configure SSL with Let's Encrypt

**Vercel / Railway / Render:**
- Connect GitHub repository
- Configure environment variables in dashboard
- Deploy automatically on push

### Database Migrations

For production updates:

```sql
-- Add new columns
ALTER TABLE pilot_requests ADD COLUMN phone VARCHAR(20);

-- Create indexes for performance
CREATE INDEX idx_pilot_requests_brand ON pilot_requests(brand);
```

## Monitoring & Analytics

### Recommended Additions

1. **Error Tracking**: Sentry, Rollbar
2. **Performance**: New Relic, DataDog
3. **Logging**: Winston, Pino
4. **Metrics**: Prometheus + Grafana

### Example Logging Setup

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

## Testing

```bash
# Run tests
npm test

# Run with coverage
npm test -- --coverage
```

## API Documentation

### POST /api/pilot-request

**Request:**
```json
{
  "name": "Sarah Johnson",
  "brand": "CloudBrew Coffee",
  "category": "coffee-beverage",
  "city": "Austin",
  "email": "sarah@cloudbrew.com",
  "goal": "trial"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Pilot request submitted successfully",
  "requestId": 42
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Failed to submit request",
  "errors": [
    {
      "field": "email",
      "message": "Valid email is required"
    }
  ]
}
```

### GET /api/cities

**Response:**
```json
[
  {
    "city_name": "New York",
    "state": "NY",
    "active": true
  },
  {
    "city_name": "San Francisco",
    "state": "CA",
    "active": true
  }
]
```

### GET /api/stats

**Response:**
```json
{
  "brands_served": 24,
  "total_samples": 45000,
  "total_leads": 8500,
  "cities_active": 5,
  "avg_conversion": 18.89
}
```

## Extending the Platform

### Adding Payment Processing

```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

app.post('/api/checkout', async (req, res) => {
  const session = await stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    line_items: [{
      price_data: {
        currency: 'usd',
        product_data: { name: 'City Launch Program' },
        unit_amount: 15000_00,
      },
      quantity: 1,
    }],
    mode: 'payment',
    success_url: `${YOUR_DOMAIN}/success`,
    cancel_url: `${YOUR_DOMAIN}/cancel`,
  });
  
  res.json({ id: session.id });
});
```

### Adding File Uploads

```javascript
const multer = require('multer');
const AWS = require('aws-sdk');

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

const upload = multer({ storage: multer.memoryStorage() });

app.post('/api/upload', upload.single('file'), async (req, res) => {
  const params = {
    Bucket: process.env.S3_BUCKET_NAME,
    Key: req.file.originalname,
    Body: req.file.buffer
  };
  
  const result = await s3.upload(params).promise();
  res.json({ url: result.Location });
});
```

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
pg_isready

# Test connection
psql -d offline_acquisition -c "SELECT 1"

# Check connection string format
# postgresql://[user]:[password]@[host]:[port]/[database]
```

### Email Not Sending

- Verify SMTP credentials
- Check firewall/security groups allow outbound port 587
- Test SMTP connection separately
- Check spam folder

### Rate Limiting Too Strict

Adjust in server.js:
```javascript
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200 // Increase from 100
});
```

## License

MIT

## Support

For questions or issues, contact: team@yourcompany.com
