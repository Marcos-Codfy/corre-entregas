import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/corre_theme.dart';
import '../tokens/corre_tokens.dart';

/// Campo de texto com rótulo acima, ajuda e erro.
class CorreTextField extends StatelessWidget {
  const CorreTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.initialValue,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint, helper, errorText, initialValue;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText, enabled;
  final ValueChanged<String>? onChanged, onSubmitted;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: context.text.labelMedium),
        const SizedBox(height: CorreSpace.xs + 2),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          maxLines: obscureText ? 1 : maxLines,
          textInputAction: textInputAction,
          style: context.text.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            errorText: errorText,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Campo de senha com botão de mostrar/ocultar.
class CorrePasswordField extends StatefulWidget {
  const CorrePasswordField({super.key, this.label = 'Senha', this.controller, this.errorText, this.initialValue});
  final String label;
  final TextEditingController? controller;
  final String? errorText, initialValue;

  @override
  State<CorrePasswordField> createState() => _CorrePasswordFieldState();
}

class _CorrePasswordFieldState extends State<CorrePasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => CorreTextField(
    label: widget.label,
    controller: widget.controller,
    initialValue: widget.initialValue,
    errorText: widget.errorText,
    obscureText: _hidden,
    prefixIcon: Icons.lock_outline,
    suffix: IconButton(
      tooltip: _hidden ? 'Mostrar senha' : 'Ocultar senha',
      icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
      onPressed: () => setState(() => _hidden = !_hidden),
    ),
  );
}

/// Máscara de telefone brasileiro: (63) 9 9999-0000.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = formatPhone(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formata dígitos como telefone: 63999990000 → (63) 9 9999-0000.
String formatPhone(String raw) {
  var d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length > 11) d = d.substring(0, 11);
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 0) b.write('(');
    if (i == 2) b.write(') ');
    if (i == 3 && d.length == 11) b.write(' ');
    if ((d.length == 11 && i == 7) || (d.length < 11 && i == 6)) b.write('-');
    b.write(d[i]);
  }
  return b.toString();
}

/// Máscara de moeda em reais a partir dos centavos digitados.
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final cents = int.tryParse(digits.isEmpty ? '0' : digits) ?? 0;
    final text = formatBrl(cents / 100);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formata valor em reais: 1234.5 → "R$ 1.234,50".
String formatBrl(num value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  final sign = negative ? '−' : '';
  return '${sign}R\$ $intPart,${parts[1]}';
}

/// Campo de busca arredondado.
class CorreSearchField extends StatelessWidget {
  const CorreSearchField({super.key, this.hint = 'Buscar', this.onChanged, this.controller});
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: CorreRadius.pillAll,
      borderSide: BorderSide(color: context.palette.line),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        border: border,
        enabledBorder: border,
      ),
    );
  }
}
