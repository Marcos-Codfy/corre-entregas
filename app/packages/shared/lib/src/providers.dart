import 'package:corre_core/corre_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ambiente de dados. Sobrescrito no `main` com o [DemoEnvironment] já carregado.
/// Na Onda 2 esta é a única troca para usar o Supabase.
final environmentProvider = Provider<DemoEnvironment>((ref) => throw UnimplementedError('Sobrescreva no main'));

final serviceProvider = Provider<DeliveryService>((ref) => ref.watch(environmentProvider).service);
final simulatorProvider = Provider<Simulator>((ref) => ref.watch(environmentProvider).simulator);

final allDeliveriesProvider = StreamProvider<List<Delivery>>((ref) => ref.watch(environmentProvider).deliveries.watchAll());
final allCouriersProvider = StreamProvider<List<Courier>>((ref) => ref.watch(environmentProvider).couriers.watchAll());
final allMerchantsProvider = StreamProvider<List<Merchant>>((ref) => ref.watch(environmentProvider).merchants.watchAll());
final couponsProvider = StreamProvider<List<Coupon>>((ref) => ref.watch(environmentProvider).coupons.watchAll());
final incidentsProvider = StreamProvider<List<Incident>>((ref) => ref.watch(environmentProvider).incidents.watchAll());
final eventsProvider = StreamProvider<List<DomainEvent>>((ref) => ref.watch(environmentProvider).events.watchAll());

final deliveryProvider = StreamProvider.family<Delivery?, String>((ref, id) => ref.watch(environmentProvider).deliveries.watch(id));
final courierProvider = StreamProvider.family<Courier?, String>((ref, id) => ref.watch(environmentProvider).couriers.watch(id));
final merchantProvider = StreamProvider.family<Merchant?, String>((ref, id) => ref.watch(environmentProvider).merchants.watch(id));
final savedCustomersProvider = StreamProvider.family<List<SavedCustomer>, String>((ref, merchantId) => ref.watch(environmentProvider).savedCustomers.watch(merchantId));
final walletProvider = StreamProvider.family<List<WalletEntry>, String>((ref, ownerId) => ref.watch(environmentProvider).wallet.watch(ownerId));

/// Relógio que atualiza a tela a cada segundo (contagens e "há X min").
final tickerProvider = StreamProvider<DateTime>((ref) => Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()));

/// Preferências locais (tema e perfil de demonstração).
final preferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('Sobrescreva no main'));

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.watch(preferencesProvider).getString(_key);
    return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.light);
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    ref.read(preferencesProvider).setString(_key, state.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Perfis do modo demonstração (sem cadastro real).
enum DemoRole {
  courier('Motoboy'),
  merchantOwner('Dono do comércio'),
  merchantStaff('Atendente do comércio'),
  support('Suporte'),
  admin('Administrador');

  const DemoRole(this.label);
  final String label;

  bool get isMerchant => this == merchantOwner || this == merchantStaff;
  bool get isBackOffice => this == support || this == admin;
}

/// Sessão de demonstração: guarda o perfil escolhido entre aberturas do app.
class DemoSession extends Notifier<DemoRole?> {
  static const _key = 'demo_role';

  @override
  DemoRole? build() {
    final saved = ref.watch(preferencesProvider).getString(_key);
    return DemoRole.values.where((r) => r.name == saved).firstOrNull;
  }

  void signIn(DemoRole role) {
    state = role;
    ref.read(preferencesProvider).setString(_key, role.name);
  }

  void signOut() {
    state = null;
    ref.read(preferencesProvider).remove(_key);
  }
}

final sessionProvider = NotifierProvider<DemoSession, DemoRole?>(DemoSession.new);
