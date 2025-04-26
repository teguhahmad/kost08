/*
  # Add address column to properties table

  1. Changes
    - Add `address` column to `properties` table
      - Type: text
      - Nullable: true (to maintain compatibility with existing records)

  2. Security
    - No changes to RLS policies needed as the existing policies will cover the new column
*/

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'properties' 
    AND column_name = 'address'
  ) THEN
    ALTER TABLE properties ADD COLUMN address text;
  END IF;
END $$;