import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class StripeService {
  // Test mode keys
  static const String _secretKey = '';
  // TODO: Load your Stripe secret key securely (e.g., from environment variables or a secure backend)
  static const String _publishableKey = 'pk_test_51QfNbvF89oa2KYgKyyAmDhZSfuYDHQ7SGY7PtHkJvmsDzaZkfNOBWBwLiWaZB3JWoULsC1b8Duk179PIki9jg1qZ00yo5t82ei';
  
  // For production, you would use:
  // static const String _secretKey = 'sk_live_your_secret_key_here';
  // static const String _publishableKey = 'pk_live_your_publishable_key_here';

  static Future<void> initialize() async {
    try {
      Stripe.publishableKey = _publishableKey;
      await Stripe.instance.applySettings();
      debugPrint('Stripe initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Stripe: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createPaymentMethod({
    required String number,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(),
          ),
        ),
      );

      return {
        'success': true,
        'paymentMethod': paymentMethod.id,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> createPaymentIntent({
    required String amount,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount,
          'currency': currency,
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
} 