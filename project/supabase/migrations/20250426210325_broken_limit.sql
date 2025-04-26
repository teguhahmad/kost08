/*
  # Fix database schema and relationships

  1. Changes
    - Add city column to properties if not exists
    - Create tenants table if not exists
    - Add RLS policies with proper checks
    - Add foreign key relationship between properties and auth.users
*/

-- Add city column to properties
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'properties' 
    AND column_name = 'city'
  ) THEN
    ALTER TABLE properties ADD COLUMN city text;
  END IF;
END $$;

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
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_policies 
    WHERE tablename = 'tenants' 
    AND policyname = 'Users can view tenants for their properties'
  ) THEN
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
  END IF;
END $$;

-- Add foreign key relationship between properties and auth.users
DO $$ 
BEGIN
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