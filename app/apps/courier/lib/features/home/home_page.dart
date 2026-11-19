import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import 'courier_controller.dart';

/// Ganhos e corridas de hoje do motoboy logado.
final todayStatsProvider = Provider<({int count, Cents earned, double km})>((ref) {
  final now = DateTime.now();
  final list = ref.watch(myHistoryProvider).where((d) {
    final t = d.timeline[d.status] ?? d.createdAt;
    return d.status == DeliveryStatus.delivered && t.year == now.year && t.month == now.month && t.day == now.day;
  }).toList();
  return (
    count: list.length,
    earned: list.fold<Cents>(0, (s, d) => s + d.courierAmount),
    km: list.fold<double>(0, (s, d) => s + d.quote.distanceKm),
  );
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _askedLocation = false;

  Future<void> _toggle(bool online) async {
    if (online && !_askedLocation) {
      final ok = await showCorreConfirm(
        context,
        title: 'Permitir localização',
        message:
            'O Corre usa o GPS para mostrar corridas perto de você e enviar sua posição ao comércio '
            'a cada 7 segundos durante a entrega. Quando você fica offline, o envio para.',
        confirmLabel: 'Permitir',
        cancelLabel: 'Agora não',
      );
      if (!ok) return;
      _askedLocation = true;
    }
    await ref.read(courierControllerProvider.notifier).setOnline(online);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final active = ref.watch(activeDeliveryProvider);
    final stats = ref.watch(todayStatsProvider);
    final merchants = ref.watch(allMerchantsProvider).value ?? const [];
    final error = ref.watch(courierControllerProvider.select((s) => s.lastError));
    ref.listen(courierControllerProvider.select((s) => s.lastError), (_, e) {
      if (e != null) CorreToast.show(context, e, tone: CorreTone.error);
    });

    if (me == null) return const Center(child: CircularProgressIndicator());
    final online = me.isOnline;
    final preferredBy = merchants.where((m) => m.preferredCourierIds.contains(me.id)).toList();

    return SafeArea(
      child: CorreReadableList(
        padding: const EdgeInsets.all(CorreSpace.lg),
        children: [
          Row(
            children: [
              CorreAvatar(name: me.name),
              const SizedBox(width: CorreSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Olá, ${me.firstName}', style: context.text.titleLarge),
                    Text(
                      '${me.bikeModel} · ★ ${me.rating?.toStringAsFixed(1).replaceAll('.', ',') ?? 'novo'}',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Semantics(
                label: online ? 'Você está online' : 'Você está offline',
                child: Switch.adaptive(value: online, onChanged: _toggle),
              ),
            ],
          ),
          const SizedBox(height: CorreSpace.lg),
          CorreCard(
            tone: CorreTone.brand,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ganhos de hoje', style: context.text.bodyMedium),
                const SizedBox(height: CorreSpace.xs),
                Text(
                  formatCents(stats.earned),
                  style: context.text.displaySmall?.copyWith(color: context.palette.brand),
                ),
                Text('${stats.count} entregas · ${km(stats.km)} rodados', style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: CorreSpace.md),
          if (active != null)
            CorreCard(
              highlighted: true,
              onTap: () => context.push(Routes.run(active.id)),
              child: Row(
                children: [
                  const Icon(Icons.two_wheeler),
                  const SizedBox(width: CorreSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Corrida em andamento', style: context.text.titleSmall),
                        Text('${active.code} · ${active.status.label}', style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            )
          else
            CorreCard(
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: CorreMapView(
                      followPoint: me.position.latLng,
                      zoom: 14,
                      pins: [
                        CorreMapPin(point: me.position.latLng, kind: CorreMarkerKind.courier, label: 'Você'),
                        for (final m in merchants.where((m) => m.approval == ApprovalStatus.approved))
                          CorreMapPin(point: m.address.point.latLng, kind: CorreMarkerKind.pickup, label: m.name),
                      ],
                    ),
                  ),
                  const SizedBox(height: CorreSpace.md),
                  Row(
                    children: [
                      Icon(
                        online ? Icons.radar : Icons.power_settings_new,
                        color: online ? context.palette.brand : context.palette.ink3,
                      ),
                      const SizedBox(width: CorreSpace.sm),
                      Expanded(
                        child: Text(
                          online
                              ? 'Procurando corridas perto de você…'
                              : 'Você está offline. Ligue para receber corridas.',
                          style: context.text.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CorreSpace.md),
                  CorreButton(
                    label: 'Simular nova corrida',
                    icon: Icons.play_arrow_rounded,
                    variant: CorreButtonVariant.accent,
                    onPressed: () => ref.read(courierControllerProvider.notifier).simulateOffer(),
                  ),
                  const SizedBox(height: CorreSpace.xs),
                  Text(
                    'Modo demonstração: as ofertas são geradas no próprio aparelho.',
                    style: context.text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (error != null) const SizedBox.shrink(),
          const CorreSectionHeader(title: 'Pico de hoje'),
          const CorreCard(
            child: CorreListItem(
              leading: Icon(Icons.local_fire_department_outlined),
              title: '18:00 – 23:00 · região central',
              subtitle: 'Mais pedidos de lanchonetes, pizzarias e açaí',
              trailing: CorreBadge(label: 'Mais pedidos', tone: CorreTone.accent),
            ),
          ),
          if (preferredBy.isNotEmpty) ...[
            const CorreSectionHeader(title: 'Comércios que preferem você'),
            CorreCard(
              child: Column(
                children: [
                  for (final m in preferredBy)
                    CorreListItem(
                      leading: CorreAvatar(name: m.name, tone: CorreTone.accent, size: 36),
                      title: m.name,
                      subtitle: '${m.category} · ${m.address.district}',
                      trailing: const Icon(Icons.favorite, size: 18),
                    ),
                ],
              ),
            ),
            const SizedBox(height: CorreSpace.xs),
            Text('Você recebe as ofertas desses comércios antes dos outros motoboys.', style: context.text.bodySmall),
          ],
        ],
      ),
    );
  }
}
