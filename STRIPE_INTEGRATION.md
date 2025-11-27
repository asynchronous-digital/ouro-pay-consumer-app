# Stripe Integration

## Overview
Stripe payment integration has been added to the app for processing credit/debit card payments when users add money to their wallet.

## Implementation Details

### 1. Dependencies
Added `flutter_stripe` package to `pubspec.yaml`:
```yaml
dependencies:
  flutter_stripe: ^12.1.0
```

### 2. Configuration
Added Stripe publishable key configuration in `lib/config/app_config.dart`:
```dart
static String get stripePublishableKey {
  final envKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  return envKey ?? '';
}
```

### 3. Initialization
Stripe is initialized in `lib/main_dev.dart`:
```dart
// Initialize Stripe
final stripeKey = AppConfig.stripePublishableKey;
if (stripeKey.isNotEmpty) {
  Stripe.publishableKey = stripeKey;
}
```

### 4. Payment Flow
The payment flow is implemented in `lib/pages/add_money_page.dart`:

1. User selects payment method (bank_transfer, credit_card, or debit_card)
2. User enters amount and notes
3. App calls backend API to create deposit
4. Backend returns `client_secret` if payment method requires Stripe
5. App initializes Stripe Payment Sheet with the client secret
6. User completes payment in Stripe UI
7. App navigates to deposit history on success

### 5. Backend Requirements
The backend API endpoint `POST /deposits` should:
- Accept payment method in the request
- For credit_card/debit_card payments:
  - Create a Stripe PaymentIntent
  - Return the `client_secret` in the response
- For bank_transfer:
  - Process normally without Stripe

**Response format:**
```json
{
  "success": true,
  "message": "Deposit created successfully",
  "data": {
    "id": 1,
    "reference": "DEP-123456",
    ...
  },
  "client_secret": "pi_xxx_secret_xxx"  // Only for card payments
}
```

### 6. Environment Variables
Add to `.env.development` and `.env.production`:
```
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx  # Test key for development
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxx  # Live key for production
```

## Testing
1. Ensure Stripe publishable key is set in environment file
2. Select "Credit Card" or "Debit Card" as payment method
3. Enter amount and notes
4. Submit - Stripe payment sheet should appear
5. Complete test payment with test card: `4242 4242 4242 4242`

## Notes
- Bank transfers bypass Stripe and use the existing flow
- Stripe Payment Sheet handles all card input and validation
- The app uses Stripe's customizable appearance with the app's gold color theme
