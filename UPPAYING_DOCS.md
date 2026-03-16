# UpPaying Developer Documentation

<p align="center">
  <strong>The Complete Payment Platform for Africa</strong>
</p>

<p align="center">
  Version 2.0.0 | Last Updated: March 2026
</p>

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Features of the Platform](#2-features-of-the-platform)
3. [Getting Started](#3-getting-started)
4. [Authentication](#4-authentication)
5. [Integration Methods](#5-integration-methods)
6. [Core API Services](#6-core-api-services)
7. [Webhooks](#7-webhooks)
8. [Security Best Practices](#8-security-best-practices)
9. [Error Handling](#9-error-handling)
10. [Sandbox Environment](#10-sandbox-environment)
11. [Production Go-Live Checklist](#11-production-go-live-checklist)
12. [Example Use Cases](#12-example-use-cases)

---

## 1. Introduction

### What is UpPaying?

UpPaying is a comprehensive digital payment and micro-banking platform designed specifically for Nigeria and emerging markets. We provide developers, fintech startups, merchants, and financial institutions with powerful APIs to build payment solutions, digital wallets, and banking applications.

### What Problems We Solve

- **Complex Payment Integration**: Connect to multiple Nigerian banks and payment channels through a single API
- **Fragmented Banking Infrastructure**: Unified interface for transfers, bill payments, and wallet operations
- **Regulatory Compliance**: Built-in KYC/AML compliance features and PCI-DSS compliance
- **Limited Financial Access**: Enable mobile wallet services for the underbanked population
- **High Transaction Costs**: Competitive pricing with transparent fee structures

### Who Can Use UpPaying

| User Type | Use Cases |
|-----------|-----------|
| **Developers** | Build payment integrations, wallet apps, and fintech solutions |
| **Merchants** | Accept online payments, manage settlements, track transactions |
| **Fintech Startups** | Launch digital banks, payment apps, and financial services |
| **Agent Networks** | Operate banking agents, POS terminals, and cash points |
| **Enterprises** | Process bulk payments, payroll, and vendor settlements |

### Key Capabilities

- **Mobile Wallet Services**: Create and manage digital wallets with full transaction history
- **Payment Gateway**: Accept card payments, bank transfers, and alternative payment methods
- **Virtual Accounts**: Generate dedicated bank accounts for customer collections
- **Bill Payments**: Process electricity, airtime, data, and TV subscriptions
- **Peer-to-Peer Transfers**: Send money between wallets instantly
- **Bank Transfers**: Send funds to any Nigerian bank account
- **QR Code Payments**: Enable QR-based payments for in-store transactions
- **USSD Payments**: Support feature phone users via USSD codes
- **Agent Banking**: Power POS terminals and agent networks
- **Micro-Loans**: Issue and manage small-dollar loans
- **Savings Walls**: Create automated savings products
- **Card Management**: Issue virtual and physical cards

---

## 2. Features of the Platform

### 2.1 Wallet Services

UpPaying mobile wallets provide a complete digital banking solution:

- **Wallet Creation**: Generate unique account numbers for each user
- **Multiple Wallet Types**: Support for main wallet, savings wallet, and targeted wallets
- **Balance Management**: Real-time balance updates with transaction history
- **Limit Controls**: Configurable daily and monthly transaction limits
- **Wallet Freezing**: Ability to freeze wallets for compliance or security reasons
- **Statement Generation**: Download detailed transaction statements
- **Interest Calculation**: Automatic interest computation for savings wallets

### 2.2 Payment Processing

Our payment gateway handles multiple payment methods:

- **Card Payments**: Support for Visa, Mastercard, and Verve cards
- **Bank Transfers**: Instant transfers to all Nigerian banks via NIP
- **USSD**: USSD codes (*945#) for feature phone users
- **QR Codes**: QR payment acceptance for retail locations
- **Bank Branding**: Custom bank name display on customer statements

### 2.3 Merchant Collections

Merchant-focused features for businesses:

- **Payment Links**: Generate shareable payment links
- **Hosted Checkout**: Pre-built secure checkout pages
- **Invoice Management**: Create and send digital invoices
- **Recurring Payments**: Set up subscription and installment plans
- **Split Payments**: Automatically split payments between parties
- **Settlement Reports**: Detailed reporting for reconciliation

### 2.4 Peer-to-Peer Transfers

Wallet-to-wallet transfer capabilities:

- **Instant Transfers**: Real-time money movement between wallets
- **Address Book**: Save frequently used contacts
- **Transfer Limits**: Configurable per-user limits
- **Transaction Alerts**: SMS and push notifications
- **Failed Transfer Reversals**: Automatic refund on failed transfers

### 2.5 Bill Payment Services

Pay bills instantly through our unified API:

| Category | Providers |
|----------|-----------|
| **Electricity** | Ikeja Electric, Eko Electric, PHED, Jos Electricity, Kano Electric, Ibadan Electricity |
| **Airtime** | MTN, Airtel, Glo, 9mobile |
| **Data** | MTN, Airtel, Glo, 9mobile |
| **TV Subscriptions** | DSTV, GOtv, Startimes |

### 2.6 QR Payments

QR-based payment solution for merchants:

- **Static QR**: Fixed QR code for donations and fixed amounts
- **Dynamic QR**: Time-limited QR codes with specific amounts
- **POS Integration**: QR acceptance via Android POS terminals

### 2.7 Virtual Accounts

Dedicated bank accounts for customer payments:

- **NUBAN Accounts**: Standard Nigerian Uniform Bank Account Numbers
- **Account Naming**: Display your brand name on transfers
- **Multiple Accounts**: Create multiple virtual accounts per customer
- **Real-time Notification**: Instant alerts on incoming payments

### 2.8 Agent Banking

Power your agent network:

- **Agent Onboarding**: Register and manage banking agents
- **Cash In/Out**: Enable cash deposit and withdrawal
- **Commission Tracking**: Automated commission calculation
- **Transaction Limits**: Configurable agent limits
- **Location Tracking**: GPS-based agent location management

---

## 3. Getting Started

### Step 1: Create a Developer Account

Navigate to the [UpPaying Developer Portal](https://dashboard.upaying.com/register) and create an account. You'll receive:

- A unique Merchant ID
- API Keys (Sandbox and Production)
- Dashboard access

### Step 2: Generate API Keys

After registration, generate your API keys from the Dashboard:

```
Sandbox Keys:
├── Public Key: pk_sandbox_xxxxxxxxxxxxxxxxxxxx
└── Secret Key: sk_sandbox_xxxxxxxxxxxxxxxxxxxx

Production Keys:
├── Public Key: pk_live_xxxxxxxxxxxxxxxxxxxx
└── Secret Key: sk_live_xxxxxxxxxxxxxxxxxxxx
```

### Step 3: Setup Sandbox Environment

The sandbox environment mirrors production with test data:

```bash
# Base URL for Sandbox
https://api-sandbox.upaying.com/v1

# Webhook URL for Testing
https://api-sandbox.upaying.com/v1/webhooks
```

### Step 4: Make Your First API Request

Create a test wallet to verify your integration:

```bash
curl -X POST https://api-sandbox.upaying.com/v1/wallets \
  -H "Authorization: Bearer sk_sandbox_xxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "usr_test_123456",
    "type": "main",
    "currency": "NGN",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "phone": "+2348012345678"
  }'
```

**Successful Response:**

```json
{
  "success": true,
  "data": {
    "id": "wl_sandbox_abc123def456",
    "userId": "usr_test_123456",
    "accountNumber": "8930001234",
    "type": "main",
    "currency": "NGN",
    "balance": "0.00",
    "availableBalance": "0.00",
    "status": "active",
    "createdAt": "2026-03-16T10:30:00.000Z"
  },
  "message": "Wallet created successfully"
}
```

---

## 4. Authentication

UpPaying uses multiple authentication methods to ensure secure API access.

### 4.1 API Keys

All API requests require authentication using your API keys:

| Key Type | Usage | Security Level |
|----------|-------|----------------|
| **Public Key** | Client-side integrations, tokenization | Low risk |
| **Secret Key** | Server-side API calls | High risk |

### 4.2 Bearer Token Authentication

Include your API key in the Authorization header:

```http
Authorization: Bearer sk_sandbox_xxxxxxxxxxxxxxxxxxxx
Content-Type: application/json
```

### 4.3 HMAC Signature (Advanced)

For enhanced security, sign your requests with HMAC-SHA256:

```javascript
const crypto = require('crypto');

function generateSignature(payload, secretKey) {
  const signature = crypto
    .createHmac('sha256', secretKey)
    .update(JSON.stringify(payload))
    .digest('hex');
  return signature;
}

// Include in headers
{
  "Authorization": "Bearer sk_sandbox_xxxxx",
  "X-Signature": "a1b2c3d4e5f6...",
  "X-Timestamp": "1707999000"
}
```

### 4.4 Webhook Verification

Verify webhook authenticity using signatures:

```javascript
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}
```

### 4.5 Request Headers

All API requests must include:

```http
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
X-Request-Id: unique-request-id
X-Timestamp: Unix timestamp
```

---

## 5. Integration Methods

UpPaying provides multiple integration options to suit your business needs.

### 5.1 Hosted Checkout

A pre-built, secure checkout page hosted by UpPaying.

**Features:**

- Fast integration (typically 10 minutes)
- PCI-DSS compliant payment page
- Mobile-optimized responsive design
- Automatic card tokenization
- Multiple payment methods
- Real-time transaction status

**When to Use:**

- Quickest path to accepting payments
- Limited development resources
- PCI compliance handled by UpPaying
- Mobile-first user experience needed

**Integration Example:**

```html
<!DOCTYPE html>
<html>
<head>
  <title>Pay with UpPaying</title>
</head>
<body>
  <form method="POST" action="https://checkout.upaying.com/pay">
    <input type="hidden" name="public_key" value="pk_sandbox_xxxxx" />
    <input type="hidden" name="amount" value="5000" />
    <input type="hidden" name="currency" value="NGN" />
    <input type="hidden" name="reference" value="ORD-123456" />
    <input type="hidden" name="customer[email]" value="customer@example.com" />
    <input type="hidden" name="customer[name]" value="John Doe" />
    <input type="hidden" name="callback_url" value="https://yoursite.com/callback" />
    <button type="submit">Pay ₦5,000</button>
  </form>
</body>
</html>
```

### 5.2 Server-to-Server API Integration

Build your own payment UI with full control.

**Capabilities:**

- Complete control over checkout experience
- Custom payment forms and flows
- Multiple payment method options
- White-label integration
- Advanced fraud detection integration

**Integration Example:**

```javascript
const axios = require('axios');

async function chargeCard(paymentData) {
  const response = await axios.post(
    'https://api-sandbox.upaying.com/v1/payments/charge',
    {
      amount: 500000, // Amount in kobo
      currency: 'NGN',
      email: 'customer@example.com',
      card: {
        number: '4084084084084081',
        cvv: '123',
        expiry_month: '12',
        expiry_year: '2027',
        pin: '1234'
      },
      reference: 'ORD-' + Date.now(),
      metadata: {
        order_id: '12345',
        product: 'Premium Subscription'
      }
    },
    {
      headers: {
        'Authorization': 'Bearer sk_sandbox_xxxxx',
        'Content-Type': 'application/json'
      }
    }
  );
  
  return response.data;
}
```

### 5.3 SDK Integration

Use our official SDKs for faster integration.

#### JavaScript/Node.js

```bash
npm install @upaying/sdk
```

```javascript
const UpPaying = require('@upaying/sdk');

const upaying = new UpPaying({
  secretKey: 'sk_sandbox_xxxxx',
  publicKey: 'pk_sandbox_xxxxx'
});

// Create wallet
const wallet = await upaying.wallets.create({
  userId: 'usr_123',
  type: 'main',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '+2348012345678'
});
```

#### Python

```bash
pip install upaying
```

```python
from upaying import UpPaying

upaying = UpPaying(
    secret_key='sk_sandbox_xxxxx',
    public_key='pk_sandbox_xxxxx'
)

wallet = upaying.wallets.create(
    user_id='usr_123',
    type='main',
    first_name='John',
    last_name='Doe',
    email='john@example.com',
    phone='+2348012345678'
)
```

#### PHP

```bash
composer require upaying/sdk
```

```php
use UpPaying\UpPaying;

$upaying = new UpPaying([
    'secret_key' => 'sk_sandbox_xxxxx',
    'public_key' => 'pk_sandbox_xxxxx'
]);

$wallet = $upaying->wallets->create([
    'user_id' => 'usr_123',
    'type' => 'main',
    'first_name' => 'John',
    'last_name' => 'Doe',
    'email' => 'john@example.com',
    'phone' => '+2348012345678'
]);
```

#### Java (Android)

```gradle
dependencies {
    implementation 'com.upaying:sdk:2.0.0'
}
```

#### Flutter

```yaml
dependencies:
  upaying_flutter: ^2.0.0
```

### 5.4 E-Commerce Plugins

Pre-built plugins for popular e-commerce platforms.

| Platform | Status | Version |
|----------|--------|---------|
| WooCommerce | Available | 2.0.0 |
| Shopify | Available | 2.0.0 |
| Magento 2 | Available | 2.0.0 |
| OpenCart | Coming Soon | - |

#### WooCommerce Integration

1. Download the UpPaying WooCommerce plugin from WordPress repository
2. Navigate to WooCommerce > Settings > Payments
3. Enable UpPaying and enter your API keys
4. Configure webhook URL for real-time notifications

---

## 6. Core API Services

### 6.1 Create Wallet

Create a new mobile wallet for a user.

**Endpoint:** `POST /v1/wallets`

**Request:**

```json
{
  "userId": "usr_123456",
  "type": "main",
  "currency": "NGN",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "phone": "+2348012345678",
  "dateOfBirth": "1990-01-15",
  "address": {
    "street": "123 Main Street",
    "city": "Lagos",
    "state": "Lagos",
    "country": "NG"
  }
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "wl_sandbox_abc123def456",
    "userId": "usr_123456",
    "accountNumber": "8930001234",
    "type": "main",
    "currency": "NGN",
    "balance": "0.00",
    "availableBalance": "0.00",
    "status": "active",
    "kycLevel": 0,
    "createdAt": "2026-03-16T10:30:00.000Z"
  },
  "message": "Wallet created successfully"
}
```

**Validation Rules:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | String | Yes | Unique user identifier |
| `type` | Enum | Yes | `main`, `savings`, `target` |
| `currency` | String | Yes | Currency code (NGN) |
| `firstName` | String | Yes | First name (min 2 chars) |
| `lastName` | String | Yes | Last name (min 2 chars) |
| `email` | String | No | Valid email address |
| `phone` | String | Yes | Valid phone number |

---

### 6.2 Transfer Money (Wallet-to-Wallet)

Transfer funds between two UpPaying wallets.

**Endpoint:** `POST /v1/wallets/transfer`

**Request:**

```json
{
  "fromWalletId": "wl_sandbox_abc123",
  "toWalletId": "wl_sandbox_xyz789",
  "amount": 50000,
  "currency": "NGN",
  "reference": "TRF-123456789",
  "narration": "Monthly rent payment",
  "metadata": {
    "category": "rent"
  }
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "trf_abc123def456",
    "reference": "TRF-123456789",
    "fromWalletId": "wl_sandbox_abc123",
    "toWalletId": "wl_sandbox_xyz789",
    "amount": "500.00",
    "currency": "NGN",
    "fee": "0.00",
    "status": "completed",
    "narration": "Monthly rent payment",
    "createdAt": "2026-03-16T10:35:00.000Z",
    "completedAt": "2026-03-16T10:35:01.000Z"
  },
  "message": "Transfer completed successfully"
}
```

---

### 6.3 Bank Transfer

Send money from a wallet to any Nigerian bank account.

**Endpoint:** `POST /v1/transfers/bank`

**Request:**

```json
{
  "walletId": "wl_sandbox_abc123",
  "amount": 100000,
  "currency": "NGN",
  "bankCode": "058",
  "accountNumber": "0123456789",
  "accountName": "John Doe",
  "reference": "BNK-123456789",
  "narration": "Salary payment",
  "saveBeneficiary": true,
  "beneficiaryName": "John Doe"
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "bt_abc123def456",
    "reference": "BNK-123456789",
    "walletId": "wl_sandbox_abc123",
    "amount": "1000.00",
    "currency": "NGN",
    "fee": "10.00",
    "totalAmount": "1010.00",
    "bankCode": "058",
    "accountNumber": "0123456789",
    "accountName": "John Doe",
    "status": "pending",
    "narration": "Salary payment",
    "createdAt": "2026-03-16T10:40:00.000Z"
  },
  "message": "Transfer initiated successfully"
}
```

**Bank Codes:**

| Bank | Code |
|------|------|
| Guaranty Trust Bank (GTB) | 058 |
| First Bank of Nigeria | 011 |
| Zenith Bank | 057 |
| United Bank for Africa (UBA) | 033 |
| Sterling Bank | 232 |
| Fidelity Bank | 070 |
| Access Bank | 044 |
| Ecobank Nigeria | 050 |
| Stanbic IBTC | 221 |
| Union Bank | 032 |

---

### 6.4 Create Payment Charge

Accept card payments from customers.

**Endpoint:** `POST /v1/payments/charge`

**Request:**

```json
{
  "amount": 250000,
  "currency": "NGN",
  "email": "customer@example.com",
  "phone": "+2348012345678",
  "card": {
    "number": "4084084084084081",
    "cvv": "123",
    "expiry_month": "12",
    "expiry_year": "2027",
    "pin": "1234"
  },
  "reference": "PAY-123456789",
  "metadata": {
    "orderId": "ORD-5678",
    "product": "Electronics"
  },
  "callbackUrl": "https://yoursite.com/payment/callback"
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "chg_abc123def456",
    "reference": "PAY-123456789",
    "amount": "2500.00",
    "currency": "NGN",
    "status": "pending",
    "message": "OTP validation required",
    "requeryReference": "RQ-ABC123XYZ",
    "createdAt": "2026-03-16T10:45:00.000Z"
  }
}
```

**3DSecure Flow:**

If the card requires 3D Secure authentication:

```json
{
  "success": true,
  "data": {
    "id": "chg_abc123def456",
    "reference": "PAY-123456789",
    "status": "3ds_required",
    "authorization": {
      "mode": "3ds",
      "redirectUrl": "https://upaying.com/3ds/auth/xxx"
    }
  }
}
```

---

### 6.5 Verify Transaction

Verify the status of a transaction using the reference.

**Endpoint:** `GET /v1/transactions/verify/{reference}`

**Request:**

```bash
curl -X GET https://api-sandbox.upaying.com/v1/transactions/verify/PAY-123456789 \
  -H "Authorization: Bearer sk_sandbox_xxxxx"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "chg_abc123def456",
    "reference": "PAY-123456789",
    "amount": "2500.00",
    "currency": "NGN",
    "status": "success",
    "customer": {
      "email": "customer@example.com",
      "phone": "+2348012345678"
    },
    "paymentMethod": "card",
    "card": {
      "last4": "4081",
      "brand": "visa"
    },
    "metadata": {
      "orderId": "ORD-5678",
      "product": "Electronics"
    },
    "createdAt": "2026-03-16T10:45:00.000Z",
    "completedAt": "2026-03-16T10:45:30.000Z"
  }
}
```

---

### 6.6 Generate Virtual Account

Create a virtual bank account for receiving payments.

**Endpoint:** `POST /v1/virtual-accounts`

**Request:**

```json
{
  "customerId": "cus_123456",
  "customerEmail": "customer@example.com",
  "customerName": "John Doe",
  "preferredBank": "gtbank",
  "reference": "VA-123456789",
  "nit": "NIBSS-123456"
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "va_abc123def456",
    "reference": "VA-123456789",
    "accountNumber": "8930005678",
    "accountName": "JOHN DOE - UPPYING",
    "bankName": "Guaranty Trust Bank",
    "bankCode": "058",
    "status": "active",
    "customerId": "cus_123456",
    "createdAt": "2026-03-16T10:50:00.000Z",
    "expiresAt": null
  },
  "message": "Virtual account created successfully"
}
```

---

### 6.7 Bill Payment API

Pay bills for electricity, airtime, data, and TV subscriptions.

**Endpoint:** `POST /v1/bills/pay`

#### Airtime Recharge

```json
{
  "service": "airtime",
  "provider": "mtn",
  "phoneNumber": "+2348012345678",
  "amount": 1000,
  "currency": "NGN",
  "reference": "AIR-123456789"
}
```

#### Data Bundle

```json
{
  "service": "data",
  "provider": "mtn",
  "phoneNumber": "+2348012345678",
  "amount": 2000,
  "currency": "NGN",
  "dataPlan": "1GB",
  "reference": "DAT-123456789"
}
```

#### Electricity Bill

```json
{
  "service": "electricity",
  "provider": "ikeja_electric",
  "meterNumber": "12345678901",
  "meterType": "prepaid",
  "amount": 5000,
  "currency": "NGN",
  "phoneNumber": "+2348012345678",
  "reference": "ELC-123456789"
}
```

#### TV Subscription

```json
{
  "service": "tv",
  "provider": "dstv",
  "smartCardNumber": "1234567890",
  "plan": "compact",
  "amount": 9600,
  "currency": "NGN",
  "reference": "TVS-123456789"
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "bill_abc123def456",
    "reference": "AIR-123456789",
    "service": "airtime",
    "provider": "mtn",
    "phoneNumber": "+2348012345678",
    "amount": "1000.00",
    "currency": "NGN",
    "status": "success",
    "token": "123456789012",
    "createdAt": "2026-03-16T10:55:00.000Z",
    "completedAt": "2026-03-16T10:55:05.000Z"
  },
  "message": "Airtime recharge successful"
}
```

---

## 7. Webhooks

Webhooks allow you to receive real-time notifications about events in your UpPaying account.

### 7.1 Available Webhook Events

| Event | Description |
|-------|-------------|
| `payment.success` | Successful payment transaction |
| `payment.pending` | Payment awaiting verification |
| `payment.failed` | Failed payment attempt |
| `payment.3ds_required` | Card requires 3D Secure authentication |
| `transfer.completed` | Successful wallet/bank transfer |
| `transfer.failed` | Failed transfer |
| `wallet.created` | New wallet created |
| `wallet.credited` | Wallet credited |
| `wallet.debited` | Wallet debited |
| `wallet.frozen` | Wallet has been frozen |
| `virtual_accountcredited` | Virtual account received payment |
| `refund.completed` | Refund processed |
| `dispute.opened` | Customer opened a dispute |
| `subscription.payment_failed` | Recurring payment failed |

### 7.2 Webhook Payload Example

```json
{
  "event": "payment.success",
  "timestamp": 1707999950,
  "data": {
    "id": "chg_abc123def456",
    "reference": "PAY-123456789",
    "amount": "2500.00",
    "currency": "NGN",
    "status": "success",
    "customer": {
      "email": "customer@example.com",
      "phone": "+2348012345678"
    },
    "paymentMethod": "card",
    "metadata": {
      "orderId": "ORD-5678"
    },
    "createdAt": "2026-03-16T10:45:00.000Z",
    "completedAt": "2026-03-16T10:45:30.000Z"
  }
}
```

### 7.3 Webhook Handling Example

```javascript
const crypto = require('crypto');

app.post('/webhooks/upaying', (req, res) => {
  const signature = req.headers['x-upaying-signature'];
  const payload = JSON.stringify(req.body);
  
  // Verify webhook signature
  if (!verifyWebhookSignature(payload, signature, process.env.WEBHOOK_SECRET)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }
  
  const event = req.body.event;
  
  switch (event) {
    case 'payment.success':
      handlePaymentSuccess(req.body.data);
      break;
    case 'payment.failed':
      handlePaymentFailed(req.body.data);
      break;
    case 'wallet.credited':
      handleWalletCredit(req.body.data);
      break;
    // Handle other events...
  }
  
  res.status(200).json({ received: true });
});

function verifyWebhookSignature(payload, signature, secret) {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  return signature === expectedSignature;
}
```

### 7.4 Webhook Retry Policy

UpPaying retries failed webhook deliveries:

- **First Retry**: 1 minute after failure
- **Second Retry**: 5 minutes after failure
- **Third Retry**: 30 minutes after failure
- **Fourth Retry**: 2 hours after failure
- **Fifth Retry**: 24 hours after failure

After 5 failed attempts, the webhook is marked as failed and requires manual retry from the dashboard.

---

## 8. Security Best Practices

### 8.1 HTTPS Requirement

All API requests must be made over HTTPS. Plain HTTP requests will be rejected.

```javascript
// ✅ Correct
const client = axios.create({
  baseURL: 'https://api.upaying.com/v1'
});

// ❌ Incorrect
const client = axios.create({
  baseURL: 'http://api.upaying.com/v1'
});
```

### 8.2 API Key Security

**Do:**

- Store API keys in environment variables
- Use separate keys for sandbox and production
- Rotate keys periodically
- Use the principle of least privilege

**Don't:**

- Commit API keys to version control
- Share keys in client-side code
- Display keys in logs or error messages
- Use production keys in development

```javascript
// ✅ Correct - Environment variables
const apiKey = process.env.UPPYING_SECRET_KEY;

// ❌ Incorrect - Hardcoded keys
const apiKey = 'sk_live_xxxxxxxxxxxxxx';
```

### 8.3 Request Signing

Sign sensitive requests with HMAC for additional security:

```javascript
const crypto = require('crypto');

function signRequest(payload, secretKey, timestamp) {
  const signaturePayload = `${timestamp}.${JSON.stringify(payload)}`;
  return crypto
    .createHmac('sha256', secretKey)
    .update(signaturePayload)
    .digest('hex');
}

// Add to request headers
const timestamp = Math.floor(Date.now() / 1000);
const signature = signRequest(payload, secretKey, timestamp);

headers['X-Timestamp'] = timestamp;
headers['X-Signature'] = signature;
```

### 8.4 Fraud Protection

Implement these fraud prevention measures:

1. **Address Verification (AVS)**: Validate billing address for card payments
2. **CVV Verification**: Always require CVV for card transactions
3. **3D Secure**: Enable 3DS for high-value transactions
4. **Velocity Checks**: Monitor transaction frequency and amounts
5. **Device Fingerprinting**: Track devices making repeated failed attempts

```javascript
async function validateTransaction(transaction) {
  const risks = [];
  
  // Check velocity
  const recentCount = await getRecentTransactionCount(transaction.customerId);
  if (recentCount > 10) {
    risks.push('HIGH_VELOCITY');
  }
  
  // Check amount against limits
  if (transaction.amount > transaction.customer.limit) {
    risks.push('AMOUNT_EXCEEDS_LIMIT');
  }
  
  // Check for high-risk countries
  if (transaction.country === 'HIGH_RISK') {
    risks.push('HIGH_RISK_COUNTRY');
  }
  
  return {
    approved: risks.length === 0,
    risks,
    score: calculateRiskScore(risks)
  };
}
```

### 8.5 Rate Limiting

Our API implements rate limiting to prevent abuse:

| Tier | Requests/Minute | Burst |
|------|-----------------|-------|
| Sandbox | 60 | 100 |
| Standard | 300 | 500 |
| Premium | 1000 | 2000 |
| Enterprise | Custom | Custom |

**Rate Limit Headers:**

```http
X-RateLimit-Limit: 300
X-RateLimit-Remaining: 295
X-RateLimit-Reset: 1708000200
```

---

## 9. Error Handling

### 9.1 Error Response Format

All errors follow a consistent format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "type": "validation_error",
    "details": {}
  }
}
```

### 9.2 Common Error Codes

#### Authentication Errors

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_API_KEY` | 401 | API key is invalid or expired |
| `MISSING_API_KEY` | 401 | API key not provided |
| `INVALID_SIGNATURE` | 401 | Request signature verification failed |

#### Wallet Errors

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `WALLET_NOT_FOUND` | 404 | Wallet does not exist |
| `WALLET_INACTIVE` | 400 | Wallet is frozen or inactive |
| `WALLET_ALREADY_EXISTS` | 400 | User already has a wallet |
| `INSUFFICIENT_FUNDS` | 400 | Wallet balance too low |
| `WALLET_LIMIT_EXCEEDED` | 400 | Transaction exceeds wallet limits |

#### Transfer Errors

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_BANK_CODE` | 400 | Invalid bank code |
| `INVALID_ACCOUNT_NUMBER` | 400 | Invalid account number |
| `ACCOUNT_NAME_MISMATCH` | 400 | Account name doesn't match |
| `TRANSFER_FAILED` | 400 | Transfer failed, contact support |
| `DAILY_LIMIT_EXCEEDED` | 400 | Daily transfer limit exceeded |

#### Payment Errors

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `CARD_DECLINED` | 400 | Card was declined |
| `INSUFFICIENT_FUNDS` | 400 | Insufficient funds on card |
| `INVALID_CARD` | 400 | Invalid card details |
| `CARD_EXPIRED` | 400 | Card has expired |
| `3DS_REQUIRED` | 400 | 3D Secure authentication needed |
| `OTP_REQUIRED` | 400 | OTP verification required |

#### Rate Limiting Errors

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |

### 9.3 Error Handling Example

```javascript
async function makePayment(paymentData) {
  try {
    const response = await axios.post(
      'https://api-sandbox.upaying.com/v1/payments/charge',
      paymentData,
      { headers: authHeaders }
    );
    return response.data;
  } catch (error) {
    if (error.response) {
      const { code, message, details } = error.response.data.error;
      
      switch (code) {
        case 'INSUFFICIENT_FUNDS':
          // Notify customer to add funds
          notifyCustomer('Insufficient funds');
          break;
        case 'CARD_DECLINED':
          // Prompt customer to use different card
          promptNewCard();
          break;
        case '3DS_REQUIRED':
          // Redirect to 3D Secure
          redirectTo3DS(error.response.data.data.authorization.redirectUrl);
          break;
        default:
          // Generic error handling
          showError(message);
      }
    }
    throw error;
  }
}
```

---

## 10. Sandbox Environment

### 10.1 Overview

The sandbox environment allows you to test all API functionality without moving real money. It mirrors the production API with test data.

**Base URLs:**

| Environment | URL |
|-------------|-----|
| Sandbox | `https://api-sandbox.upaying.com/v1` |
| Production | `https://api.upaying.com/v1` |

### 10.2 Test Cards

Use these test cards for sandbox testing:

| Card Number | Brand | Result |
|-------------|-------|--------|
| `4084084084084081` | Visa | Success |
| `5060990580000218499` | Verve | Success |
| `5555555555554444` | Mastercard | Success |
| `4000000000000002` | Visa | Card Declined |
| `4000000000009995` | Visa | Insufficient Funds |

**Test Card Credentials:**

- **OTP**: `123456` (for all test cards)
- **PIN**: `1234` (for PIN transactions)
- **AVS**: Any value works

### 10.3 Test Bank Accounts

| Bank | Account Number | Account Name | Result |
|------|----------------|--------------|--------|
| GTBank | 0000000000 | TEST USER | Success |
| First Bank | 0000000001 | TEST USER | Success |
| Any | 0000000002 | - | Failed |

### 10.4 Test Phone Numbers

| Service | Phone Number | Description |
|---------|--------------|-------------|
| Airtime | +2348010000001 | Successful recharge |
| Airtime | +2348010000002 | Failed - Invalid number |
| Data | +2348010000003 | Successful data bundle |

### 10.5 Sandbox Wallet Data

Pre-created test wallets:

| Wallet ID | Account Number | Balance | Status |
|-----------|----------------|---------|--------|
| `wl_sandbox_test001` | 8930000001 | ₦100,000 | Active |
| `wl_sandbox_test002` | 8930000002 | ₦50,000 | Active |
| `wl_sandbox_test003` | 8930000003 | ₦0 | Active |
| `wl_sandbox_frozen` | 8930000099 | ₦10,000 | Frozen |

---

## 11. Production Go-Live Checklist

Before going live with your integration, complete this checklist:

### 11.1 Configuration

- [ ] Verify all API endpoints use production URLs
- [ ] Update environment variables with production keys
- [ ] Configure production webhook endpoints
- [ ] Set up SSL/TLS certificates on your servers

### 11.2 Security

- [ ] Verify domain ownership in dashboard
- [ ] Enable webhook signature verification
- [ ] Implement request signing for sensitive operations
- [ ] Review and enforce rate limiting
- [ ] Enable fraud detection rules

### 11.3 Testing

- [ ] Complete sandbox testing for all payment flows
- [ ] Test successful and failed transactions
- [ ] Test webhook delivery and handling
- [ ] Perform end-to-end testing with real test cards
- [ ] Test error handling scenarios

### 11.4 Compliance

- [ ] Complete merchant KYC verification
- [ ] Ensure PCI-DSS compliance (if storing card data)
- [ ] Add required legal pages (Terms, Privacy Policy)
- [ ] Configure refund and dispute handling policies

### 11.5 Monitoring

- [ ] Set up production monitoring and alerting
- [ ] Configure error logging
- [ ] Establish incident response procedures
- [ ] Set up customer support contact information

### 11.6 Deployment

- [ ] Switch from sandbox to production API keys
- [ ] Enable production mode in dashboard
- [ ] Perform a live test transaction (use small amount)
- [ ] Verify settlement schedule with UpPaying

---

## 12. Example Use Cases

### 12.1 E-Commerce Checkout

Complete checkout flow for an online store:

```javascript
const express = require('express');
const axios = require('axios');
const app = express();

const UPPYING_SECRET_KEY = process.env.UPPYING_SECRET_KEY;
const UPPYING_PUBLIC_KEY = process.env.UPPYING_PUBLIC_KEY;

// Step 1: Initialize checkout
app.post('/api/checkout/initialize', async (req, res) => {
  const { amount, email, items } = req.body;
  
  const reference = 'ORD-' + Date.now();
  
  try {
    const response = await axios.post(
      'https://api-sandbox.upaying.com/v1/payments/charge',
      {
        amount: amount * 100, // Convert to kobo
        currency: 'NGN',
        email,
        reference,
        metadata: {
          items,
          amount,
          order_type: 'ecommerce'
        },
        callbackUrl: `https://yoursite.com/api/checkout/callback`
      },
      {
        headers: {
          'Authorization': `Bearer ${UPPYING_SECRET_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    res.json({
      success: true,
      data: response.data.data,
      checkoutUrl: `https://checkout.upaying.com/pay/${response.data.data.reference}`
    });
  } catch (error) {
    res.status(400).json({ error: error.response.data.error });
  }
});

// Step 2: Handle webhook callback
app.post('/api/checkout/callback', async (req, res) => {
  const { event, data } = req.body;
  
  if (event === 'payment.success') {
    const { reference, amount, status } = data;
    
    // Update order status
    await updateOrderStatus(reference, 'paid');
    
    // Send confirmation email
    await sendOrderConfirmation(reference);
    
    // Trigger fulfillment
    await triggerFulfillment(reference);
  }
  
  res.json({ received: true });
});

app.listen(3000);
```

### 12.2 Mobile Wallet App

Build a complete wallet application:

```javascript
const UpPaying = require('@upaying/sdk');

const upaying = new UpPaying({
  secretKey: process.env.UPPYING_SECRET_KEY
});

class WalletService {
  // Create user wallet
  async createWallet(user) {
    return await upaying.wallets.create({
      userId: user.id,
      type: 'main',
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone
    });
  }
  
  // Get wallet balance
  async getBalance(walletId) {
    const wallet = await upaying.wallets.get(walletId);
    return {
      balance: wallet.balance,
      available: wallet.availableBalance
    };
  }
  
  // Transfer to another wallet
  async transferToWallet(fromWalletId, toAccountNumber, amount, narration) {
    // Get recipient wallet by account number
    const recipient = await upaying.wallets.getByAccountNumber(toAccountNumber);
    
    return await upaying.wallets.transfer({
      fromWalletId,
      toWalletId: recipient.id,
      amount: amount * 100,
      narration
    });
  }
  
  // Send to bank
  async sendToBank(walletId, bankCode, accountNumber, amount) {
    return await upaying.transfers.toBank({
      walletId,
      amount: amount * 100,
      bankCode,
      accountNumber
    });
  }
  
  // Get transaction history
  async getStatement(walletId, startDate, endDate) {
    return await upaying.wallets.getStatement(walletId, {
      startDate,
      endDate,
      limit: 50
    });
  }
  
  // Pay bills
  async buyAirtime(phoneNumber, amount, provider) {
    return await upaying.bills.pay({
      service: 'airtime',
      provider,
      phoneNumber,
      amount: amount * 100
    });
  }
  
  async buyData(phoneNumber, plan, provider) {
    return await upaying.bills.pay({
      service: 'data',
      provider,
      phoneNumber,
      dataPlan: plan
    });
  }
}

module.exports = new WalletService();
```

### 12.3 Agent Banking POS

Power a POS terminal for agent banking:

```javascript
const UpPaying = require('@upaying/sdk');

const agent = new UpPaying({
  secretKey: process.env.AGENT_SECRET_KEY
});

class AgentService {
  // Cash In (Customer deposits cash to wallet)
  async cashIn(agentWalletId, customerPhone, amount) {
    // Verify customer wallet exists
    const customer = await agent.customers.verify(customerPhone);
    
    // Credit customer wallet
    const transaction = await agent.wallets.credit({
      walletId: customer.walletId,
      amount: amount * 100,
      reference: `CI-${Date.now()}`,
      narration: `Cash deposit from Agent ${agent.id}`
    });
    
    // Record agent commission
    const commission = this.calculateCommission(amount);
    await this.creditAgentCommission(agentWalletId, commission);
    
    return {
      transactionId: transaction.id,
      amount,
      commission,
      customerBalance: transaction.newBalance
    };
  }
  
  // Cash Out (Customer withdraws cash)
  async cashOut(agentWalletId, customerPhone, amount) {
    // Verify customer wallet
    const customer = await agent.customers.verify(customerPhone);
    
    // Check sufficient balance
    const wallet = await agent.wallets.get(customer.walletId);
    if (wallet.availableBalance < amount * 100) {
      throw new Error('Insufficient customer balance');
    }
    
    // Debit customer wallet
    const transaction = await agent.wallets.debit({
      walletId: customer.walletId,
      amount: amount * 100,
      reference: `CO-${Date.now()}`,
      narration: `Cash withdrawal at Agent ${agent.id}`
    });
    
    // Record agent commission
    const commission = this.calculateCommission(amount);
    await this.creditAgentCommission(agentWalletId, commission);
    
    return {
      transactionId: transaction.id,
      amount,
      commission,
      customerBalance: transaction.newBalance
    };
  }
  
  // Bill Payment (Airtime, Data, etc.)
  async processBillPayment(agentWalletId, service, phoneNumber, amount) {
    const result = await agent.bills.pay({
      service,
      phoneNumber,
      amount: amount * 100,
      agentId: agentWalletId
    });
    
    const commission = this.calculateBillCommission(service, amount);
    await this.creditAgentCommission(agentWalletId, commission);
    
    return { ...result, commission };
  }
  
  calculateCommission(amount) {
    if (amount < 1000) return 10;
    if (amount < 5000) return 20;
    if (amount < 10000) return 30;
    return 50;
  }
  
  calculateBillCommission(service, amount) {
    const rates = {
      airtime: 0.02,
      data: 0.03,
      electricity: 0.015,
      tv: 0.02
    };
    return Math.round(amount * (rates[service] || 0.01));
  }
}

module.exports = new AgentService();
```

### 12.4 Subscription Payments

Set up recurring payments for subscriptions:

```javascript
const UpPaying = require('@upaying/sdk');

const upaying = new UpPaying({
  secretKey: process.env.UPPYING_SECRET_KEY
});

class SubscriptionService {
  // Create subscription plan
  async createPlan(name, amount, interval) {
    return await upaying.subscriptions.create({
      name,
      amount: amount * 100,
      currency: 'NGN',
      interval, // 'daily', 'weekly', 'monthly', 'yearly'
      metadata: {
        features: ['unlimited_access', 'premium_support']
      }
    });
  }
  
  // Subscribe a customer
  async subscribeCustomer(customerEmail, cardId, planId) {
    return await upaying.subscriptions.createSubscription({
      customer: customerEmail,
      card: cardId,
      plan: planId,
      startDate: new Date().toISOString()
    });
  }
  
  // Handle webhook for subscription events
  async handleSubscriptionWebhook(event) {
    switch (event.type) {
      case 'subscription.created':
        await this.activateSubscription(event.data);
        break;
      case 'subscription.payment_success':
        await this.recordPayment(event.data);
        break;
      case 'subscription.payment_failed':
        await this.handleFailedPayment(event.data);
        break;
      case 'subscription.expired':
        await this.deactivateSubscription(event.data);
        break;
      case 'subscription.cancelled':
        await this.cancelSubscription(event.data);
        break;
    }
  }
  
  // Cancel subscription
  async cancelSubscription(subscriptionId) {
    return await upaying.subscriptions.cancel(subscriptionId);
  }
}

module.exports = new SubscriptionService();
```

---

## Support & Resources

### Documentation

- [API Reference](https://docs.upaying.com)
- [Status Page](https://status.upaying.com)
- [Changelog](https://docs.upaying.com/changelog)

### Developer Tools

- [Postman Collection](https://postman.upaying.com)
- [SDK Downloads](https://developers.upaying.com/sdks)
- [Code Samples](https://github.com/upaying)

### Support Channels

- **Technical Support**: support@upaying.com
- **Sales**: sales@upaying.com
- **Emergency**: +234 700 UPPYING

---

<p align="center">
  &copy; 2026 UpPaying Technologies. All rights reserved.
</p>
