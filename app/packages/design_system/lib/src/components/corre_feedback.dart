import 'package:flutter/material.dart';

import '../theme/corre_theme.dart';
import '../tokens/corre_tokens.dart';
import 'corre_button.dart';

/// Avisos rápidos padronizados.
abstract final class CorreToast {
  static void show(BuildContext context, String message, {CorreTone tone = CorreTone.neutral}) {
    final (fg, _) = context.toneColors(tone);
    final icon = switch (tone) {
      CorreTone.success => Icons.check_circle,
      CorreTone.error => Icons.error,
      CorreTone.warning => Icons.warning_amber_rounded,
      _ => Icons.info_outline,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: tone == CorreTone.neutral ? Colors.white : fg),
              const SizedBox(width: CorreSpace.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

/// Diálogo de confirmação. Retorna true se confirmado.
Future<bool> showCorreConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Voltar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: ctx.text.titleLarge),
      content: Text(message, style: ctx.text.bodyLarge),
      actionsPadding: const EdgeInsets.fromLTRB(CorreSpace.lg, 0, CorreSpace.lg, CorreSpace.lg),
      actions: [
        Row(
          children: [
            Expanded(
              child: CorreButton(
                label: cancelLabel,
                variant: CorreButtonVariant.ghost,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            const SizedBox(width: CorreSpace.sm),
            Expanded(
              child: CorreButton(
                label: confirmLabel,
                variant: destructive ? CorreButtonVariant.danger : CorreButtonVariant.primary,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Abre um bottom sheet padrão com título.
Future<T?> showCorreSheet<T>(BuildContext context, {required String title, required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          CorreSpace.lg,
          0,
          CorreSpace.lg,
          CorreSpace.lg + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ctx.text.titleLarge),
            const SizedBox(height: CorreSpace.md),
            child,
          ],
        ),
      ),
    ),
  );
}

/// Estado vazio, de erro ou de "sem conexão".
class CorreEmptyState extends StatelessWidget {
  const CorreEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tone = CorreTone.neutral,
  });

  final IconData icon;
  final String title;
  final String? message, actionLabel;
  final VoidCallback? onAction;
  final CorreTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = context.toneColors(tone);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CorreSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(CorreSpace.lg),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: fg),
            ),
            const SizedBox(height: CorreSpace.lg),
            Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: CorreSpace.sm),
              Text(message!, style: context.text.bodyMedium, textAlign: TextAlign.center),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: CorreSpace.lg),
              CorreButton(label: actionLabel!, onPressed: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bloco cinza pulsante para carregamento.
class CorreSkeleton extends StatefulWidget {
  const CorreSkeleton({super.key, this.width = double.infinity, this.height = 16, this.radius = CorreRadius.sm});
  final double width, height, radius;

  @override
  State<CorreSkeleton> createState() => _CorreSkeletonState();
}

class _CorreSkeletonState extends State<CorreSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: .45, end: 1.0).animate(_c),
    child: Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(color: context.palette.line, borderRadius: BorderRadius.circular(widget.radius)),
    ),
  );
}

/// Faixa de aviso dentro da tela (ex.: sem internet, documento vencendo).
class CorreBanner extends StatelessWidget {
  const CorreBanner({
    super.key,
    required this.message,
    this.tone = CorreTone.info,
    this.icon,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final CorreTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = context.toneColors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CorreSpace.md, vertical: CorreSpace.sm),
      decoration: BoxDecoration(color: bg, borderRadius: CorreRadius.mdAll),
      child: Row(
        children: [
          Icon(icon ?? Icons.info_outline, color: fg, size: 20),
          const SizedBox(width: CorreSpace.sm),
          Expanded(
            child: Text(message, style: context.text.bodyMedium?.copyWith(color: context.palette.ink)),
          ),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
