const express = require('express');
const cors = require('cors');
const { body, validationResult } = require('express-validator');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
});

const formLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 5, // limit each IP to 5 form submissions per hour
    message: 'Too many submissions from this IP, please try again later.'
});

app.use('/api/', limiter);

// Database connection (PostgreSQL example - you can swap for MongoDB, MySQL, etc.)
const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Email service integration (using Nodemailer with SendGrid/Mailgun/SES)
const nodemailer = require('nodemailer');

// Create transporter (only if SMTP credentials are provided)
let transporter = null;
if (process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS) {
    transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT || 587,
        secure: process.env.SMTP_PORT == 465, // true for 465, false for other ports
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    });
}

// CRM Integration (example with HubSpot - can be swapped)
let hubspotClient = null;
if (process.env.HUBSPOT_API_KEY) {
    const hubspot = require('@hubspot/api-client');
    hubspotClient = new hubspot.Client({ accessToken: process.env.HUBSPOT_API_KEY });
}

// ============================================
// API ENDPOINTS
// ============================================

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Submit pilot request form
app.post('/api/pilot-request', 
    formLimiter,
    [
        body('name').trim().notEmpty().withMessage('Name is required'),
        body('brand').trim().notEmpty().withMessage('Brand name is required'),
        body('category').isIn([
            'coffee-beverage', 
            'food-snacks', 
            'personal-care', 
            'wellness', 
            'beauty', 
            'other'
        ]).withMessage('Invalid category'),
        body('city').trim().notEmpty().withMessage('Target city is required'),
        body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
        body('goal').isIn([
            'trial', 
            'leads', 
            'launch', 
            'acquisition', 
            'research'
        ]).withMessage('Invalid goal')
    ],
    async (req, res) => {
        // Validate input
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { name, brand, category, city, email, goal } = req.body;

        try {
            // 1. Save to database
            const result = await pool.query(
                `INSERT INTO pilot_requests 
                (name, brand, category, city, email, goal, submitted_at, ip_address, user_agent) 
                VALUES ($1, $2, $3, $4, $5, $6, NOW(), $7, $8) 
                RETURNING id`,
                [
                    name, 
                    brand, 
                    category, 
                    city, 
                    email, 
                    goal,
                    req.ip,
                    req.get('user-agent')
                ]
            );

            const requestId = result.rows[0].id;

            // 2. Send confirmation email to user
            if (transporter) {
                try {
                    await transporter.sendMail({
                        from: process.env.FROM_EMAIL,
                        to: email,
                        subject: 'Your Offline Pilot Request - Next Steps',
                        html: `
                            <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
                                <h2>Thanks for your interest, ${name}!</h2>
                                <p>We received your pilot request for <strong>${brand}</strong> in ${city}.</p>
                                
                                <div style="background: #f5f5f5; padding: 20px; margin: 20px 0;">
                                    <h3>What happens next:</h3>
                                    <ol>
                                        <li>Our team will review your brand and target market</li>
                                        <li>We'll prepare a custom pilot plan with locations, timeline, and pricing</li>
                                        <li>You'll receive a detailed proposal within 48 hours</li>
                                    </ol>
                                </div>
                                
                                <p><strong>Your Request ID:</strong> #${requestId}</p>
                                
                                <p>Questions? Reply to this email or call us at (555) 123-4567.</p>
                                
                                <p>Best,<br>The Offline Team</p>
                            </div>
                        `
                    });
                } catch (emailError) {
                    console.error('Error sending user confirmation email:', emailError);
                    // Don't fail the request if email fails
                }
            }

            // 3. Send notification to internal team
            if (transporter) {
                try {
                    await transporter.sendMail({
                        from: process.env.FROM_EMAIL,
                        to: process.env.INTERNAL_EMAIL,
                        subject: `New Pilot Request: ${brand} - ${city}`,
                        html: `
                            <h2>New Pilot Request Received</h2>
                            <p><strong>Request ID:</strong> #${requestId}</p>
                            <p><strong>Brand:</strong> ${brand}</p>
                            <p><strong>Contact:</strong> ${name} (${email})</p>
                            <p><strong>Category:</strong> ${category}</p>
                            <p><strong>City:</strong> ${city}</p>
                            <p><strong>Goal:</strong> ${goal}</p>
                            <p><strong>Submitted:</strong> ${new Date().toISOString()}</p>
                            
                            <a href="${process.env.ADMIN_URL || 'http://localhost:3000'}/requests/${requestId}" 
                               style="display: inline-block; padding: 12px 24px; background: #000; color: #fff; text-decoration: none; margin-top: 20px;">
                                View in Dashboard
                            </a>
                        `
                    });
                } catch (emailError) {
                    console.error('Error sending internal notification email:', emailError);
                    // Don't fail the request if email fails
                }
            }

            // 4. Create contact in CRM (HubSpot example)
            if (hubspotClient) {
                try {
                    await hubspotClient.crm.contacts.basicApi.create({
                        properties: {
                            email: email,
                            firstname: name.split(' ')[0],
                            lastname: name.split(' ').slice(1).join(' ') || name.split(' ')[0],
                            company: brand,
                            city: city,
                            lead_source: 'Website Pilot Request',
                            product_category: category,
                            campaign_goal: goal
                        }
                    });
                } catch (crmError) {
                    console.error('CRM sync error:', crmError);
                    // Don't fail the request if CRM fails
                }
            }

            // 5. Send success response
            res.status(201).json({
                success: true,
                message: 'Pilot request submitted successfully',
                requestId: requestId
            });

        } catch (error) {
            console.error('Error processing pilot request:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to submit request. Please try again or contact us directly.'
            });
        }
    }
);

