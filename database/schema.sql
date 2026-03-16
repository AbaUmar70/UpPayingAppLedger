-- UpPaying Fintech Platform - Complete PostgreSQL Database Schema
-- 60+ Tables covering all fintech modules
-- Version: 1.0.0

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- SECTION 1: USER & AUTHENTICATION MODULE
-- =====================================================

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'blocked')),
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(status);

-- User profiles
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    address TEXT,
    date_of_birth DATE,
    nationality VARCHAR(50),
    state VARCHAR(50),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    profile_image_url TEXT,
    bvn VARCHAR(11),
    nin VARCHAR(11),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- Roles table
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Permissions table
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User roles junction table
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, role_id)
);

-- Role permissions junction table
CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
    UNIQUE(role_id, permission_id)
);

-- Sessions table
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_info JSONB,
    ip_address VARCHAR(45),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_token ON sessions(token);

-- Refresh tokens table
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);

-- API Keys table
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    public_key TEXT UNIQUE NOT NULL,
    secret_key_hash TEXT NOT NULL,
    name VARCHAR(100),
    scopes TEXT[],
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP
);

CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_public_key ON api_keys(public_key);

-- Login attempts tracking
CREATE TABLE login_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(150),
    ip_address VARCHAR(45),
    user_agent TEXT,
    success BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_login_attempts_user_id ON login_attempts(user_id);
CREATE INDEX idx_login_attempts_created_at ON login_attempts(created_at);

-- =====================================================
-- SECTION 2: WALLET MODULE
-- =====================================================

-- Wallets table
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    currency VARCHAR(10) DEFAULT 'NGN',
    wallet_type VARCHAR(20) DEFAULT 'main' CHECK (wallet_type IN ('main', 'savings', 'escrow', 'merchant')),
    balance BIGINT DEFAULT 0,
    available_balance BIGINT DEFAULT 0,
    locked_balance BIGINT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'frozen', 'closed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wallets_user_id ON wallets(user_id);
CREATE INDEX idx_wallets_account_number ON wallets(account_number);
CREATE INDEX idx_wallets_status ON wallets(status);

-- Wallet balances history (for auditing)
CREATE TABLE wallet_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE,
    available_balance BIGINT NOT NULL,
    locked_balance BIGINT NOT NULL,
    total_balance BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wallet_balances_wallet_id ON wallet_balances(wallet_id);

-- Wallet limits
CREATE TABLE wallet_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE UNIQUE,
    daily_limit BIGINT DEFAULT 5000000,
    monthly_limit BIGINT DEFAULT 20000000,
    single_transaction_limit BIGINT DEFAULT 1000000,
    daily_used BIGINT DEFAULT 0,
    monthly_used BIGINT DEFAULT 0,
    reset_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wallet freeze/lock reasons
CREATE TABLE wallet_freeze (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE,
    freeze_type VARCHAR(20) CHECK (freeze_type IN ('full', 'partial', 'debit', 'credit')),
    reason TEXT,
    frozen_by UUID REFERENCES users(id),
    unfrozen_by UUID REFERENCES users(id),
    unfrozen_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wallet_freeze_wallet_id ON wallet_freeze(wallet_id);

-- Wallet statements/transaction history
CREATE TABLE wallet_statements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE,
    transaction_id UUID,
    reference VARCHAR(100) NOT NULL,
    description TEXT,
    debit BIGINT DEFAULT 0,
    credit BIGINT DEFAULT 0,
    balance_before BIGINT NOT NULL,
    balance_after BIGINT NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wallet_statements_wallet_id ON wallet_statements(wallet_id);
CREATE INDEX idx_wallet_statements_reference ON wallet_statements(reference);
CREATE INDEX idx_wallet_statements_created_at ON wallet_statements(created_at);

-- Wallet audit logs
CREATE TABLE wallet_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    performed_by UUID REFERENCES users(id),
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SECTION 3: LEDGER ACCOUNTING MODULE (Double-Entry)
-- =====================================================

-- Ledger accounts
CREATE TABLE ledger_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_number VARCHAR(30) UNIQUE NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL CHECK (account_type IN (
        'asset', 'liability', 'equity', 'revenue', 'expense',
        'user_wallet', 'merchant_wallet', 'escrow', 'system_fee',
        'settlement', 'bank_clearing', 'loan_account', 'savings_account'
    )),
    currency VARCHAR(10) DEFAULT 'NGN',
    user_id UUID REFERENCES users(id),
    wallet_id UUID REFERENCES wallets(id),
    parent_account_id UUID REFERENCES ledger_accounts(id),
    is_active BOOLEAN DEFAULT true,
    allow_manual_entry BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ledger_accounts_account_number ON ledger_accounts(account_number);
CREATE INDEX idx_ledger_accounts_user_id ON ledger_accounts(user_id);
CREATE INDEX idx_ledger_accounts_wallet_id ON ledger_accounts(wallet_id);

-- Account balances (cached)
CREATE TABLE account_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID REFERENCES ledger_accounts(id) ON DELETE CASCADE UNIQUE,
    balance BIGINT DEFAULT 0,
    debit_balance BIGINT DEFAULT 0,
    credit_balance BIGINT DEFAULT 0,
    last_transaction_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_account_balances_account_id ON account_balances(account_id);

-- Ledger transaction groups
CREATE TABLE ledger_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN (
        'wallet_transfer', 'merchant_payment', 'bill_payment', 'bank_withdrawal',
        'bank_deposit', 'card_payment', 'loan_disbursement', 'loan_repayment',
        'fee_charge', 'reversal', 'settlement', 'commission', 'airtime_purchase',
        'data_purchase', 'electricity_payment'
    )),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    total_amount BIGINT NOT NULL,
    currency VARCHAR(10) DEFAULT 'NGN',
    metadata JSONB,
    source_reference VARCHAR(100),
    reversed_by UUID,
    reversed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE INDEX idx_ledger_transactions_reference ON ledger_transactions(reference);
