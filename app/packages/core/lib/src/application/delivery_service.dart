import 'dart:math' as math;

import '../domain/delivery_status.dart';
import '../domain/dispatch.dart';
import '../domain/entities.dart';
import '../domain/geo.dart';
import '../domain/pricing.dart';
import '../domain/repositories.dart';

/// Erro de regra de negócio com mensagem pronta para a tela.
class BusinessError implements Exception {
  BusinessError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Casos de uso das entregas: criar, aceitar, avançar etapas, confirmar código, cancelar.
class DeliveryService {
  DeliveryService({
    required this.deliveries,
    required this.couriers,
    required this.merchants,
    required this.wallet,
    required this.events,
    required this.incidents,
    this.clock = const SystemClock(),
    PricingService pricing = const PricingService(),
    this.planner = const DispatchPlanner(),
    math.Random? random,
  })  : // ignore: prefer_initializing_formals
        _pricing = pricing,
        _random = random ?? math.Random();

  final DeliveryRepository deliveries;
  final CourierRepository couriers;
  final MerchantRepository merchants;
  final WalletRepository wallet;
  final EventLog events;
  final IncidentRepository incidents;
  final Clock clock;
  PricingService _pricing;
  PricingService get pricing => _pricing;
  final DispatchPlanner planner;
  final math.Random _random;
  int _seq = 4900;
  int _escalationSpentThisMonth = 0;

  int get escalationSpentThisMonth => _escalationSpentThisMonth;

  /// Admin muda a tabela de preços. Vale para as próximas entregas.
  void updatePricing(PricingRules rules, {required String adminId}) {
    if (rules.baseFreight <= 0 || rules.perExtraKm < 0 || rules.platformFee < 0 || rules.baseKm <= 0) {
      throw BusinessError('Valores de preço inválidos');
    }
    final before = _pricing.rules;
    _pricing = PricingService(rules);
    _log('pricing.updated', actor: adminId, data: {
      'baseFreight': [before.baseFreight, rules.baseFreight],
      'perExtraKm': [before.perExtraKm, rules.perExtraKm],
      'platformFee': [before.platformFee, rules.platformFee],
    });
  }

  String _id(String prefix) => '$prefix-${clock.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 20)}';

  void _log(String type, {String? actor, Delivery? d, GeoPoint? at, Map<String, Object?> data = const {}}) => events.append(
        DomainEvent(type: type, at: clock.now(), actorId: actor, deliveryId: d?.id, position: at, data: data),
      );

  /// Cotação para o comércio antes de pedir.
  Quote quoteFor(Merchant merchant, GeoPoint dropoff, {int extraStops = 0, bool rainOrLateNight = false}) =>
      pricing.quote(Geo.roadKm(merchant.address.point, dropoff), extraStops: extraStops, rainOrLateNight: rainOrLateNight);

