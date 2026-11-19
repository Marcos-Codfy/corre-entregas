import 'package:corre_design_system/corre_design_system.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart';

class DomainSection extends StatefulWidget {
  const DomainSection({super.key});

  @override
  State<DomainSection> createState() => _DomainSectionState();
}

class _DomainSectionState extends State<DomainSection> {
  int _ringKey = 0;
  String? _codeError;
  int _stars = 4;

  @override
  Widget build(BuildContext context) => CorrePage(maxWidth: 900, children: [
        DemoBlock(
          title: 'Oferta de corrida',
          description: 'O motoboy tem 20 segundos para aceitar. Recusar não gera punição.',
          child: CorreCard(
            child: Column(children: [
              Row(children: [
                const CorreBadge(label: 'Nova corrida', tone: CorreTone.info),
                const Spacer(),
                Text('Preferido do comércio', style: context.text.bodySmall),
              ]),
              const SizedBox(height: CorreSpace.md),
              CorreCountdownRing(key: ValueKey(_ringKey), total: const Duration(seconds: 20)),
              const SizedBox(height: CorreSpace.md),
              Text('R\$ 8,00', style: context.text.headlineMedium?.copyWith(color: context.palette.brand)),
              Text('4,2 km · coleta a 900 m · 100% seu', style: context.text.bodySmall),
              const SizedBox(height: CorreSpace.md),
              Row(children: [
                Expanded(child: CorreButton(label: 'Recusar', variant: CorreButtonVariant.danger, onPressed: () => setState(() => _ringKey++))),
                const SizedBox(width: CorreSpace.sm),
                Expanded(flex: 2, child: CorreButton(label: 'Aceitar', onPressed: () => setState(() => _ringKey++))),
              ]),
            ]),
          ),
        ),
        const DemoBlock(
          title: 'Linha do tempo da entrega',
          child: CorreCard(
            child: CorreStepTimeline(steps: [
              CorreStep('Motoboy aceitou', CorreStepState.done, time: '19:22'),
              CorreStep('Chegou no comércio', CorreStepState.done, time: '19:29'),
              CorreStep('Pedido coletado', CorreStepState.done, time: '19:31'),
              CorreStep('A caminho do cliente', CorreStepState.current),
              CorreStep('Entregue', CorreStepState.pending),
            ]),
          ),
        ),
        DemoBlock(
          title: 'Código de entrega',
          description: 'Digite 7316 para ver o sucesso; qualquer outro mostra erro.',
          child: CorreCard(
            child: CorreCodeInput(
              errorText: _codeError,
              onCompleted: (v) {
                final ok = v == '7316';
                setState(() => _codeError = ok ? null : 'Código não confere. Confirme com o cliente.');
                if (ok) CorreToast.show(context, 'Entrega confirmada', tone: CorreTone.success);
              },
            ),
          ),
        ),
        const DemoBlock(
          title: 'Resumo de preço',
          child: CorrePriceSummary(
            lines: [CorrePriceLine('Frete do motoboy (6 km)', 9.5), CorrePriceLine('Taxa da plataforma', 1.5)],
            total: 11,
            footnote: 'Reservado do seu saldo. Volta se ninguém aceitar em 10 min.',
          ),
        ),
        DemoBlock(
          title: 'Cartões de entrega',
          child: Column(children: [
            CorreDeliveryCard(code: '#PL-4821', title: 'Mariana', subtitle: 'Diego · chega em ~6 min', statusLabel: 'A caminho', statusTone: CorreTone.warning, value: 11, onTap: () {}),
            const SizedBox(height: CorreSpace.sm),
            CorreDeliveryCard(code: '#PL-4823', title: 'João', subtitle: 'Oferecido a 2 motoboys · 0:40', statusLabel: 'Procurando', statusTone: CorreTone.info, onTap: () {}),
            const SizedBox(height: CorreSpace.sm),
            CorreDeliveryCard(code: '#PL-4810', title: 'Bia', subtitle: '307 Sul · cancelada pelo comércio', statusLabel: 'Cancelada', statusTone: CorreTone.error, value: 0, onTap: () {}),
          ]),
        ),
        DemoBlock(
          title: 'Mapa',
          description: 'OpenStreetMap, grátis e sem chave. Rota em "L", como as avenidas de Palmas.',
          child: SizedBox(
            height: 280,
            child: CorreMapView(
              zoom: 14,
              route: correLRoute(const LatLng(-10.1918, -48.3258), const LatLng(-10.1985, -48.3239)),
              pins: const [
                CorreMapPin(point: LatLng(-10.1918, -48.3258), kind: CorreMarkerKind.pickup, label: 'Coleta'),
                CorreMapPin(point: LatLng(-10.1985, -48.3239), kind: CorreMarkerKind.dropoff, label: 'Entrega'),
                CorreMapPin(point: LatLng(-10.1940, -48.3256), kind: CorreMarkerKind.courier, label: 'Motoboy'),
              ],
            ),
          ),
        ),
        const DemoBlock(
          title: 'Marcadores de mapa',
          child: Wrap(spacing: CorreSpace.lg, children: [
            CorreMapMarker(kind: CorreMarkerKind.courier, label: 'Motoboy'),
            CorreMapMarker(kind: CorreMarkerKind.pickup, label: 'Coleta'),
            CorreMapMarker(kind: CorreMarkerKind.dropoff, label: 'Entrega'),
          ]),
        ),
        DemoBlock(title: 'Avaliação', child: CorreRating(value: _stars, onChanged: (v) => setState(() => _stars = v))),
      ]);
}

class LayoutSection extends StatefulWidget {
  const LayoutSection({super.key});

  @override
  State<LayoutSection> createState() => _LayoutSectionState();
}

class _LayoutSectionState extends State<LayoutSection> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => CorrePage(maxWidth: 900, children: [
        DemoBlock(
          title: 'Navegação inferior (app do motoboy)',
          child: ClipRRect(
            borderRadius: CorreRadius.mdAll,
            child: CorreBottomNav(
              index: _tab,
              onTap: (i) => setState(() => _tab = i),
              items: const [
                CorreNavItem(label: 'Início', icon: Icons.home_outlined, selectedIcon: Icons.home),
                CorreNavItem(label: 'Corrida', icon: Icons.two_wheeler),
                CorreNavItem(label: 'Carteira', icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet),
                CorreNavItem(label: 'Perfil', icon: Icons.person_outline, selectedIcon: Icons.person),
              ],
            ),
          ),
        ),
        DemoBlock(
          title: 'Menu do painel web',
          description: 'Este próprio catálogo usa o shell do painel: menu lateral no desktop, trilho no tablet e gaveta no celular. '
              'Redimensione a janela para ver.',
          child: CorreBanner(message: 'Tela atual: ${context.screenSize.name}', icon: Icons.aspect_ratio),
        ),
        const DemoBlock(
          title: 'Grade responsiva',
          child: CorreResponsiveGrid(children: [
            CorreCard(child: Text('1')),
            CorreCard(child: Text('2')),
            CorreCard(child: Text('3')),
            CorreCard(child: Text('4')),
          ]),
        ),
      ]);
}
