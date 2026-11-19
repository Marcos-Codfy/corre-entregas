import 'package:flutter/material.dart';

import '../theme/corre_theme.dart';
import '../tokens/corre_tokens.dart';

/// Cartão de superfície com borda suave.
class CorreCard extends StatelessWidget {
  const CorreCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(CorreSpace.lg),
    this.tone,
    this.highlighted = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Quando definido, pinta o fundo com o tom (ex.: resumo de preço).
  final CorreTone? tone;

  /// Borda na cor da marca (ex.: plano recomendado).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = tone == null ? Theme.of(context).colorScheme.surface : context.toneColors(tone!).$2;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: CorreRadius.mdAll,
        side: BorderSide(color: highlighted ? p.brand : (tone == null ? p.line : Colors.transparent), width: highlighted ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Etiqueta curta de status.
class CorreBadge extends StatelessWidget {
  const CorreBadge({super.key, required this.label, this.tone = CorreTone.neutral, this.icon});
  final String label;
  final CorreTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = context.toneColors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CorreSpace.sm + 2, vertical: CorreSpace.xs - 1),
      decoration: BoxDecoration(color: bg, borderRadius: CorreRadius.pillAll),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: CorreSpace.xs)],
        Text(label, style: context.text.labelSmall?.copyWith(color: fg)),
      ]),
    );
  }
}

/// Avatar com iniciais.
class CorreAvatar extends StatelessWidget {
  const CorreAvatar({super.key, required this.name, this.size = 40, this.tone = CorreTone.brand});
  final String name;
  final double size;
  final CorreTone tone;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = context.toneColors(tone);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(initials(name), style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: size * .38)),
    );
  }
}

/// Item de lista padrão.
class CorreListItem extends StatelessWidget {
  const CorreListItem({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.onTap});
  final String title;
  final String? subtitle;
  final Widget? leading, trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: CorreSpace.md),
          child: Row(children: [
            if (leading != null) ...[leading!, const SizedBox(width: CorreSpace.md)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: context.text.titleSmall),
                if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
              ]),
            ),
            ?trailing,
          ]),
        ),
      );
}

/// Título de seção com ação opcional.
class CorreSectionHeader extends StatelessWidget {
  const CorreSectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: CorreSpace.lg, bottom: CorreSpace.sm),
        child: Row(children: [
          Expanded(child: Text(title, style: context.text.titleMedium)),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ]),
      );
}

/// Linha "rótulo ........ valor".
class CorreKeyValue extends StatelessWidget {
  const CorreKeyValue({super.key, required this.label, required this.value, this.emphasize = false, this.valueColor});
  final String label, value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = emphasize ? context.text.titleMedium : context.text.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CorreSpace.xs),
      child: Row(children: [
        Expanded(child: Text(label, style: emphasize ? style : style?.copyWith(color: context.palette.ink2))),
        Text(value, style: (emphasize ? style : context.text.titleSmall)?.copyWith(color: valueColor)),
      ]),
    );
  }
}

/// Indicador numérico para painéis.
class CorreKpiTile extends StatelessWidget {
  const CorreKpiTile({super.key, required this.label, required this.value, this.delta, this.positive = true, this.icon});
  final String label, value;
  final String? delta;
  final bool positive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CorreCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[Icon(icon, size: 18, color: p.ink3), const SizedBox(width: CorreSpace.xs)],
          Expanded(child: Text(label, style: context.text.bodySmall, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: CorreSpace.sm),
        Text(value, style: context.text.headlineSmall),
        if (delta != null)
          Text(delta!, style: context.text.labelMedium?.copyWith(color: positive ? p.success : p.error)),
      ]),
    );
  }
}

/// Barra de progresso com rótulo.
class CorreProgressBar extends StatelessWidget {
  const CorreProgressBar({super.key, required this.value, this.label});
  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: CorreRadius.pillAll,
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor: context.palette.line,
            color: context.palette.brand,
          ),
        ),
        if (label != null) ...[const SizedBox(height: CorreSpace.xs), Text(label!, style: context.text.bodySmall)],
      ]);
}

/// Tabela simples para o painel web, com rolagem horizontal em telas estreitas.
class CorreDataTable extends StatelessWidget {
  const CorreDataTable({super.key, required this.columns, required this.rows, this.onRowTap});
  final List<String> columns;
  final List<List<Widget>> rows;
  final ValueChanged<int>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return CorreCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: DataTable(
              headingTextStyle: context.text.labelMedium,
              showCheckboxColumn: false,
              columns: [for (final c in columns) DataColumn(label: Text(c))],
              rows: [
                for (var i = 0; i < rows.length; i++)
                  DataRow(
                    onSelectChanged: onRowTap == null ? null : (_) => onRowTap!(i),
                    cells: [for (final cell in rows[i]) DataCell(cell)],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
