/*
  # Add user_list table for user management

  1. New Tables
    - `user_list`
      - `id` (uuid, primary key)
      - `email` (text, unique)
      - `password` (text)
      - `name` (text)
      - `role` (enum: superadmin, admin, user)
      - `status` (enum: active, inactive)
      - `last_login` (timestamptz)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS
    - Add policies for user management
    - Hash passwords using pgcrypto
*/

-- Create role enum type
CREATE TYPE user_list_role AS ENUM ('superadmin', 'admin', 'user');

-- Create status enum type
CREATE TYPE user_list_status AS ENUM ('active', 'inactive');

-- Create user_list table
CREATE TABLE IF NOT EXISTS user_list (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  password text NOT NULL,
  name text NOT NULL,
  role user_list_role NOT NULL DEFAULT 'user',
  status user_list_status NOT NULL DEFAULT 'active',
  last_login timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE user_list ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_list_email ON user_list(email);
CREATE INDEX IF NOT EXISTS idx_user_list_role ON user_list(role);
CREATE INDEX IF NOT EXISTS idx_user_list_status ON user_list(status);

-- Create policies
CREATE POLICY "Users can read their own data"
  ON user_list
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Superadmins can manage all users"
  ON user_list
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_list
      WHERE id = auth.uid()
      AND role = 'superadmin'
      AND status = 'active'
    )
  );

-- Create function to hash password
CREATE OR REPLACE FUNCTION hash_password(password text)
RETURNS text AS $$
BEGIN
  RETURN crypt(password, gen_salt('bf'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to verify password
CREATE OR REPLACE FUNCTION verify_password(email text, password text)
RETURNS TABLE (
  id uuid,
  role user_list_role,
  name text
) AS $$
BEGIN
  RETURN QUERY
  SELECT ul.id, ul.role, ul.name
  FROM user_list ul
  WHERE ul.email = verify_password.email
  AND ul.password = crypt(verify_password.password, ul.password)
  AND ul.status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert default superadmin
INSERT INTO user_list (
  email,
  password,
  name,
  role,
  status
) VALUES (
  'admin@kostmanager.com',
  hash_password('Admin123!'),
  'Super Admin',
  'superadmin',
  'active'
) ON CONFLICT (email) DO NOTHING;

-- Create trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_list_updated_at
  BEFORE UPDATE ON user_list
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create function to update last_login
CREATE OR REPLACE FUNCTION update_last_login(user_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE user_list
  SET last_login = now()
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;