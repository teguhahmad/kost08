/*
  # Initial Schema Setup for Boarding House Management System

  1. New Tables
    - `properties`
      - Basic property information (name, address, contact details)
      - Owner reference to auth.users
    - `rooms`
      - Room details (number, floor, type, price)
      - Status tracking (occupied, vacant, maintenance)
      - Property reference
    - `tenants`
      - Tenant information
      - Room and property references
      - Payment status tracking
    - `payments`
      - Payment records
      - References to tenant, room, and property
    - `maintenance_requests`
      - Maintenance ticket details
      - References to room, tenant, and property
    - `notifications`
      - System notifications
      - User-specific and property-wide notifications
    - `user_settings`
      - User preferences and settings
      - Notification preferences
    - `subscription_plans`
      - Available subscription tiers
      - Feature limits and pricing
    - `subscriptions`
      - User subscriptions
      - Subscription status tracking

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
    - Add policies for backoffice access
*/

-- Create required ENUMs
CREATE TYPE notification_type AS ENUM ('system', 'user', 'property', 'payment');
CREATE TYPE notification_status AS ENUM ('unread', 'read');
CREATE TYPE user_role AS ENUM ('superadmin', 'admin', 'support');
CREATE TYPE user_status AS ENUM ('active', 'inactive');

-- Properties table
CREATE TABLE properties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  address text NOT NULL,
  city text NOT NULL,
  phone text,
  email text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Rooms table
CREATE TABLE rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  number text NOT NULL,
  floor text NOT NULL,
  type text NOT NULL,
  price numeric NOT NULL,
  status text NOT NULL,
  facilities text[],
  tenant_id uuid,
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tenants table
CREATE TABLE tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  phone text NOT NULL,
  email text NOT NULL,
  room_id uuid REFERENCES rooms(id),
  start_date date NOT NULL,
  end_date date NOT NULL,
  status text NOT NULL,
  payment_status text NOT NULL,
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Payments table
CREATE TABLE payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId" uuid REFERENCES tenants(id),
  "roomId" uuid REFERENCES rooms(id),
  amount numeric NOT NULL,
  date date,
  "dueDate" date NOT NULL,
  status text NOT NULL,
  "paymentMethod" text,
  notes text,
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Maintenance requests table
CREATE TABLE maintenance_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES rooms(id),
  tenant_id uuid REFERENCES tenants(id),
  title text NOT NULL,
  description text NOT NULL,
  date date NOT NULL,
  status text NOT NULL,
  priority text NOT NULL,
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Notifications table
CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  message text NOT NULL,
  type notification_type NOT NULL,
  status notification_status NOT NULL DEFAULT 'unread',
  created_at timestamptz DEFAULT now(),
  target_user_id uuid REFERENCES auth.users(id),
  target_property_id uuid REFERENCES properties(id)
);

-- User settings table
CREATE TABLE user_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL UNIQUE,
  email_notifications boolean DEFAULT true,
  payment_reminders boolean DEFAULT true,
  maintenance_updates boolean DEFAULT true,
  new_tenants boolean DEFAULT true,
  currency text DEFAULT 'IDR',
  date_format text DEFAULT 'DD/MM/YYYY',
  payment_reminder_days integer DEFAULT 5,
  session_timeout integer DEFAULT 30,
  login_notifications boolean DEFAULT true,
  two_factor_enabled boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Subscription plans table
CREATE TABLE subscription_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price integer NOT NULL,
  max_properties integer NOT NULL,
  max_rooms_per_property integer NOT NULL,
  features jsonb NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Subscriptions table
CREATE TABLE subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  plan_id uuid REFERENCES subscription_plans(id) NOT NULL,
  status text NOT NULL CHECK (status IN ('active', 'cancelled', 'expired')),
  current_period_start timestamptz NOT NULL,
  current_period_end timestamptz NOT NULL,
  cancel_at_period_end boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Backoffice users table
CREATE TABLE backoffice_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  name text NOT NULL,
  role user_role NOT NULL,
  status user_status NOT NULL DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  last_login timestamptz
);

-- Enable Row Level Security
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE backoffice_users ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies

-- Properties policies
CREATE POLICY "Users can manage their own properties"
  ON properties FOR ALL TO authenticated
  USING (owner_id = auth.uid());

CREATE POLICY "Backoffice can view all properties"
  ON properties FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM backoffice_users
    WHERE id = auth.uid() AND status = 'active'
  ));

