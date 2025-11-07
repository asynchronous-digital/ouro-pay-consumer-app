# Ouro Pay Consumer App - Development Commands

.PHONY: help dev prod clean deps doctor

# Default target
help:
	@echo "Available commands:"
	@echo "  make deps     - Get Flutter dependencies"
	@echo "  make clean    - Clean build files"
	@echo "  make doctor   - Run Flutter doctor"
	@echo "  make dev      - Run development flavor"
	@echo "  make prod     - Run production flavor"
	@echo "  make dev-ios  - Run development flavor on iOS"
	@echo "  make prod-ios - Run production flavor on iOS"
	@echo "  make build-dev-android  - Build development APK"
	@echo "  make build-prod-android - Build production APK"

# Flutter commands
deps:
	flutter pub get

clean:
	flutter clean
	flutter pub get

doctor:
	flutter doctor

# Run development flavor
dev:
	flutter run --flavor development --target lib/main_dev.dart

# Run production flavor  
prod:
	flutter run --flavor production --target lib/main_prod.dart

# Run development flavor on iOS
dev-ios:
	flutter run --flavor development --target lib/main_dev.dart

# Run production flavor on iOS
prod-ios:
	flutter run --flavor production --target lib/main_prod.dart

# Build Android APKs
build-dev-android:
	flutter build apk --flavor development --target lib/main_dev.dart

build-prod-android:
	flutter build apk --flavor production --target lib/main_prod.dart

# Build iOS (requires Xcode)
build-dev-ios:
	flutter build ios --flavor development --target lib/main_dev.dart --no-codesign

build-prod-ios:
	flutter build ios --flavor production --target lib/main_prod.dart --no-codesign