CREATE INDEX idx_ledger_transactions_status ON ledger_transactions(status);
CREATE INDEX idx_ledger_transactions_type ON ledger_transactions(transaction_type);
CREATE INDEX idx_ledger_transactions_created_at ON ledger_transactions(created_at);

-- Ledger entries (debit/credit lines)
CREATE TABLE ledger_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES ledger_transactions(id) ON DELETE CASCADE,
    account_id UUID REFERENCES ledger_accounts(id) ON DELETE RESTRICT,
    entry_type VARCHAR(10) NOT NULL CHECK (entry_type IN ('DEBIT', 'CREDIT')),
    amount BIGINT NOT NULL,
    currency VARCHAR(10) DEFAULT 'NGN',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ledger_entries_transaction_id ON ledger_entries(transaction_id);
CREATE INDEX idx_ledger_entries_account_id ON ledger_entries(account_id);

-- Ledger reversals
CREATE TABLE ledger_reversals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    original_transaction_id UUID REFERENCES ledger_transactions(id),
    reversal_transaction_id UUID REFERENCES ledger_transactions(id),
    reason TEXT,
    reversed_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ledger audit log
CREATE TABLE ledger_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES ledger_transactions(id),
    action VARCHAR(50) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    performed_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SECTION 4: TRANSACTIONS MODULE
-- =====================================================

-- Core transactions table
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(100) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN (
        'wallet_transfer', 'payment', 'bill_payment', 'bank_transfer',
        'airtime', 'data', 'electricity', 'cable', 'withdrawal', 'deposit'
    )),
    subtype VARCHAR(50),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'success', 'failed', 'reversed', 'refunded'
    )),
    amount BIGINT NOT NULL,
    fee BIGINT DEFAULT 0,
    net_amount BIGINT NOT NULL,
    currency VARCHAR(10) DEFAULT 'NGN',
    sender_id UUID REFERENCES users(id),
    sender_wallet_id UUID REFERENCES wallets(id),
    receiver_id UUID REFERENCES users(id),
    receiver_wallet_id UUID REFERENCES wallets(id),
    merchant_id UUID,
    description TEXT,
    metadata JSONB,
    initiated_by UUID REFERENCES users(id),
    processed_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    failed_at TIMESTAMP
);

CREATE INDEX idx_transactions_reference ON transactions(reference);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_sender_id ON transactions(sender_id);
CREATE INDEX idx_transactions_receiver_id ON transactions(receiver_id);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);

