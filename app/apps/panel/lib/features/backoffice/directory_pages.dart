import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MerchantsDirectoryPage extends ConsumerWidget {
  const MerchantsDirectoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchants = ref.watch(allMerchantsProvider).value ?? const <Merchant>[];
    final deliveries = ref.watch(allDeliveriesProvider).value ?? const <Delivery>[];
    return CorrePage(children: [
      Text('Comércios', style: context.text.headlineSmall),
      const SizedBox(height: CorreSpace.md),
      CorreDataTable(
        columns: const ['Comércio', 'Categoria', 'Bairro', 'Saldo', 'Entregas', 'Preferidos', 'Cadastro'],
        rows: [
          for (final m in merchants)
            [
              Text(m.name),
              Text(m.category),
              Text(m.address.district),
              Text(formatCents(m.balance)),
              Text('${deliveries.where((d) => d.merchantId == m.id).length}'),
              Text('${m.preferredCourierIds.length}'),
              CorreBadge(label: m.approval.label, tone: m.approval == ApprovalStatus.approved ? CorreTone.success : CorreTone.warning),
            ],
        ],
      ),
    ]);
  }
}

class CouriersDirectoryPage extends ConsumerWidget {
  const CouriersDirectoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couriers = ref.watch(allCouriersProvider).value ?? const <Courier>[];
    final deliveries = ref.watch(allDeliveriesProvider).value ?? const <Delivery>[];
    return CorrePage(children: [
      Text('Motoboys', style: context.text.headlineSmall),
      Text('Nota abaixo de 4,0 tira da fila automática; abaixo de 3,5 o suporte conversa e combina um plano antes de qualquer bloqueio.', style: context.text.bodyMedium),
      const SizedBox(height: CorreSpace.md),
      CorreDataTable(
        columns: const ['Motoboy', 'Moto', 'Nota', 'Entregas', 'Situação', 'Cadastro'],
        rows: [
          for (final c in couriers)
            [
              Text(c.name),
              Text(c.bikeModel),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(c.rating?.toStringAsFixed(1) ?? 'novo'),
                if ((c.rating ?? 5) < 4) ...[
                  const SizedBox(width: CorreSpace.xs),
                  CorreBadge(label: (c.rating ?? 5) < 3.5 ? 'conversar' : 'fora da fila', tone: CorreTone.error),
                ],
              ]),
              Text('${deliveries.where((d) => d.courierId == c.id && d.status == DeliveryStatus.delivered).length}'),
              CorreBadge(
                label: switch (c.availability) {
                  CourierAvailability.offline => 'Offline',
                  CourierAvailability.online => 'Livre',
                  CourierAvailability.onDelivery => 'Em entrega',
                },
                tone: switch (c.availability) {
                  CourierAvailability.offline => CorreTone.neutral,
                  CourierAvailability.online => CorreTone.success,
                  CourierAvailability.onDelivery => CorreTone.warning,
                },
              ),
              CorreBadge(label: c.approval.label, tone: c.approval == ApprovalStatus.approved ? CorreTone.success : CorreTone.warning),
            ],
        ],
      ),
    ]);
  }
}

/// Repasses do dia: saldo de cada motoboy para pagar via Pix (manual no MVP).
class PayoutsPage extends ConsumerWidget {
  const PayoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.read(environmentProvider);
    ref.watch(allDeliveriesProvider);
    final couriers = (ref.watch(allCouriersProvider).value ?? const <Courier>[]).where((c) => c.approval == ApprovalStatus.approved).toList();
    final rows = [for (final c in couriers) (c, env.wallet.balanceOf(c.id))]..sort((a, b) => b.$2.compareTo(a.$2));
    final total = rows.fold<Cents>(0, (s, r) => s + (r.$2 > 0 ? r.$2 : 0));
    final csv = StringBuffer('motoboy;chave_pix;valor\n');
    for (final r in rows.where((r) => r.$2 > 0)) {
      csv.writeln('${r.$1.name};${r.$1.pixKey.isEmpty ? 'cadastrar' : r.$1.pixKey};${(r.$2 / 100).toStringAsFixed(2)}');
    }

    return CorrePage(maxWidth: 1000, children: [
      Row(children: [
        Expanded(child: Text('Repasses', style: context.text.headlineSmall)),
        CorreButton(
          label: 'Copiar lista Pix (CSV)',
          icon: Icons.copy,
          variant: CorreButtonVariant.ghost,
          expand: false,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: csv.toString()));
            if (context.mounted) CorreToast.show(context, 'Lista copiada', tone: CorreTone.success);
          },
        ),
      ]),
      Text('No MVP o Pix é feito à mão no banco. Na Onda 2 o Asaas paga automático no mesmo dia.', style: context.text.bodyMedium),
      const SizedBox(height: CorreSpace.md),
      CorreKpiTile(label: 'Total a pagar hoje', value: formatCents(total), icon: Icons.payments_outlined),
      const SizedBox(height: CorreSpace.md),
      CorreDataTable(
        columns: const ['Motoboy', 'Chave Pix', 'Saldo', ''],
        rows: [
          for (final r in rows)
            [
              Text(r.$1.name),
              Text(r.$1.pixKey.isEmpty ? '—' : r.$1.pixKey),
              Text(formatCents(r.$2)),
              r.$2 > 0
                  ? TextButton(
                      onPressed: () async {
                        await env.service.withdraw(r.$1.id);
                        if (context.mounted) CorreToast.show(context, 'Pix de ${formatCents(r.$2)} para ${r.$1.firstName} registrado', tone: CorreTone.success);
                      },
                      child: const Text('Marcar como pago'),
                    )
                  : const SizedBox.shrink(),
            ],
        ],
      ),
    ]);
  }
}

/// Registro de eventos: base para auditoria, métricas e análise futura.
class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final events = (ref.watch(eventsProvider).value ?? const <DomainEvent>[]).where((e) => _filter.isEmpty || e.type.contains(_filter)).take(300).toList();
    return CorrePage(children: [
      Text('Eventos', style: context.text.headlineSmall),
      Text('Tudo o que acontece fica registrado com data, quem fez e posição. Nome e telefone do cliente não entram aqui.', style: context.text.bodyMedium),
      const SizedBox(height: CorreSpace.md),
      SizedBox(width: 320, child: CorreSearchField(hint: 'Filtrar por tipo (ex.: offer, delivery, coupon)', onChanged: (v) => setState(() => _filter = v))),
      const SizedBox(height: CorreSpace.md),
      if (events.isEmpty)
        const CorreCard(child: CorreEmptyState(icon: Icons.list_alt, title: 'Nenhum evento ainda', message: 'Crie uma entrega ou deixe a tela Ao vivo aberta.'))
      else
        CorreDataTable(
          columns: const ['Hora', 'Tipo', 'Quem', 'Dados'],
          rows: [
            for (final e in events)
              [
                Text('${hhmm(e.at)}:${e.at.second.toString().padLeft(2, '0')}'),
                Text(e.type, style: const TextStyle(fontFamily: 'monospace')),
                Text(e.actorId ?? 'sistema'),
                Text(e.data.entries.map((x) => '${x.key}=${x.value}').join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
          ],
        ),
    ]);
  }
}
