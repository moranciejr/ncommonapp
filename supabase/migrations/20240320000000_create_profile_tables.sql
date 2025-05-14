-- Create interests table
CREATE TABLE IF NOT EXISTS interests (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    category TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create user_interests junction table
CREATE TABLE IF NOT EXISTS user_interests (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    interest_id BIGINT REFERENCES interests(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, interest_id)
);

-- Add profile fields to users table
ALTER TABLE auth.users
ADD COLUMN IF NOT EXISTS full_name TEXT,
ADD COLUMN IF NOT EXISTS dob DATE,
ADD COLUMN IF NOT EXISTS mood TEXT,
ADD COLUMN IF NOT EXISTS profile_complete BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;

-- Insert default interests with categories
INSERT INTO interests (name, category) VALUES
    -- Sports & Recreation
    ('Bowling', 'Sports'),
    ('Golf', 'Sports'),
    ('Working Out', 'Sports'),
    ('Hiking', 'Outdoors'),
    ('Swimming', 'Sports'),
    ('Tennis', 'Sports'),
    ('Basketball', 'Sports'),
    ('Soccer', 'Sports'),
    ('Yoga', 'Fitness'),
    ('Running', 'Fitness'),
    
    -- Entertainment
    ('Movies', 'Entertainment'),
    ('Gaming', 'Entertainment'),
    ('Live Music', 'Entertainment'),
    ('Theater', 'Entertainment'),
    ('Concerts', 'Entertainment'),
    ('Reading', 'Entertainment'),
    ('Art', 'Entertainment'),
    
    -- Social
    ('Dining Out', 'Social'),
    ('Cooking', 'Social'),
    ('Coffee', 'Social'),
    ('Travel', 'Social'),
    ('Photography', 'Social'),
    ('Dancing', 'Social'),
    ('Board Games', 'Social'),
    
    -- Tech & Learning
    ('Coding', 'Technology'),
    ('AI', 'Technology'),
    ('Science', 'Learning'),
    ('History', 'Learning'),
    ('Languages', 'Learning'),
    ('Writing', 'Learning')
ON CONFLICT (name) DO NOTHING;

-- Create RLS policies
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own interests"
    ON user_interests FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own interests"
    ON user_interests FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own interests"
    ON user_interests FOR DELETE
    USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for interests table
CREATE TRIGGER update_interests_updated_at
    BEFORE UPDATE ON interests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column(); 