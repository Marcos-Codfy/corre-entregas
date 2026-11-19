import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Página pública de rastreio do cliente final (sem login), aberta pelo link do WhatsApp.
class TrackingPage extends ConsumerWidget {
  const TrackingPage({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(allDeliveriesProvider);
    final d = ref.read(environmentProvider).deliveries.byTrackingToken(token);
    if (d == null) {
      return const Scaffold(
        body: CorreEmptyState(
          icon: Icons.link_off,
          title: 'Link de rastreio inválido',
          message: 'Confira a mensagem do comércio ou fale com ele. Na demonstração, abra o rastreio pelo painel do comércio.',
        ),
      );
    }
    final merchant = ref.watch(merchantProvider(d.merchantId)).value;
    final courier = d.courierId == null ? null : ref.watch(courierProvider(d.courierId!)).value;
    final eta = courier == null || d.status.isFinal ? null : Geo.etaMinutes(Geo.roadKm(courier.position, d.dropoff.point));

    final headline = switch (d.status) {
      DeliveryStatus.searching => 'Estamos chamando um motoboy',
      DeliveryStatus.accepted || DeliveryStatus.atMerchant => 'O motoboy está buscando seu pedido',
      DeliveryStatus.pickedUp || DeliveryStatus.toCustomer => 'Seu pedido está a caminho',
      DeliveryStatus.atCustomer => 'O motoboy chegou!',
      DeliveryStatus.delivered => 'Pedido entregue',
      _ => d.status.label,
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(padding: const EdgeInsets.all(CorreSpace.lg), children: [
              Row(children: [
                const CorreLogo(size: 24),
                const Spacer(),
                Text(merchant?.name ?? '', style: context.text.titleSmall),
              ]),
              const SizedBox(height: CorreSpace.lg),
              Text(headline, style: context.text.headlineMedium),
              if (eta != null && d.status.index >= DeliveryStatus.pickedUp.index) Text('Chega em cerca de $eta min', style: context.text.titleMedium?.copyWith(color: context.palette.brand)),
              const SizedBox(height: CorreSpace.md),
              SizedBox(
                height: 260,
                child: CorreMapView(
                  zoom: 14,
                  followPoint: courier?.position.latLng,
                  center: courier == null ? d.dropoff.point.latLng : null,
                  pins: [
                    CorreMapPin(point: d.pickup.point.latLng, kind: CorreMarkerKind.pickup),
                    CorreMapPin(point: d.dropoff.point.latLng, kind: CorreMarkerKind.dropoff),
                    if (courier != null && !d.status.isFinal) CorreMapPin(point: courier.position.latLng, kind: CorreMarkerKind.courier),
                  ],
                ),
              ),
              const SizedBox(height: CorreSpace.md),
              if (!d.status.isFinal)
                CorreCard(
                  tone: CorreTone.accent,
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Seu código de entrega', style: context.text.bodyMedium),
                        Text('Informe ao motoboy quando ele chegar.', style: context.text.bodySmall),
                      ]),
                    ),
                    Text(d.deliveryCode, style: context.text.headlineMedium?.copyWith(letterSpacing: 6)),
                  ]),
                ),
              const SizedBox(height: CorreSpace.md),
              if (courier != null)
                CorreCard(
                  child: CorreListItem(
                    leading: CorreAvatar(name: courier.name),
                    title: courier.firstName,
                    subtitle: '${courier.bikeModel} · ★ ${courier.rating?.toStringAsFixed(1) ?? 'novo'}',
                  ),
                ),
              const SizedBox(height: CorreSpace.md),
              CorreCard(child: CorreStepTimeline(steps: deliverySteps(d))),
              const SizedBox(height: CorreSpace.md),
              Text('Dúvidas sobre o pedido? Fale com ${merchant?.name ?? 'o comércio'}.', style: context.text.bodySmall, textAlign: TextAlign.center),
            ]),
          ),
        ),
      ),
    );
  }
}
