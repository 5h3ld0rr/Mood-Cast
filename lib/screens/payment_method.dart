import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String planTitle;
  final String planPrice;

  const PaymentMethodScreen({
    super.key,
    required this.planTitle,
    required this.planPrice,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedCardType = 'Visa'; // Default selection

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );

      // Mock processing delay
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Close loading
        _showSuccessDialog();
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 64,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are now subscribed to ${widget.planTitle}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to subscription
              Navigator.of(context).pop(); // Back to profile or home
            },
            child: const Text(
              'Great!',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Text(
          'Payment Method',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Card Preview
              _buildCreditCardPreview(),
              const SizedBox(height: 32),

              const Text(
                'Select Payment Method',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Card Selection
              Row(
                children: [
                  Expanded(
                    child: _buildCardSelector(
                      'Visa',
                      'https://raw.githubusercontent.com/muhammederdem/credit-card-form/master/src/assets/images/visa.png',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCardSelector(
                      'Mastercard',
                      'https://raw.githubusercontent.com/muhammederdem/credit-card-form/master/src/assets/images/mastercard.png',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'Card Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Cardholder Name',
                controller: _nameController,
                hint: 'John Doe',
                onChanged: (v) => setState(() {}),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Card Number',
                controller: _cardNumberController,
                hint: '0000 0000 0000 0000',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberFormatter(),
                ],
                validator: (v) => v!.length < 19 ? 'Invalid card number' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Expiry Date',
                      controller: _expiryController,
                      hint: 'MM/YY',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateFormatter(),
                      ],
                      validator: (v) => v!.length < 5 ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'CVV',
                      controller: _cvvController,
                      hint: '123',
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (v) => v!.length < 3 ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCardPreview() {
    bool isVisa = _selectedCardType == 'Visa';
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isVisa
              ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
              : [const Color(0xFF37474F), const Color(0xFF212121)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isVisa ? Colors.blue : Colors.black).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.contactless_outlined,
                color: Colors.white54,
                size: 32,
              ),
              Image.network(
                isVisa
                    ? 'https://raw.githubusercontent.com/muhammederdem/credit-card-form/master/src/assets/images/visa.png'
                    : 'https://raw.githubusercontent.com/muhammederdem/credit-card-form/master/src/assets/images/mastercard.png',
                height: 30,
                color: isVisa ? Colors.white : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '**** **** **** ****',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CARD HOLDER',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    _nameController.text.isEmpty
                        ? 'YOUR NAME'
                        : _nameController.text.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPIRES',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    'MM/YY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardSelector(String type, String logoUrl) {
    bool isSelected = _selectedCardType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedCardType = type),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Image.network(
            logoUrl,
            height: 24,
            errorBuilder: (context, error, stackTrace) => Text(
              type,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: AppTheme.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) return newValue;
    String enteredData = newValue.text.replaceAll(' ', '');
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < enteredData.length; i++) {
      buffer.write(enteredData[i]);
      int index = i + 1;
      if (index % 4 == 0 && index != enteredData.length) buffer.write(' ');
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) return newValue;
    String enteredData = newValue.text.replaceAll('/', '');
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < enteredData.length; i++) {
      buffer.write(enteredData[i]);
      int index = i + 1;
      if (index % 2 == 0 && index != enteredData.length) buffer.write('/');
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
}