  /// Cria a entrega e reserva o valor do saldo do comércio.
  Future<Delivery> create({
    required String merchantId,
    required Customer customer,
    required Address dropoff,
    String notes = '',
    List<String> tags = const [],
    int extraStops = 0,
    bool rainOrLateNight = false,
    Cents? orderValue,
    bool waiveFee = false,
  }) async {
    final merchant = merchants.byId(merchantId) ?? (throw BusinessError('Comércio não encontrado'));
    if (merchant.approval != ApprovalStatus.approved) throw BusinessError('Cadastro do comércio ainda em análise');
    if (customer.name.trim().isEmpty) throw BusinessError('Informe o nome do cliente');
    if (customer.phone.length < 10) throw BusinessError('Telefone do cliente incompleto');

    var quote = quoteFor(merchant, dropoff.point, extraStops: extraStops, rainOrLateNight: rainOrLateNight);
    if (waiveFee) quote = Quote(distanceKm: quote.distanceKm, freight: quote.freight, platformFee: 0, extras: quote.extras);
    if (quote.distanceKm > planner.rules.broadcastRadiusKm + 5) throw BusinessError('Endereço fora da área atendida');
    if (merchant.balance < quote.merchantTotal) {
      throw BusinessError('Saldo insuficiente. Recarregue ${formatCents(quote.merchantTotal - merchant.balance)} ou mais.');
    }

    final now = clock.now();
    final d = Delivery(
      id: _id('dlv'),
      code: '#PL-${++_seq}',
      merchantId: merchantId,
      customer: customer,
      pickup: merchant.address,
      dropoff: dropoff,
      quote: quote,
      deliveryCode: (1000 + _random.nextInt(9000)).toString(),
      trackingToken: _id('t').hashCode.toUnsigned(32).toRadixString(36),
      createdAt: now,
      timeline: {DeliveryStatus.searching: now},
      notes: notes,
      tags: tags,
      orderValue: orderValue,
    );
    await merchants.save(merchant.copyWith(balance: merchant.balance - quote.merchantTotal));
    await wallet.add(WalletEntry(id: _id('w'), ownerId: merchantId, amount: -quote.merchantTotal, description: 'Entrega ${d.code} (reserva)', at: now, kind: WalletEntryKind.fee));
    await deliveries.save(d);
    _log('delivery.created', actor: merchantId, d: d, at: dropoff.point, data: {
      'distanceKm': quote.distanceKm,
      'freight': quote.freight,
      'fee': quote.platformFee,
      'orderValue': orderValue,
      'district': dropoff.district,
    });
    return d;
  }

  Delivery _get(String id) => deliveries.byId(id) ?? (throw BusinessError('Entrega não encontrada'));

  /// Registra que a oferta foi mostrada a um motoboy.
  Future<void> markOffered(String deliveryId, String courierId) async {
    final d = _get(deliveryId);
    await deliveries.save(d.copyWith(offeredTo: {...d.offeredTo, courierId}.toList()));
    _log('offer.sent', actor: courierId, d: d);
  }

  Future<Delivery> accept(String deliveryId, String courierId) async {
    final d = _get(deliveryId);
    if (d.status != DeliveryStatus.searching) throw BusinessError('Essa corrida já foi aceita por outro motoboy');
    final c = couriers.byId(courierId) ?? (throw BusinessError('Motoboy não encontrado'));
    if (!c.isFree) throw BusinessError('Termine a corrida atual antes de aceitar outra');
    final next = d.transition(DeliveryStatus.accepted, clock.now()).copyWith(courierId: courierId);
    await deliveries.save(next);
    await couriers.save(c.copyWith(availability: CourierAvailability.onDelivery));
    _log('offer.accepted', actor: courierId, d: next, at: c.position, data: {'secondsToAccept': clock.now().difference(d.createdAt).inSeconds});
    return next;
  }

  /// Recusar nunca gera punição; só fica registrado para métricas.
  void decline(String deliveryId, String courierId, {String reason = 'recusou'}) {
    _log('offer.declined', actor: courierId, d: deliveries.byId(deliveryId), data: {'reason': reason});
  }

  /// Suporte escolhe um motoboy e atribui a entrega (despacho manual).
  Future<Delivery> assignManually(String deliveryId, String courierId, {required String supportId}) async {
    final d = await accept(deliveryId, courierId);
    _log('dispatch.manual', actor: supportId, d: d, data: {'courierId': courierId});
    return d;
  }

  /// Avança para a próxima etapa (ação do motoboy).
  Future<Delivery> advance(String deliveryId, DeliveryStatus to, {GeoPoint? at, double? traveledKm}) async {
    final d = _get(deliveryId);
    var next = d.transition(to, clock.now());
    if (traveledKm != null) next = next.copyWith(courierTraveledKm: traveledKm);
    await deliveries.save(next);
    _log('delivery.${to.name}', actor: d.courierId, d: next, at: at);
    if (to == DeliveryStatus.returned) await _finishReturn(next);
    return next;
  }

