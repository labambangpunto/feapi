import 'package:flutter/services.dart';

class CurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isEmpty) return const TextEditingValue();

    String formatted = _addDots(numericOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addDots(String text) {
    String buffer = '';
    for (int i = 0; i < text.length; i++) {
      buffer = text[text.length - 1 - i] + buffer;
      if ((i + 1) % 3 == 0 && i != text.length - 1) buffer = '.$buffer';
    }
    return buffer;
  }
}
