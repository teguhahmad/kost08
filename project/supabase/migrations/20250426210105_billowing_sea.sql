/*
  # Fix database schema and relationships

  1. New Tables
    - `tenants`
      - `id` (uuid, primary key)
      - `property_id` (uuid, foreign key to properties)
      - `user_id` (uuid, foreign key to auth.users)
      - `status` (text)
      - `start_date` (date)
      - `end_date` (date)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Changes
    - Add `city` column to properties table
    - Add foreign key relationship between properties and auth.users

  3. Security
    - Enable RLS on new tables
    - Add policies for authenticated users
*/

-- Add city column to properties
ALTER TABLE properties 
ADD COLUMN IF NOT EXISTS city text;

-- Create tenants table
CREATE TABLE IF NOT EXISTS tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid REFERENCES properties(id),
  user_id uuid REFERENCES auth.users(id),
  status text NOT NULL,
  start_date date,
  end_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on tenants
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- Add RLS policies for tenants
CREATE POLICY "Users can view tenants for their properties"
  ON tenants
  FOR SELECT
  TO authenticated
  USING (
    property_id IN (
      SELECT id FROM properties 
      WHERE owner_id = auth.uid()
    )
  );

-- Add RLS policies for properties
CREATE POLICY "Users can view their properties"
  ON properties
  FOR SELECT
  TO authenticated
  USING (owner_id = auth.uid());

-- Add foreign key relationship between properties and auth.users
DO $$ 
BEGIN
  -- Check if the foreign key already exists
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'properties_owner_id_fkey'
  ) THEN
    ALTER TABLE properties
    ADD CONSTRAINT properties_owner_id_fkey
    FOREIGN KEY (owner_id) REFERENCES auth.users(id);
  END IF;
END $$;