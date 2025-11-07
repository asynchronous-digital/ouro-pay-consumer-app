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
    switch (_environment) {
      case Environment.development:
        return 'Ouro Pay Dev';
      case Environment.production:
        return 'Ouro Pay';
    }
  }

  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        return 'https://api-dev.ouropay.com';
      case Environment.production:
        return 'https://api.ouropay.com';
    }
  }

  static String get apiVersion {
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
    switch (_environment) {
      case Environment.development:
        return 'com.ouropay.consumer.dev';
      case Environment.production:
        return 'com.ouropay.consumer';
    }
  }

  static Duration get connectionTimeout {
    switch (_environment) {
      case Environment.development:
        return const Duration(seconds: 30);
      case Environment.production:
        return const Duration(seconds: 15);
    }
  }

  static int get maxRetries {
    switch (_environment) {
      case Environment.development:
        return 3;
      case Environment.production:
        return 2;
    }
  }
}
