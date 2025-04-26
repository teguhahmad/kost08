/*
  # Update user_list table to use plain text passwords

  1. Changes
    - Drop password hashing functions
    - Update password column to use plain text
    - Update admin password to plain text
*/

-- Drop existing functions
DROP FUNCTION IF EXISTS hash_password(text);
DROP FUNCTION IF EXISTS verify_password(text, text);

-- Update admin password to plain text
UPDATE user_list
SET password = 'Admin123!'
WHERE email = 'admin@kostmanager.com';