import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Acompanhamento de uma entrega (comércio, suporte e admin).
class DeliveryDetailPage extends ConsumerWidget {
  const DeliveryDetailPage({super.key, required this.deliveryId});
  final String deliveryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(deliveryProvider(deliveryId)).value;
    if (d == null) return const CorreEmptyState(icon: Icons.search_off, title: 'Entrega não encontrada');
    final courier = d.courierId == null ? null : ref.watch(courierProvider(d.courierId!)).value;
    final merchant = ref.watch(merchantProvider(d.merchantId)).value;
    final role = ref.watch(sessionProvider);
    final now = ref.watch(tickerProvider).value ?? DateTime.now();
    final service = ref.read(serviceProvider);
    final wide = context.screenSize == CorreScreenSize.desktop;
    final trackingUrl = ExternalLinks.trackingUrl(d.trackingToken);

    Future<void> run(Future<void> Function() f, String ok) async {
      try {
        await f();
        if (context.mounted) CorreToast.show(context, ok, tone: CorreTone.success);
      } on BusinessError catch (e) {
        if (context.mounted) CorreToast.show(context, e.message, tone: CorreTone.error);
      }
    }

    final map = SizedBox(
      height: wide ? 460 : 280,
      child: CorreMapView(
        zoom: 14,
        followPoint: courier?.position.latLng,
        center: courier == null ? d.pickup.point.latLng : null,
        route: courier != null && !d.status.isFinal && d.status.index < DeliveryStatus.pickedUp.index
            ? [...bestRouteLatLng(courier.position, d.pickup.point), ...bestRouteLatLng(d.pickup.point, d.dropoff.point)]
            : courier != null && !d.status.isFinal
                ? bestRouteLatLng(courier.position, d.dropoff.point)
                : bestRouteLatLng(d.pickup.point, d.dropoff.point),
        pins: [
          CorreMapPin(point: d.pickup.point.latLng, kind: CorreMarkerKind.pickup, label: merchant?.name),
          CorreMapPin(point: d.dropoff.point.latLng, kind: CorreMarkerKind.dropoff, label: d.customer.firstName),
          if (courier != null && !d.status.isFinal) CorreMapPin(point: courier.position.latLng, kind: CorreMarkerKind.courier, label: courier.firstName),
        ],
      ),
    );

