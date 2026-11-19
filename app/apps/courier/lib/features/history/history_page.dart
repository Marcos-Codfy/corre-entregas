import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/courier_controller.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  int _days = 1;

  @override
  Widget build(BuildContext context) {
    final merchants = {for (final m in ref.watch(allMerchantsProvider).value ?? const <Merchant>[]) m.id: m};
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: _days - 1));
    final list = ref
        .watch(myHistoryProvider)
        .where((d) => (d.timeline[d.status] ?? d.createdAt).isAfter(start))
        .toList();
    final earned = list
        .where((d) => d.status == DeliveryStatus.delivered)
        .fold<Cents>(0, (s, d) => s + d.courierAmount);

    return SafeArea(
      child: CorreReadableList(
        padding: const EdgeInsets.all(CorreSpace.lg),
        children: [
          Text('Corridas', style: context.text.headlineSmall),
          const SizedBox(height: CorreSpace.md),
          CorreSegmented<int>(
            options: const {1: 'Hoje', 7: '7 dias', 30: '30 dias'},
            value: _days,
            onChanged: (v) => setState(() => _days = v),
          ),
          const SizedBox(height: CorreSpace.md),
          CorreCard(
            child: Row(
              children: [
                Expanded(
                  child: CorreKeyValue(label: 'Entregas', value: '${list.length}'),
                ),
                const SizedBox(width: CorreSpace.lg),
                Expanded(
                  child: CorreKeyValue(label: 'Ganhos', value: formatCents(earned)),
                ),
              ],
            ),
          ),
          const SizedBox(height: CorreSpace.md),
          if (list.isEmpty)
            const CorreEmptyState(
              icon: Icons.two_wheeler,
              title: 'Nenhuma corrida no período',
              message: 'Fique online no início para receber ofertas.',
            )
          else
            for (final d in list)
              Padding(
                padding: const EdgeInsets.only(bottom: CorreSpace.sm),
                child: CorreDeliveryCard(
                  code: d.code,
                  title: merchants[d.merchantId]?.name ?? 'Comércio',
                  subtitle:
                      '${ddmm(d.createdAt)} ${hhmm(d.createdAt)} · ${d.dropoff.district} · ${km(d.quote.distanceKm)}',
                  statusLabel: d.status.shortLabel,
                  statusTone: d.status.tone,
                  value: d.status == DeliveryStatus.delivered ? d.courierAmount / 100 : d.cancellationFee / 100,
                ),
              ),
        ],
      ),
    );
  }
}
