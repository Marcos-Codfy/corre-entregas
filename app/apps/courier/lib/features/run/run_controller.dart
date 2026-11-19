import 'package:corre_core/corre_core.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/courier_controller.dart';
import '../offline/offline_queue.dart';

/// Próxima ação da corrida conforme o estado.
enum RunAction {
  arriveMerchant('Cheguei no comércio'),
  pickUp('Coletei o pedido'),
  arriveCustomer('Cheguei no cliente'),
  confirmCode('Confirmar com o código'),
  returnToMerchant('Voltar ao comércio'),
  finishReturn('Devolvi ao comércio'),
  none('');

  const RunAction(this.label);
  final String label;

  static RunAction of(DeliveryStatus s) => switch (s) {
    DeliveryStatus.accepted => arriveMerchant,
    DeliveryStatus.atMerchant => pickUp,
    DeliveryStatus.pickedUp || DeliveryStatus.toCustomer => arriveCustomer,
    DeliveryStatus.atCustomer => confirmCode,
    DeliveryStatus.customerAbsent => returnToMerchant,
    DeliveryStatus.returning => finishReturn,
    _ => none,
  };
}

/// ViewModel da corrida: avança etapas, relata problemas e desiste.
class RunController {
  RunController(this.ref);
  final Ref ref;

  DeliveryService get _s => ref.read(serviceProvider);
  Simulator get _sim => ref.read(simulatorProvider);
  OfflineQueue get _queue => ref.read(offlineQueueProvider.notifier);
  String get _me => ref.read(myCourierIdProvider);

  GeoPoint? get _position => _s.couriers.byId(_me)?.position;

  /// Alvo atual da navegação (coleta ou cliente).
  GeoPoint? targetOf(Delivery d) => switch (d.status) {
    DeliveryStatus.accepted || DeliveryStatus.atMerchant || DeliveryStatus.returning => d.pickup.point,
    DeliveryStatus.pickedUp ||
    DeliveryStatus.toCustomer ||
    DeliveryStatus.atCustomer ||
    DeliveryStatus.customerAbsent => d.dropoff.point,
    _ => null,
  };

  double remainingKm(Delivery d) {
    final t = targetOf(d), p = _position;
    return t == null || p == null ? 0 : Geo.roadKm(p, t);
  }

  Future<void> perform(Delivery d, RunAction a) async {
    switch (a) {
      case RunAction.arriveMerchant:
        await _queue.run(
          'Cheguei no comércio',
          () => _s.advance(d.id, DeliveryStatus.atMerchant, at: _position).then((_) {}),
        );
      case RunAction.pickUp:
        await _queue.run('Pedido coletado', () async {
          await _s.advance(d.id, DeliveryStatus.pickedUp, at: _position);
          await _s.advance(d.id, DeliveryStatus.toCustomer, at: _position);
          _sim.followRoute(_me, d.id);
        });
      case RunAction.arriveCustomer:
        await _queue.run(
          'Cheguei no cliente',
          () => _s.advance(d.id, DeliveryStatus.atCustomer, at: _position).then((_) {}),
        );
      case RunAction.returnToMerchant:
        await _queue.run('Retorno ao comércio', () async {
          await _s.advance(d.id, DeliveryStatus.returning, at: _position);
          _sim.followRoute(_me, d.id);
        });
      case RunAction.finishReturn:
        await _queue.run('Pedido devolvido', () async {
          await _s.advance(d.id, DeliveryStatus.returned, at: _position);
          _sim.stopRoute(_me);
        });
      case RunAction.confirmCode || RunAction.none:
        break;
    }
  }

  Future<void> customerAbsent(Delivery d) =>
      _queue.run('Cliente ausente', () => _s.advance(d.id, DeliveryStatus.customerAbsent, at: _position).then((_) {}));

  /// Cliente apareceu durante a espera: volta para a confirmação por código.
  Future<bool> confirm(Delivery d, String code, {bool viaMerchant = false}) async {
    final ok = await _s.confirmCode(d.id, code, viaMerchantCall: viaMerchant);
    if (ok) _sim.stopRoute(_me);
    return ok;
  }

  Future<void> report(Delivery d, IncidentKind kind, String description) =>
      _s.openIncident(d.id, kind, openedBy: _me, description: description).then((_) {});

  Future<void> giveBack(Delivery d, String reason) async {
    _sim.stopRoute(_me);
    await _s.courierGiveBack(d.id, reason: reason);
  }

  /// Modo demonstração: leva a moto direto ao destino.
  Future<void> skipTravel(Delivery d) async {
    final t = targetOf(d);
    final c = _s.couriers.byId(_me);
    if (t == null || c == null) return;
    final traveled = Geo.roadKm(c.position, t);
    await _s.couriers.save(c.copyWith(position: t));
    await _s.deliveries.save(_s.deliveries.byId(d.id)!.copyWith(courierTraveledKm: d.courierTraveledKm + traveled));
  }
}

final runControllerProvider = Provider<RunController>(RunController.new);
