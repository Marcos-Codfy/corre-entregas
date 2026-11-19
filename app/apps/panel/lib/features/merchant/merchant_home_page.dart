import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/session.dart';

class MerchantHomePage extends ConsumerWidget {
  const MerchantHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchant = ref.watch(myMerchantProvider);
    final role = ref.watch(sessionProvider);
    final all = ref.watch(myDeliveriesProvider);
    final couriers = {for (final c in ref.watch(allCouriersProvider).value ?? const <Courier>[]) c.id: c};
    final now = ref.watch(tickerProvider).value ?? DateTime.now();
    if (merchant == null) return const Center(child: CircularProgressIndicator());

    final active = all.where((d) => !d.status.isFinal).toList();
    final today = all.where((d) => d.createdAt.year == now.year && d.createdAt.month == now.month && d.createdAt.day == now.day).toList();
    final todaySpent = today.fold<Cents>(0, (s, d) => s + (d.status == DeliveryStatus.delivered ? d.merchantTotal : 0));
    final online = couriers.values.where((c) => c.isOnline && Geo.roadKm(c.position, merchant.address.point) <= 10).length;
    final ifoodCommission = today.fold<int>(0, (s, d) => s + ((d.orderValue ?? 0) * .262).round());
    final month = all.where((d) => d.status == DeliveryStatus.delivered && d.createdAt.year == now.year && d.createdAt.month == now.month).toList();
    final savings = SavingsReport.from(month);

    return CorrePage(children: [
      Text('Boa noite, ${merchant.name}', style: context.text.headlineSmall),
      Text('${merchant.address.short} · $online motoboys online a até 10 km', style: context.text.bodyMedium),
      const SizedBox(height: CorreSpace.lg),
      if (role?.canSeeFinance ?? false) ...[
        CorreCard(
          tone: CorreTone.success,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Você economizou este mês', style: context.text.bodyMedium),
                Text(formatCents(savings.saved), style: context.text.displaySmall?.copyWith(color: context.palette.success)),
                Text(
                  '${savings.count} entregas: ${formatCents(savings.paid)} aqui contra ~${formatCents(savings.ifood)} no iFood Entrega (23% + 3,2% do pedido).',
                  style: context.text.bodySmall,
                ),
              ]),
            ),
            if (context.screenSize != CorreScreenSize.mobile) Icon(Icons.savings_outlined, size: 56, color: context.palette.success),
          ]),
        ),
        const SizedBox(height: CorreSpace.xs),
        Text('Quando o valor do pedido não foi informado, a conta usa R\$ 50 como referência.', style: context.text.bodySmall),
        const SizedBox(height: CorreSpace.lg),
      ],
      CorreButton(
        label: 'Pedir entregador',
        icon: Icons.two_wheeler,
        variant: CorreButtonVariant.accent,
        size: CorreButtonSize.large,
        onPressed: () => context.go('/nova'),
      ),
      const SizedBox(height: CorreSpace.lg),
      CorreResponsiveGrid(children: [
        if (role?.canSeeFinance ?? false) CorreKpiTile(label: 'Saldo', value: formatCents(merchant.balance), icon: Icons.account_balance_wallet_outlined),
        CorreKpiTile(label: 'Entregas hoje', value: '${today.length}', icon: Icons.local_shipping_outlined),
        CorreKpiTile(label: 'Em andamento', value: '${active.length}', icon: Icons.sensors),
        if (role?.canSeeFinance ?? false)
          CorreKpiTile(
            label: 'Gasto hoje',
            value: formatCents(todaySpent),
            delta: ifoodCommission > 0 ? 'No iFood Entrega seria ~${formatCents(ifoodCommission)}' : null,
            icon: Icons.savings_outlined,
          ),
      ]),
      const CorreSectionHeader(title: 'Em andamento'),
      if (active.isEmpty)
        const CorreCard(
          child: CorreEmptyState(icon: Icons.inbox_outlined, title: 'Nenhuma entrega em andamento', message: 'Quando você pedir um entregador, ele aparece aqui.'),
        )
      else
        for (final d in active)
          Padding(
            padding: const EdgeInsets.only(bottom: CorreSpace.sm),
            child: CorreDeliveryCard(
              code: d.code,
              title: d.customer.firstName,
              subtitle: d.courierId == null
                  ? 'Oferecido a ${d.offeredTo.length} motoboy(s) · ${timeAgo(d.createdAt, now)}'
                  : '${couriers[d.courierId]?.firstName ?? 'Motoboy'} · ${d.status.label}',
              statusLabel: d.status.shortLabel,
              statusTone: d.status.tone,
              value: d.merchantTotal / 100,
              onTap: () => context.go('/entrega/${d.id}'),
            ),
          ),
      const CorreSectionHeader(title: 'Seus motoboys preferidos'),
      CorreCard(
        child: merchant.preferredCourierIds.isEmpty
            ? const Text('Marque até 3 motoboys de confiança: eles recebem suas entregas primeiro.')
            : Wrap(spacing: CorreSpace.lg, runSpacing: CorreSpace.sm, children: [
                for (final id in merchant.preferredCourierIds)
                  if (couriers[id] != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      CorreAvatar(name: couriers[id]!.name, size: 32),
                      const SizedBox(width: CorreSpace.sm),
                      Text('${couriers[id]!.firstName} ★${couriers[id]!.rating?.toStringAsFixed(1) ?? '-'}', style: context.text.titleSmall),
                      const SizedBox(width: CorreSpace.xs),
                      CorreBadge(label: couriers[id]!.isOnline ? 'online' : 'offline', tone: couriers[id]!.isOnline ? CorreTone.success : CorreTone.neutral),
                    ]),
              ]),
      ),
    ]);
  }
}

/// Comparação com o Plano Entrega do iFood (23% de comissão + 3,2% de pagamento online).
class SavingsReport {
  const SavingsReport(this.count, this.paid, this.ifood);
  final int count;
  final Cents paid, ifood;
  Cents get saved => ifood > paid ? ifood - paid : 0;

  static const ifoodRate = .262;
  static const defaultOrderValue = 5000;

  static SavingsReport from(List<Delivery> delivered) {
    var paid = 0, ifood = 0;
    for (final d in delivered) {
      paid += d.merchantTotal;
      ifood += ((d.orderValue ?? defaultOrderValue) * ifoodRate).round();
    }
    return SavingsReport(delivered.length, paid, ifood);
  }
}
