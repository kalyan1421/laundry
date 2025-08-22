import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final String countryCode;

  const PhoneInputField({
    Key? key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.enabled = true,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.countryCode = '+91',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: focusNode?.hasFocus == true
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: focusNode?.hasFocus == true ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Country code
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                countryCode,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            // Phone number input
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                enabled: enabled,
                // Enhanced autofill hints for better Google integration
                autofillHints: const [
                  AutofillHints.telephoneNumber,
                  AutofillHints.telephoneNumberNational,
                  AutofillHints.telephoneNumberDevice,
                ],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                  // Custom formatter for Indian phone numbers
                  _IndianPhoneNumberFormatter(),
                ],
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: hintText ?? '9876 543210',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFA0AEC0),
                    fontWeight: FontWeight.w400,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(0)),
                  ),
                  errorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: validator,
                onChanged: onChanged,
                onFieldSubmitted: (_) => onFieldSubmitted?.call(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom formatter for Indian phone numbers with spacing
class _IndianPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 4) {
        formatted += ' ';
      }
      formatted += text[i];
    }
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