    final info = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text('${d.code} · ${d.customer.firstName}', style: context.text.titleLarge)),
        CorreBadge(label: d.status.shortLabel, tone: d.status.tone),
      ]),
      Text('${d.dropoff.short} · ${km(d.quote.distanceKm)} · pedido ${timeAgo(d.createdAt, now)}', style: context.text.bodySmall),
      const SizedBox(height: CorreSpace.md),
      if (d.status == DeliveryStatus.searching)
        CorreBanner(
          tone: CorreTone.info,
          icon: Icons.radar,
          message: 'Procurando motoboy: oferecido a ${d.offeredTo.length}. Preferidos primeiro, depois 5, 7 e 10 km.'
              '${d.escalation > 0 ? ' Frete aumentado em ${formatCents(d.escalation)}.' : ''}',
        ),
      if (courier != null)
        CorreCard(
          child: CorreListItem(
            leading: CorreAvatar(name: courier.name),
            title: courier.name,
            subtitle: '${courier.bikeModel} · ★ ${courier.rating?.toStringAsFixed(1) ?? 'novo'}'
                '${d.status.isActive && !d.status.isFinal ? ' · chega em ~${bestRoute(courier.position, d.status.index < DeliveryStatus.pickedUp.index ? d.pickup.point : d.dropoff.point).etaMinutes} min' : ''}',
            trailing: CorreIconButton(icon: Icons.phone, tooltip: 'Ligar', tone: CorreTone.brand, onPressed: () => ExternalLinks.open(ExternalLinks.phone(courier.phone))),
          ),
        ),
      const SizedBox(height: CorreSpace.md),
      CorreCard(child: CorreStepTimeline(steps: deliverySteps(d))),
      if (!d.status.isFinal) ...[
        const SizedBox(height: CorreSpace.md),
        CorreCard(
          tone: CorreTone.accent,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Código de entrega do cliente', style: context.text.bodyMedium),
            Text(d.deliveryCode, style: context.text.displaySmall?.copyWith(letterSpacing: 8)),
            Text('Sem mensagem? Vale também ${d.customer.fallbackCode} (4 últimos dígitos do telefone).', style: context.text.bodySmall),
            const SizedBox(height: CorreSpace.md),
            Wrap(spacing: CorreSpace.sm, runSpacing: CorreSpace.sm, children: [
              CorreButton(
                label: 'Enviar pelo WhatsApp',
                icon: Icons.chat_outlined,
                expand: false,
                onPressed: () => ExternalLinks.open(ExternalLinks.whatsapp(d.customer.phone, ExternalLinks.whatsappMessage(d, merchantName: merchant?.name ?? 'comércio'))),
              ),
              CorreButton(
                label: 'Copiar link',
                icon: Icons.link,
                variant: CorreButtonVariant.ghost,
                expand: false,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: ExternalLinks.whatsappMessage(d, merchantName: merchant?.name ?? 'comércio')));
                  if (context.mounted) CorreToast.show(context, 'Mensagem com link e código copiada', tone: CorreTone.success);
                },
              ),
              CorreButton(
                label: 'Ver rastreio',
                icon: Icons.open_in_new,
                variant: CorreButtonVariant.ghost,
                expand: false,
                onPressed: () => context.push('/r/${d.trackingToken}'),
              ),
            ]),
            const SizedBox(height: CorreSpace.xs),
            SelectableText(trackingUrl, style: context.text.bodySmall),
          ]),
        ),
      ],
      const SizedBox(height: CorreSpace.md),
      CorrePriceSummary(
        lines: [
          CorrePriceLine('Frete do motoboy', d.quote.freight / 100),
          if (d.quote.extras > 0) CorrePriceLine('Adicionais', d.quote.extras / 100),
          CorrePriceLine('Taxa da plataforma', d.quote.platformFee / 100),
          if (d.cancellationFee > 0) CorrePriceLine('Taxa de cancelamento (motoboy)', d.cancellationFee / 100),
        ],
        total: (d.status == DeliveryStatus.cancelledByMerchant ? d.cancellationFee : (d.status == DeliveryStatus.noCourier ? 0 : d.merchantTotal)) / 100,
        footnote: d.status == DeliveryStatus.cancelledByMerchant || d.status == DeliveryStatus.noCourier ? 'O restante voltou ao seu saldo.' : null,
      ),
      const SizedBox(height: CorreSpace.md),
      if (d.status == DeliveryStatus.atCustomer)
        CorreButton(
          label: 'Cliente sem código: confirmar entrega',
          variant: CorreButtonVariant.secondary,
          onPressed: () async {
            final ok = await showCorreConfirm(context,
                title: 'Confirmar sem código?', message: 'Use só se você falou com o motoboy e o cliente. O caso fica registrado para o suporte.');
            if (ok) await run(() => service.confirmCode(d.id, '', viaMerchantCall: true), 'Entrega confirmada');
          },
        ),
      if (d.status.merchantCanCancel && role != null) ...[
        const SizedBox(height: CorreSpace.sm),
        CorreButton(
          label: 'Cancelar entrega',
          variant: CorreButtonVariant.danger,
          onPressed: () async {
            final fee = service.pricing.cancellationFee(accepted: d.status != DeliveryStatus.searching, courierTraveledKm: d.courierTraveledKm);
            final ok = await showCorreConfirm(context,
                title: 'Cancelar ${d.code}?',
                message: fee == 0
                    ? 'Sem custo: o valor volta inteiro para o seu saldo.'
                    : 'O motoboy já rodou ${km(d.courierTraveledKm)}. Ele recebe ${formatCents(fee)} e o resto volta ao seu saldo.',
                confirmLabel: 'Cancelar entrega',
                destructive: true);
            if (ok) await run(() => service.cancel(d.id, reason: 'cancelado pelo painel').then((_) {}), 'Entrega cancelada');
          },
        ),
      ],
      if (d.status == DeliveryStatus.delivered && d.courierId != null) ...[
        CorreCard(
          child: Column(children: [
            Text(d.courierRating == null ? 'Como foi o motoboy?' : 'Sua avaliação', style: context.text.titleSmall),
            const SizedBox(height: CorreSpace.xs),
            CorreRating(
              value: d.courierRating ?? 0,
              onChanged: d.courierRating != null ? null : (v) => run(() => service.rateCourier(d.id, v), 'Obrigado pela avaliação'),
            ),
          ]),
        ),
      ],
      if (d.status.isActive && !d.status.isFinal) ...[
        const SizedBox(height: CorreSpace.sm),
        TextButton.icon(
          icon: const Icon(Icons.report_outlined),
          label: const Text('Relatar problema ao suporte'),
          onPressed: () async {
            final k = await showCorreSheet<IncidentKind>(context,
                title: 'Qual o problema?',
                child: Column(children: [
                  for (final k in IncidentKind.values)
                    CorreListItem(title: k.label, trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).pop(k)),
                ]));
            if (k != null) await run(() => service.openIncident(d.id, k, openedBy: d.merchantId).then((_) {}), 'Suporte avisado');
          },
        ),
      ],
    ]);

    return CorrePage(maxWidth: 1200, children: [
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => context.go(role?.isBackOffice ?? false ? '/' : '/entregas'), icon: const Icon(Icons.arrow_back), label: const Text('Voltar'))),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: map),
          const SizedBox(width: CorreSpace.xl),
          Expanded(flex: 2, child: info),
        ])
      else ...[map, const SizedBox(height: CorreSpace.lg), info],
    ]);
  }
}