  /// Confere o código do cliente. Errar não muda o estado.
  Future<bool> confirmCode(String deliveryId, String code, {bool viaMerchantCall = false}) async {
    final d = _get(deliveryId);
    if (d.status != DeliveryStatus.atCustomer && d.status != DeliveryStatus.customerAbsent) {
      throw BusinessError('Chegue no cliente antes de confirmar');
    }
    final ok = viaMerchantCall || code == d.deliveryCode || code == d.customer.fallbackCode;
    _log(ok ? 'proof.ok' : 'proof.wrong_code', actor: d.courierId, d: d, data: {'viaMerchantCall': viaMerchantCall});
    if (!ok) return false;
    await _complete(d.copyWith(usedFallbackCode: viaMerchantCall || code != d.deliveryCode));
    return true;
  }

  Future<void> _complete(Delivery d) async {
    final now = clock.now();
    final done = d.transition(DeliveryStatus.delivered, now).copyWith(customer: d.customer.anonymized());
    await deliveries.save(done);
    if (d.courierId != null) {
      await wallet.add(WalletEntry(id: _id('w'), ownerId: d.courierId!, amount: d.courierAmount, description: 'Entrega ${d.code}', at: now, kind: WalletEntryKind.freight));
      final c = couriers.byId(d.courierId!);
      if (c != null) await couriers.save(c.copyWith(availability: CourierAvailability.online, idleSince: now));
    }
    _log('delivery.delivered', actor: d.courierId, d: done, at: d.dropoff.point, data: {
      'minutesTotal': now.difference(d.createdAt).inMinutes,
      'courierAmount': d.courierAmount,
    });
  }

  Future<void> _finishReturn(Delivery d) async {
    final now = clock.now();
    if (d.courierId == null) return;
    final amount = d.courierAmount + pricing.returnFee(d.quote.freight);
    await wallet.add(WalletEntry(id: _id('w'), ownerId: d.courierId!, amount: amount, description: 'Entrega ${d.code} + retorno', at: now, kind: WalletEntryKind.freight));
    final c = couriers.byId(d.courierId!);
    if (c != null) await couriers.save(c.copyWith(availability: CourierAvailability.online, idleSince: now));
  }

  /// Cancelamento pelo comércio, com a regra de 1 km.
  Future<Delivery> cancel(String deliveryId, {required String reason}) async {
    final d = _get(deliveryId);
    if (!d.status.merchantCanCancel) throw BusinessError('Depois da coleta não dá para cancelar. Fale com o suporte.');
    final fee = pricing.cancellationFee(accepted: d.status != DeliveryStatus.searching, courierTraveledKm: d.courierTraveledKm);
    final now = clock.now();
    final next = d.transition(DeliveryStatus.cancelledByMerchant, now).copyWith(cancellationFee: fee);
    await deliveries.save(next);
    await _refundMerchant(d, d.merchantTotal - fee, now, 'Estorno ${d.code}');
    if (d.courierId != null) {
      if (fee > 0) {
        await wallet.add(WalletEntry(id: _id('w'), ownerId: d.courierId!, amount: fee, description: 'Cancelamento ${d.code}', at: now, kind: WalletEntryKind.adjustment));
      }
      final c = couriers.byId(d.courierId!);
      if (c != null) await couriers.save(c.copyWith(availability: CourierAvailability.online, idleSince: now));
    }
    _log('delivery.cancelled', actor: d.merchantId, d: next, data: {'reason': reason, 'fee': fee, 'traveledKm': d.courierTraveledKm});
    return next;
  }

  /// Ninguém aceitou em 10 minutos: devolve tudo ao comércio.
  Future<Delivery> giveUp(String deliveryId) async {
    final d = _get(deliveryId);
    final next = d.transition(DeliveryStatus.noCourier, clock.now());
    await deliveries.save(next);
    await _refundMerchant(d, d.merchantTotal, clock.now(), 'Estorno ${d.code} (sem motoboy)');
    _log('dispatch.no_courier', d: next, data: {'offeredTo': d.offeredTo.length});
    return next;
  }

  /// 5 min sem aceite: frete sobe R$ 1, pago pela plataforma até o teto mensal.
  Future<Delivery> escalate(String deliveryId) async {
    final d = _get(deliveryId);
    final step = pricing.escalationAvailable(_escalationSpentThisMonth);
    _log('dispatch.escalate', d: d, data: {'amount': step, 'budgetLeft': pricing.rules.escalationMonthlyBudget - _escalationSpentThisMonth});
    if (step == 0 || d.escalation > 0) return d;
    _escalationSpentThisMonth += step;
    final next = d.copyWith(escalation: step);
    await deliveries.save(next);
    return next;
  }

