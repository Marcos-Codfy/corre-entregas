import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/session.dart';

/// Gera o CSV das entregas (sem dados pessoais do cliente).
String deliveriesCsv(List<Delivery> list, Map<String, Courier> couriers) {
  String esc(String v) => v.contains(RegExp(r'[;"\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
  final b = StringBuffer('codigo;data;hora;bairro;distancia_km;status;motoboy;frete;taxa;total\n');
  for (final d in list) {
    b.writeln([
      d.code,
      ddmm(d.createdAt),
      hhmm(d.createdAt),
      esc(d.dropoff.district),
      d.quote.distanceKm.toStringAsFixed(1),
      d.status.shortLabel,
      esc(couriers[d.courierId]?.name ?? ''),
      (d.quote.freight / 100).toStringAsFixed(2),
      (d.quote.platformFee / 100).toStringAsFixed(2),
      (d.merchantTotal / 100).toStringAsFixed(2),
    ].join(';'));
  }
  return b.toString();
}

class DeliveriesPage extends ConsumerStatefulWidget {
  const DeliveriesPage({super.key});

  @override
  ConsumerState<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends ConsumerState<DeliveriesPage> {
  int _days = 7;
  String _status = 'todas';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final couriers = {for (final c in ref.watch(allCouriersProvider).value ?? const <Courier>[]) c.id: c};
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: _days - 1));
    final list = ref.watch(myDeliveriesProvider).where((d) {
      if (d.createdAt.isBefore(start)) return false;
      if (_status == 'entregues' && d.status != DeliveryStatus.delivered) return false;
      if (_status == 'problemas' && d.status == DeliveryStatus.delivered) return false;
      if (_q.isNotEmpty && !'${d.code} ${d.dropoff.district} ${couriers[d.courierId]?.name ?? ''}'.toLowerCase().contains(_q.toLowerCase())) return false;
      return true;
    }).toList();
    final delivered = list.where((d) => d.status == DeliveryStatus.delivered).toList();
    final spent = delivered.fold<Cents>(0, (s, d) => s + d.merchantTotal);
    final ifood = delivered.fold<int>(0, (s, d) => s + ((d.orderValue ?? 0) * .262).round() + 0);

    return CorrePage(children: [
      Row(children: [
        Expanded(child: Text('Entregas', style: context.text.headlineSmall)),
        CorreButton(
          label: 'Copiar CSV',
          icon: Icons.download_outlined,
          variant: CorreButtonVariant.ghost,
          expand: false,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: deliveriesCsv(list, couriers)));
            if (context.mounted) CorreToast.show(context, 'CSV copiado (${list.length} linhas). Cole no Excel ou Planilhas.', tone: CorreTone.success);
          },
        ),
      ]),
      const SizedBox(height: CorreSpace.md),
      Wrap(spacing: CorreSpace.lg, runSpacing: CorreSpace.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        CorreSegmented<int>(options: const {1: 'Hoje', 7: '7 dias', 30: '30 dias'}, value: _days, onChanged: (v) => setState(() => _days = v)),
        CorreSegmented<String>(options: const {'todas': 'Todas', 'entregues': 'Entregues', 'problemas': 'Canceladas e outras'}, value: _status, onChanged: (v) => setState(() => _status = v)),
        SizedBox(width: 280, child: CorreSearchField(hint: 'Código, bairro ou motoboy', onChanged: (v) => setState(() => _q = v))),
      ]),
      const SizedBox(height: CorreSpace.md),
      CorreResponsiveGrid(children: [
        CorreKpiTile(label: 'Entregas no período', value: '${list.length}'),
        CorreKpiTile(label: 'Entregues', value: '${delivered.length}'),
        CorreKpiTile(label: 'Gasto com entregas', value: formatCents(spent)),
        CorreKpiTile(label: 'No iFood Entrega (26,2% do pedido)', value: formatCents(ifood), delta: ifood > spent ? 'Economia de ${formatCents(ifood - spent)}' : null),
      ]),
      const SizedBox(height: CorreSpace.md),
      if (list.isEmpty)
        const CorreCard(child: CorreEmptyState(icon: Icons.inbox_outlined, title: 'Nada no período'))
      else
        CorreDataTable(
          columns: const ['Código', 'Quando', 'Bairro', 'Motoboy', 'Status', 'Total'],
          onRowTap: (i) => context.go('/entrega/${list[i].id}'),
          rows: [
            for (final d in list.take(200))
              [
                Text(d.code),
                Text('${ddmm(d.createdAt)} ${hhmm(d.createdAt)}'),
                Text(d.dropoff.district),
                Text(couriers[d.courierId]?.firstName ?? '—'),
                CorreBadge(label: d.status.shortLabel, tone: d.status.tone),
                Text(formatCents(d.merchantTotal)),
              ],
          ],
        ),
    ]);
  }
}
