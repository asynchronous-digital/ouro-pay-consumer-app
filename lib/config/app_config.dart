import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment {
  development,
  production,
}

class AppConfig {
  static Environment _environment = Environment.development;

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static String get appName {
    // Try to get from env, fallback to default
    final envName = dotenv.env['APP_NAME'];
    if (envName != null && envName.isNotEmpty) {
      return envName;
    }

    switch (_environment) {
      case Environment.development:
        return 'Ouro Pay Dev';
      case Environment.production:
        return 'Ouro Pay';
    }
  }

  static String get baseUrl {
    // Get from environment variable
    final envBaseUrl = dotenv.env['BASE_URL'];
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    // Fallback to default if env not loaded
    switch (_environment) {
      case Environment.development:
        return 'http://64.225.108.213/api/v1';
      case Environment.production:
        return 'http://64.225.108.213/api/v1';
    }
  }

  static String get apiVersion {
    // Try to get from env, fallback to default
    final envVersion = dotenv.env['API_VERSION'];
    if (envVersion != null && envVersion.isNotEmpty) {
      return envVersion;
    }

    switch (_environment) {
      case Environment.development:
        return 'v1';
      case Environment.production:
        return 'v1';
    }
  }

  static bool get isDebugMode {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.production:
        return false;
    }
  }

  static String get bundleId {
    // Try to get from env, fallback to default
    final envBundleId = dotenv.env['BUNDLE_ID'];
    if (envBundleId != null && envBundleId.isNotEmpty) {
      return envBundleId;
    }

    switch (_environment) {
      case Environment.development:
        return 'com.ouropay.consumer.dev';
      case Environment.production:
        return 'com.ouropay.consumer';
    }
  }

  static Duration get connectionTimeout {
    // Try to get from env, fallback to default
    final envTimeout = dotenv.env['CONNECTION_TIMEOUT'];
    if (envTimeout != null && envTimeout.isNotEmpty) {
      final timeoutSeconds = int.tryParse(envTimeout);
      if (timeoutSeconds != null) {
        return Duration(seconds: timeoutSeconds);
      }
    }

    switch (_environment) {
      case Environment.development:
        return const Duration(seconds: 30);
      case Environment.production:
        return const Duration(seconds: 15);
    }
  }

  static int get maxRetries {
    // Try to get from env, fallback to default
    final envRetries = dotenv.env['MAX_RETRIES'];
    if (envRetries != null && envRetries.isNotEmpty) {
      final retries = int.tryParse(envRetries);
      if (retries != null) {
        return retries;
      }
    }

    switch (_environment) {
      case Environment.development:
        return 3;
      case Environment.production:
        return 2;
    }
  }

  static String get stripePublishableKey {
    final envKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    return envKey ?? '';
  }
}
