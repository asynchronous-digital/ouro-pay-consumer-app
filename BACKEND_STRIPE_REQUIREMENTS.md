# Backend Requirements for Stripe Integration

## What the Backend Developer Needs to Implement

### 1. Install Stripe SDK
```bash
composer require stripe/stripe-php
```

### 2. Add Stripe Secret Key to Environment
```env
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxx  # Test key
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxxx  # Production key
```

### 3. Modify `POST /deposits` Endpoint

**Current behavior:** Creates deposit record and returns deposit data

**New behavior:** 
- Check if `payment_method` is `credit_card` or `debit_card`
- If yes, create a Stripe PaymentIntent
- Return the `client_secret` in the response

### 4. Code Implementation Example

```php
public function store(Request $request)
{
    $validated = $request->validate([
        'currency_code' => 'required|string',
        'amount' => 'required|numeric|min:0.01',
        'payment_method' => 'required|string|in:bank_transfer,credit_card,debit_card',
        'notes' => 'nullable|string',
    ]);

    // Create deposit record
    $deposit = Deposit::create([
        'user_id' => auth()->id(),
        'currency_code' => $validated['currency_code'],
        'amount' => $validated['amount'],
        'payment_method' => $validated['payment_method'],
        'notes' => $validated['notes'],
        'status' => 'pending',
    ]);

    $clientSecret = null;

    // If payment method is card, create Stripe PaymentIntent
    if (in_array($validated['payment_method'], ['credit_card', 'debit_card'])) {
        \Stripe\Stripe::setApiKey(config('services.stripe.secret'));

        $paymentIntent = \Stripe\PaymentIntent::create([
            'amount' => $validated['amount'] * 100, // Convert to cents
            'currency' => strtolower($validated['currency_code']),
            'payment_method_types' => ['card'],
            'metadata' => [
                'deposit_id' => $deposit->id,
                'user_id' => auth()->id(),
            ],
        ]);

        $clientSecret = $paymentIntent->client_secret;
        
        // Store payment intent ID for webhook handling
        $deposit->update([
            'stripe_payment_intent_id' => $paymentIntent->id,
        ]);
    }

    return response()->json([
        'success' => true,
        'message' => 'Deposit created successfully',
        'data' => $deposit,
        'client_secret' => $clientSecret, // THIS IS CRITICAL!
    ]);
}
```

### 5. Add Stripe Webhook Handler

Create a webhook endpoint to handle payment confirmations:

```php
// Route: POST /webhooks/stripe
public function handleStripeWebhook(Request $request)
{
    \Stripe\Stripe::setApiKey(config('services.stripe.secret'));
    
    $endpoint_secret = config('services.stripe.webhook_secret');
    
    $payload = $request->getContent();
    $sig_header = $request->header('Stripe-Signature');
    
    try {
        $event = \Stripe\Webhook::constructEvent(
            $payload, $sig_header, $endpoint_secret
        );
    } catch(\Exception $e) {
        return response()->json(['error' => 'Invalid signature'], 400);
    }

    // Handle the event
    switch ($event->type) {
        case 'payment_intent.succeeded':
            $paymentIntent = $event->data->object;
            
            // Update deposit status
            $deposit = Deposit::where('stripe_payment_intent_id', $paymentIntent->id)->first();
            if ($deposit) {
                $deposit->update([
                    'status' => 'completed',
                    'processed_at' => now(),
                ]);
                
                // Credit user's wallet
                $this->creditUserWallet($deposit);
            }
            break;
            
        case 'payment_intent.payment_failed':
            $paymentIntent = $event->data->object;
            
            $deposit = Deposit::where('stripe_payment_intent_id', $paymentIntent->id)->first();
            if ($deposit) {
                $deposit->update(['status' => 'failed']);
            }
            break;
    }

    return response()->json(['status' => 'success']);
}
```

### 6. Database Migration

Add column to deposits table:

```php
Schema::table('deposits', function (Blueprint $table) {
    $table->string('stripe_payment_intent_id')->nullable()->after('payment_method');
});
```

### 7. Configure Stripe Webhook in Stripe Dashboard

1. Go to Stripe Dashboard → Developers → Webhooks
2. Add endpoint: `https://your-api-domain.com/api/v1/webhooks/stripe`
3. Select events to listen for:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
4. Copy the webhook signing secret and add to `.env`:
   ```
   STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx
   ```

## Response Format Required

### For Card Payments (credit_card, debit_card):
```json
{
  "success": true,
  "message": "Deposit created successfully",
  "data": {
    "id": 123,
    "reference": "DEP-123456",
    "currency_code": "EUR",
    "amount": 100.00,
    "payment_method": "credit_card",
    "status": "pending",
    ...
  },
  "client_secret": "pi_3ABC123_secret_XYZ789"
}
```

### For Bank Transfer:
```json
{
  "success": true,
  "message": "Deposit created successfully",
  "data": {
    "id": 124,
    "reference": "DEP-123457",
    "currency_code": "EUR",
    "amount": 100.00,
    "payment_method": "bank_transfer",
    "status": "pending",
    ...
  },
  "client_secret": null
}
```

## Testing

Use Stripe test cards:
- **Success:** `4242 4242 4242 4242`
- **Decline:** `4000 0000 0000 0002`
- **Requires authentication:** `4000 0025 0000 3155`

Any expiry date in the future and any 3-digit CVC will work.

## Summary Checklist for Backend Developer

- [ ] Install Stripe PHP SDK
- [ ] Add `STRIPE_SECRET_KEY` to environment
- [ ] Modify `POST /deposits` to create PaymentIntent for card payments
- [ ] Return `client_secret` in response
- [ ] Add `stripe_payment_intent_id` column to deposits table
- [ ] Create webhook endpoint `/webhooks/stripe`
- [ ] Configure webhook in Stripe Dashboard
- [ ] Add `STRIPE_WEBHOOK_SECRET` to environment
- [ ] Test with Stripe test cards
- [ ] Provide Stripe publishable key for mobile app (starts with `pk_test_` or `pk_live_`)