// Get available cities (for dynamic population)
app.get('/api/cities', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT city_name, state, active FROM cities WHERE active = true ORDER BY city_name'
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching cities:', error);
        res.status(500).json({ error: 'Failed to fetch cities' });
    }
});

// Get campaign stats (for homepage metrics)
app.get('/api/stats', async (req, res) => {
    try {
        const stats = await pool.query(`
            SELECT 
                COUNT(DISTINCT brand_id) as brands_served,
                SUM(samples_distributed) as total_samples,
                SUM(leads_captured) as total_leads,
                COUNT(DISTINCT city) as cities_active,
                ROUND(AVG(conversion_rate), 2) as avg_conversion
            FROM campaigns 
            WHERE status = 'completed'
        `);
        
        res.json(stats.rows[0]);
    } catch (error) {
        console.error('Error fetching stats:', error);
        res.status(500).json({ error: 'Failed to fetch stats' });
    }
});

// Newsletter signup
app.post('/api/newsletter',
    formLimiter,
    [
        body('email').isEmail().normalizeEmail().withMessage('Valid email required')
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { email } = req.body;

        try {
            await pool.query(
                'INSERT INTO newsletter_subscribers (email, subscribed_at) VALUES ($1, NOW()) ON CONFLICT (email) DO NOTHING',
                [email]
            );

            // Add to email marketing platform (e.g., Mailchimp, SendGrid)
            // Implementation depends on your ESP

            res.json({ success: true, message: 'Subscribed successfully' });
        } catch (error) {
            console.error('Newsletter signup error:', error);
            res.status(500).json({ error: 'Subscription failed' });
        }
    }
);

// Contact form (general inquiries)
app.post('/api/contact',
    formLimiter,
    [
        body('name').trim().notEmpty(),
        body('email').isEmail().normalizeEmail(),
        body('message').trim().notEmpty().isLength({ min: 10 })
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { name, email, message } = req.body;

        try {
            await pool.query(
                'INSERT INTO contact_messages (name, email, message, submitted_at) VALUES ($1, $2, $3, NOW())',
                [name, email, message]
            );

            if (transporter) {
                try {
                    await transporter.sendMail({
                        from: process.env.FROM_EMAIL,
                        to: process.env.INTERNAL_EMAIL,
                        subject: `Contact Form: ${name}`,
                        text: `From: ${name} (${email})\n\n${message}`
                    });
                } catch (emailError) {
                    console.error('Error sending contact form email:', emailError);
                }
            }

            res.json({ success: true });
        } catch (error) {
            console.error('Contact form error:', error);
            res.status(500).json({ error: 'Failed to send message' });
        }
    }
);

// ============================================
// ADMIN ENDPOINTS (Protected)
// ============================================

// Simple API key authentication middleware
const authenticateAdmin = (req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    if (apiKey === process.env.ADMIN_API_KEY) {
        next();
    } else {
        res.status(401).json({ error: 'Unauthorized' });
    }
};

// Get all pilot requests (admin only)
app.get('/api/admin/requests', authenticateAdmin, async (req, res) => {
    try {
        const { status, page = 1, limit = 50 } = req.query;
        const offset = (page - 1) * limit;

        let query = 'SELECT * FROM pilot_requests';
        const params = [];

        if (status) {
            query += ' WHERE status = $1';
            params.push(status);
        }

        query += ' ORDER BY submitted_at DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
        params.push(limit, offset);

        const result = await pool.query(query, params);
        const countResult = await pool.query('SELECT COUNT(*) FROM pilot_requests');

        res.json({
            requests: result.rows,
            total: parseInt(countResult.rows[0].count),
            page: parseInt(page),
            limit: parseInt(limit)
        });
    } catch (error) {
        console.error('Error fetching requests:', error);
        res.status(500).json({ error: 'Failed to fetch requests' });
    }
});

// Update request status (admin only)
app.patch('/api/admin/requests/:id', authenticateAdmin, async (req, res) => {
    const { id } = req.params;
    const { status, notes } = req.body;

    try {
        await pool.query(
            'UPDATE pilot_requests SET status = $1, notes = $2, updated_at = NOW() WHERE id = $3',
            [status, notes, id]
        );

        res.json({ success: true });
    } catch (error) {
        console.error('Error updating request:', error);
        res.status(500).json({ error: 'Update failed' });
    }
});

// ============================================
// ERROR HANDLING
// ============================================

app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// ============================================
// START SERVER
// ============================================

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;