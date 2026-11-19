import 'entities.dart';

/// Contratos de acesso a dados. Na Onda 1 as implementações são em memória
/// (`InMemory*`); na Onda 2 viram Supabase sem mudar as telas.
abstract interface class DeliveryRepository {
  Stream<List<Delivery>> watchAll();
  Stream<Delivery?> watch(String id);
  Delivery? byId(String id);
  Delivery? byTrackingToken(String token);
  List<Delivery> all();
  Future<void> save(Delivery delivery);
}

abstract interface class CourierRepository {
  Stream<List<Courier>> watchAll();
  Stream<Courier?> watch(String id);
  Courier? byId(String id);
  List<Courier> all();
  Future<void> save(Courier courier);
}

abstract interface class MerchantRepository {
  Stream<List<Merchant>> watchAll();
  Stream<Merchant?> watch(String id);
  Merchant? byId(String id);
  List<Merchant> all();
  Future<void> save(Merchant merchant);
}

abstract interface class WalletRepository {
  Stream<List<WalletEntry>> watch(String ownerId);
  List<WalletEntry> entries(String ownerId);
  int balanceOf(String ownerId);
  Future<void> add(WalletEntry entry);
}

abstract interface class CouponRepository {
  Stream<List<Coupon>> watchAll();
  List<Coupon> all();
  Coupon? byCode(String code);
  Future<void> save(Coupon coupon);
}

abstract interface class IncidentRepository {
  Stream<List<Incident>> watchAll();
  List<Incident> all();
  Future<void> save(Incident incident);
}

abstract interface class SavedCustomerRepository {
  Stream<List<SavedCustomer>> watch(String merchantId);
  List<SavedCustomer> list(String merchantId);
  Future<void> save(SavedCustomer customer);
  Future<void> delete(String id);
}

abstract interface class EventLog {
  Stream<List<DomainEvent>> watchAll();
  List<DomainEvent> all();
  void append(DomainEvent event);
}

/// Fonte de hora trocável (testes usam relógio fixo).
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}
