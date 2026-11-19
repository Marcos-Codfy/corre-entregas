import 'dart:async';

import 'package:corre_core/corre_core.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Id do motoboy logado (no modo demonstração é sempre o mesmo perfil).
final myCourierIdProvider = Provider<String>((ref) => Seed.demoCourierId);

final meProvider = Provider<Courier?>((ref) => ref.watch(courierProvider(ref.watch(myCourierIdProvider))).value);

/// Corrida em andamento do motoboy logado, se houver.
final activeDeliveryProvider = Provider<Delivery?>((ref) {
  final me = ref.watch(myCourierIdProvider);
  final all = ref.watch(allDeliveriesProvider).value ?? const [];
  return all.where((d) => d.courierId == me && d.status.isActive && !d.status.isFinal).firstOrNull;
});

/// Entregas concluídas pelo motoboy logado.
final myHistoryProvider = Provider<List<Delivery>>((ref) {
  final me = ref.watch(myCourierIdProvider);
  final all = ref.watch(allDeliveriesProvider).value ?? const [];
  return all.where((d) => d.courierId == me && d.status.isFinal).toList();
});

class CourierHomeState {
  const CourierHomeState({this.offer, this.busy = false, this.lastError});
  final Offer? offer;
  final bool busy;
  final String? lastError;

  CourierHomeState copyWith({Offer? offer, bool clearOffer = false, bool? busy, String? lastError}) =>
      CourierHomeState(offer: clearOffer ? null : (offer ?? this.offer), busy: busy ?? this.busy, lastError: lastError);
}

/// ViewModel da tela inicial: online/offline, ofertas, aceitar e recusar.
class CourierController extends Notifier<CourierHomeState> {
  StreamSubscription<Offer>? _sub;
  Timer? _firstOffer;

  String get _me => ref.read(myCourierIdProvider);
  DeliveryService get _service => ref.read(serviceProvider);
  Simulator get _sim => ref.read(simulatorProvider);

  @override
  CourierHomeState build() {
    _sub = _sim.offers.where((o) => o.courierId == _me).listen((o) => state = state.copyWith(offer: o));
    ref.onDispose(() {
      _sub?.cancel();
      _firstOffer?.cancel();
    });
    return const CourierHomeState();
  }

  Future<void> setOnline(bool online) async {
    final me = _service.couriers.byId(_me);
    if (me == null) return;
    if (!online && me.availability == CourierAvailability.onDelivery) {
      state = state.copyWith(lastError: 'Termine a corrida antes de ficar offline');
      return;
    }
    await _service.couriers.save(
      me.copyWith(
        availability: online ? CourierAvailability.online : CourierAvailability.offline,
        idleSince: DateTime.now(),
      ),
    );
    if (online) {
      _sim.startCourierFeed(_me);
      _firstOffer = Timer(const Duration(seconds: 4), () => _sim.offerTo(_me));
    } else {
      _sim.stopCourierFeed();
      _firstOffer?.cancel();
      state = state.copyWith(clearOffer: true);
    }
  }

  /// Botão do modo demonstração: chama uma oferta agora.
  Future<void> simulateOffer() async {
    final me = _service.couriers.byId(_me);
    if (me == null) return;
    if (!me.isOnline) await setOnline(true);
    _firstOffer?.cancel();
    await _sim.offerTo(_me);
  }

  Future<String?> accept() async {
    final offer = state.offer;
    if (offer == null) return null;
    state = state.copyWith(busy: true);
    try {
      final d = await _service.accept(offer.delivery.id, _me);
      _sim.followRoute(_me, d.id);
      state = const CourierHomeState();
      return d.id;
    } on BusinessError catch (e) {
      state = CourierHomeState(lastError: e.message);
      return null;
    }
  }

  /// Recusar ou deixar o tempo acabar: sem punição, outro motoboy recebe.
  void decline({bool expired = false}) {
    final offer = state.offer;
    if (offer == null) return;
    _service.decline(offer.delivery.id, _me, reason: expired ? 'tempo esgotado' : 'recusou');
    unawaited(_sim.handOffToOthers(offer.delivery.id, except: _me));
    state = const CourierHomeState();
  }

  void clearError() => state = state.copyWith();
}

final courierControllerProvider = NotifierProvider<CourierController, CourierHomeState>(CourierController.new);
