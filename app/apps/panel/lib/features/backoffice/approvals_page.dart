import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aprovação manual de cadastros de motoboys e comércios.
class ApprovalsPage extends ConsumerWidget {
  const ApprovalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.read(environmentProvider);
    final couriers = (ref.watch(allCouriersProvider).value ?? const <Courier>[]).where((c) => c.approval == ApprovalStatus.pending).toList();
    final merchants = (ref.watch(allMerchantsProvider).value ?? const <Merchant>[]).where((m) => m.approval == ApprovalStatus.pending).toList();

    void log(String type, String id) => env.events.append(DomainEvent(type: type, at: DateTime.now(), actorId: Seed.supportUserId, data: {'id': id}));

    return CorrePage(maxWidth: 1000, children: [
      Text('Cadastros', style: context.text.headlineSmall),
      const SizedBox(height: CorreSpace.xs),
      const CorreBanner(
        icon: Icons.gavel_outlined,
        message: 'Regra atual: 18 anos ou mais, CNH A definitiva com EAR. Rever a exigência legal (Lei 12.009/2009 e MP 1.360/2026) antes do lançamento.',
      ),
      CorreSectionHeader(title: 'Motoboys (${couriers.length})'),
      if (couriers.isEmpty) const CorreCard(child: Text('Nenhum motoboy aguardando.')),
      for (final c in couriers)
        Padding(
          padding: const EdgeInsets.only(bottom: CorreSpace.md),
          child: CorreCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CorreListItem(leading: CorreAvatar(name: c.name), title: c.name, subtitle: '${c.bikeModel} · nascido em ${c.birthYear} · ${formatPhone(c.phone)}'),
              Wrap(spacing: CorreSpace.sm, runSpacing: CorreSpace.sm, children: [
                for (final k in DocumentKind.values)
                  ActionChip(
                    avatar: Icon(c.documents[k] == ApprovalStatus.approved ? Icons.check_circle : Icons.pending_outlined,
                        size: 18, color: c.documents[k] == ApprovalStatus.approved ? context.palette.success : context.palette.warning),
                    label: Text(k.label),
                    onPressed: () => env.couriers.save(c.copyWith(documents: {...c.documents, k: ApprovalStatus.approved})),
                  ),
              ]),
              const SizedBox(height: CorreSpace.xs),
              Text('Toque no documento para marcá-lo como conferido.', style: context.text.bodySmall),
              const SizedBox(height: CorreSpace.md),
              Row(children: [
                Expanded(
                  child: CorreButton(
                    label: 'Recusar',
                    variant: CorreButtonVariant.danger,
                    onPressed: () async {
                      await env.couriers.save(c.copyWith(approval: ApprovalStatus.rejected));
                      log('courier.rejected', c.id);
                    },
                  ),
                ),
                const SizedBox(width: CorreSpace.sm),
                Expanded(
                  flex: 2,
                  child: CorreButton(
                    label: 'Aprovar',
                    onPressed: () async {
                      if (c.documents.length < DocumentKind.values.length || c.documents.values.any((s) => s != ApprovalStatus.approved)) {
                        CorreToast.show(context, 'Confira todos os documentos antes de aprovar', tone: CorreTone.warning);
                        return;
                      }
                      await env.couriers.save(c.copyWith(approval: ApprovalStatus.approved, availability: CourierAvailability.offline));
                      log('courier.approved', c.id);
                      if (context.mounted) CorreToast.show(context, '${c.firstName} aprovado. Aviso enviado por WhatsApp.', tone: CorreTone.success);
                    },
                  ),
                ),
              ]),
            ]),
          ),
        ),
      CorreSectionHeader(title: 'Comércios (${merchants.length})'),
      if (merchants.isEmpty) const CorreCard(child: Text('Nenhum comércio aguardando.')),
      for (final m in merchants)
        CorreCard(
          child: Row(children: [
            Expanded(child: CorreListItem(leading: CorreAvatar(name: m.name, tone: CorreTone.accent), title: m.name, subtitle: '${m.category} · ${m.address.short}')),
            CorreButton(
              label: 'Aprovar',
              expand: false,
              onPressed: () async {
                await env.merchants.save(m.copyWith(approval: ApprovalStatus.approved));
                log('merchant.approved', m.id);
              },
            ),
          ]),
        ),
    ]);
  }
}