-- Transaction metadata
CREATE TABLE transaction_metadata (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES transactions(id) ON DELETE CASCADE,
    key VARCHAR(100) NOT NULL,
    value JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transaction_metadata_transaction_id ON transaction_metadata(transaction_id);

-- Transaction status logs
CREATE TABLE transaction_status_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES transactions(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    message TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transaction_status_logs_transaction_id ON transaction_status_logs(transaction_id);

-- Transaction attachments (receipts, etc.)
CREATE TABLE transaction_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES transactions(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SECTION 5: PAYMENT GATEWAY MODULE
-- =====================================================

-- Payment charges
CREATE TABLE payment_charges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(100) UNIQUE NOT NULL,
    merchant_id UUID NOT NULL,
    customer_id UUID REFERENCES users(id),
    amount BIGINT NOT NULL,
    fee BIGINT DEFAULT 0,
    net_amount BIGINT NOT NULL,
    currency VARCHAR(10) DEFAULT 'NGN',
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'success', 'failed', 'reversed'
    )),
    payment_method VARCHAR(50),
    channel VARCHAR(50),
    gateway_response JSONB,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

CREATE INDEX idx_payment_charges_reference ON payment_charges(reference);
CREATE INDEX idx_payment_charges_merchant_id ON payment_charges(merchant_id);
CREATE INDEX idx_payment_charges_customer_id ON payment_charges(customer_id);
CREATE INDEX idx_payment_charges_status ON payment_charges(status);

-- Payment methods
CREATE TABLE payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('card', 'bank_account', 'wallet', 'ussd', 'qr')),
    provider VARCHAR(50) NOT NULL,
    provider_reference VARCHAR(100),
    last_four VARCHAR(4),
    card_brand VARCHAR(20),
    card_type VARCHAR(20),
    expiry_month VARCHAR(2),
    expiry_year VARCHAR(4),
    is_default BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id);

-- Payment authorizations
CREATE TABLE payment_authorizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_charge_id UUID REFERENCES payment_charges(id),
    authorization_code VARCHAR(100),
    auth_type VARCHAR(20),
    status VARCHAR(20),
    expires_at TIMESTAMP,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment captures
CREATE TABLE payment_captures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_charge_id UUID REFERENCES payment_charges(id),
    amount BIGINT NOT NULL,
    status VARCHAR(20),
    captured_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment refunds
CREATE TABLE payment_refunds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_charge_id UUID REFERENCES payment_charges(id),
    reference VARCHAR(100) UNIQUE NOT NULL,
    amount BIGINT NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed')),
    gateway_response JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

CREATE INDEX idx_payment_refunds_payment_charge_id ON payment_refunds(payment_charge_id);

-- Payment disputes
CREATE TABLE payment_disputes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_charge_id UUID REFERENCES payment_charges(id),
    reference VARCHAR(100) UNIQUE NOT NULL,
    reason VARCHAR(100),
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'pending', 'resolved', 'closed')),
    amount BIGINT NOT NULL,
    evidence JSONB,
    resolution TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- Payment webhooks
CREATE TABLE payment_webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_charge_id UUID REFERENCES payment_charges(id),
    event_type VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL,
    delivered BOOLEAN DEFAULT false,
    delivery_attempts INT DEFAULT 0,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment splits (for marketplace)
CREATE TABLE payment_splits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_charge_id UUID REFERENCES payment_charges(id),
    recipient_id UUID NOT NULL,
    amount BIGINT NOT NULL,
    percentage DECIMAL(5,2),
    status VARCHAR(20) DEFAULT 'pending',
    settled_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SECTION 6: BANKING INTEGRATION MODULE
-- =====================================================

-- Bank accounts
CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    account_number VARCHAR(20) NOT NULL,
    bank_code VARCHAR(10) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    account_name VARCHAR(150) NOT NULL,
    account_type VARCHAR(20) DEFAULT 'savings',
    is_verified BOOLEAN DEFAULT false,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP
);

CREATE INDEX idx_bank_accounts_user_id ON bank_accounts(user_id);
CREATE INDEX idx_bank_accounts_account_number ON bank_accounts(account_number);

-- Bank transfers
CREATE TABLE bank_transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES transactions(id),
    bank_account_id UUID REFERENCES bank_accounts(id),
    reference VARCHAR(100) UNIQUE NOT NULL,
    amount BIGINT NOT NULL,
    fee BIGINT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'success', 'failed')),
    session_id VARCHAR(100),
    destination_bank_code VARCHAR(10),
    destination_account_number VARCHAR(20),
    narration TEXT,
    gateway_response JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

CREATE INDEX idx_bank_transfers_reference ON bank_transfers(reference);
CREATE INDEX idx_bank_transfers_status ON bank_transfers(status);

-- Bank transfer logs
CREATE TABLE bank_transfer_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bank_transfer_id UUID REFERENCES bank_transfers(id),
    status VARCHAR(50),
    message TEXT,
    response_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bank webhooks