-- Rooms policies
CREATE POLICY "Users can manage rooms in their properties"
  ON rooms FOR ALL TO authenticated
  USING (property_id IN (
    SELECT id FROM properties WHERE owner_id = auth.uid()
  ));

-- Tenants policies
CREATE POLICY "Users can manage tenants in their properties"
  ON tenants FOR ALL TO authenticated
  USING (property_id IN (
    SELECT id FROM properties WHERE owner_id = auth.uid()
  ));

-- Payments policies
CREATE POLICY "Users can manage payments in their properties"
  ON payments FOR ALL TO authenticated
  USING (property_id IN (
    SELECT id FROM properties WHERE owner_id = auth.uid()
  ));

-- Maintenance requests policies
CREATE POLICY "Users can manage maintenance requests in their properties"
  ON maintenance_requests FOR ALL TO authenticated
  USING (property_id IN (
    SELECT id FROM properties WHERE owner_id = auth.uid()
  ));

-- Notifications policies
CREATE POLICY "Users can view their notifications"
  ON notifications FOR SELECT TO authenticated
  USING (
    target_user_id = auth.uid() OR
    target_property_id IN (
      SELECT id FROM properties WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their notifications"
  ON notifications FOR ALL TO authenticated
  USING (target_user_id = auth.uid())
  WITH CHECK (target_user_id = auth.uid());

-- User settings policies
CREATE POLICY "Users can manage their settings"
  ON user_settings FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Subscription plans policies
CREATE POLICY "Anyone can view subscription plans"
  ON subscription_plans FOR SELECT TO authenticated
  USING (true);

-- Subscriptions policies
CREATE POLICY "Users can view their subscriptions"
  ON subscriptions FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can manage their subscriptions"
  ON subscriptions FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Backoffice users policies
CREATE POLICY "Superadmin can manage users"
  ON backoffice_users FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM backoffice_users
      WHERE id = auth.uid()
      AND role = 'superadmin'
      AND status = 'active'
    )
  );

CREATE POLICY "Users can view backoffice users"
  ON backoffice_users FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM backoffice_users
      WHERE id = auth.uid()
      AND status = 'active'
    )
  );

-- Create indexes for better query performance
CREATE INDEX idx_properties_owner_id ON properties(owner_id);
CREATE INDEX idx_rooms_property_id ON rooms(property_id);
CREATE INDEX idx_tenants_property_id ON tenants(property_id);
CREATE INDEX idx_payments_property_id ON payments(property_id);
CREATE INDEX idx_maintenance_property_id ON maintenance_requests(property_id);
CREATE INDEX idx_notifications_target_user ON notifications(target_user_id);
CREATE INDEX idx_notifications_target_property ON notifications(target_property_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- Insert default subscription plans
INSERT INTO subscription_plans (name, description, price, max_properties, max_rooms_per_property, features)
VALUES 
  (
    'Basic',
    'Perfect for small property owners',
    99000,
    1,
    10,
    '{
      "tenant_data": true,
      "auto_billing": false,
      "billing_notifications": true,
      "financial_reports": "basic",
      "data_backup": false,
      "multi_user": false,
      "analytics": false,
      "support": "basic"
    }'
  ),
  (
    'Professional',
    'Ideal for growing businesses',
    299000,
    5,
    30,
    '{
      "tenant_data": true,
      "auto_billing": true,
      "billing_notifications": true,
      "financial_reports": "advanced",
      "data_backup": "weekly",
      "multi_user": true,
      "analytics": true,
      "support": "priority"
    }'
  ),
  (
    'Enterprise',
    'For large property management companies',
    999000,
    20,
    100,
    '{
      "tenant_data": true,
      "auto_billing": true,
      "billing_notifications": true,
      "financial_reports": "predictive",
      "data_backup": "realtime",
      "multi_user": true,
      "analytics": "predictive",
      "support": "24/7"
    }'
  );

-- Create function to initialize user settings
CREATE OR REPLACE FUNCTION initialize_user_settings()
RETURNS trigger AS $$
BEGIN
  INSERT INTO user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to initialize settings for new users
DROP TRIGGER IF EXISTS initialize_user_settings_trigger ON auth.users;
CREATE TRIGGER initialize_user_settings_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION initialize_user_settings();

-- Insert initial superadmin
INSERT INTO backoffice_users (email, name, role, status)
VALUES (
  'admin@kostmanager.com',
  'Super Admin',
  'superadmin',
  'active'
) ON CONFLICT (email) DO NOTHING;