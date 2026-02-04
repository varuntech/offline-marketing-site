# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Node.js/Express backend with static HTML frontend for an experiential marketing agency platform. Handles lead capture, CRM integration (HubSpot), and email notifications.

## Development Commands

All commands run from the `backend/` directory:

```bash
npm run dev          # Start with auto-reload (nodemon)
npm start            # Production mode
npm test             # Run Jest tests with coverage
npm run lint         # ESLint
npm run db:migrate   # Run database migrations
npm run db:seed      # Seed database
```

## Architecture

```
frontend/index.html  →  Express API (backend/server.js)  →  PostgreSQL
                                    ↓
                         Email (Nodemailer) + CRM (HubSpot)
```

**Key pattern**: Form submissions save to database immediately, then process emails/CRM asynchronously via `setImmediate()` to avoid blocking the response.

## Database

PostgreSQL with two core tables (see `backend/schema.sql`):
- `pilot_requests` - Lead capture from website forms
- `cities` - Available cities for campaigns

Setup: `psql -d offline_acquisition -f backend/schema.sql`

## API Endpoints

**Public:**
- `POST /api/pilot-request` - Submit lead form (rate limited: 5/hour)
- `GET /api/cities` - Active cities list
- `GET /api/stats` - Campaign metrics
- `POST /api/newsletter` - Email subscription
- `POST /api/contact` - Contact form
- `GET /api/health` - Health check

**Admin (requires `x-api-key` header):**
- `GET /api/admin/requests` - List requests (supports `?status=`, `?page=`, `?limit=`)
- `PATCH /api/admin/requests/:id` - Update status/notes

## Environment Variables

See `backend/.env.example`. Required for basic operation:
- `DATABASE_URL` - PostgreSQL connection string
- `ADMIN_API_KEY` - Admin endpoint authentication

Optional integrations:
- `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`, `FROM_EMAIL`, `INTERNAL_EMAIL` - Email
- `HUBSPOT_API_KEY` - CRM sync

## Valid Form Values

Categories: `coffee-beverage`, `food-snacks`, `personal-care`, `wellness`, `beauty`, `other`

Goals: `trial`, `leads`, `launch`, `acquisition`, `research`