CREATE TABLE bank_webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    processed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bank settlements
CREATE TABLE bank_settlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(100) UNIQUE NOT NULL,
    bank_account_id UUID REFERENCES bank_accounts(id),
    amount BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    settlement_date DATE,
    value_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- Bank reconciliation
CREATE TABLE bank_reconciliation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bank_account_id UUID REFERENCES bank_accounts(id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    bank_balance BIGINT NOT NULL,
    system_balance BIGINT NOT NULL,
    difference BIGINT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Virtual accounts
CREATE TABLE virtual_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    bank_code VARCHAR(10) NOT NULL,
    account_name VARCHAR(150) NOT NULL,
    wallet_id UUID REFERENCES wallets(id),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

CREATE INDEX idx_virtual_accounts_user_id ON virtual_accounts(user_id);
CREATE INDEX idx_virtual_accounts_account_number ON virtual_accounts(account_number);

-- Virtual account events
CREATE TABLE virtual_account_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    virtual_account_id UUID REFERENCES virtual_accounts(id),
    event_type VARCHAR(50) NOT NULL,
    amount BIGINT,
    sender_details JSONB,
    reference VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SECTION 7: MERCHANT MODULE
-- =====================================================

-- Merchants
CREATE TABLE merchants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    business_name VARCHAR(150) NOT NULL,
    business_type VARCHAR(50),
    business_email VARCHAR(150),
    business_phone VARCHAR(20),
    business_address TEXT,
    website VARCHAR(255),
    logo_url TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'terminated')),
    category VARCHAR(50),
    settlement_schedule VARCHAR(20) DEFAULT 'daily',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_merchants_user_id ON merchants(user_id);
CREATE INDEX idx_merchants_status ON merchants(status);

-- Merchant profiles
CREATE TABLE merchant_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID REFERENCES merchants(id) ON DELETE CASCADE UNIQUE,
    tagline VARCHAR(255),
    description TEXT,
    facebook_url VARCHAR(255),
    twitter_url VARCHAR(255),
    instagram_url VARCHAR(255),
    support_email VARCHAR(150),
    support_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Merchant settlements
CREATE TABLE merchant_settlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID REFERENCES merchants(id),
    reference VARCHAR(100) UNIQUE NOT NULL,
    amount BIGINT NOT NULL,
    fee BIGINT DEFAULT 0,
    net_amount BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    settlement_date DATE,
    bank_account_id UUID REFERENCES bank_accounts(id),
    transaction_references TEXT[],
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

CREATE INDEX idx_merchant_settlements_merchant_id ON merchant_settlements(merchant_id);
CREATE INDEX idx_merchant_settlements_status ON merchant_settlements(status);

-- Merchant fees
CREATE TABLE merchant_fees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID REFERENCES merchants(id),
    fee_type VARCHAR(50) NOT NULL,
    percentage DECIMAL(5,4),
    flat_fee BIGINT DEFAULT 0,
    min_amount BIGINT,
    max_amount BIGINT,
    currency VARCHAR(10) DEFAULT 'NGN',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Merchant API keys
CREATE TABLE merchant_api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID REFERENCES merchants(id) ON DELETE CASCADE,
    public_key TEXT UNIQUE NOT NULL,
    secret_key_hash TEXT NOT NULL,
    name VARCHAR(100),
    scopes TEXT[],
    ip_whitelist TEXT[],
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP
);

CREATE INDEX idx_merchant_api_keys_merchant_id ON merchant_api_keys(merchant_id);
CREATE INDEX idx_merchant_api_keys_public_key ON merchant_api_keys(public_key);

-- Merchant webhooks
CREATE TABLE merchant_webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID REFERENCES merchants(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    events TEXT[] NOT NULL,
    secret_hash TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Merchant payouts
CREATE TABLE merchant_payouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID REFERENCES merchants(id),
    reference VARCHAR(100) UNIQUE NOT NULL,
    amount BIGINT NOT NULL,
    fee BIGINT DEFAULT 0,
    net_amount BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    bank_account_id UUID REFERENCES bank_accounts(id),
    narration TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- =====================================================
-- SECTION 8: BILL PAYMENTS MODULE
-- =====================================================

-- Bill providers
CREATE TABLE bill_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(150) NOT NULL,
    provider_type VARCHAR(50) NOT NULL CHECK (provider_type IN ('airtime', 'data', 'electricity', 'cable', 'water')),
    provider_code VARCHAR(50) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    fee_structure JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bill_providers_type ON bill_providers(provider_type);

-- Bill categories
CREATE TABLE bill_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bill transactions
CREATE TABLE bill_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(100) UNIQUE NOT NULL,
    provider_id UUID REFERENCES bill_providers(id),
    user_id UUID REFERENCES users(id),
    wallet_id UUID REFERENCES wallets(id),
    bill_type VARCHAR(50) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    amount BIGINT NOT NULL,
    fee BIGINT DEFAULT 0,
    net_amount BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'success', 'failed')),
    provider_reference VARCHAR(100),
    provider_response JSONB,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

