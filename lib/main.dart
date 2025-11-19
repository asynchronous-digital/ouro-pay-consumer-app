import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try loading the development env first, fall back to default .env if missing.
  try {
    await dotenv.load(fileName: '.env.development');
  } catch (_) {
    // ignore and try default
    try {
      await dotenv.load();
    } catch (_) {
      // If no env file is present, continue without throwing so the app can still run.
    }
  }

  // Default to development environment
  AppConfig.setEnvironment(Environment.development);
  runApp(const OuroPayApp());
}
