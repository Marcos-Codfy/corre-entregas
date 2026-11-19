import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/corre_theme.dart';
import '../tokens/corre_tokens.dart';
import 'corre_display.dart';
import 'corre_inputs.dart';

/// Logo em texto: "corre."
class CorreLogo extends StatelessWidget {
  const CorreLogo({super.key, this.size = 28, this.subtitle});
  final double size;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('corre', style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: p.brand, letterSpacing: -.5)),
      Text('.', style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: p.accent)),
      if (subtitle != null) ...[
        const SizedBox(width: CorreSpace.sm),
        Text(subtitle!, style: context.text.bodyMedium),
      ],
    ]);
  }
}

/// Contagem regressiva circular da oferta de corrida.
class CorreCountdownRing extends StatefulWidget {
  const CorreCountdownRing({super.key, required this.total, this.size = 96, this.onFinished, this.paused = false});
  final Duration total;
  final double size;
  final VoidCallback? onFinished;
  final bool paused;

  @override
  State<CorreCountdownRing> createState() => _CorreCountdownRingState();
}

class _CorreCountdownRingState extends State<CorreCountdownRing> {
  late int _left = widget.total.inSeconds;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.paused) return;
      if (_left <= 1) {
        _t?.cancel();
        setState(() => _left = 0);
        widget.onFinished?.call();
        return;
      }
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final frac = _left / math.max(1, widget.total.inSeconds);
    return Semantics(
      label: '$_left segundos para aceitar',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: frac,
              strokeWidth: 8,
              backgroundColor: p.line,
              color: frac < .3 ? p.error : p.brand,
            ),
          ),
          Text('${_left}s', style: context.text.headlineSmall?.copyWith(color: frac < .3 ? p.error : p.brand)),
        ]),
      ),
    );
  }
}

/// Estado de uma etapa na linha do tempo.
enum CorreStepState { done, current, pending }

class CorreStep {
  const CorreStep(this.label, this.state, {this.time});
  final String label;
  final CorreStepState state;
  final String? time;
}

/// Linha do tempo vertical das etapas da entrega.
class CorreStepTimeline extends StatelessWidget {
  const CorreStepTimeline({super.key, required this.steps});
  final List<CorreStep> steps;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(children: [
      for (var i = 0; i < steps.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 24,
              child: Column(children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: switch (steps[i].state) {
                      CorreStepState.done => p.brand,
                      CorreStepState.current => p.accent,
                      CorreStepState.pending => Colors.transparent,
                    },
                    border: Border.all(color: steps[i].state == CorreStepState.pending ? p.line : Colors.transparent, width: 2),
                  ),
                  child: steps[i].state == CorreStepState.done ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                ),
                if (i < steps.length - 1)
                  Expanded(child: Container(width: 2, color: steps[i].state == CorreStepState.done ? p.brand : p.line)),
              ]),
            ),
            const SizedBox(width: CorreSpace.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: CorreSpace.md),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      steps[i].label,
                      style: steps[i].state == CorreStepState.pending
                          ? context.text.bodyMedium?.copyWith(color: p.ink3)
                          : context.text.titleSmall,
                    ),
                  ),
                  if (steps[i].time != null) Text(steps[i].time!, style: context.text.bodySmall),
                ]),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// Entrada do código de entrega (4 dígitos).
class CorreCodeInput extends StatefulWidget {
  const CorreCodeInput({super.key, this.length = 4, required this.onCompleted, this.errorText});
  final int length;
  final ValueChanged<String> onCompleted;
  final String? errorText;

  @override
  State<CorreCodeInput> createState() => _CorreCodeInputState();
}

class _CorreCodeInputState extends State<CorreCodeInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = _controller.text;
    return Column(children: [
      GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: Stack(children: [
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 64,
              child: TextField(
                key: const Key('code-input'),
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(widget.length)],
                onChanged: (v) {
                  setState(() {});
                  if (v.length == widget.length) widget.onCompleted(v);
                },
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < widget.length; i++)
              Container(
                width: 56,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: CorreSpace.xs),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: CorreRadius.mdAll,
                  border: Border.all(
                    width: 2,
                    color: widget.errorText != null ? p.error : (i == value.length ? p.brand : p.line),
                  ),
                ),
                child: Text(i < value.length ? value[i] : '', style: context.text.headlineMedium),
              ),
          ]),
        ]),
      ),
      if (widget.errorText != null) ...[
        const SizedBox(height: CorreSpace.sm),
        Text(widget.errorText!, style: context.text.bodySmall?.copyWith(color: p.error)),
      ],
    ]);
  }
}

/// Linha de um resumo de preço.
class CorrePriceLine {
  const CorrePriceLine(this.label, this.value);
  final String label;
  final num value;
}

/// Resumo de preço com total.
class CorrePriceSummary extends StatelessWidget {
  const CorrePriceSummary({super.key, required this.lines, required this.total, this.footnote});
  final List<CorrePriceLine> lines;
  final num total;
  final String? footnote;

  @override
  Widget build(BuildContext context) => CorreCard(
        tone: CorreTone.brand,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final l in lines) CorreKeyValue(label: l.label, value: formatBrl(l.value)),
          const Divider(height: CorreSpace.lg),
          CorreKeyValue(label: 'Total', value: formatBrl(total), emphasize: true, valueColor: context.palette.brand),
          if (footnote != null) ...[
            const SizedBox(height: CorreSpace.xs),
            Text(footnote!, style: context.text.bodySmall),
          ],
        ]),
      );
}

/// Cartão de resumo de uma entrega (listas e acompanhamento).
class CorreDeliveryCard extends StatelessWidget {
  const CorreDeliveryCard({
    super.key,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusTone,
    this.value,
    this.onTap,
  });

  final String code, title, subtitle, statusLabel;
  final CorreTone statusTone;
  final num? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CorreCard(
        onTap: onTap,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$code · $title', style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(subtitle, style: context.text.bodySmall, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: CorreSpace.sm),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            CorreBadge(label: statusLabel, tone: statusTone),
            if (value != null) ...[const SizedBox(height: CorreSpace.xs), Text(formatBrl(value!), style: context.text.labelMedium)],
          ]),
        ]),
      );
}

enum CorreMarkerKind { courier, pickup, dropoff }

/// Marcador para mapas (moto, coleta, entrega).
class CorreMapMarker extends StatelessWidget {
  const CorreMapMarker({super.key, required this.kind, this.size = 36, this.label});
  final CorreMarkerKind kind;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (color, icon) = switch (kind) {
      CorreMarkerKind.courier => (p.accent, Icons.two_wheeler),
      CorreMarkerKind.pickup => (p.brand, Icons.storefront),
      CorreMarkerKind.dropoff => (p.info, Icons.home_rounded),
    };
    return Tooltip(
      message: label ?? '',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: CorreShadow.card,
        ),
        child: Icon(icon, color: kind == CorreMarkerKind.courier ? const Color(0xFF16202A) : Colors.white, size: size * .5),
      ),
    );
  }
}

/// Estrelas de avaliação (somente leitura ou selecionável).
class CorreRating extends StatelessWidget {
  const CorreRating({super.key, required this.value, this.onChanged, this.size = 28});
  final int value;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          InkWell(
            onTap: onChanged == null ? null : () => onChanged!(i),
            customBorder: const CircleBorder(),
            child: Icon(i <= value ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: context.palette.accent),
          ),
      ]);
}