CREATE INDEX idx_bill_transactions_reference ON bill_transactions(reference);
CREATE INDEX idx_bill_transactions_provider_id ON bill_transactions(provider_id);
CREATE INDEX idx_bill_transactions_user_id ON bill_transactions(user_id);
CREATE INDEX idx_bill_transactions_status ON bill_transactions(status);

-- Bill payment logs
CREATE TABLE bill_payment_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bill_transaction_id UUID REFERENCES bill_transactions(id),
    action VARCHAR(50) NOT NULL,
    request_data JSONB,
    response_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SECTION 9: KYC / COMPLIANCE MODULE
-- =====================================================

-- KYC submissions
CREATE TABLE kyc_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    kyc_level INT DEFAULT 1 CHECK (kyc_level IN (1, 2, 3)),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'under_review', 'approved', 'rejected')),
    bvn_verified BOOLEAN DEFAULT false,
    nin_verified BOOLEAN DEFAULT false,
    face_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewed_by UUID REFERENCES users(id)
);

CREATE INDEX idx_kyc_submissions_user_id ON kyc_submissions(user_id);
CREATE INDEX idx_kyc_submissions_status ON kyc_submissions(status);

-- KYC documents
CREATE TABLE kyc_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submission_id UUID REFERENCES kyc_submissions(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('id_card', 'passport', 'drivers_license', 'voters_card', 'utility_bill', 'bank_statement')),
    document_number VARCHAR(100),
    issue_date DATE,
    expiry_date DATE,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50),
    verification_status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP
);

CREATE INDEX idx_kyc_documents_submission_id ON kyc_documents(submission_id);

-- KYC verifications
CREATE TABLE kyc_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submission_id UUID REFERENCES kyc_submissions(id),
    verification_type VARCHAR(50) NOT NULL,
    provider VARCHAR(50),
    reference VARCHAR(100),
    result JSONB,
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- AML checks
CREATE TABLE aml_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    check_type VARCHAR(50) NOT NULL,
    reference VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending',
    risk_score INT,
    result JSONB,
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_aml_checks_user_id ON aml_checks(user_id);

-- Sanctions screening
CREATE TABLE sanctions_screening (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    screened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending',
    matches JSONB,
    cleared BOOLEAN DEFAULT false
);

-- Risk scores
CREATE TABLE risk_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    score INT NOT NULL CHECK (score >= 0 AND score <= 100),
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    factors JSONB,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_risk_scores_user_id ON risk_scores(user_id);

-- =====================================================
-- SECTION 10: FRAUD DETECTION MODULE
-- =====================================================

-- Fraud rules
CREATE TABLE fraud_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN ('velocity', 'amount', 'geo', 'device', 'behavior', 'pattern')),
    conditions JSONB NOT NULL,
    action VARCHAR(20) DEFAULT 'alert' CHECK (action IN ('allow', 'block', 'review', 'alert')),
    risk_score INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    priority INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fraud alerts
CREATE TABLE fraud_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES transactions(id),
    rule_id UUID REFERENCES fraud_rules(id),
    risk_score INT NOT NULL,
    alert_type VARCHAR(50) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'false_positive')),
    assigned_to UUID REFERENCES users(id),
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

CREATE INDEX idx_fraud_alerts_transaction_id ON fraud_alerts(transaction_id);
CREATE INDEX idx_fraud_alerts_status ON fraud_alerts(status);

-- Fraud cases
CREATE TABLE fraud_cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_number VARCHAR(50) UNIQUE NOT NULL,
    alert_id UUID REFERENCES fraud_alerts(id),
    user_id UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'open',
    priority VARCHAR(20) DEFAULT 'medium',
    description TEXT,
    investigation_notes TEXT,
    resolution TEXT,
    assigned_to UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

-- Fraud scores history
CREATE TABLE fraud_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    transaction_id UUID REFERENCES transactions(id),
    score INT NOT NULL CHECK (score >= 0 AND score <= 100),
    factors JSONB,
    decision VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fraud_scores_user_id ON fraud_scores(user_id);
