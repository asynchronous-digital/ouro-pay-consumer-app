# Stripe Integration - Keys Required

## Based on stripe-test.html Analysis

After reviewing the `stripe-test.html` file, here's what you need:

## 1. Stripe Publishable Key (Required for Mobile App)

**Add to `.env.development`:**
```
STRIPE_PUBLISHABLE_KEY=pk_test_51KndLMJMbcYUPEPUmIyiSrN4KE50Za4XplFUAbFVhysGnWy4XVfdsUs9JCunGQHMmWuSPKZ5B02gi74G43zR7Q0I008TVRQGpG
```

This is the **same key** used in the HTML test file (line 47).

## 2. Backend API Endpoint

The backend should respond to: `POST /api/v1/deposits`

**Request:**
```json
{
  "currency_code": "USD",
  "amount": 100.00,
  "payment_method": "card"
}
```

**Response (from backend):**
```json
{
  "success": true,
  "message": "Deposit created successfully",
  "data": {
    "id": 123,
    "reference": "DEP-123456",
    "client_secret": "pi_xxx_secret_xxx",  // ← This is what mobile app needs
    ...
  }
}
```

## Key Differences: Web vs Mobile

### Web (stripe-test.html):
- Uses `stripe.confirmCardPayment()` with Card Element
- User manually enters card details in a form
- Uses JavaScript Stripe.js library

### Mobile (Flutter):
- Uses **Stripe Payment Sheet** (recommended by Stripe for mobile)
- Payment Sheet provides a pre-built, native UI
- Handles card input, validation, and 3D Secure automatically
- Better UX for mobile users

## Implementation Summary

### Mobile App Flow:
1. User enters amount and notes
2. App calls `POST /deposits` → Backend creates PaymentIntent
3. Backend returns `client_secret` in response
4. App initializes Payment Sheet with `client_secret`
5. App presents Payment Sheet (user enters card)
6. Stripe processes payment
7. App shows success/failure

### What Backend Needs to Do:
```php
// When payment_method is 'card'
$paymentIntent = \Stripe\PaymentIntent::create([
    'amount' => $amount * 100,
    'currency' => 'usd',
    'payment_method_types' => ['card'],
]);

return [
    'success' => true,
    'data' => [
        'id' => $deposit->id,
        'client_secret' => $paymentIntent->client_secret,  // ← Critical!
        ...
    ]
];
```

## Testing

Use Stripe test cards:
- **Success:** `4242 4242 4242 4242`
- **Decline:** `4000 0000 0000 0002`
- **Requires 3D Secure:** `4000 0025 0000 3155`

Any future expiry date and any 3-digit CVC works for test mode.

## Summary

**You only need ONE key for the mobile app:**
- ✅ `STRIPE_PUBLISHABLE_KEY` (starts with `pk_test_` or `pk_live_`)

The backend developer needs:
- ✅ `STRIPE_SECRET_KEY` (starts with `sk_test_` or `sk_live_`)

Both keys come from the same Stripe account.
