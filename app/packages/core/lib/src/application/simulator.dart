import 'dart:async';
import 'dart:math' as math;

import '../data/seed.dart';
import '../domain/delivery_status.dart';
import '../domain/dispatch.dart';
import '../domain/entities.dart';
import '../domain/geo.dart';
import 'delivery_service.dart';

/// Oferta de corrida mostrada a um motoboy.
class Offer {
  Offer({required this.delivery, required this.courierId, required this.expiresIn, required this.reason});
  final Delivery delivery;
  final String courierId;
  final Duration expiresIn;

  /// preferred, radius:5, radius:7, broadcast, manual
  final String reason;
  bool get fromPreferred => reason == 'preferred';
}

/// Simula o "outro lado" enquanto não existe backend (Onda 1):
/// comércios pedindo, motoboys aceitando e andando no mapa.
class Simulator {
  Simulator(this.service, {math.Random? random, this.timeScale = 6, this.tick = const Duration(seconds: 1)})
      : _r = random ?? math.Random();

  final DeliveryService service;
  final math.Random _r;

  /// Quantas vezes mais rápido que o tempo real os prazos do despacho correm.
  final double timeScale;

  /// Intervalo de atualização da posição (representa o GPS de 7 s).
  final Duration tick;

  final _offers = StreamController<Offer>.broadcast();
  final _timers = <Timer>[];
  final _moving = <String, Timer>{};
  final _dispatching = <String>{};
  bool _disposed = false;

  Stream<Offer> get offers => _offers.stream;

  Duration _scaled(Duration d) => Duration(milliseconds: math.max(200, d.inMilliseconds ~/ timeScale));

  void dispose() {
    _disposed = true;
    for (final t in [..._timers, ..._moving.values]) {
      t.cancel();
    }
    _offers.close();
  }

  // ---------------------------------------------------------------- motoboy

  Timer? _feed;

  /// Enquanto o motoboy de demonstração estiver livre, chegam ofertas de tempos em tempos.
  void startCourierFeed(String courierId, {Duration every = const Duration(seconds: 35)}) {
    _feed?.cancel();
    _feed = Timer.periodic(every, (_) {
      final c = service.couriers.byId(courierId);
      if (c != null && c.isFree) offerTo(courierId);
    });
    _timers.add(_feed!);
  }

  void stopCourierFeed() => _feed?.cancel();

  /// Cria uma entrega de um comércio próximo e oferece ao motoboy.
  Future<Offer?> offerTo(String courierId) async {
    if (_disposed) return null;
    final c = service.couriers.byId(courierId);
    if (c == null || !c.isFree) return null;
    final merchants = service.merchants.all().where((m) => m.approval == ApprovalStatus.approved).toList()
      ..sort((a, b) => Geo.roadKm(a.address.point, c.position).compareTo(Geo.roadKm(b.address.point, c.position)));
    final m = merchants[_r.nextInt(math.min(3, merchants.length))];
    await _ensureBalance(m.id);
    final drop = Seed.places[_r.nextInt(Seed.places.length)];
    final d = await service.create(
      merchantId: m.id,
      customer: Seed.randomCustomer(_r),
      dropoff: drop,
      tags: _r.nextBool() ? const ['1 sacola'] : const ['Bebida', 'Bag térmica'],
      orderValue: 2500 + _r.nextInt(8000),
    );
    await service.markOffered(d.id, courierId);
    final offer = Offer(
      delivery: d,
      courierId: courierId,
      expiresIn: service.planner.rules.offerTimeout,
      reason: m.preferredCourierIds.contains(courierId) ? 'preferred' : 'radius:5',
    );
    _offers.add(offer);
    return offer;
  }

  /// Oferta recusada ou expirada: outro motoboy simulado pega.
  Future<void> handOffToOthers(String deliveryId, {String? except}) => runDispatch(deliveryId, skip: {?except});

  /// Move o motoboy em direção ao alvo da etapa atual (coleta ou cliente).
  void followRoute(String courierId, String deliveryId, {double kmPerTick = .12}) {
    _moving[courierId]?.cancel();
    _moving[courierId] = Timer.periodic(tick, (t) async {
      final d = service.deliveries.byId(deliveryId);
      final c = service.couriers.byId(courierId);
      if (_disposed || d == null || c == null || d.status.isFinal) {
        t.cancel();
        return;
      }
      final target = switch (d.status) {
        DeliveryStatus.accepted => d.pickup.point,
        DeliveryStatus.toCustomer || DeliveryStatus.pickedUp => d.dropoff.point,
        DeliveryStatus.returning => d.pickup.point,
        _ => null,
      };
      if (target == null) return;
      final left = Geo.straightKm(c.position, target);
      if (left < .01) return;
      final step = math.min(1.0, kmPerTick / left);
      final next = Geo.lerp(c.position, target, step);
      await service.couriers.save(c.copyWith(position: next));
      await service.deliveries.save(d.copyWith(courierTraveledKm: d.courierTraveledKm + Geo.straightKm(c.position, next) * Geo.roadFactor));
    });
  }

  void stopRoute(String courierId) => _moving.remove(courierId)?.cancel();