CREATE INDEX idx_fraud_scores_transaction_id ON fraud_scores(transaction_id);

-- Fraud blacklist
CREATE TABLE fraud_blacklist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier_type VARCHAR(50) NOT NULL CHECK (identifier_type IN ('email', 'phone', 'ip_address', 'device_id', 'account_number', 'card_pan')),
    identifier_value VARCHAR(255) NOT NULL,
    reason TEXT,
    added_by UUID REFERENCES users(id),
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(identifier_type, identifier_value)
);

-- Fraud velocity checks
CREATE TABLE fraud_velocity_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    check_type VARCHAR(50) NOT NULL,
    window_minutes INT NOT NULL,
    max_count INT NOT NULL,
    current_count INT DEFAULT 0,
    last_reset_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SECTION 11: LOANS MODULE
-- =====================================================

-- Loan products
CREATE TABLE loan_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    min_amount BIGINT NOT NULL,
    max_amount BIGINT NOT NULL,
    interest_rate DECIMAL(5,4) NOT NULL,
    interest_type VARCHAR(20) DEFAULT 'flat' CHECK (interest_type IN ('flat', 'reducing')),
    tenure_min_days INT NOT NULL,
    tenure_max_days INT NOT NULL,
    tenor_type VARCHAR(20) DEFAULT 'daily' CHECK (tenor_type IN ('daily', 'weekly', 'monthly')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Loan applications
CREATE TABLE loan_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    product_id UUID REFERENCES loan_products(id),
    reference VARCHAR(100) UNIQUE NOT NULL,
    amount_requested BIGINT NOT NULL,
    amount_approved BIGINT,
    interest_rate DECIMAL(5,4),
    tenure_days INT NOT NULL,
    purpose TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'under_review', 'approved', 'rejected', 'disbursed', 'defaulted', 'repaid'
    )),
    risk_score INT,
    approved_by UUID REFERENCES users(id),
    rejected_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    disbursed_at TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE INDEX idx_loan_applications_user_id ON loan_applications(user_id);
CREATE INDEX idx_loan_applications_status ON loan_applications(status);
CREATE INDEX idx_loan_applications_reference ON loan_applications(reference);

-- Loan disbursements
CREATE TABLE loan_disbursements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES loan_applications(id),
    reference VARCHAR(100) UNIQUE NOT NULL,
    amount BIGINT NOT NULL,
    interest_amount BIGINT NOT NULL,
    total_amount BIGINT NOT NULL,
    wallet_id UUID REFERENCES wallets(id),
    status VARCHAR(20) DEFAULT 'pending',
    disbursement_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- Loan repayments
CREATE TABLE loan_repayments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES loan_applications(id),
    reference VARCHAR(100) UNIQUE NOT NULL,
    amount BIGINT NOT NULL,
    principal_amount BIGINT,
    interest_amount BIGINT,
    penalty_amount BIGINT DEFAULT 0,
    payment_method VARCHAR(20),
    status VARCHAR(20) DEFAULT 'pending',
    paid_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- Loan schedules
CREATE TABLE loan_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES loan_applications(id),
    installment_number INT NOT NULL,
    due_date DATE NOT NULL,
    amount_due BIGINT NOT NULL,
    principal_due BIGINT NOT NULL,
    interest_due BIGINT NOT NULL,
    penalty_due BIGINT DEFAULT 0,
    amount_paid BIGINT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'partial', 'overdue', 'waived')),
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_loan_schedules_application_id ON loan_schedules(application_id);
CREATE INDEX idx_loan_schedules_due_date ON loan_schedules(due_date);

-- =====================================================
-- SECTION 12: AGENT BANKING MODULE
-- =====================================================

-- Agents
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    agent_code VARCHAR(50) UNIQUE NOT NULL,
    business_name VARCHAR(150) NOT NULL,
    agent_type VARCHAR(50) DEFAULT 'super_agent' CHECK (agent_type IN ('super_agent', 'agent', 'sub_agent')),
    commission_rate DECIMAL(5,4) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'terminated')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activated_at TIMESTAMP
);

CREATE INDEX idx_agents_agent_code ON agents(agent_code);
CREATE INDEX idx_agents_user_id ON agents(user_id);

-- Agent locations
CREATE TABLE agent_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    address TEXT NOT NULL,
    state VARCHAR(50),
    lga VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agent_locations_agent_id ON agent_locations(agent_id);

