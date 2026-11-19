import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../home/courier_controller.dart';
import 'run_controller.dart';

class RunPage extends ConsumerWidget {
  const RunPage({super.key, required this.deliveryId});
  final String deliveryId;

  static const _steps = [
    (DeliveryStatus.accepted, 'Indo ao comércio'),
    (DeliveryStatus.atMerchant, 'No comércio'),
    (DeliveryStatus.toCustomer, 'Indo ao cliente'),
    (DeliveryStatus.atCustomer, 'No cliente'),
    (DeliveryStatus.delivered, 'Entregue'),
  ];

  int _stepIndex(DeliveryStatus s) => switch (s) {
    DeliveryStatus.accepted => 0,
    DeliveryStatus.atMerchant => 1,
    DeliveryStatus.pickedUp || DeliveryStatus.toCustomer => 2,
    DeliveryStatus.atCustomer || DeliveryStatus.customerAbsent => 3,
    _ => 4,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(deliveryProvider(deliveryId)).value;
    final me = ref.watch(meProvider);
    final ctrl = ref.read(runControllerProvider);
    if (d == null || me == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final merchant = ref.watch(merchantProvider(d.merchantId)).value;
    if (d.status.isFinal || d.courierId != me.id) return _Finished(delivery: d);

    final action = RunAction.of(d.status);
    final target = ctrl.targetOf(d);
    final left = ctrl.remainingKm(d);
    final goingToCustomer = d.status == DeliveryStatus.toCustomer || d.status == DeliveryStatus.pickedUp;
    final idx = _stepIndex(d.status);

    Future<void> doAction() async {
      if (action == RunAction.confirmCode) {
        context.push(Routes.proof(d.id));
        return;
      }
      final needsArrival =
          action == RunAction.arriveMerchant || action == RunAction.arriveCustomer || action == RunAction.finishReturn;
      if (needsArrival && left > .3) {
        final ok = await showCorreConfirm(
          context,
          title: 'Você ainda não chegou',
          message: 'Faltam ${km(left)} até o destino. Confirmar a chegada mesmo assim?',
          confirmLabel: 'Confirmar chegada',
        );
        if (!ok) return;
      }
      await ctrl.perform(d, action);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(d.code),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            onSelected: (v) async {
              if (v == 'problem') await _reportProblem(context, ctrl, d);
              if (v == 'giveback' && context.mounted) {
                final ok = await showCorreConfirm(
                  context,
                  title: 'Desistir da corrida?',
                  message:
                      'A entrega volta para outros motoboys. Não há punição, mas avise o comércio se já estiver perto.',
                  confirmLabel: 'Desistir',
                  destructive: true,
                );
                if (ok) {
                  await ctrl.giveBack(d, 'desistiu na tela de corrida');
                  if (context.mounted) context.go(Routes.home);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'problem', child: Text('Relatar problema')),
              if (d.status == DeliveryStatus.accepted)
                const PopupMenuItem(value: 'giveback', child: Text('Desistir da corrida')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CorreMapView(
              borderRadius: BorderRadius.zero,
              followPoint: me.position.latLng,
              zoom: 15,
              route: target == null ? const [] : correLRoute(me.position.latLng, target.latLng),
              pins: [
                CorreMapPin(point: d.pickup.point.latLng, kind: CorreMarkerKind.pickup, label: merchant?.name),
                CorreMapPin(point: d.dropoff.point.latLng, kind: CorreMarkerKind.dropoff, label: d.customer.firstName),
                CorreMapPin(point: me.position.latLng, kind: CorreMarkerKind.courier, label: 'Você'),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(CorreRadius.lg)),
              boxShadow: CorreShadow.raised,
            ),
            padding: const EdgeInsets.fromLTRB(CorreSpace.lg, CorreSpace.lg, CorreSpace.lg, CorreSpace.lg),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Flexible(child: CorreBadge(label: d.status.shortLabel, tone: d.status.tone)),
                      const SizedBox(width: CorreSpace.sm),
                      const Spacer(),
                      if (target != null)
                        Text('${km(left)} · ~${Geo.etaMinutes(left)} min', style: context.text.labelMedium),
                    ],
                  ),
                  const SizedBox(height: CorreSpace.md),
                  Row(
                    children: [
                      for (var i = 0; i < _steps.length; i++) ...[
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: CorreRadius.pillAll,
                              color: i < idx
                                  ? context.palette.brand
                                  : (i == idx ? context.palette.accent : context.palette.line),
                            ),
                          ),
                        ),
                        if (i < _steps.length - 1) const SizedBox(width: CorreSpace.xs),
                      ],
                    ],
                  ),
                  const SizedBox(height: CorreSpace.md),
                  if (d.status == DeliveryStatus.incident)
                    const CorreBanner(
                      tone: CorreTone.error,
                      icon: Icons.support_agent,
                      message: 'Ocorrência em análise. O suporte vai entrar em contato.',
                    )
                  else ...[
                    Text(
                      goingToCustomer || idx >= 3 ? d.customer.name : (merchant?.name ?? 'Comércio'),
                      style: context.text.titleLarge,
                    ),
                    Text(goingToCustomer || idx >= 3 ? d.dropoff.line : d.pickup.line, style: context.text.bodyMedium),
                    if ((goingToCustomer || idx >= 3) && d.notes.isNotEmpty)
                      Text('Obs.: ${d.notes}', style: context.text.bodySmall),
                    const SizedBox(height: CorreSpace.md),
                    Row(
                      children: [
                        Expanded(
                          child: CorreButton(
                            label: 'Maps',
                            icon: Icons.map_outlined,
                            variant: CorreButtonVariant.ghost,
                            size: CorreButtonSize.small,
                            onPressed: target == null
                                ? null
                                : () => ExternalLinks.open(ExternalLinks.googleMapsTo(target)),
                          ),
                        ),
                        const SizedBox(width: CorreSpace.sm),
                        Expanded(
                          child: CorreButton(
                            label: 'Waze',
                            icon: Icons.navigation_outlined,
                            variant: CorreButtonVariant.ghost,
                            size: CorreButtonSize.small,
                            onPressed: target == null ? null : () => ExternalLinks.open(ExternalLinks.wazeTo(target)),
                          ),
                        ),
                        const SizedBox(width: CorreSpace.sm),
                        Expanded(
                          child: CorreButton(
                            label: 'Ligar',
                            icon: Icons.phone,
                            variant: CorreButtonVariant.ghost,
                            size: CorreButtonSize.small,
                            onPressed: () => ExternalLinks.open(
                              ExternalLinks.phone(idx >= 2 ? d.customer.phone : (merchant?.phone ?? '')),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CorreSpace.md),
                    if (d.status == DeliveryStatus.customerAbsent) _AbsentWait(delivery: d),
                    if (action != RunAction.none)
                      CorreButton(label: action.label, size: CorreButtonSize.large, onPressed: doAction),
                    if (d.status == DeliveryStatus.atCustomer) ...[
                      const SizedBox(height: CorreSpace.sm),
                      CorreButton(
                        label: 'Cliente não está',
                        variant: CorreButtonVariant.ghost,
                        onPressed: () => ctrl.customerAbsent(d),
                      ),
                    ],
                    if (target != null && left > .05 && action != RunAction.confirmCode) ...[
                      const SizedBox(height: CorreSpace.xs),
                      TextButton.icon(
                        onPressed: () => ctrl.skipTravel(d),
                        icon: const Icon(Icons.fast_forward_rounded, size: 18),
                        label: const Text('Pular deslocamento (demonstração)'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reportProblem(BuildContext context, RunController ctrl, Delivery d) async {
    final kind = await showCorreSheet<IncidentKind>(
      context,
      title: 'O que aconteceu?',
      child: Column(
        children: [
          for (final k in IncidentKind.values)
            CorreListItem(
              title: k.label,
              subtitle: k.critical ? 'Crítico: o suporte liga para você' : null,
              leading: Icon(
                k.critical ? Icons.warning_amber_rounded : Icons.help_outline,
                color: k.critical ? context.palette.error : null,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pop(k),
            ),
        ],
      ),
    );
    if (kind == null) return;
    await ctrl.report(d, kind, 'Relatado pelo app do motoboy');
    if (context.mounted) {
      CorreToast.show(
        context,
        kind.critical ? 'Suporte avisado. Fique em segurança.' : 'Problema registrado',
        tone: kind.critical ? CorreTone.warning : CorreTone.success,
      );
    }
  }
}

/// Contagem dos 10 minutos de espera com cliente ausente.
class _AbsentWait extends ConsumerStatefulWidget {
  const _AbsentWait({required this.delivery});
  final Delivery delivery;

  @override
  ConsumerState<_AbsentWait> createState() => _AbsentWaitState();
}

class _AbsentWaitState extends ConsumerState<_AbsentWait> {
  bool _skip = false;

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(tickerProvider).value ?? DateTime.now();
    final since = widget.delivery.timeline[DeliveryStatus.customerAbsent] ?? now;
    final left = const Duration(minutes: 10) - now.difference(since);
    final done = _skip || left.isNegative;
    final mm = left.inMinutes.clamp(0, 10).toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).clamp(0, 59).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(bottom: CorreSpace.md),
      child: CorreCard(
        tone: CorreTone.warning,
        child: Column(
          children: [
            Text(done ? 'Espera concluída' : 'Aguarde o cliente: $mm:$ss', style: context.text.titleMedium),
            const SizedBox(height: CorreSpace.xs),
            Text(
              'Ligue para o cliente e para o comércio. Depois de 10 min você pode voltar; o retorno paga +50% do frete.',
              style: context.text.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CorreSpace.sm),
            Row(
              children: [
                Expanded(
                  child: CorreButton(
                    label: 'Cliente apareceu',
                    variant: CorreButtonVariant.secondary,
                    size: CorreButtonSize.small,
                    onPressed: () => context.push(Routes.proof(widget.delivery.id)),
                  ),
                ),
                if (!done) ...[
                  const SizedBox(width: CorreSpace.sm),
                  Expanded(
                    child: CorreButton(
                      label: 'Pular espera (demo)',
                      variant: CorreButtonVariant.ghost,
                      size: CorreButtonSize.small,
                      onPressed: () => setState(() => _skip = true),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Finished extends ConsumerWidget {
  const _Finished({required this.delivery});
  final Delivery delivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ok = delivery.status == DeliveryStatus.delivered || delivery.status == DeliveryStatus.returned;
    final returned = delivery.status == DeliveryStatus.returned;
    final pricing = ref.read(serviceProvider).pricing;
    final amount = returned
        ? delivery.courierAmount + pricing.returnFee(delivery.quote.freight)
        : delivery.courierAmount;
    return Scaffold(
      body: SafeArea(
        child: CorreEmptyState(
          icon: ok ? Icons.check_circle_outline : Icons.info_outline,
          tone: ok ? CorreTone.success : CorreTone.neutral,
          title: ok ? (returned ? 'Pedido devolvido' : 'Entrega concluída!') : delivery.status.label,
          message: ok
              ? '+${formatCents(amount)} na sua carteira. O Pix cai hoje.'
              : delivery.cancellationFee > 0
              ? 'Você recebe ${formatCents(delivery.cancellationFee)} pelo deslocamento.'
              : 'Essa corrida não está mais com você.',
          actionLabel: 'Voltar ao início',
          onAction: () => context.go(Routes.home),
        ),
      ),
    );
  }
}
