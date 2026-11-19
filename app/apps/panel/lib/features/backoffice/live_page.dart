import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Suporte ao vivo: fila sem aceite, mapa de motoboys e despacho manual.
class LivePage extends ConsumerWidget {
  const LivePage({super.key});

  Future<void> _assign(BuildContext context, WidgetRef ref, Delivery d, List<Courier> couriers) async {
    final free = couriers.where((c) => c.isFree && c.approval == ApprovalStatus.approved).toList()
      ..sort((a, b) => Geo.roadKm(a.position, d.pickup.point).compareTo(Geo.roadKm(b.position, d.pickup.point)));
    final chosen = await showCorreSheet<Courier>(
      context,
      title: 'Atribuir ${d.code} a um motoboy',
      child: free.isEmpty
          ? const CorreEmptyState(icon: Icons.person_off_outlined, title: 'Nenhum motoboy livre agora')
          : Column(children: [
              Text('Combine por telefone ou WhatsApp antes de atribuir.', style: context.text.bodySmall),
              for (final c in free.take(8))
                CorreListItem(
                  leading: CorreAvatar(name: c.name, size: 36),
                  title: c.name,
                  subtitle: '${km(Geo.roadKm(c.position, d.pickup.point))} da coleta · ★ ${c.rating?.toStringAsFixed(1) ?? 'novo'}',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pop(c),
                ),
            ]),
    );
    if (chosen == null) return;
    try {
      await ref.read(serviceProvider).assignManually(d.id, chosen.id, supportId: Seed.supportUserId);
      if (context.mounted) CorreToast.show(context, '${d.code} atribuída a ${chosen.firstName}', tone: CorreTone.success);
    } on BusinessError catch (e) {
      if (context.mounted) CorreToast.show(context, e.message, tone: CorreTone.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(allDeliveriesProvider).value ?? const <Delivery>[];
    final couriers = ref.watch(allCouriersProvider).value ?? const <Courier>[];
    final merchants = {for (final m in ref.watch(allMerchantsProvider).value ?? const <Merchant>[]) m.id: m};
    final incidents = (ref.watch(incidentsProvider).value ?? const <Incident>[]).where((i) => i.status != IncidentStatus.resolved).toList();
    final now = ref.watch(tickerProvider).value ?? DateTime.now();

    final searching = deliveries.where((d) => d.status == DeliveryStatus.searching).toList();
    final active = deliveries.where((d) => d.status.isActive && !d.status.isFinal).toList();
    final online = couriers.where((c) => c.isOnline).toList();
    final wide = context.screenSize == CorreScreenSize.desktop;

    final map = SizedBox(
      height: wide ? 560 : 320,
      child: CorreMapView(
        zoom: 13,
        center: GeoPoint.palmas.latLng,
        pins: [
          for (final m in merchants.values.where((m) => m.approval == ApprovalStatus.approved))
            CorreMapPin(point: m.address.point.latLng, kind: CorreMarkerKind.pickup, label: m.name),
          for (final d in active) CorreMapPin(point: d.dropoff.point.latLng, kind: CorreMarkerKind.dropoff, label: d.code),
          for (final c in online) CorreMapPin(point: c.position.latLng, kind: CorreMarkerKind.courier, label: '${c.firstName} · ${c.isFree ? 'livre' : 'em entrega'}'),
        ],
      ),
    );

    final queue = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CorreSectionHeader(title: 'Sem aceite (${searching.length})'),
      if (searching.isEmpty)
        const CorreCard(child: Text('Nenhuma entrega esperando. 👍'))
      else
        for (final d in searching)
          Padding(
            padding: const EdgeInsets.only(bottom: CorreSpace.sm),
            child: CorreCard(
              highlighted: now.difference(d.createdAt).inMinutes >= 5,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${d.code} · ${merchants[d.merchantId]?.name ?? ''}', style: context.text.titleSmall)),
                  CorreBadge(label: timeAgo(d.createdAt, now), tone: now.difference(d.createdAt).inMinutes >= 5 ? CorreTone.error : CorreTone.info),
                ]),
                Text('${d.dropoff.district} · ${km(d.quote.distanceKm)} · oferecido a ${d.offeredTo.length}', style: context.text.bodySmall),
                const SizedBox(height: CorreSpace.sm),
                Row(children: [
                  Expanded(child: CorreButton(label: 'Despachar na mão', size: CorreButtonSize.small, onPressed: () => _assign(context, ref, d, couriers))),
                  const SizedBox(width: CorreSpace.sm),
                  CorreButton(label: 'Abrir', size: CorreButtonSize.small, variant: CorreButtonVariant.ghost, expand: false, onPressed: () => context.go('/entrega/${d.id}')),
                ]),
              ]),
            ),
          ),
      CorreSectionHeader(title: 'Em andamento (${active.length})'),
      for (final d in active.take(12))
        Padding(
          padding: const EdgeInsets.only(bottom: CorreSpace.sm),
          child: CorreDeliveryCard(
            code: d.code,
            title: merchants[d.merchantId]?.name ?? '',
            subtitle: '${couriers.where((c) => c.id == d.courierId).firstOrNull?.firstName ?? ''} · ${d.status.label}',
            statusLabel: d.status.shortLabel,
            statusTone: d.status.tone,
            onTap: () => context.go('/entrega/${d.id}'),
          ),
        ),
    ]);

    return CorrePage(maxWidth: 1400, children: [
      CorreResponsiveGrid(children: [
        CorreKpiTile(label: 'Motoboys online', value: '${online.length}', icon: Icons.two_wheeler),
        CorreKpiTile(label: 'Livres agora', value: '${online.where((c) => c.isFree).length}', icon: Icons.check_circle_outline),
        CorreKpiTile(label: 'Sem aceite', value: '${searching.length}', icon: Icons.hourglass_top, positive: searching.isEmpty),
        CorreKpiTile(label: 'Ocorrências abertas', value: '${incidents.length}', icon: Icons.report_outlined, positive: incidents.isEmpty),
      ]),
      const SizedBox(height: CorreSpace.lg),
      if (incidents.any((i) => i.kind.critical))
        Padding(
          padding: const EdgeInsets.only(bottom: CorreSpace.md),
          child: CorreBanner(
            tone: CorreTone.error,
            icon: Icons.warning_amber_rounded,
            message: 'Ocorrência crítica aberta. Siga o roteiro e decida junto com o outro sócio.',
            actionLabel: 'Ver',
            onAction: () => context.go('/ocorrencias'),
          ),
        ),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: map),
          const SizedBox(width: CorreSpace.lg),
          Expanded(flex: 2, child: queue),
        ])
      else ...[map, queue],
    ]);
  }
}
