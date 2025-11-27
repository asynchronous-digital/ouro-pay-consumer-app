# Backend API Requirements - Quick Summary

## Job 1: User Verification Check After Login

### What We Need:
After user logs in and lands on dashboard, we need to check if the user is verified or not.

### API Required:
**Endpoint:** `GET /api/user/verification-status`

**What it should return:**
```json
{
  "is_verified": true,  // or false
  "permissions": {
    "can_add_money": true,      // false if not verified
    "can_trade_gold": true,      // false if not verified
    "can_purchase_gold": true    // false if not verified
  }
}
```

### Business Logic:
- If `is_verified = false`, user **CANNOT**:
  - ❌ Add money to wallet
  - ❌ Trade gold
  - ❌ Purchase gold
  
- If `is_verified = true`, user **CAN** do everything ✅

---

## Job 2: App Lock with PIN/Fingerprint/Face Unlock

### What We Need:
When app goes to background and comes back, user must unlock the app using:
- PIN (6 digits), OR
- Fingerprint, OR  
- Face unlock

### APIs Required:

#### 1. Create PIN
**Endpoint:** `POST /api/user/security/pin/create`
```json
{
  "pin": "123456",
  "pin_confirmation": "123456"
}
```

#### 2. Verify PIN (when unlocking app)
**Endpoint:** `POST /api/user/security/pin/verify`
```json
{
  "pin": "123456"
}
```
**Returns:** `{"verified": true}` or `{"verified": false}`

#### 3. Update PIN
**Endpoint:** `PUT /api/user/security/pin/update`
```json
{
  "current_pin": "123456",
  "new_pin": "654321",
  "new_pin_confirmation": "654321"
}
```

#### 4. Enable Biometric (Fingerprint/Face)
**Endpoint:** `POST /api/user/security/biometric/enable`
```json
{
  "biometric_type": "fingerprint",  // or "face"
  "pin": "123456"  // confirm with PIN
}
```

#### 5. Check Security Settings
**Endpoint:** `GET /api/user/security/pin/status`
**Returns:**
```json
{
  "pin_enabled": true,
  "biometric_enabled": true
}
```

---

## Important Security Rules:

### For PIN:
1. ✅ Hash the PIN (use bcrypt or similar) - **NEVER store plain text**
2. ✅ Allow only 3 failed attempts
3. ✅ Lock account for 30 minutes after 3 failed attempts
4. ✅ PIN must be 6 digits
5. ✅ PIN cannot be 123456, 111111, etc. (too simple)

### For Biometric:
1. ✅ Biometric verification happens on **phone only** (not on server)
2. ✅ **NO API CALL** needed when user unlocks with fingerprint/face
3. ✅ API only needed to enable/disable biometric feature in settings
4. ✅ Server only stores: "biometric enabled: yes/no"
5. ✅ **DO NOT** store fingerprint/face data on server

---

## How It Works (Mobile App Side):

### User Verification Flow:
1. User logs in ✅
2. User goes to dashboard ✅
3. App calls `GET /api/user/verification-status` 🆕
4. If not verified → Disable "Add Money", "Trade", "Purchase" buttons 🆕
5. Show message: "Your account is pending verification" 🆕

### App Lock Flow:
1. User sets up PIN in app settings 🆕
2. User optionally enables fingerprint/face unlock 🆕
3. When app goes to background for > 30 seconds 🆕
4. When app comes back → Show unlock screen 🆕
5. User chooses unlock method:
   - **Option A: PIN** → App calls `POST /api/user/security/pin/verify` 🆕
   - **Option B: Fingerprint/Face** → Verified locally on device (NO API call) 🆕
6. If verified → User can access app ✅

**Important:** Biometric unlock is instant and offline - no server communication needed!

---

## Timeline Request:
Please let us know:
1. When can these APIs be ready?
2. Will you implement all endpoints or need us to prioritize?
3. Any questions or concerns?

---

## Full Details:
See `BACKEND_REQUIREMENTS.md` for complete API specifications with all request/response examples.
