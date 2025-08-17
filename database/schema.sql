-- Golf Tracker Analytics Database Schema
-- Dieses Schema sollte in Supabase ausgeführt werden

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum for difficulty levels
CREATE TYPE difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced', 'championship');

-- Create golf_courses table
CREATE TABLE golf_courses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    address VARCHAR(300) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(200),
    holes INTEGER NOT NULL CHECK (holes IN (9, 18, 27)),
    par INTEGER NOT NULL CHECK (par >= 27 AND par <= 108),
    yardage INTEGER CHECK (yardage >= 1000 AND yardage <= 8000),
    difficulty difficulty_level NOT NULL,
    green_fee DECIMAL(10, 2) CHECK (green_fee >= 0),
    latitude DECIMAL(10, 8) CHECK (latitude >= -90 AND latitude <= 90),
    longitude DECIMAL(11, 8) CHECK (longitude >= -180 AND longitude <= 180),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_golf_courses_city ON golf_courses(city);
CREATE INDEX idx_golf_courses_country ON golf_courses(country);
CREATE INDEX idx_golf_courses_difficulty ON golf_courses(difficulty);
CREATE INDEX idx_golf_courses_is_active ON golf_courses(is_active);
CREATE INDEX idx_golf_courses_location ON golf_courses(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for automatic updated_at updates
CREATE TRIGGER update_golf_courses_updated_at 
    BEFORE UPDATE ON golf_courses 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data
INSERT INTO golf_courses (
    name, description, address, city, country, postal_code, phone, email, website,
    holes, par, yardage, difficulty, green_fee, latitude, longitude
) VALUES
(
    'Münchener Golf Club',
    'Einer der ältesten und prestigeträchtigsten Golfclubs Deutschlands mit einem anspruchsvollen 18-Loch-Platz.',
    'Golfplatzstraße 1',
    'München',
    'Deutschland',
    '80539',
    '+49 89 123456',
    'info@mgc.de',
    'https://www.mgc.de',
    18,
    72,
    6200,
    'championship',
    95.00,
    48.1351,
    11.5820
),
(
    'Golf Club Berlin-Wannsee',
    'Traditionsreicher Golfplatz am Wannsee mit herrlichem Blick über das Wasser.',
    'Am Golfplatz 5',
    'Berlin',
    'Deutschland',
    '14109',
    '+49 30 987654',
    'info@gc-wannsee.de',
    'https://www.gc-wannsee.de',
    18,
    71,
    5950,
    'advanced',
    75.00,
    52.4167,
    13.1833
),
(
    'Golf Resort Bad Griesbach',
    'Golfresort mit mehreren Plätzen in der idyllischen bayerischen Landschaft.',
    'Golfallee 1',
    'Bad Griesbach',
    'Deutschland',
    '94086',
    '+49 8532 79123',
    'info@golfresort-badgriesbach.de',
    'https://www.golfresort-badgriesbach.de',
    18,
    72,
    6100,
    'intermediate',
    65.00,
    48.4667,
    13.1833
);

-- Create RLS (Row Level Security) policies if needed
-- Uncomment and modify as needed for your security requirements

-- ALTER TABLE golf_courses ENABLE ROW LEVEL SECURITY;

-- Create policy for read access (all users can read all golf courses)
-- CREATE POLICY "Golf courses are viewable by everyone" 
--     ON golf_courses FOR SELECT 
--     USING (true);

-- Create policy for insert/update/delete (only authenticated users)
-- CREATE POLICY "Golf courses are insertable by authenticated users" 
--     ON golf_courses FOR INSERT 
--     TO authenticated 
--     WITH CHECK (true);

-- CREATE POLICY "Golf courses are updatable by authenticated users" 
--     ON golf_courses FOR UPDATE 
--     TO authenticated 
--     USING (true);

-- CREATE POLICY "Golf courses are deletable by authenticated users" 
--     ON golf_courses FOR DELETE 
--     TO authenticated 
--     USING (true);
