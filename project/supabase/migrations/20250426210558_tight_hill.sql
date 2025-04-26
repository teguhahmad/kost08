/*
  # Add missing columns to properties table

  1. Changes
    - Add `email` column to `properties` table
      - Type: text
      - Nullable: true (to maintain compatibility with existing records)
    - Add `phone` column to `properties` table
      - Type: text  
      - Nullable: true

  2. Security
    - No changes to RLS policies needed as existing policies will cover the new columns
*/

DO $$ 
BEGIN
  -- Add email column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'properties' 
    AND column_name = 'email'
  ) THEN
    ALTER TABLE properties ADD COLUMN email text;
  END IF;

  -- Add phone column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'properties' 
    AND column_name = 'phone'
  ) THEN
    ALTER TABLE properties ADD COLUMN phone text;
  END IF;
END $$;