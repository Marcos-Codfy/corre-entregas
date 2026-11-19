import 'dart:math' as math;

import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indicadores do negócio (admin).
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allDeliveriesProvider).value ?? const <Delivery>[];
    final couriers = ref.watch(allCouriersProvider).value ?? const <Courier>[];
    final merchants = {for (final m in ref.watch(allMerchantsProvider).value ?? const <Merchant>[]) m.id: m};
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: _days - 1));
    final list = all.where((d) => !d.createdAt.isBefore(start)).toList();
    final m = DeliveryMetrics.from(list);
    final service = ref.read(serviceProvider);

    final hours = [for (var h = 10; h <= 23; h++) h];
    final maxHour = hours.map((h) => m.byHour[h] ?? 0).fold(1, math.max);
    final topMerchants = m.byMerchant.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final bikes = <String, int>{};
    for (final c in couriers.where((c) => c.approval == ApprovalStatus.approved)) {
      bikes[c.bikeModel] = (bikes[c.bikeModel] ?? 0) + 1;
    }
    final deliveredHours = m.delivered * m.avgMinutesTotal / 60;

    return CorrePage(maxWidth: 1300, children: [
      Row(children: [
        Expanded(child: Text('Indicadores', style: context.text.headlineSmall)),
        CorreSegmented<int>(options: const {1: 'Hoje', 7: '7 dias', 30: '30 dias'}, value: _days, onChanged: (v) => setState(() => _days = v)),
      ]),
      const SizedBox(height: CorreSpace.md),
      CorreResponsiveGrid(children: [
        CorreKpiTile(label: 'Entregas', value: '${m.total}', icon: Icons.local_shipping_outlined),
        CorreKpiTile(label: 'Taxa de sucesso', value: '${(m.successRate * 100).toStringAsFixed(0)}%', positive: m.successRate >= .9, icon: Icons.task_alt),
        CorreKpiTile(label: 'Aceite em até 5 min', value: '${(m.acceptedWithin5MinRate * 100).toStringAsFixed(0)}%', delta: 'meta: 90%', positive: m.acceptedWithin5MinRate >= .9, icon: Icons.timer_outlined),
        CorreKpiTile(label: 'Tempo médio até aceite', value: '${m.avgSecondsToAccept.round()} s', icon: Icons.bolt),
        CorreKpiTile(label: 'Tempo total médio', value: '${m.avgMinutesTotal.round()} min', icon: Icons.schedule),
        CorreKpiTile(label: 'Receita da plataforma', value: formatCents(m.platformRevenue), icon: Icons.payments_outlined),
        CorreKpiTile(label: 'Pago aos motoboys', value: formatCents(m.courierEarnings), icon: Icons.two_wheeler),
        CorreKpiTile(
          label: 'Ganho médio por hora rodando',
          value: deliveredHours == 0 ? '—' : formatCents((m.courierEarnings / deliveredHours).round()),
          icon: Icons.trending_up,
        ),
        CorreKpiTile(label: 'Ticket médio dos pedidos', value: formatCents(m.avgOrderValue), icon: Icons.receipt_outlined),
        CorreKpiTile(label: 'Canceladas', value: '${m.cancelled}', positive: false, icon: Icons.cancel_outlined),
        CorreKpiTile(label: 'Sem motoboy', value: '${m.noCourier}', positive: m.noCourier == 0, icon: Icons.person_off_outlined),
        CorreKpiTile(label: 'Escalonamento no mês', value: '${formatCents(service.escalationSpentThisMonth)} de ${formatCents(service.pricing.rules.escalationMonthlyBudget)}', icon: Icons.savings_outlined),
      ]),
      const CorreSectionHeader(title: 'Entregas por hora do dia'),
      CorreCard(
        child: SizedBox(
          height: 180,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final h in hours)
              Expanded(
                child: Tooltip(
                  message: '${h}h: ${m.byHour[h] ?? 0} entregas',
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                      height: 140 * (m.byHour[h] ?? 0) / maxHour,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: h >= 18 ? context.palette.accent : context.palette.brand,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$h', style: context.text.labelSmall),
                  ]),
                ),
              ),
          ]),
        ),
      ),
      const SizedBox(height: CorreSpace.xs),
      Text('Amarelo: pico da noite (18h às 23h).', style: context.text.bodySmall),
      CorreResponsiveGrid(desktopColumns: 2, tabletColumns: 2, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CorreSectionHeader(title: 'Comércios que mais pedem'),
          CorreDataTable(
            columns: const ['Comércio', 'Entregas', 'Participação'],
            rows: [
              for (final e in topMerchants.take(6))
                [
                  Text(merchants[e.key]?.name ?? e.key),
                  Text('${e.value}'),
                  Text('${(e.value / math.max(1, m.total) * 100).toStringAsFixed(0)}%'),
                ],
            ],
          ),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CorreSectionHeader(title: 'Motos usadas (só o modelo)'),
          CorreCard(
            child: Column(children: [
              for (final e in bikes.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: CorreSpace.xs),
                  child: Row(children: [
                    SizedBox(width: 150, child: Text(e.key, style: context.text.bodyMedium)),
                    Expanded(child: CorreProgressBar(value: e.value / math.max(1, bikes.values.fold(0, math.max)))),
                    const SizedBox(width: CorreSpace.sm),
                    Text('${e.value}'),
                  ]),
                ),
            ]),
          ),
        ]),
      ]),
    ]);
  }
}
