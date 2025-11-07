import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/app.dart';

void main() {
  AppConfig.setEnvironment(Environment.production);
  runApp(const OuroPayApp());
}
