import 'package:flutter/material.dart';

import '../theme/corre_theme.dart';
import '../tokens/corre_tokens.dart';

enum CorreButtonVariant { primary, secondary, accent, ghost, danger }

enum CorreButtonSize { small, medium, large }

/// Botão padrão. Mostra carregando e bloqueia toque quando [loading] = true.
class CorreButton extends StatelessWidget {
  const CorreButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CorreButtonVariant.primary,
    this.size = CorreButtonSize.medium,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final CorreButtonVariant variant;
  final CorreButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg, border) = switch (variant) {
      CorreButtonVariant.primary => (p.brand, Colors.white, Colors.transparent),
      CorreButtonVariant.secondary => (p.brandLight, p.brand, Colors.transparent),
      CorreButtonVariant.accent => (p.accent, const Color(0xFF16202A), Colors.transparent),
      CorreButtonVariant.ghost => (Colors.transparent, p.ink, p.line),
      CorreButtonVariant.danger => (p.error.withValues(alpha: .12), p.error, Colors.transparent),
    };
    final (height, font, pad) = switch (size) {
      CorreButtonSize.small => (36.0, 13.0, CorreSpace.md),
      CorreButtonSize.medium => (48.0, 15.0, CorreSpace.lg),
      CorreButtonSize.large => (58.0, 17.0, CorreSpace.xl),
    };
    final enabled = onPressed != null && !loading;

    final Widget child = loading
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: font + 4), const SizedBox(width: CorreSpace.sm)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: CorreDuration.fast,
        opacity: onPressed == null ? .45 : 1,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: CorreRadius.mdAll,
            side: BorderSide(color: border, width: 1.5),
          ),
          child: InkWell(
            borderRadius: CorreRadius.mdAll,
            onTap: enabled ? onPressed : null,
            child: Container(
              height: height,
              padding: EdgeInsets.symmetric(horizontal: pad),
              alignment: Alignment.center,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: fg, fontSize: font, fontWeight: FontWeight.w700),
                child: IconTheme.merge(
                  data: IconThemeData(color: fg),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Botão redondo só com ícone.
class CorreIconButton extends StatelessWidget {
  const CorreIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.tone = CorreTone.neutral,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final CorreTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = context.toneColors(tone);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(CorreSpace.sm + 2),
            child: Icon(icon, size: 20, color: fg),
          ),
        ),
      ),
    );
  }
}
