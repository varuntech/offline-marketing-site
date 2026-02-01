-- Database Schema for Offline Acquisition Platform
-- PostgreSQL

-- ============================================
-- PILOT REQUESTS TABLE
-- ============================================
CREATE TABLE pilot_requests (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL,
    city VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    goal VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'new',
    notes TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    -- Indexes
    INDEX idx_status (status),
    INDEX idx_submitted_at (submitted_at),
    INDEX idx_email (email),
    INDEX idx_city (city)
);

-- ============================================
-- CITIES TABLE
-- ============================================
CREATE TABLE cities (
    id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    active BOOLEAN DEFAULT true,
    launch_date DATE,
    market_size VARCHAR(50),
    avg_foot_traffic INTEGER,
    permit_difficulty VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(city_name, state)
);

-- Insert initial cities
INSERT INTO cities (city_name, state, active, launch_date) VALUES
    ('New York', 'NY', true, '2024-01-15'),
    ('San Francisco', 'CA', true, '2024-02-01'),
    ('Austin', 'TX', true, '2024-03-10'),
    ('Seattle', 'WA', true, '2024-04-05'),
    ('Los Angeles', 'CA', true, '2024-05-20');

-- ============================================
-- CAMPAIGNS TABLE
-- ============================================
CREATE TABLE campaigns (
    id SERIAL PRIMARY KEY,
    brand_id INTEGER REFERENCES brands(id),
    brand_name VARCHAR(255) NOT NULL,
    campaign_name VARCHAR(255) NOT NULL,
    campaign_type VARCHAR(50) NOT NULL, -- 'sampling', 'lead-capture', 'city-launch'
    city VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'planned', -- planned, active, completed, cancelled
    
    -- Performance metrics
    samples_distributed INTEGER DEFAULT 0,
    leads_captured INTEGER DEFAULT 0,
    first_purchases INTEGER DEFAULT 0,
    total_cost DECIMAL(10, 2),
    
    -- Calculated metrics
    cost_per_lead DECIMAL(10, 2),
    cost_per_sample DECIMAL(10, 2),
    conversion_rate DECIMAL(5, 2),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_status (status),
    INDEX idx_city (city),
    INDEX idx_dates (start_date, end_date)
);

-- ============================================
-- BRANDS TABLE
-- ============================================
CREATE TABLE brands (
    id SERIAL PRIMARY KEY,
    brand_name VARCHAR(255) NOT NULL UNIQUE,
    company_name VARCHAR(255),
    category VARCHAR(50),
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    website VARCHAR(255),
    
    -- Account info
    account_status VARCHAR(50) DEFAULT 'lead', -- lead, active, paused, churned
    lifetime_value DECIMAL(10, 2) DEFAULT 0,
    total_campaigns INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_status (account_status),
    INDEX idx_category (category)
);

-- ============================================
-- CAMPAIGN LOCATIONS TABLE
-- ============================================
CREATE TABLE campaign_locations (
    id SERIAL PRIMARY KEY,
    campaign_id INTEGER REFERENCES campaigns(id) ON DELETE CASCADE,
    location_name VARCHAR(255) NOT NULL,
    location_type VARCHAR(50), -- mall, street, park, transit, event
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    
    -- Location performance
    foot_traffic_estimate INTEGER,
    samples_distributed INTEGER DEFAULT 0,
    leads_captured INTEGER DEFAULT 0,
    
    -- Logistics
    permit_required BOOLEAN DEFAULT true,
    permit_status VARCHAR(50),
    permit_cost DECIMAL(10, 2),
    
    active_dates DATERANGE,
    
    INDEX idx_campaign (campaign_id),
    INDEX idx_city (city)
);

-- ============================================
-- LEADS TABLE
-- ============================================
CREATE TABLE leads (
    id SERIAL PRIMARY KEY,
    campaign_id INTEGER REFERENCES campaigns(id),
    campaign_location_id INTEGER REFERENCES campaign_locations(id),
    
    -- Lead info
    email VARCHAR(255),
    phone VARCHAR(20),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    zip_code VARCHAR(10),
    
    -- Capture details
    capture_method VARCHAR(50), -- qr, sms, email, form
    opted_in_email BOOLEAN DEFAULT false,
    opted_in_sms BOOLEAN DEFAULT false,
    
    -- Conversion tracking
    coupon_code VARCHAR(50),
    coupon_redeemed BOOLEAN DEFAULT false,
    redemption_date TIMESTAMP,
    first_purchase_amount DECIMAL(10, 2),
    
    captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_campaign (campaign_id),
    INDEX idx_email (email),
    INDEX idx_captured_at (captured_at),
    INDEX idx_redeemed (coupon_redeemed)
);

-- ============================================
-- AMBASSADORS TABLE
-- ============================================
CREATE TABLE ambassadors (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    
    -- Profile
    city VARCHAR(100),
    state VARCHAR(50),
    availability TEXT, -- JSON or text description
    hourly_rate DECIMAL(10, 2),
    
    -- Performance
    total_campaigns INTEGER DEFAULT 0,
    total_samples_distributed INTEGER DEFAULT 0,
    total_leads_captured INTEGER DEFAULT 0,
    avg_rating DECIMAL(3, 2),
    
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, suspended
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_city (city),
    INDEX idx_status (status)
);

