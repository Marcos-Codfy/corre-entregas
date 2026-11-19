import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ocorrências com roteiro de atendimento. Críticas exigem todos os passos antes de resolver.
class IncidentsPage extends ConsumerWidget {
  const IncidentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(incidentsProvider).value ?? const <Incident>[];
    final deliveries = {for (final d in ref.watch(allDeliveriesProvider).value ?? const <Delivery>[]) d.id: d};
    final now = ref.watch(tickerProvider).value ?? DateTime.now();
    final env = ref.read(environmentProvider);

    return CorrePage(maxWidth: 1000, children: [
      Text('Ocorrências', style: context.text.headlineSmall),
      Text('Acidente, pedido avariado e cobrança divergente são críticos: repasse bloqueado até resolver e decisão com os dois sócios.', style: context.text.bodyMedium),
      const SizedBox(height: CorreSpace.md),
      if (list.isEmpty)
        const CorreCard(
          child: CorreEmptyState(
            icon: Icons.verified_outlined,
            tone: CorreTone.success,
            title: 'Nenhuma ocorrência',
            message: 'Na demonstração, relate um problema pela tela de uma entrega em andamento.',
          ),
        ),
      for (final i in list)
        Padding(
          padding: const EdgeInsets.only(bottom: CorreSpace.md),
          child: CorreCard(
            highlighted: i.kind.critical && i.status != IncidentStatus.resolved,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(i.kind.critical ? Icons.warning_amber_rounded : Icons.help_outline, color: i.kind.critical ? context.palette.error : context.palette.ink2),
                const SizedBox(width: CorreSpace.sm),
                Expanded(child: Text('${i.kind.label} · ${deliveries[i.deliveryId]?.code ?? ''}', style: context.text.titleMedium)),
                CorreBadge(
                  label: switch (i.status) {
                    IncidentStatus.open => 'Aberta',
                    IncidentStatus.inProgress => 'Em atendimento',
                    IncidentStatus.resolved => 'Resolvida',
                  },
                  tone: i.status == IncidentStatus.resolved ? CorreTone.success : (i.kind.critical ? CorreTone.error : CorreTone.warning),
                ),
              ]),
              Text('Aberta ${timeAgo(i.openedAt, now)} · ${i.description}', style: context.text.bodySmall),
              if (i.checklist.isNotEmpty) ...[
                const SizedBox(height: CorreSpace.sm),
                for (final step in i.checklist.entries)
                  CorreCheckbox(
                    label: step.key,
                    value: step.value,
                    onChanged: i.status == IncidentStatus.resolved
                        ? null
                        : (v) => env.incidents.save(i.copyWith(
                              status: IncidentStatus.inProgress,
                              checklist: {...i.checklist, step.key: v ?? false},
                            )),
                  ),
              ],
              if (i.resolution != null) Text('Decisão: ${i.resolution}', style: context.text.bodyMedium),
              const SizedBox(height: CorreSpace.sm),
              Wrap(spacing: CorreSpace.sm, children: [
                if (deliveries[i.deliveryId] != null)
                  CorreButton(label: 'Ver entrega', variant: CorreButtonVariant.ghost, size: CorreButtonSize.small, expand: false, onPressed: () => context.go('/entrega/${i.deliveryId}')),
                if (i.status != IncidentStatus.resolved)
                  CorreButton(
                    label: 'Resolver',
                    size: CorreButtonSize.small,
                    expand: false,
                    onPressed: () async {
                      if (i.checklist.values.any((done) => !done)) {
                        CorreToast.show(context, 'Conclua todos os passos do roteiro antes de resolver', tone: CorreTone.warning);
                        return;
                      }
                      final note = TextEditingController();
                      final ok = await showCorreSheet<bool>(context,
                          title: 'Registrar decisão',
                          child: Column(children: [
                            CorreTextField(label: 'O que foi decidido (com os dois sócios)', controller: note, maxLines: 3),
                            const SizedBox(height: CorreSpace.md),
                            CorreButton(label: 'Salvar e resolver', onPressed: () => Navigator.of(context).pop(true)),
                          ]));
                      if (ok == true) {
                        await env.incidents.save(i.copyWith(status: IncidentStatus.resolved, resolution: note.text.isEmpty ? 'Resolvido' : note.text));
                        env.events.append(DomainEvent(type: 'incident.resolved', at: DateTime.now(), actorId: Seed.supportUserId, deliveryId: i.deliveryId));
                      }
                      note.dispose();
                    },
                  ),
              ]),
            ]),
          ),
        ),
    ]);
  }
}
