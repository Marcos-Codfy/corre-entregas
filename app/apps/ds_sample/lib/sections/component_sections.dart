import 'package:corre_design_system/corre_design_system.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class ButtonsSection extends StatefulWidget {
  const ButtonsSection({super.key});

  @override
  State<ButtonsSection> createState() => _ButtonsSectionState();
}

class _ButtonsSectionState extends State<ButtonsSection> {
  bool _loading = false;

  Future<void> _fakeLoad() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => CorrePage(maxWidth: 900, children: [
        DemoBlock(
          title: 'Variantes',
          description: 'Primário para a ação principal da tela; destaque (accent) para chamar motoboy; perigo para cancelar.',
          child: Wrap(spacing: CorreSpace.sm, runSpacing: CorreSpace.sm, children: [
            for (final v in CorreButtonVariant.values)
              CorreButton(label: v.name, variant: v, expand: false, onPressed: () {}),
          ]),
        ),
        DemoBlock(
          title: 'Tamanhos',
          child: Wrap(spacing: CorreSpace.sm, runSpacing: CorreSpace.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final s in CorreButtonSize.values) CorreButton(label: s.name, size: s, expand: false, onPressed: () {}),
          ]),
        ),
        DemoBlock(
          title: 'Estados',
          child: Column(children: [
            CorreButton(label: 'Pedir entregador', icon: Icons.two_wheeler, variant: CorreButtonVariant.accent, size: CorreButtonSize.large, onPressed: () {}),
            const SizedBox(height: CorreSpace.sm),
            CorreButton(label: 'Toque para carregar', loading: _loading, onPressed: _fakeLoad),
            const SizedBox(height: CorreSpace.sm),
            const CorreButton(label: 'Desabilitado'),
          ]),
        ),
        DemoBlock(
          title: 'Botão de ícone',
          child: Wrap(spacing: CorreSpace.sm, children: [
            CorreIconButton(icon: Icons.phone, tooltip: 'Ligar', tone: CorreTone.brand, onPressed: () {}),
            CorreIconButton(icon: Icons.chat_outlined, tooltip: 'WhatsApp', tone: CorreTone.success, onPressed: () {}),
            CorreIconButton(icon: Icons.map_outlined, tooltip: 'Abrir no mapa', onPressed: () {}),
            CorreIconButton(icon: Icons.report_outlined, tooltip: 'Relatar problema', tone: CorreTone.error, onPressed: () {}),
          ]),
        ),
      ]);
}

class InputsSection extends StatelessWidget {
  const InputsSection({super.key});

  @override
  Widget build(BuildContext context) => CorrePage(maxWidth: 600, children: [
        DemoBlock(
          title: 'Campos de texto',
          child: Column(children: [
            const CorreTextField(label: 'E-mail', hint: 'voce@email.com', prefixIcon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: CorreSpace.md),
            const CorrePasswordField(),
            const SizedBox(height: CorreSpace.md),
            CorreTextField(label: 'WhatsApp do cliente', hint: '(63) 9 9999-0000', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone, inputFormatters: [PhoneInputFormatter()]),
            const SizedBox(height: CorreSpace.md),
            CorreTextField(label: 'Valor do pedido (opcional)', hint: 'R\$ 0,00', keyboardType: TextInputType.number, inputFormatters: [CurrencyInputFormatter()], helper: 'Usado só para relatórios.'),
            const SizedBox(height: CorreSpace.md),
            const CorreTextField(label: 'Observação', hint: 'Ex.: portão azul, interfone 12', maxLines: 3),
            const SizedBox(height: CorreSpace.md),
            const CorreTextField(label: 'CNPJ', initialValue: '12.345.678/0001-0', errorText: 'CNPJ incompleto'),
            const SizedBox(height: CorreSpace.md),
            const CorreTextField(label: 'Campo desabilitado', initialValue: 'Burger da 106', enabled: false),
          ]),
        ),
        const DemoBlock(title: 'Busca', child: CorreSearchField(hint: 'Buscar entrega, cliente ou motoboy')),
      ]);
}

class SelectionSection extends StatefulWidget {
  const SelectionSection({super.key});

  @override
  State<SelectionSection> createState() => _SelectionSectionState();
}

