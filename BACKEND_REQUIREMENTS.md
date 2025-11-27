# Backend API Requirements for Ouro Pay Consumer App

## Document Version: 1.0
**Date:** November 27, 2025  
**Prepared for:** Backend Development Team

---

## Table of Contents
1. [Overview](#overview)
2. [User Flow](#user-flow)
3. [Required API Endpoints](#required-api-endpoints)
4. [Detailed API Specifications](#detailed-api-specifications)
5. [Security Considerations](#security-considerations)

---

## Overview

This document outlines the backend API requirements for implementing user verification checks and app security features (PIN, fingerprint, and face unlock) in the Ouro Pay Consumer App.

---

## User Flow

### Current Flow
1. User completes sign-up process
2. User is redirected to **Login Page**
3. After successful login, user lands on **Dashboard Screen**

### Required Flow Enhancement
1. User completes sign-up → Redirected to **Login Page** ✅ (Already implemented)
2. User logs in → Redirected to **Dashboard Screen** ✅ (Already implemented)
3. **Dashboard loads** → App calls API to check user verification status ⚠️ (NEW REQUIREMENT)
4. **If user is NOT verified:**
   - User **CANNOT** add money
   - User **CANNOT** trade gold
   - User **CANNOT** purchase gold
   - Display appropriate UI message/banner indicating verification pending
5. **App Security:** When app goes to background and returns, user must unlock using:
   - PIN code, OR
   - Fingerprint, OR
   - Face unlock

---

## Required API Endpoints

### 1. User Verification Status Check API
**Purpose:** Check if the logged-in user has been verified by admin/system

### 2. PIN Management APIs
**Purpose:** Allow users to set, update, and verify PIN for app unlock

### 3. Biometric Token Storage (Optional)
**Purpose:** Store encrypted biometric authentication tokens if needed

---

## Detailed API Specifications

### 1. User Verification Status Check

#### Endpoint
```
GET /api/user/verification-status
```

#### Headers
```json
{
  "Authorization": "Bearer {access_token}",
  "Content-Type": "application/json"
}
```

#### Request
No request body required (user identified by access token)

#### Response - Success (200 OK)
```json
{
  "success": true,
  "data": {
    "user_id": 12345,
    "email": "user@example.com",
    "is_verified": true,
    "verification_status": "approved",
    "verified_at": "2025-11-25T10:30:00Z",
    "verification_type": "manual",
    "permissions": {
      "can_add_money": true,
      "can_trade_gold": true,
      "can_purchase_gold": true,
      "can_withdraw": true
    }
  },
  "message": "User verification status retrieved successfully"
}
```

#### Response - User Not Verified (200 OK)
```json
{
  "success": true,
  "data": {
    "user_id": 12345,
    "email": "user@example.com",
    "is_verified": false,
    "verification_status": "pending",
    "verified_at": null,
    "verification_type": null,
    "pending_reason": "Document verification in progress",
    "permissions": {
      "can_add_money": false,
      "can_trade_gold": false,
      "can_purchase_gold": false,
      "can_withdraw": false
    }
  },
  "message": "User verification is pending"
}
```

#### Response - Verification Rejected (200 OK)
```json
{
  "success": true,
  "data": {
    "user_id": 12345,
    "email": "user@example.com",
    "is_verified": false,
    "verification_status": "rejected",
    "verified_at": null,
    "verification_type": null,
    "rejection_reason": "Invalid identity document",
    "permissions": {
      "can_add_money": false,
      "can_trade_gold": false,
      "can_purchase_gold": false,
      "can_withdraw": false
    }
  },
  "message": "User verification was rejected"
}
```

#### Response - Unauthorized (401)
```json
{
  "success": false,
  "message": "Unauthorized. Invalid or expired token"
}
```

#### Verification Status Values
- `pending` - User submitted documents, waiting for admin review
- `approved` - User is verified and can perform all actions
- `rejected` - User verification was rejected, needs to resubmit documents
- `suspended` - User account is temporarily suspended

---

### 2. PIN Management APIs

#### 2.1 Set/Create PIN

**Endpoint**
```
POST /api/user/security/pin/create
```

**Headers**
```json
{
  "Authorization": "Bearer {access_token}",
  "Content-Type": "application/json"
}
```

**Request Body**
```json
{
  "pin": "123456",
  "pin_confirmation": "123456"
}
```

**Response - Success (200 OK)**
```json
{
  "success": true,
  "message": "PIN created successfully",
  "data": {
    "pin_enabled": true,
    "created_at": "2025-11-27T22:00:00Z"
  }
}
```

**Response - Validation Error (422)**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "pin": ["PIN must be 6 digits"],
    "pin_confirmation": ["PIN confirmation does not match"]
  }
}
```

**Validation Rules:**
- PIN must be exactly 6 digits
- PIN cannot be sequential (e.g., 123456, 654321)
- PIN cannot be repetitive (e.g., 111111, 000000)
- PIN and PIN confirmation must match

---

#### 2.2 Update/Change PIN

**Endpoint**
```
PUT /api/user/security/pin/update
```

**Headers**
```json
{
  "Authorization": "Bearer {access_token}",
  "Content-Type": "application/json"
}
```

**Request Body**
```json
{
  "current_pin": "123456",
  "new_pin": "654321",
  "new_pin_confirmation": "654321"
}
```

**Response - Success (200 OK)**
```json
{
  "success": true,
  "message": "PIN updated successfully",
  "data": {
    "updated_at": "2025-11-27T22:05:00Z"
  }
}
```

**Response - Invalid Current PIN (400)**
```json
{
  "success": false,
  "message": "Current PIN is incorrect"
}
```

---

#### 2.3 Verify PIN

**Endpoint**
```
POST /api/user/security/pin/verify
```

**Headers**
```json
{
  "Authorization": "Bearer {access_token}",
  "Content-Type": "application/json"
}
```

**Request Body**
```json
{
  "pin": "123456"
}
```

**Response - Success (200 OK)**
```json
{
  "success": true,
  "message": "PIN verified successfully",
  "data": {
    "verified": true,
    "session_token": "temp_session_xyz123" // Optional: temporary session token
  }
}
```

**Response - Invalid PIN (400)**
```json
{
  "success": false,
  "message": "Invalid PIN",
  "data": {
    "verified": false,
    "attempts_remaining": 2,
    "locked_until": null
  }
}
```

**Response - Account Locked (429)**
```json
{
  "success": false,
  "message": "Too many failed attempts. Account locked temporarily",
  "data": {
    "verified": false,
    "attempts_remaining": 0,
    "locked_until": "2025-11-27T22:30:00Z"
  }
}
```

**Security Rules:**
- Maximum 3 failed attempts
- After 3 failed attempts, lock for 30 minutes
- Reset attempt counter on successful verification

---

#### 2.4 Check PIN Status

**Endpoint**
```
GET /api/user/security/pin/status
```

**Headers**
```json
{
  "Authorization": "Bearer {access_token}",
  "Content-Type": "application/json"
}
```

**Response - Success (200 OK)**
```json
{
  "success": true,
  "data": {
    "pin_enabled": true,
    "biometric_enabled": true,
    "created_at": "2025-11-27T22:00:00Z",
    "last_updated": "2025-11-27T22:05:00Z"
  }
}
```

---

#### 2.5 Disable PIN

**Endpoint**
```
DELETE /api/user/security/pin/disable
```

**Headers**
```json
{
  "Authorization": "Bearer {access_token}",
  "Content-Type": "application/json"
}
```

**Request Body**
```json
{
  "pin": "123456",
  "password": "user_account_password" // For additional security
}
```

**Response - Success (200 OK)**
```json
{
  "success": true,
  "message": "PIN disabled successfully",
  "data": {
    "pin_enabled": false
  }
}
```

---

### 3. Biometric Authentication Settings

#### 3.1 Enable Biometric Authentication

**Endpoint**
```
POST /api/user/security/biometric/enable
```

**Headers**
```json
{
  "Authorization": "Bearer {access_token}",
  "Content-Type": "application/json"
}
```

**Request Body**
```json
{
  "biometric_type": "fingerprint", // or "face" or "both"
  "device_id": "unique_device_identifier",
  "pin": "123456" // Require PIN confirmation
}
```

**Response - Success (200 OK)**
```json
{
  "success": true,
  "message": "Biometric authentication enabled successfully",
  "data": {
    "biometric_enabled": true,
    "biometric_type": "fingerprint",
    "enabled_at": "2025-11-27T22:10:00Z"
  }
}
```

---

#### 3.2 Disable Biometric Authentication

**Endpoint**
```
POST /api/user/security/biometric/disable
```

**Headers**
```json
{
  "Authorization": "Bearer {access_token}",
  "Content-Type": "application/json"
}
```

**Request Body**
```json
{
  "pin": "123456" // Require PIN confirmation
}
```

**Response - Success (200 OK)**
```json
{
  "success": true,
  "message": "Biometric authentication disabled successfully",
  "data": {
    "biometric_enabled": false
  }
}
```

---

## Security Considerations

### 1. PIN Storage
- **NEVER** store PIN in plain text
- Use strong hashing algorithm (bcrypt, Argon2, or PBKDF2)
- Add salt to each PIN hash
- Store hash in secure database column

### 2. Rate Limiting
- Implement rate limiting on PIN verification endpoint
- Maximum 3 attempts per 30-minute window
- Lock account temporarily after failed attempts

### 3. Biometric Authentication
- Biometric verification happens on **client-side** (device)
- Backend only stores:
  - Whether biometric is enabled
  - Device ID for security
  - Biometric type preference
- **DO NOT** store biometric data on server

### 4. Session Management
- After successful PIN/biometric verification, optionally issue temporary session token
- Session token valid for app session only
- Invalidate on app background/foreground if needed

### 5. HTTPS Only
- All endpoints must use HTTPS
- Implement certificate pinning for production

---

## Implementation Notes for Mobile App

### App Lock Flow
1. **App goes to background:**
   - Start timer
   - If app is in background for > 30 seconds, require unlock

2. **App returns to foreground:**
   - Check if PIN/biometric is enabled
   - Show unlock screen (PIN or biometric)
   - Call `/api/user/security/pin/verify` if PIN entered
   - On successful verification, allow access

3. **Biometric Authentication:**
   - Use device's native biometric API (fingerprint/face)
   - Verification happens locally on device
   - No API call needed for biometric (only for enabling/disabling feature)

### User Verification Check
1. **On Dashboard Load:**
   - Call `/api/user/verification-status`
   - Store verification status in app state
   - If `is_verified: false`, disable buttons for:
     - Add Money
     - Trade Gold
     - Purchase Gold
   - Show banner/message: "Your account is pending verification"

2. **Periodic Check:**
   - Re-check verification status every time user navigates to dashboard
   - Or implement push notification when verification status changes

---

## Questions for Backend Team

Please confirm the following:

1. ✅ Can you implement the `/api/user/verification-status` endpoint?
2. ✅ Can you implement all PIN management endpoints?
3. ✅ Can you implement biometric settings endpoints?
4. ⚠️ What hashing algorithm will you use for PIN storage?
5. ⚠️ Will you implement rate limiting on PIN verification?
6. ⚠️ Do you need any additional fields in the requests/responses?
7. ⚠️ What is the expected timeline for these API implementations?

---

## Contact

For questions or clarifications, please contact:
- **Mobile Development Team Lead:** [Your Name]
- **Email:** [Your Email]

---

**End of Document**