-- ============================================
-- CAMPAIGN STAFFING TABLE
-- ============================================
CREATE TABLE campaign_staffing (
    id SERIAL PRIMARY KEY,
    campaign_id INTEGER REFERENCES campaigns(id) ON DELETE CASCADE,
    campaign_location_id INTEGER REFERENCES campaign_locations(id),
    ambassador_id INTEGER REFERENCES ambassadors(id),
    
    shift_date DATE NOT NULL,
    shift_start TIME NOT NULL,
    shift_end TIME NOT NULL,
    status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, completed, cancelled, no-show
    
    -- Performance
    samples_distributed INTEGER,
    leads_captured INTEGER,
    hours_worked DECIMAL(5, 2),
    payment_amount DECIMAL(10, 2),
    
    notes TEXT,
    
    INDEX idx_campaign (campaign_id),
    INDEX idx_ambassador (ambassador_id),
    INDEX idx_date (shift_date)
);

-- ============================================
-- NEWSLETTER SUBSCRIBERS TABLE
-- ============================================
CREATE TABLE newsletter_subscribers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    unsubscribed_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active', -- active, unsubscribed
    
    INDEX idx_email (email),
    INDEX idx_status (status)
);

-- ============================================
-- CONTACT MESSAGES TABLE
-- ============================================
CREATE TABLE contact_messages (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'new', -- new, read, responded, archived
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_status (status),
    INDEX idx_submitted_at (submitted_at)
);

-- ============================================
-- ANALYTICS EVENTS TABLE
-- ============================================
CREATE TABLE analytics_events (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    user_id VARCHAR(255),
    session_id VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    referrer TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_event_type (event_type),
    INDEX idx_created_at (created_at),
    INDEX idx_user_id (user_id)
);

-- ============================================
-- VIEWS FOR REPORTING
-- ============================================

-- Campaign performance summary
CREATE VIEW campaign_performance AS
SELECT 
    c.id,
    c.campaign_name,
    c.brand_name,
    c.city,
    c.campaign_type,
    c.start_date,
    c.end_date,
    c.status,
    c.samples_distributed,
    c.leads_captured,
    c.first_purchases,
    c.total_cost,
    CASE 
        WHEN c.leads_captured > 0 THEN c.total_cost / c.leads_captured 
        ELSE 0 
    END as cost_per_lead,
    CASE 
        WHEN c.samples_distributed > 0 THEN c.total_cost / c.samples_distributed 
        ELSE 0 
    END as cost_per_sample,
    CASE 
        WHEN c.samples_distributed > 0 THEN (c.leads_captured::float / c.samples_distributed * 100) 
        ELSE 0 
    END as sample_to_lead_rate,
    CASE 
        WHEN c.leads_captured > 0 THEN (c.first_purchases::float / c.leads_captured * 100) 
        ELSE 0 
    END as lead_to_purchase_rate
FROM campaigns c;

-- Ambassador performance
CREATE VIEW ambassador_performance AS
SELECT 
    a.id,
    a.first_name,
    a.last_name,
    a.email,
    a.city,
    COUNT(DISTINCT cs.campaign_id) as campaigns_worked,
    SUM(cs.samples_distributed) as total_samples,
    SUM(cs.leads_captured) as total_leads,
    CASE 
        WHEN SUM(cs.samples_distributed) > 0 
        THEN (SUM(cs.leads_captured)::float / SUM(cs.samples_distributed) * 100) 
        ELSE 0 
    END as conversion_rate,
    SUM(cs.hours_worked) as total_hours,
    SUM(cs.payment_amount) as total_earned
FROM ambassadors a
LEFT JOIN campaign_staffing cs ON a.id = cs.ambassador_id
WHERE cs.status = 'completed'
GROUP BY a.id, a.first_name, a.last_name, a.email, a.city;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Update campaign metrics from leads
CREATE OR REPLACE FUNCTION update_campaign_metrics()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE campaigns 
    SET 
        leads_captured = (SELECT COUNT(*) FROM leads WHERE campaign_id = NEW.campaign_id),
        first_purchases = (SELECT COUNT(*) FROM leads WHERE campaign_id = NEW.campaign_id AND coupon_redeemed = true),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.campaign_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_campaign_on_lead_insert
AFTER INSERT ON leads
FOR EACH ROW
EXECUTE FUNCTION update_campaign_metrics();

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Sample brand
INSERT INTO brands (brand_name, company_name, category, contact_name, contact_email, account_status)
VALUES 
    ('CloudBrew Coffee', 'CloudBrew Inc.', 'coffee-beverage', 'Sarah Johnson', 'sarah@cloudbrew.com', 'active'),
    ('GlowUp Skincare', 'GlowUp Beauty Co.', 'personal-care', 'Mike Chen', 'mike@glowup.com', 'active');

-- Sample campaign
INSERT INTO campaigns (brand_id, brand_name, campaign_name, campaign_type, city, start_date, end_date, status, total_cost)
VALUES 
    (1, 'CloudBrew Coffee', 'NYC Cold Brew Launch', 'city-launch', 'New York', '2026-02-15', '2026-03-15', 'active', 15000.00);

-- Indexes for performance
CREATE INDEX idx_campaigns_dates ON campaigns(start_date, end_date);
CREATE INDEX idx_leads_campaign_date ON leads(campaign_id, captured_at);
CREATE INDEX idx_campaign_locations_campaign ON campaign_locations(campaign_id);

-- Comments
COMMENT ON TABLE pilot_requests IS 'Stores all incoming pilot program requests from the website';
COMMENT ON TABLE campaigns IS 'Main campaigns table tracking all field marketing activations';
COMMENT ON TABLE leads IS 'Individual leads captured during campaigns with conversion tracking';
COMMENT ON TABLE ambassadors IS 'Brand ambassadors/field staff database';
COMMENT ON TABLE campaign_staffing IS 'Junction table connecting campaigns, locations, and ambassadors';
