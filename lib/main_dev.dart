import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables for development
  await dotenv.load(fileName: '.env.development');
  
  AppConfig.setEnvironment(Environment.development);
  runApp(const OuroPayApp());
}
