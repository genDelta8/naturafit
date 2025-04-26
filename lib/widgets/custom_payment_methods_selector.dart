import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/services/stripe_service.dart';
import 'package:flutter/services.dart';

class PaymentMethod {
  final String name;
  final List<PaymentField> fields;
  final IconData icon;

  PaymentMethod({
    required this.name,
    this.fields = const [],
    required this.icon,
  });
}

class PaymentField {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool isStripeField;
  final int? maxLength;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;

  PaymentField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.isStripeField = false,
    this.maxLength,
    this.formatters,
    this.validator,
  });
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    String numbers = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    
    for (int i = 0; i < numbers.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += numbers[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    String numbers = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    
    if (numbers.length >= 2) {
      formatted = '${numbers.substring(0, 2)}/${numbers.substring(2)}';
    } else {
      formatted = numbers;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CardValidation {
  static bool isValidCardNumber(String number) {
    if (number.isEmpty) return false;
    
    // Remove all non-digits
    number = number.replaceAll(RegExp(r'\D'), '');
    
    if (number.length < 13 || number.length > 19) return false;
    
    // Luhn Algorithm
    int sum = 0;
    bool alternate = false;
    
    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }
  
  static bool isValidExpiryDate(String month, String year) {
    if (month.isEmpty || year.isEmpty) return false;
    
    int expiryMonth = int.tryParse(month) ?? 0;
    int expiryYear = int.tryParse('20$year') ?? 0;
    
    if (expiryMonth < 1 || expiryMonth > 12) return false;
    
    DateTime now = DateTime.now();
    DateTime expiry = DateTime(expiryYear, expiryMonth + 1, 0);
    
    return expiry.isAfter(now);
  }
  
  static bool isValidCVC(String cvc) {
    if (cvc.isEmpty) return false;
    return cvc.length >= 3 && cvc.length <= 4;
  }
}

class CustomPaymentMethodsSelector extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onChanged;
  final List<Map<String, dynamic>>? initialValue;

  const CustomPaymentMethodsSelector({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<CustomPaymentMethodsSelector> createState() => _CustomPaymentMethodsSelectorState();
}

class _CustomPaymentMethodsSelectorState extends State<CustomPaymentMethodsSelector> {
  late final List<PaymentMethod> _availableMethods;
  final Map<String, bool> _selectedMethods = {};
  
  @override
  void initState() {
    super.initState();
    _availableMethods = [
      PaymentMethod(
        name: 'Cash',
        icon: Icons.payments_outlined,
      ),
      PaymentMethod(
        name: 'Card',
        icon: Icons.credit_card_outlined,
        fields: _createCardFields(),
      ),
      PaymentMethod(
        name: 'Bank',
        icon: Icons.account_balance_outlined,
        fields: _createBankFields(),
      ),
    ];

    // Initialize selected methods
    for (var method in _availableMethods) {
      _selectedMethods[method.name] = method.name == 'Cash';
    }

    _applyInitialValues();
  }

  List<PaymentField> _createCardFields() {
    return [
      PaymentField(
        label: 'Card Number',
        hint: 'Enter your card number',
        controller: TextEditingController(),
        keyboardType: TextInputType.number,
        isStripeField: true,
        maxLength: 19,
        formatters: [
          FilteringTextInputFormatter.digitsOnly,
          CardNumberInputFormatter(),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Card number is required';
          }
          if (!CardValidation.isValidCardNumber(value)) {
            return 'Invalid card number';
          }
          return null;
        },
      ),
      PaymentField(
        label: 'Expiry Date',
        hint: 'MM/YY',
        controller: TextEditingController(),
        keyboardType: TextInputType.number,
        isStripeField: true,
        maxLength: 5,
        formatters: [
          FilteringTextInputFormatter.digitsOnly,
          ExpiryDateInputFormatter(),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Expiry date is required';
          }
          final parts = value.split('/');
          if (parts.length != 2) return 'Invalid format';
          if (!CardValidation.isValidExpiryDate(parts[0], parts[1])) {
            return 'Invalid expiry date';
          }
          return null;
        },
      ),
      PaymentField(
        label: 'CVC',
        hint: 'Enter CVC',
        controller: TextEditingController(),
        keyboardType: TextInputType.number,
        isStripeField: true,
        maxLength: 4,
        formatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'CVC is required';
          }
          if (!CardValidation.isValidCVC(value)) {
            return 'Invalid CVC';
          }
          return null;
        },
      ),
    ];
  }

  List<PaymentField> _createBankFields() {
    return [
      PaymentField(
        label: 'Account Number',
        hint: 'Enter your account number',
        controller: TextEditingController(),
        keyboardType: TextInputType.number,
      ),
      PaymentField(
        label: 'Bank Name',
        hint: 'Enter your bank name',
        controller: TextEditingController(),
      ),
      PaymentField(
        label: 'Branch',
        hint: 'Enter your branch',
        controller: TextEditingController(),
      ),
    ];
  }

  void _applyInitialValues() {
    if (widget.initialValue != null) {
      // Reset all selections first
      for (var method in _availableMethods) {
        _selectedMethods[method.name] = false;
      }
      
      for (var methodData in widget.initialValue!) {
        final methodName = methodData['name'] as String;
        _selectedMethods[methodName] = true;

        final method = _availableMethods.firstWhere(
          (m) => m.name == methodName,
          orElse: () => PaymentMethod(
            name: methodName,
            icon: Icons.payment_outlined,
          ),
        );

        if (methodData['fields'] != null) {
          final fields = methodData['fields'] as Map<String, dynamic>;
          for (var field in method.fields) {
            if (fields.containsKey(field.label)) {
              field.controller.text = fields[field.label].toString();
            }
          }
        }
      }
    }
  }

  Widget _buildPaymentMethodSelector() {
    final selectedMethod = _availableMethods.firstWhere(
      (method) => _selectedMethods[method.name] ?? false,
      orElse: () => _availableMethods[0],
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: _availableMethods.map((method) {
          return Expanded(
            child: _buildMethodButton(method, selectedMethod),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMethodButton(PaymentMethod method, PaymentMethod selectedMethod) {
    return GestureDetector(
      onTap: () {
        setState(() {
          for (var key in _selectedMethods.keys) {
            _selectedMethods[key] = key == method.name;
          }
          _validateAndUpdate();
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Container(
          decoration: BoxDecoration(
            color: selectedMethod.name == method.name
                ? myGrey30
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selectedMethod.name == method.name ? myGrey90 : Colors.transparent,
              border: Border.all(
                color: selectedMethod.name == method.name ? Colors.transparent : myGrey60,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  method.icon,
                  size: 18,
                  color: selectedMethod.name == method.name ? Colors.white : myGrey90,
                ),
                const SizedBox(width: 8),
                Text(
                  method.name,
                  style: GoogleFonts.plusJakartaSans(
                    color: selectedMethod.name == method.name ? Colors.white : myGrey90,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentFields(PaymentMethod method) {
    return Column(
      children: method.fields.map((field) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CustomFocusTextField(
          label: field.label,
          hintText: field.hint,
          controller: field.controller,
          keyboardType: field.keyboardType,
          maxLength: field.maxLength,
          inputFormatters: field.formatters,
          validator: field.validator,
          onChanged: (_) => _validateAndUpdate(),
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMethod = _availableMethods.firstWhere(
      (method) => _selectedMethods[method.name] ?? false,
      orElse: () => _availableMethods[0],
    );
    final isAnySelected = _selectedMethods.containsValue(true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: myGrey90,
          ),
        ),
        
        const SizedBox(height: 8),
        _buildPaymentMethodSelector(),
        if (isAnySelected && selectedMethod.fields.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildPaymentFields(selectedMethod),
        ],
      ],
    );
  }

  void _validateAndUpdate() {
    bool isValid = true;
    final selectedMethod = _availableMethods.firstWhere(
      (method) => _selectedMethods[method.name] ?? false,
      orElse: () => _availableMethods[0],
    );

    if (selectedMethod.fields.isNotEmpty) {
      for (var field in selectedMethod.fields) {
        if (field.validator != null) {
          final error = field.validator!(field.controller.text);
          if (error != null) {
            isValid = false;
            break;
          }
        }
      }
    }

    if (isValid) {
      _updatePaymentMethods();
    }
  }

  void _updatePaymentMethods() async {
    final selectedMethods = _availableMethods
        .where((method) => _selectedMethods[method.name] ?? false)
        .map((method) async {
      Map<String, dynamic> result = {
        'name': method.name,
        'selected': true,
        'fields': <String, String>{},
      };

      if (method.name == 'Card' && method.fields.any((f) => f.isStripeField)) {
        try {
          final cardNumber = method.fields.firstWhere((f) => f.label == 'Card Number').controller.text;
          final expiryDate = method.fields.firstWhere((f) => f.label == 'Expiry Date').controller.text;
          final parts = expiryDate.split('/');
          final expMonth = parts[0];
          final expYear = parts[1];
          final cvc = method.fields.firstWhere((f) => f.label == 'CVC').controller.text;

          final stripeResult = await StripeService.createPaymentMethod(
            number: cardNumber,
            expMonth: expMonth,
            expYear: expYear,
            cvc: cvc,
          );

          if (stripeResult['success']) {
            result['stripePaymentMethodId'] = stripeResult['paymentMethod'];
          }
        } catch (e) {
          debugPrint('Error creating Stripe payment method: $e');
        }
      }

      // Add fields for any payment method type
      if (method.fields.isNotEmpty) {
        result['fields'] = Map<String, String>.fromEntries(
          method.fields.map((field) => MapEntry(field.label, field.controller.text))
        );
      }

      return result;
    }).toList();

    final List<Map<String, dynamic>> results = await Future.wait(selectedMethods);
    widget.onChanged(List<Map<String, dynamic>>.from(results));
  }

  @override
  void dispose() {
    for (var method in _availableMethods) {
      for (var field in method.fields) {
        field.controller.dispose();
      }
    }
    super.dispose();
  }
} 