class _SelectionSectionState extends State<SelectionSection> {
  String _period = 'hoje';
  final _tags = <String>{'1 sacola'};
  bool _online = true, _terms = false;
  String _vehicle = 'cg';

  @override
  Widget build(BuildContext context) => CorrePage(maxWidth: 700, children: [
        DemoBlock(
          title: 'Segmentado',
          child: CorreSegmented<String>(
            options: const {'hoje': 'Hoje', '7d': '7 dias', 'mes': 'Mês'},
            value: _period,
            onChanged: (v) => setState(() => _period = v),
          ),
        ),
        DemoBlock(
          title: 'Chips (múltipla escolha)',
          child: Wrap(spacing: CorreSpace.sm, runSpacing: CorreSpace.sm, children: [
            for (final t in ['1 sacola', 'Bebida', 'Frágil', 'Bag térmica'])
              CorreChip(
                label: t,
                selected: _tags.contains(t),
                onTap: () => setState(() => _tags.contains(t) ? _tags.remove(t) : _tags.add(t)),
              ),
          ]),
        ),
        DemoBlock(
          title: 'Switch, checkbox e lista',
          child: CorreCard(
            child: Column(children: [
              CorreSwitchTile(title: 'Ficar online', subtitle: 'Você recebe ofertas de corrida', value: _online, onChanged: (v) => setState(() => _online = v)),
              CorreCheckbox(label: 'Li e aceito os termos de uso', value: _terms, onChanged: (v) => setState(() => _terms = v ?? false)),
              const SizedBox(height: CorreSpace.sm),
              CorreDropdown<String>(
                label: 'Modelo da moto',
                items: const {'cg': 'Honda CG 160', 'fan': 'Honda Fan 160', 'factor': 'Yamaha Factor 150', 'pop': 'Honda Pop 110i'},
                value: _vehicle,
                onChanged: (v) => setState(() => _vehicle = v ?? _vehicle),
              ),
            ]),
          ),
        ),
      ]);
}

class DisplaySection extends StatelessWidget {
  const DisplaySection({super.key});

  @override
  Widget build(BuildContext context) => CorrePage(maxWidth: 900, children: [
        const DemoBlock(
          title: 'Indicadores (KPI)',
          child: CorreResponsiveGrid(children: [
            CorreKpiTile(label: 'Entregas hoje', value: '42', delta: '+12% vs. ontem', icon: Icons.local_shipping_outlined),
            CorreKpiTile(label: 'Aceite em até 5 min', value: '94%', delta: '+3 p.p.', icon: Icons.timer_outlined),
            CorreKpiTile(label: 'Tempo médio de coleta', value: '11 min', delta: '+2 min', positive: false, icon: Icons.storefront_outlined),
            CorreKpiTile(label: 'Motoboys online', value: '9', icon: Icons.two_wheeler),
          ]),
        ),
        DemoBlock(
          title: 'Cartões, avatar e lista',
          child: CorreCard(
            child: Column(children: [
              CorreListItem(
                leading: const CorreAvatar(name: 'Diego Martins'),
                title: 'Diego Martins',
                subtitle: 'Honda CG 160 · ★ 4,9',
                trailing: const CorreBadge(label: 'Online', tone: CorreTone.success),
                onTap: () {},
              ),
              const Divider(),
              CorreListItem(
                leading: const CorreAvatar(name: 'Rafa', tone: CorreTone.accent),
                title: 'Rafael Souza',
                subtitle: 'Yamaha Factor 150 · ★ 4,8',
                trailing: const CorreBadge(label: 'Em entrega', tone: CorreTone.warning),
                onTap: () {},
              ),
              const Divider(),
              const CorreKeyValue(label: 'Entregas na semana', value: '58'),
              const CorreKeyValue(label: 'Fretes', value: 'R\$ 464,00'),
              const CorreKeyValue(label: 'Disponível', value: 'R\$ 96,50', emphasize: true),
            ]),
          ),
        ),
        const DemoBlock(title: 'Progresso', child: CorreProgressBar(value: .72, label: 'Cadastro: 3 de 4 documentos enviados')),
        DemoBlock(
          title: 'Tabela (painel)',
          child: CorreDataTable(
            columns: const ['Código', 'Comércio', 'Cliente', 'Status', 'Frete'],
            rows: [
              for (final r in const [
                ['#PL-4821', 'Burger da 106', 'Mariana', 'A caminho', 'R\$ 9,50'],
                ['#PL-4822', 'Farmácia Vida', 'João', 'Procurando', 'R\$ 8,00'],
                ['#PL-4823', 'Açaí da Praia', 'Bia', 'Entregue', 'R\$ 11,00'],
              ])
                [
                  Text(r[0]),
                  Text(r[1]),
                  Text(r[2]),
                  CorreBadge(label: r[3], tone: r[3] == 'Entregue' ? CorreTone.success : r[3] == 'Procurando' ? CorreTone.info : CorreTone.warning),
                  Text(r[4]),
                ],
            ],
          ),
        ),
      ]);
}

