-- Create schema for ncommon application
CREATE SCHEMA IF NOT EXISTS ncommon;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS ncommon.users (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create profiles table
CREATE TABLE IF NOT EXISTS ncommon.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES ncommon.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create RLS policies
ALTER TABLE ncommon.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ncommon.profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Users can view their own data" ON ncommon.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON ncommon.users
    FOR UPDATE USING (auth.uid() = id);

-- Create policies for profiles table
CREATE POLICY "Profiles are viewable by everyone" ON ncommon.profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON ncommon.profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON ncommon.profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Create function to handle user creation
CREATE OR REPLACE FUNCTION ncommon.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO ncommon.users (id, email)
    VALUES (NEW.id, NEW.email);
    
    INSERT INTO ncommon.profiles (user_id, full_name)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION ncommon.handle_new_user();

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION ncommon.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to tables
CREATE TRIGGER handle_users_updated_at
    BEFORE UPDATE ON ncommon.users
    FOR EACH ROW EXECUTE FUNCTION ncommon.handle_updated_at();

CREATE TRIGGER handle_profiles_updated_at
    BEFORE UPDATE ON ncommon.profiles
    FOR EACH ROW EXECUTE FUNCTION ncommon.handle_updated_at(); 