-- Agent transactions
CREATE TABLE agent_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id),
    transaction_id UUID REFERENCES transactions(id),
    transaction_type VARCHAR(50) NOT NULL,
    amount BIGINT NOT NULL,
    commission_amount BIGINT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'success',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agent_transactions_agent_id ON agent_transactions(agent_id);

-- Agent commissions
CREATE TABLE agent_commissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id),
    transaction_id UUID REFERENCES transactions(id),
    reference VARCHAR(100) UNIQUE NOT NULL,
    amount BIGINT NOT NULL,
    commission_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    settled_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agent_commissions_agent_id ON agent_commissions(agent_id);

-- =====================================================
-- SECTION 13: NOTIFICATIONS MODULE
-- =====================================================

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('transaction', 'alert', 'system', 'marketing', 'kyc')),
    channel VARCHAR(20) NOT NULL CHECK (channel IN ('sms', 'email', 'push', 'in_app')),
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Notification templates
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    subject VARCHAR(150),
    body TEXT NOT NULL,
    variables JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Email logs
CREATE TABLE email_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    to_email VARCHAR(150) NOT NULL,
    from_email VARCHAR(150),
    subject VARCHAR(200),
    body TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'bounced')),
    provider_response JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP
);

CREATE INDEX idx_email_logs_user_id ON email_logs(user_id);
CREATE INDEX idx_email_logs_status ON email_logs(status);

-- SMS logs
CREATE TABLE sms_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    phone_number VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed')),
    provider VARCHAR(50),
    provider_response JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP
);

CREATE INDEX idx_sms_logs_user_id ON sms_logs(user_id);
CREATE INDEX idx_sms_logs_phone_number ON sms_logs(phone_number);

-- Push notifications
CREATE TABLE push_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    status VARCHAR(20) DEFAULT 'pending',
    device_token TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP
);

-- =====================================================
-- SECTION 14: SYSTEM OPERATIONS MODULE
-- =====================================================

-- Audit logs
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- System settings
CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(100) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    is_encrypted BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Service health
CREATE TABLE service_health (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'healthy' CHECK (status IN ('healthy', 'degraded', 'down')),
    response_time_ms INT,
    last_check_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Job queue
CREATE TABLE job_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_name VARCHAR(100) NOT NULL,
    payload JSONB,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'retrying')),
    priority INT DEFAULT 0,
    attempts INT DEFAULT 0,
    max_attempts INT DEFAULT 3,
    scheduled_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_job_queue_status ON job_queue(status);
CREATE INDEX idx_job_queue_scheduled_at ON job_queue(scheduled_at);

-- Event logs
CREATE TABLE event_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    source_service VARCHAR(100),
    data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_event_logs_event_type ON event_logs(event_type);
CREATE INDEX idx_event_logs_created_at ON event_logs(created_at);

-- =====================================================
-- SECTION 15: SAVINGS MODULE
-- =====================================================

-- Savings accounts
CREATE TABLE savings_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    wallet_id UUID REFERENCES wallets(id),
    plan_type VARCHAR(50) NOT NULL CHECK (plan_type IN ('target', 'flexible', 'fixed')),
    target_amount BIGINT,
    current_balance BIGINT DEFAULT 0,
    interest_rate DECIMAL(5,4),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    matured_at TIMESTAMP
);

CREATE INDEX idx_savings_accounts_user_id ON savings_accounts(user_id);
CREATE INDEX idx_savings_accounts_status ON savings_accounts(status);

-- Savings transactions
CREATE TABLE savings_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    savings_account_id UUID REFERENCES savings_accounts(id),
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('deposit', 'withdrawal', 'interest', 'penalty')),
    amount BIGINT NOT NULL,
    reference VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'success',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_savings_transactions_account_id ON savings_transactions(savings_account_id);

-- =====================================================
-- SECTION 16: REPORTS & ANALYTICS
-- =====================================================

-- Daily transaction summaries
CREATE TABLE daily_transaction_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    total_transactions INT DEFAULT 0,
    total_volume BIGINT DEFAULT 0,
    total_fees BIGINT DEFAULT 0,
    success_count INT DEFAULT 0,
    failed_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date)
);

CREATE INDEX idx_daily_transaction_summaries_date ON daily_transaction_summaries(date);

