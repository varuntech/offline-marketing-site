-- MINIMAL SCHEMA - Just what you need for the form to work
-- Copy and paste this entire file into Railway's SQL console

-- Create pilot_requests table (the main one you need)
CREATE TABLE IF NOT EXISTS pilot_requests (
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
    user_agent TEXT
);

-- Create cities table (for the cities API)
CREATE TABLE IF NOT EXISTS cities (
    id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    active BOOLEAN DEFAULT true,
    launch_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert the 5 cities
INSERT INTO cities (city_name, state, active, launch_date) VALUES
    ('New York', 'NY', true, '2024-01-15'),
    ('San Francisco', 'CA', true, '2024-02-01'),
    ('Austin', 'TX', true, '2024-03-10'),
    ('Seattle', 'WA', true, '2024-04-05'),
    ('Los Angeles', 'CA', true, '2024-05-20')
ON CONFLICT DO NOTHING;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_pilot_requests_submitted ON pilot_requests(submitted_at);
CREATE INDEX IF NOT EXISTS idx_pilot_requests_email ON pilot_requests(email);

-- Verify tables were created
SELECT 'pilot_requests table created' as status, COUNT(*) as row_count FROM pilot_requests
UNION ALL
SELECT 'cities table created' as status, COUNT(*) as row_count FROM cities;