class FeedbackSection extends StatelessWidget {
  const FeedbackSection({super.key});

  @override
  Widget build(BuildContext context) => CorrePage(maxWidth: 700, children: [
        DemoBlock(
          title: 'Avisos rápidos',
          child: Wrap(spacing: CorreSpace.sm, runSpacing: CorreSpace.sm, children: [
            CorreButton(label: 'Sucesso', expand: false, variant: CorreButtonVariant.secondary, onPressed: () => CorreToast.show(context, 'Entrega confirmada', tone: CorreTone.success)),
            CorreButton(label: 'Erro', expand: false, variant: CorreButtonVariant.danger, onPressed: () => CorreToast.show(context, 'Código incorreto', tone: CorreTone.error)),
            CorreButton(label: 'Informação', expand: false, variant: CorreButtonVariant.ghost, onPressed: () => CorreToast.show(context, 'Oferta enviada a 2 motoboys')),
          ]),
        ),
        DemoBlock(
          title: 'Diálogo e bottom sheet',
          child: Wrap(spacing: CorreSpace.sm, runSpacing: CorreSpace.sm, children: [
            CorreButton(
              label: 'Cancelar entrega',
              expand: false,
              variant: CorreButtonVariant.danger,
              onPressed: () async {
                final ok = await showCorreConfirm(context,
                    title: 'Cancelar entrega?',
                    message: 'O motoboy já rodou mais de 1 km. Serão cobrados R\$ 3,00 para ele.',
                    confirmLabel: 'Cancelar entrega',
                    destructive: true);
                if (context.mounted) CorreToast.show(context, ok ? 'Entrega cancelada' : 'Mantida');
              },
            ),
            CorreButton(
              label: 'Relatar problema',
              expand: false,
              variant: CorreButtonVariant.ghost,
              onPressed: () => showCorreSheet<void>(context,
                  title: 'O que aconteceu?',
                  child: Column(children: [
                    for (final m in ['Cliente não atende', 'Endereço errado', 'Pedido avariado', 'Acidente'])
                      CorreListItem(title: m, trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.pop(context)),
                  ])),
            ),
          ]),
        ),
        const DemoBlock(
          title: 'Faixas de aviso',
          child: Column(children: [
            CorreBanner(message: 'Sem internet. Suas ações ficam salvas e são enviadas quando voltar.', tone: CorreTone.warning, icon: Icons.wifi_off),
            SizedBox(height: CorreSpace.sm),
            CorreBanner(message: 'Sua CNH vence em 20 dias.', tone: CorreTone.error, icon: Icons.badge_outlined, actionLabel: 'Atualizar'),
            SizedBox(height: CorreSpace.sm),
            CorreBanner(message: 'Chuva em Palmas: +R\$ 3 por entrega até as 22h.', tone: CorreTone.info, icon: Icons.water_drop_outlined),
          ]),
        ),
        const DemoBlock(
          title: 'Carregando',
          child: CorreCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CorreSkeleton(width: 160, height: 18),
              SizedBox(height: CorreSpace.sm),
              CorreSkeleton(),
              SizedBox(height: CorreSpace.sm),
              CorreSkeleton(width: 220),
            ]),
          ),
        ),
        const DemoBlock(
          title: 'Estado vazio',
          child: CorreCard(
            child: CorreEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nenhuma entrega hoje',
              message: 'Quando você pedir um entregador, ele aparece aqui.',
              actionLabel: 'Pedir entregador',
              tone: CorreTone.brand,
            ),
          ),
        ),
      ]);
}
