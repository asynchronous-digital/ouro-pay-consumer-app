import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables for production
  await dotenv.load(fileName: '.env.production');
  
  AppConfig.setEnvironment(Environment.production);
  runApp(const OuroPayApp());
}