-- Merchant analytics
CREATE TABLE merchant_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID REFERENCES merchants(id),
    date DATE NOT NULL,
    total_transactions INT DEFAULT 0,
    total_volume BIGINT DEFAULT 0,
    total_fees BIGINT DEFAULT 0,
    successful_transactions INT DEFAULT 0,
    failed_transactions INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(merchant_id, date)
);

-- =====================================================
-- FINAL: ADDITIONAL UTILITY TABLES
-- =====================================================

-- Countries
CREATE TABLE countries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(3) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    currency_symbol VARCHAR(10),
    is_active BOOLEAN DEFAULT true
);

-- Banks
CREATE TABLE banks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(10) UNIQUE NOT NULL,
    country_code VARCHAR(3) DEFAULT 'NGN',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to update wallet balance
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update wallet timestamp
CREATE TRIGGER trigger_wallet_updated
    BEFORE UPDATE ON wallets
    FOR EACH ROW
    EXECUTE FUNCTION update_wallet_balance();

-- Function to update ledger account timestamp
CREATE OR REPLACE FUNCTION update_ledger_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for ledger accounts
CREATE TRIGGER trigger_ledger_account_updated
    BEFORE UPDATE ON ledger_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_ledger_timestamp();

-- Function to calculate account balance from ledger
CREATE OR REPLACE FUNCTION get_account_balance(p_account_id UUID)
RETURNS BIGINT AS $$
DECLARE
    v_balance BIGINT;
BEGIN
    SELECT COALESCE(SUM(
        CASE
            WHEN entry_type = 'CREDIT' THEN amount
            ELSE -amount
        END
    ), 0) INTO v_balance
    FROM ledger_entries
    WHERE account_id = p_account_id;
    
    RETURN v_balance;
END;
$$ LANGUAGE plpgsql;

-- Function to verify double-entry balance for a transaction
CREATE OR REPLACE FUNCTION verify_double_entry(p_transaction_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_total_debit BIGINT;
    v_total_credit BIGINT;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO v_total_debit
    FROM ledger_entries
    WHERE transaction_id = p_transaction_id AND entry_type = 'DEBIT';
    
    SELECT COALESCE(SUM(amount), 0) INTO v_total_credit
    FROM ledger_entries
    WHERE transaction_id = p_transaction_id AND entry_type = 'CREDIT';
    
    RETURN v_total_debit = v_total_credit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEEDS (Initial Data)
-- =====================================================

-- Insert default roles
INSERT INTO roles (name, description) VALUES
('super_admin', 'Full system access'),
('admin', 'Administrative access'),
('user', 'Regular user'),
('merchant', 'Merchant account'),
('agent', 'Agent banking'),
('kyc_manager', 'KYC verification manager'),
('finance', 'Finance team'),
('support', 'Customer support');

-- Insert default permissions
INSERT INTO permissions (name, resource, action) VALUES
('create_user', 'users', 'create'),
('read_user', 'users', 'read'),
('update_user', 'users', 'update'),
('delete_user', 'users', 'delete'),
('create_transaction', 'transactions', 'create'),
('read_transaction', 'transactions', 'read'),
('create_wallet', 'wallets', 'create'),
('read_wallet', 'wallets', 'read'),
('manage_merchant', 'merchants', 'manage'),
('view_reports', 'reports', 'view'),
('manage_kyc', 'kyc', 'manage'),
('manage_fraud', 'fraud', 'manage');

-- Insert default system settings
INSERT INTO system_settings (key, value, description) VALUES
('platform_fee_percentage', '{"value": 0.015}', 'Platform fee percentage (1.5%)'),
('min_transfer_amount', '{"value": 100}', 'Minimum transfer amount'),
('max_transfer_amount', '{"value": 5000000}', 'Maximum transfer amount'),
('settlement_schedule', '{"value": "daily"}', 'Default settlement schedule');

-- Insert default countries
INSERT INTO countries (name, code, currency_code, currency_symbol) VALUES
('Nigeria', 'NGN', 'NGN', '₦'),
('Ghana', 'GHS', 'GHS', '₵'),
('Kenya', 'KES', 'KES', 'KSh'),
('United States', 'USD', 'USD', '$');

-- Insert sample banks
INSERT INTO banks (name, code) VALUES
('Access Bank', '044'),
(' Guaranty Trust Bank', '058'),
('United Bank for Africa', '033'),
('Zenith Bank', '057'),
('First Bank of Nigeria', '011'),
('Sterling Bank', '232'),
('Ecobank Nigeria', '050'),
('Diamond Bank', '063'),
('Fidelity Bank', '070'),
('Heritage Bank', '030');
