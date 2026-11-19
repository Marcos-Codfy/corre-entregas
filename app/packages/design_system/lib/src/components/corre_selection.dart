import 'package:flutter/material.dart';

import '../theme/corre_theme.dart';
import '../tokens/corre_tokens.dart';

/// Chip selecionável (filtros, tags).
class CorreChip extends StatelessWidget {
  const CorreChip({super.key, required this.label, this.selected = false, this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.brand : p.ink2;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.brandLight : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: CorreRadius.pillAll,
          side: BorderSide(color: selected ? p.brand : p.line, width: 1.5),
        ),
        child: InkWell(
          borderRadius: CorreRadius.pillAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CorreSpace.md, vertical: CorreSpace.sm - 2),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: CorreSpace.xs)],
              Text(label, style: context.text.labelMedium?.copyWith(color: color)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Linha com texto e switch.
class CorreSwitchTile extends StatelessWidget {
  const CorreSwitchTile({super.key, required this.title, this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: context.text.titleSmall),
        subtitle: subtitle == null ? null : Text(subtitle!, style: context.text.bodySmall),
        value: value,
        onChanged: onChanged,
      );
}

/// Opções exclusivas em linha (ex.: Hoje / 7 dias / Mês).
class CorreSegmented<T> extends StatelessWidget {
  const CorreSegmented({super.key, required this.options, required this.value, required this.onChanged});
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: CorreSpace.sm,
        runSpacing: CorreSpace.sm,
        children: [
          for (final e in options.entries)
            CorreChip(label: e.value, selected: e.key == value, onTap: () => onChanged(e.key)),
        ],
      );
}

/// Caixa de seleção com rótulo.
class CorreCheckbox extends StatelessWidget {
  const CorreCheckbox({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(label, style: context.text.bodyLarge),
        value: value,
        onChanged: onChanged,
      );
}

/// Lista suspensa com rótulo.
class CorreDropdown<T> extends StatelessWidget {
  const CorreDropdown({super.key, required this.label, required this.items, required this.value, required this.onChanged});
  final String label;
  final Map<T, String> items;
  final T value;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: context.text.labelMedium),
          const SizedBox(height: CorreSpace.xs + 2),
          DropdownButtonFormField<T>(
            initialValue: value,
            items: [for (final e in items.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: onChanged,
          ),
        ],
      );
}