  /// Distância restante até o alvo, em km de rua.
  double remainingKm(String courierId, GeoPoint target) {
    final c = service.couriers.byId(courierId);
    return c == null ? 0 : Geo.roadKm(c.position, target);
  }

  // ---------------------------------------------------------------- comércio / painel

  /// Roda o despacho com motoboys simulados (o motoboy de demonstração não participa aqui,
  /// porque o celular e o painel ainda não conversam entre si).
  Future<void> runDispatch(String deliveryId, {Set<String> skip = const {}}) async {
    if (!_dispatching.add(deliveryId)) return;
    try {
      final d0 = service.deliveries.byId(deliveryId);
      if (d0 == null) return;
      final merchant = service.merchants.byId(d0.merchantId)!;
      final plan = service.planner.plan(
        merchant: merchant,
        couriers: service.couriers.all(),
        exclude: {Seed.demoCourierId, ...skip},
      );
      final started = DateTime.now();
      var escalated = false;
      for (final step in plan) {
        for (final id in step.courierIds) {
          if (_disposed) return;
          final d = service.deliveries.byId(deliveryId);
          if (d == null || d.status != DeliveryStatus.searching) return;
          await service.markOffered(deliveryId, id);
        }
        await Future<void>.delayed(_scaled(service.planner.rules.offerTimeout));
        final elapsed = DateTime.now().difference(started) * timeScale;
        final decision = service.planner.decide(elapsed);
        if (decision == DispatchDecision.giveUp) break;
        if (decision == DispatchDecision.escalate && !escalated) {
          escalated = true;
          await service.escalate(deliveryId);
        }
        // Chance de aceite cresce no broadcast e para preferidos.
        final chance = step.isBroadcast ? .9 : (step.reason == 'preferred' ? .7 : .45);
        if (_r.nextDouble() < chance) {
          final id = step.courierIds[_r.nextInt(step.courierIds.length)];
          final c = service.couriers.byId(id);
          final d = service.deliveries.byId(deliveryId);
          if (c != null && c.isFree && d != null && d.status == DeliveryStatus.searching) {
            await service.accept(deliveryId, id);
            unawaited(_autoRun(deliveryId, id));
            return;
          }
        }
        service.decline(deliveryId, step.courierIds.first, reason: 'sem resposta');
      }
      final d = service.deliveries.byId(deliveryId);
      if (d != null && d.status == DeliveryStatus.searching) await service.giveUp(deliveryId);
    } finally {
      _dispatching.remove(deliveryId);
    }
  }

  /// Leva a entrega até o fim sozinha (motoboy simulado).
  Future<void> _autoRun(String deliveryId, String courierId) async {
    followRoute(courierId, deliveryId, kmPerTick: .18);
    Future<bool> arrive(GeoPoint target) async {
      for (var i = 0; i < 400; i++) {
        if (_disposed) return false;
        final d = service.deliveries.byId(deliveryId);
        if (d == null || d.status.isFinal || d.status == DeliveryStatus.incident) return false;
        if (remainingKm(courierId, target) < .03) return true;
        await Future<void>.delayed(tick);
      }
      return false;
    }

    Future<bool> step(DeliveryStatus s) async {
      final d = service.deliveries.byId(deliveryId);
      if (d == null || !DeliveryFlow.canTransition(d.status, s)) return false;
      await service.advance(deliveryId, s, at: service.couriers.byId(courierId)?.position);
      return true;
    }

    final d = service.deliveries.byId(deliveryId)!;
    if (!await arrive(d.pickup.point) || !await step(DeliveryStatus.atMerchant)) return;
    await Future<void>.delayed(_scaled(const Duration(minutes: 1)));
    if (!await step(DeliveryStatus.pickedUp) || !await step(DeliveryStatus.toCustomer)) return;
    if (!await arrive(d.dropoff.point) || !await step(DeliveryStatus.atCustomer)) return;
    await Future<void>.delayed(_scaled(const Duration(seconds: 30)));
    final now = service.deliveries.byId(deliveryId)!;
    if (now.status == DeliveryStatus.atCustomer) await service.confirmCode(deliveryId, now.deliveryCode);
    stopRoute(courierId);
  }

  /// Movimento de fundo no painel: outros comércios pedindo de tempos em tempos.
  void startBackgroundTraffic({Duration every = const Duration(seconds: 40), Set<String> exceptMerchants = const {}}) {
    _timers.add(Timer.periodic(every, (_) async {
      if (_disposed) return;
      final ms = service.merchants.all().where((m) => m.approval == ApprovalStatus.approved && !exceptMerchants.contains(m.id)).toList();
      if (ms.isEmpty) return;
      final m = ms[_r.nextInt(ms.length)];
      await _ensureBalance(m.id);
      final d = await service.create(merchantId: m.id, customer: Seed.randomCustomer(_r), dropoff: Seed.places[_r.nextInt(Seed.places.length)]);
      unawaited(runDispatch(d.id));
    }));
  }

  Future<void> _ensureBalance(String merchantId) async {
    final m = service.merchants.byId(merchantId);
    if (m != null && m.balance < 5000) await service.topUp(merchantId, 10000);
  }
}
