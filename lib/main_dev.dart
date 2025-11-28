import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/app.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables for development
  await dotenv.load(fileName: '.env.development');

  AppConfig.setEnvironment(Environment.development);

  // Initialize Stripe
  final stripeKey = AppConfig.stripePublishableKey;
  if (stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
    Stripe.merchantIdentifier = 'merchant.com.ouropay.consumer';
    Stripe.urlScheme = 'ouropay';
    await Stripe.instance.applySettings();
  }

  runApp(const OuroPayApp());
}
