import 'package:corre_core/corre_core.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Comércio do perfil de demonstração.
final myMerchantIdProvider = Provider<String>((ref) => Seed.demoMerchantId);

final myMerchantProvider = Provider<Merchant?>((ref) => ref.watch(merchantProvider(ref.watch(myMerchantIdProvider))).value);

/// Entregas do comércio logado, mais recentes primeiro.
final myDeliveriesProvider = Provider<List<Delivery>>((ref) {
  final id = ref.watch(myMerchantIdProvider);
  return (ref.watch(allDeliveriesProvider).value ?? const []).where((d) => d.merchantId == id).toList();
});

/// O que cada papel pode ver (RBAC do painel).
extension DemoRolePermissions on DemoRole {
  bool get canSeeFinance => this == DemoRole.merchantOwner || this == DemoRole.admin;
  bool get canManageTeam => this == DemoRole.merchantOwner;
  bool get canEditPrices => this == DemoRole.admin;
  bool get canManageCoupons => this == DemoRole.admin;
  bool get canApprove => this == DemoRole.support || this == DemoRole.admin;
}
