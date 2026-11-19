import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session.dart';

/// Até 3 motoboys de confiança recebem as entregas primeiro.
class PreferredCouriersPage extends ConsumerWidget {
  const PreferredCouriersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(myMerchantProvider);
    final couriers = (ref.watch(allCouriersProvider).value ?? const <Courier>[]).where((c) => c.approval == ApprovalStatus.approved).toList()
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    if (m == null) return const SizedBox.shrink();

    Future<void> toggle(Courier c) async {
      final current = [...m.preferredCourierIds];
      if (current.contains(c.id)) {
        current.remove(c.id);
      } else {
        if (current.length >= Merchant.maxPreferred) {
          CorreToast.show(context, 'Máximo de ${Merchant.maxPreferred} preferidos. Remova um antes.', tone: CorreTone.warning);
          return;
        }
        current.add(c.id);
      }
      await ref.read(environmentProvider).merchants.save(m.copyWith(preferredCourierIds: current));
    }

    return CorrePage(maxWidth: 900, children: [
      Text('Motoboys preferidos', style: context.text.headlineSmall),
      Text('Escolha até 3. A oferta vai primeiro para eles (se estiverem online e livres) e depois para os mais próximos.', style: context.text.bodyMedium),
      const SizedBox(height: CorreSpace.md),
      CorreBadge(label: '${m.preferredCourierIds.length} de ${Merchant.maxPreferred} escolhidos', tone: CorreTone.brand),
      const SizedBox(height: CorreSpace.md),
      CorreCard(
        child: Column(children: [
          for (final c in couriers)
            CorreListItem(
              leading: CorreAvatar(name: c.name),
              title: c.name,
              subtitle: '${c.bikeModel} · ★ ${c.rating?.toStringAsFixed(1) ?? 'novo'} · ${c.ratingCount} avaliações${(c.rating ?? 5) < 4 ? ' · fora da fila automática' : ''}',
              trailing: IconButton(
                tooltip: m.preferredCourierIds.contains(c.id) ? 'Remover dos preferidos' : 'Marcar como preferido',
                icon: Icon(m.preferredCourierIds.contains(c.id) ? Icons.favorite : Icons.favorite_border, color: context.palette.error),
                onPressed: () => toggle(c),
              ),
            ),
        ]),
      ),
    ]);
  }
}

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) => CorrePage(maxWidth: 900, children: [
        Text('Equipe', style: context.text.headlineSmall),
        Text('Atendentes pedem e acompanham entregas, mas não veem o financeiro. Cada atendente usa um aparelho por vez.', style: context.text.bodyMedium),
        const SizedBox(height: CorreSpace.md),
        const CorreCard(
          child: Column(children: [
            CorreListItem(leading: CorreAvatar(name: 'Dono Burger'), title: 'Você (dono)', subtitle: 'Acesso total · vários aparelhos', trailing: CorreBadge(label: 'Dono', tone: CorreTone.brand)),
            Divider(),
            CorreListItem(leading: CorreAvatar(name: 'Juliana Caixa', tone: CorreTone.accent), title: 'Juliana (caixa)', subtitle: 'Último acesso hoje 19:02', trailing: CorreBadge(label: 'Atendente')),
          ]),
        ),
        const SizedBox(height: CorreSpace.md),
        Builder(
          builder: (context) => CorreButton(
            label: 'Convidar atendente',
            icon: Icons.person_add_alt,
            variant: CorreButtonVariant.secondary,
            expand: false,
            onPressed: () => CorreToast.show(context, 'Na versão real o convite vai por e-mail.'),
          ),
        ),
      ]);
}

class MerchantSettingsPage extends ConsumerStatefulWidget {
  const MerchantSettingsPage({super.key});

  @override
  ConsumerState<MerchantSettingsPage> createState() => _MerchantSettingsPageState();
}

class _MerchantSettingsPageState extends ConsumerState<MerchantSettingsPage> {
  bool _sound = true, _autoWhats = false;

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(myMerchantProvider);
    if (m == null) return const SizedBox.shrink();
    return CorrePage(maxWidth: 800, children: [
      Text('Configurações', style: context.text.headlineSmall),
      const CorreSectionHeader(title: 'Dados do comércio'),
      CorreCard(
        child: Column(children: [
          CorreKeyValue(label: 'Nome', value: m.name),
          CorreKeyValue(label: 'Categoria', value: m.category),
          CorreKeyValue(label: 'CNPJ', value: m.cnpj.isEmpty ? '—' : m.cnpj),
          CorreKeyValue(label: 'Endereço de retirada', value: m.address.line),
          CorreKeyValue(label: 'Cadastro', value: m.approval.label),
        ]),
      ),
      const CorreSectionHeader(title: 'Preferências'),
      CorreCard(
        child: Column(children: [
          CorreSwitchTile(title: 'Som quando o motoboy aceitar', value: _sound, onChanged: (v) => setState(() => _sound = v)),
          CorreSwitchTile(title: 'Abrir o WhatsApp do cliente ao criar a entrega', value: _autoWhats, onChanged: (v) => setState(() => _autoWhats = v)),
          CorreSwitchTile(title: 'Tema escuro', value: ref.watch(themeModeProvider) == ThemeMode.dark, onChanged: (_) => ref.read(themeModeProvider.notifier).toggle()),
        ]),
      ),
      const CorreSectionHeader(title: 'Privacidade'),
      const CorreCard(
        child: Text('Nome e telefone dos clientes são apagados depois da entrega. Guardamos só o bairro e dados de tempo e distância para melhorar o serviço.'),
      ),
    ]);
  }
}
