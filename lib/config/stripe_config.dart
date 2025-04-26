class StripeConfig {
  static const String publishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  static const String secretKey = String.fromEnvironment('STRIPE_SECRET_KEY');
} 