import 'dart:async';

import '../domain/entities.dart';
import '../domain/repositories.dart';

/// Tabela em memória que emite a lista atual a cada mudança.
class _Table<T> {
  _Table(this._idOf);
  final String Function(T) _idOf;
  final _rows = <String, T>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  /// Cópia: quem chama pode ordenar sem afetar a tabela.
  List<T> all() => List.of(_rows.values);
  T? byId(String id) => _rows[id];

  void remove(String id) {
    _rows.remove(id);
    _changes.add(null);
  }

  void put(T row) {
    _rows[_idOf(row)] = row;
    _changes.add(null);
  }

  /// Emite o valor atual na inscrição e depois a cada mudança.
  Stream<R> watch<R>(R Function() read) => Stream<R>.multi((c) {
        c.add(read());
        final sub = _changes.stream.listen((_) => c.add(read()));
        c.onCancel = sub.cancel;
      });
}

class InMemoryDeliveryRepository implements DeliveryRepository {
  final _t = _Table<Delivery>((d) => d.id);

  @override
  List<Delivery> all() => _t.all()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  @override
  Delivery? byId(String id) => _t.byId(id);
  @override
  Delivery? byTrackingToken(String token) => _t.all().where((d) => d.trackingToken == token).firstOrNull;
  @override
  Future<void> save(Delivery delivery) async => _t.put(delivery);
  @override
  Stream<List<Delivery>> watchAll() => _t.watch(all);
  @override
  Stream<Delivery?> watch(String id) => _t.watch(() => _t.byId(id));
}

class InMemoryCourierRepository implements CourierRepository {
  final _t = _Table<Courier>((c) => c.id);
  @override
  List<Courier> all() => _t.all();
  @override
  Courier? byId(String id) => _t.byId(id);
  @override
  Future<void> save(Courier courier) async => _t.put(courier);
  @override
  Stream<List<Courier>> watchAll() => _t.watch(all);
  @override
  Stream<Courier?> watch(String id) => _t.watch(() => _t.byId(id));
}

class InMemoryMerchantRepository implements MerchantRepository {
  final _t = _Table<Merchant>((m) => m.id);
  @override
  List<Merchant> all() => _t.all();
  @override
  Merchant? byId(String id) => _t.byId(id);
  @override
  Future<void> save(Merchant merchant) async => _t.put(merchant);
  @override
  Stream<List<Merchant>> watchAll() => _t.watch(all);
  @override
  Stream<Merchant?> watch(String id) => _t.watch(() => _t.byId(id));
}

class InMemoryWalletRepository implements WalletRepository {
  final _t = _Table<WalletEntry>((e) => e.id);

  @override
  List<WalletEntry> entries(String ownerId) =>
      _t.all().where((e) => e.ownerId == ownerId).toList()..sort((a, b) => b.at.compareTo(a.at));
  @override
  int balanceOf(String ownerId) => entries(ownerId).fold(0, (s, e) => s + e.amount);
  @override
  Future<void> add(WalletEntry entry) async => _t.put(entry);
  @override
  Stream<List<WalletEntry>> watch(String ownerId) => _t.watch(() => entries(ownerId));
}

class InMemoryCouponRepository implements CouponRepository {
  final _t = _Table<Coupon>((c) => c.code);
  @override
  List<Coupon> all() => _t.all();
  @override
  Coupon? byCode(String code) => _t.byId(code.toUpperCase());
  @override
  Future<void> save(Coupon coupon) async => _t.put(coupon);
  @override
  Stream<List<Coupon>> watchAll() => _t.watch(all);
}

class InMemoryIncidentRepository implements IncidentRepository {
  final _t = _Table<Incident>((i) => i.id);
  @override
  List<Incident> all() => _t.all()..sort((a, b) => b.openedAt.compareTo(a.openedAt));
  @override
  Future<void> save(Incident incident) async => _t.put(incident);
  @override
  Stream<List<Incident>> watchAll() => _t.watch(all);
}

class InMemoryEventLog implements EventLog {
  final _events = <DomainEvent>[];
  final _changes = StreamController<void>.broadcast(sync: true);

  @override
  List<DomainEvent> all() => List.unmodifiable(_events.reversed);
  @override
  void append(DomainEvent event) {
    _events.add(event);
    _changes.add(null);
  }

  @override
  Stream<List<DomainEvent>> watchAll() => Stream.multi((c) {
        c.add(all());
        final sub = _changes.stream.listen((_) => c.add(all()));
        c.onCancel = sub.cancel;
      });
}

class InMemorySavedCustomerRepository implements SavedCustomerRepository {
  final _t = _Table<SavedCustomer>((c) => c.id);

  /// Mais usados primeiro; empate pelo uso mais recente.
  @override
  List<SavedCustomer> list(String merchantId) => _t.all().where((c) => c.merchantId == merchantId).toList()
    ..sort((a, b) {
      final t = b.timesUsed.compareTo(a.timesUsed);
      return t != 0 ? t : b.lastUsed.compareTo(a.lastUsed);
    });
  @override
  Future<void> save(SavedCustomer customer) async => _t.put(customer);
  @override
  Future<void> delete(String id) async => _t.remove(id);
  @override
  Stream<List<SavedCustomer>> watch(String merchantId) => _t.watch(() => list(merchantId));
}
