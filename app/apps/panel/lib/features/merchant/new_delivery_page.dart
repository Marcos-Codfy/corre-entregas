import 'dart:async';

import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/session.dart';
import 'wallet_page.dart';

/// Busca de endereço simulada (na Onda 2: Google Places Autocomplete).
List<Address> searchAddresses(String q) {
  final t = q.trim().toLowerCase();
  if (t.length < 2) return const [];
  return Seed.places.where((a) => '${a.line} ${a.district}'.toLowerCase().contains(t)).take(6).toList();
}

class NewDeliveryPage extends ConsumerStatefulWidget {
  const NewDeliveryPage({super.key});

  @override
  ConsumerState<NewDeliveryPage> createState() => _NewDeliveryPageState();
}

class _NewDeliveryPageState extends ConsumerState<NewDeliveryPage> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  final _orderValue = TextEditingController();
  Address? _address;
  final _tags = <String>{'1 sacola'};
  bool _extraStop = false, _rain = false, _sending = false;
  String? _nameErr, _phoneErr, _addrErr;
  List<Address> _results = const [];

  @override
  void dispose() {
    for (final c in [_search, _name, _phone, _notes, _orderValue]) {
      c.dispose();
    }
    super.dispose();
  }

  void _pinOnMap(LatLng p) => setState(() {
        _address = Address(line: 'Ponto marcado no mapa', district: 'Palmas', point: GeoPoint(p.latitude, p.longitude), reference: _notes.text);
        _results = const [];
        _addrErr = null;
      });

  Future<void> _submit() async {
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _nameErr = _name.text.trim().isEmpty ? 'Informe o nome do cliente' : null;
      _phoneErr = phone.length < 10 ? 'Telefone com DDD' : null;
      _addrErr = _address == null ? 'Escolha o endereço na busca ou toque no mapa' : null;
    });
    if (_nameErr != null || _phoneErr != null || _addrErr != null) return;
    setState(() => _sending = true);
    try {
      final cents = int.tryParse(_orderValue.text.replaceAll(RegExp(r'\D'), ''));
      final credits = ref.read(feeWaiverCreditsProvider.notifier);
      final waive = credits.consume();
      final Delivery d;
      try {
        d = await ref.read(serviceProvider).create(
            merchantId: ref.read(myMerchantIdProvider),
            customer: Customer(name: _name.text.trim(), phone: phone),
            dropoff: _address!,
            notes: _notes.text.trim(),
            tags: _tags.toList(),
            extraStops: _extraStop ? 1 : 0,
            rainOrLateNight: _rain,
            orderValue: cents == 0 ? null : cents,
            waiveFee: waive,
          );
      } catch (_) {
        if (waive) credits.add(1);
        rethrow;
      }
      unawaited(ref.read(simulatorProvider).runDispatch(d.id));
      if (mounted) context.go('/entrega/${d.id}');
    } on BusinessError catch (e) {
      if (mounted) CorreToast.show(context, e.message, tone: CorreTone.error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ref.watch(myMerchantProvider);
    if (merchant == null) return const SizedBox.shrink();
    final service = ref.read(serviceProvider);
    final quote = _address == null ? null : service.quoteFor(merchant, _address!.point, extraStops: _extraStop ? 1 : 0, rainOrLateNight: _rain);
    final wide = context.screenSize != CorreScreenSize.mobile;

    final form = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CorreTextField(label: 'Retirada', initialValue: '${merchant.name} · ${merchant.address.line}', enabled: false, prefixIcon: Icons.storefront),
      const SizedBox(height: CorreSpace.md),
      CorreTextField(
        label: 'Endereço do cliente',
        controller: _search,
        hint: 'Digite a quadra, ex.: 208 Sul, ARSE, Taquaralto',
        prefixIcon: Icons.search,
        errorText: _addrErr,
        onChanged: (v) => setState(() => _results = searchAddresses(v)),
      ),
      if (_results.isNotEmpty)
        CorreCard(
          padding: const EdgeInsets.symmetric(horizontal: CorreSpace.md),
          child: Column(children: [
            for (final a in _results)
              CorreListItem(
                leading: const Icon(Icons.place_outlined),
                title: a.line,
                subtitle: a.district,
                onTap: () => setState(() {
                  _address = a;
                  _search.text = a.line;
                  _results = const [];
                  _addrErr = null;
                }),
              ),
          ]),
        ),
      if (_address != null) ...[
        const SizedBox(height: CorreSpace.xs),
        Text('Selecionado: ${_address!.short}', style: context.text.bodySmall),
      ],
      const SizedBox(height: CorreSpace.md),
      Row(children: [
        Expanded(child: CorreTextField(label: 'Nome do cliente', controller: _name, errorText: _nameErr)),
        const SizedBox(width: CorreSpace.md),
        Expanded(
          child: CorreTextField(label: 'WhatsApp do cliente', controller: _phone, errorText: _phoneErr, keyboardType: TextInputType.phone, inputFormatters: [PhoneInputFormatter()]),
        ),
      ]),
      const SizedBox(height: CorreSpace.md),
      CorreTextField(label: 'Observação para o motoboy', controller: _notes, hint: 'Ex.: portão azul, interfone 12', maxLines: 2),
      const SizedBox(height: CorreSpace.md),
      CorreTextField(
        label: 'Valor do pedido (opcional, só para relatório)',
        controller: _orderValue,
        keyboardType: TextInputType.number,
        inputFormatters: [CurrencyInputFormatter()],
      ),
      const SizedBox(height: CorreSpace.md),
      Wrap(spacing: CorreSpace.sm, runSpacing: CorreSpace.sm, children: [
        for (final t in ['1 sacola', 'Bebida', 'Frágil', 'Bag térmica', 'Pizza'])
          CorreChip(label: t, selected: _tags.contains(t), onTap: () => setState(() => _tags.contains(t) ? _tags.remove(t) : _tags.add(t))),
      ]),
      const SizedBox(height: CorreSpace.sm),
      CorreSwitchTile(title: 'Segunda parada na mesma rota (+R\$ 2,00)', subtitle: '2 clientes no mesmo caminho', value: _extraStop, onChanged: (v) => setState(() => _extraStop = v)),
      CorreSwitchTile(title: 'Chuva ou após 23h (+R\$ 3,00)', subtitle: 'Vai 100% para o motoboy', value: _rain, onChanged: (v) => setState(() => _rain = v)),
      const SizedBox(height: CorreSpace.sm),
      const CorreBanner(icon: Icons.money_off, message: 'O motoboy só entrega: o cliente paga o pedido direto a você.'),
    ]);

    final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: wide ? 360 : 240,
        child: CorreMapView(
          center: merchant.address.point.latLng,
          zoom: 13,
          onTap: _pinOnMap,
          route: _address == null ? const [] : correLRoute(merchant.address.point.latLng, _address!.point.latLng),
          pins: [
            CorreMapPin(point: merchant.address.point.latLng, kind: CorreMarkerKind.pickup),
            if (_address != null) CorreMapPin(point: _address!.point.latLng, kind: CorreMarkerKind.dropoff),
          ],
        ),
      ),
      const SizedBox(height: CorreSpace.xs),
      Text('Toque no mapa para ajustar o ponto de entrega.', style: context.text.bodySmall),
      const SizedBox(height: CorreSpace.md),
      if (quote != null)
        CorrePriceSummary(
          lines: [
            CorrePriceLine('Frete do motoboy (${km(quote.distanceKm)})', quote.freight / 100),
            if (quote.extras > 0) CorrePriceLine('Adicionais', quote.extras / 100),
            CorrePriceLine('Taxa da plataforma', quote.platformFee / 100),
          ],
          total: quote.merchantTotal / 100,
          footnote: 'Reservado do saldo (${formatCents(merchant.balance)}). Volta se ninguém aceitar em 10 min.',
        )
      else
        const CorreCard(child: Text('Escolha o endereço para ver o valor. Até 5 km: R\$ 8,00 + R\$ 1,50 de taxa.')),
      const SizedBox(height: CorreSpace.md),
      CorreButton(label: 'Chamar motoboy', size: CorreButtonSize.large, loading: _sending, onPressed: _submit),
    ]);

    return CorrePage(maxWidth: 1100, children: [
      Text('Nova entrega', style: context.text.headlineSmall),
      const SizedBox(height: CorreSpace.lg),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: form),
          const SizedBox(width: CorreSpace.xl),
          Expanded(flex: 2, child: side),
        ])
      else ...[form, const SizedBox(height: CorreSpace.lg), side],
    ]);
  }
}