  /// Motoboy desistiu depois de aceitar: volta a procurar sem punição.
  Future<Delivery> courierGiveBack(String deliveryId, {required String reason}) async {
    final d = _get(deliveryId);
    final next = d.transition(DeliveryStatus.searching, clock.now()).copyWith(clearCourier: true, courierTraveledKm: 0);
    await deliveries.save(next);
    final c = d.courierId == null ? null : couriers.byId(d.courierId!);
    if (c != null) await couriers.save(c.copyWith(availability: CourierAvailability.online, idleSince: clock.now()));
    _log('delivery.given_back', actor: d.courierId, d: next, data: {'reason': reason});
    return next;
  }

  Future<Incident> openIncident(String deliveryId, IncidentKind kind, {required String openedBy, String description = ''}) async {
    final d = _get(deliveryId);
    if (!d.status.isFinal && d.status != DeliveryStatus.searching && kind.critical) {
      await deliveries.save(d.transition(DeliveryStatus.incident, clock.now()));
    }
    final i = Incident(
      id: _id('inc'),
      deliveryId: deliveryId,
      kind: kind,
      openedAt: clock.now(),
      openedBy: openedBy,
      description: description,
      checklist: kind.critical ? {for (final s in Incident.criticalScript) s: false} : const {},
    );
    await incidents.save(i);
    _log('incident.opened', actor: openedBy, d: d, data: {'kind': kind.name, 'critical': kind.critical});
    return i;
  }

  Future<void> rateCourier(String deliveryId, int stars) async {
    if (stars < 1 || stars > 5) throw BusinessError('A nota vai de 1 a 5');
    final d = _get(deliveryId);
    if (d.status != DeliveryStatus.delivered) throw BusinessError('Só dá para avaliar entregas concluídas');
    await deliveries.save(d.copyWith(courierRating: stars));
    final c = d.courierId == null ? null : couriers.byId(d.courierId!);
    if (c != null) {
      final count = math.min(30, c.ratingCount + 1);
      final avg = ((c.rating ?? stars.toDouble()) * (count - 1) + stars) / count;
      await couriers.save(c.copyWith(rating: count >= 5 ? double.parse(avg.toStringAsFixed(2)) : c.rating, ratingCount: c.ratingCount + 1));
    }
    _log('rating.courier', d: d, data: {'stars': stars});
  }

  Future<void> topUp(String merchantId, Cents amount) async {
    if (amount < 5000) throw BusinessError('Recarga mínima de R\$ 50,00');
    final m = merchants.byId(merchantId) ?? (throw BusinessError('Comércio não encontrado'));
    await merchants.save(m.copyWith(balance: m.balance + amount));
    await wallet.add(WalletEntry(id: _id('w'), ownerId: merchantId, amount: amount, description: 'Recarga via Pix', at: clock.now(), kind: WalletEntryKind.topUp));
    _log('wallet.topup', actor: merchantId, data: {'amount': amount});
  }

  Future<void> withdraw(String courierId) async {
    final balance = wallet.balanceOf(courierId);
    if (balance <= 0) throw BusinessError('Sem saldo para sacar');
    await wallet.add(WalletEntry(id: _id('w'), ownerId: courierId, amount: -balance, description: 'Saque Pix', at: clock.now(), kind: WalletEntryKind.withdrawal));
    _log('wallet.withdraw', actor: courierId, data: {'amount': balance});
  }

  Future<void> _refundMerchant(Delivery d, Cents amount, DateTime at, String description) async {
    if (amount <= 0) return;
    final m = merchants.byId(d.merchantId);
    if (m == null) return;
    await merchants.save(m.copyWith(balance: m.balance + amount));
    await wallet.add(WalletEntry(id: _id('w'), ownerId: m.id, amount: amount, description: description, at: at, kind: WalletEntryKind.refund));
  }
}
