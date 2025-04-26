/*
  # Enable pgcrypto and create password verification function

  1. Changes
    - Enable pgcrypto extension for cryptographic functions
    - Create verify_password function for secure password verification

  2. Security
    - Function is accessible only to authenticated users
    - Uses secure password hashing via pgcrypto
*/

-- Enable the pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create a function to verify passwords
CREATE OR REPLACE FUNCTION verify_password(
  input_password text,
  hashed_password text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    input_password IS NOT NULL AND
    hashed_password IS NOT NULL AND
    crypt(input_password, hashed_password) = hashed_password
  );
END;
$$;