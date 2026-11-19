import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import 'courier_controller.dart';

/// Oferta de corrida em tela cheia, com 20 s para aceitar.
class OfferOverlay extends ConsumerStatefulWidget {
  const OfferOverlay({super.key, required this.offer});
  final Offer offer;

  @override
  ConsumerState<OfferOverlay> createState() => _OfferOverlayState();
}

class _OfferOverlayState extends ConsumerState<OfferOverlay> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.offer.delivery;
    final me = ref.watch(meProvider);
    final merchant = ref.watch(merchantProvider(d.merchantId)).value;
    final toPickup = me == null ? 0.0 : Geo.roadKm(me.position, d.pickup.point);
    final busy = ref.watch(courierControllerProvider.select((s) => s.busy));
    final ctrl = ref.read(courierControllerProvider.notifier);

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(CorreSpace.md),
              padding: const EdgeInsets.all(CorreSpace.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: CorreRadius.lgAll,
                boxShadow: CorreShadow.raised,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: CorreSpace.sm,
                    runSpacing: CorreSpace.xs,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      const CorreBadge(label: 'Nova corrida', tone: CorreTone.info, icon: Icons.bolt),
                      if (widget.offer.fromPreferred)
                        const CorreBadge(
                          label: 'Você é preferido deste comércio',
                          tone: CorreTone.brand,
                          icon: Icons.favorite,
                        ),
                    ],
                  ),
                  const SizedBox(height: CorreSpace.md),
                  SizedBox(
                    height: 140,
                    child: CorreMapView(
                      interactive: false,
                  fitToPins: true,
                      zoom: 13,
                      route: correLRoute(d.pickup.point.latLng, d.dropoff.point.latLng),
                      pins: [
                        if (me != null) CorreMapPin(point: me.position.latLng, kind: CorreMarkerKind.courier),
                        CorreMapPin(point: d.pickup.point.latLng, kind: CorreMarkerKind.pickup),
                        CorreMapPin(point: d.dropoff.point.latLng, kind: CorreMarkerKind.dropoff),
                      ],
                    ),
                  ),
                  const SizedBox(height: CorreSpace.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatCents(d.courierAmount),
                              style: context.text.displaySmall?.copyWith(color: context.palette.brand),
                            ),
                            Text('100% seu · Pix no mesmo dia', style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      CorreCountdownRing(
                        key: ValueKey(d.id),
                        total: widget.offer.expiresIn,
                        size: 84,
                        onFinished: () => ctrl.decline(expired: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: CorreSpace.md),
                  CorreKeyValue(label: 'Até a coleta', value: '${km(toPickup)} · ~${Geo.etaMinutes(toPickup)} min'),
                  CorreKeyValue(
                    label: 'Coleta → cliente',
                    value: '${km(d.quote.distanceKm)} · ~${Geo.etaMinutes(d.quote.distanceKm)} min',
                  ),
                  const Divider(height: CorreSpace.lg),
                  _Place(icon: Icons.storefront, title: merchant?.name ?? 'Comércio', subtitle: d.pickup.short),
                  const SizedBox(height: CorreSpace.sm),
                  _Place(icon: Icons.home_rounded, title: 'Entrega em ${d.dropoff.district}', subtitle: d.dropoff.line),
                  if (d.tags.isNotEmpty) ...[
                    const SizedBox(height: CorreSpace.sm),
                    Wrap(
                      spacing: CorreSpace.xs,
                      children: [for (final t in d.tags) CorreBadge(label: t)],
                    ),
                  ],
                  const SizedBox(height: CorreSpace.sm),
                  Text(
                    'Só entregar: sem cobrança na porta. Recusar não gera punição.',
                    style: context.text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CorreSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: CorreButton(
                          label: 'Recusar',
                          variant: CorreButtonVariant.ghost,
                          onPressed: busy ? null : ctrl.decline,
                        ),
                      ),
                      const SizedBox(width: CorreSpace.sm),
                      Expanded(
                        flex: 2,
                        child: CorreButton(
                          label: 'Aceitar corrida',
                          size: CorreButtonSize.large,
                          loading: busy,
                          onPressed: () async {
                            // A oferta some ao aceitar; guarda o router antes.
                            final router = GoRouter.of(context);
                            final id = await ctrl.accept();
                            if (id != null) router.push(Routes.run(id));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: context.palette.ink2),
      const SizedBox(width: CorreSpace.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.titleSmall),
            Text(subtitle, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ],
  );
}
