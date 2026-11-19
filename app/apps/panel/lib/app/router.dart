import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/backoffice/approvals_page.dart';
import '../features/backoffice/dashboard_page.dart';
import '../features/backoffice/directory_pages.dart';
import '../features/backoffice/incidents_page.dart';
import '../features/backoffice/live_page.dart';
import '../features/backoffice/pricing_coupons_pages.dart';
import '../features/merchant/deliveries_page.dart';
import '../features/merchant/delivery_detail_page.dart';
import '../features/merchant/merchant_home_page.dart';
import '../features/merchant/new_delivery_page.dart';
import '../features/merchant/settings_pages.dart';
import '../features/merchant/wallet_page.dart';
import '../features/tracking/tracking_page.dart';
import 'session.dart';
import 'shell.dart';

/// Item do menu lateral.
class PanelNav {
  const PanelNav(this.path, this.label, this.icon, this.builder);
  final String path, label;
  final IconData icon;
  final WidgetBuilder builder;
}

List<PanelNav> navFor(DemoRole role) => switch (role) {
      DemoRole.merchantOwner || DemoRole.merchantStaff => [
          PanelNav('/', 'Início', Icons.home_outlined, (_) => const MerchantHomePage()),
          PanelNav('/nova', 'Nova entrega', Icons.add_location_alt_outlined, (_) => const NewDeliveryPage()),
          PanelNav('/entregas', 'Entregas', Icons.receipt_long_outlined, (_) => const DeliveriesPage()),
          if (role.canSeeFinance) PanelNav('/carteira', 'Carteira e plano', Icons.account_balance_wallet_outlined, (_) => const MerchantWalletPage()),
          PanelNav('/preferidos', 'Motoboys preferidos', Icons.favorite_outline, (_) => const PreferredCouriersPage()),
          if (role.canManageTeam) PanelNav('/equipe', 'Equipe', Icons.group_outlined, (_) => const TeamPage()),
          PanelNav('/config', 'Configurações', Icons.settings_outlined, (_) => const MerchantSettingsPage()),
        ],
      DemoRole.support || DemoRole.admin => [
          if (role == DemoRole.admin) PanelNav('/', 'Indicadores', Icons.insights_outlined, (_) => const DashboardPage()),
          PanelNav(role == DemoRole.admin ? '/ao-vivo' : '/', 'Ao vivo', Icons.sensors, (_) => const LivePage()),
          PanelNav('/ocorrencias', 'Ocorrências', Icons.report_outlined, (_) => const IncidentsPage()),
          PanelNav('/cadastros', 'Cadastros', Icons.how_to_reg_outlined, (_) => const ApprovalsPage()),
          PanelNav('/comercios', 'Comércios', Icons.storefront_outlined, (_) => const MerchantsDirectoryPage()),
          PanelNav('/motoboys', 'Motoboys', Icons.two_wheeler, (_) => const CouriersDirectoryPage()),
          if (role == DemoRole.admin) ...[
            PanelNav('/precos', 'Preços', Icons.price_change_outlined, (_) => const PricingPage()),
            PanelNav('/cupons', 'Cupons', Icons.local_offer_outlined, (_) => const CouponsAdminPage()),
            PanelNav('/repasses', 'Repasses', Icons.payments_outlined, (_) => const PayoutsPage()),
            PanelNav('/eventos', 'Eventos', Icons.list_alt_outlined, (_) => const EventsPage()),
          ],
        ],
      DemoRole.courier => const [],
    };

final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<DemoRole?>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => session.value = next);
  ref.onDispose(session.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc.startsWith('/r/')) return null; // rastreio público
      final role = session.value;
      if (role == null || role == DemoRole.courier) return loc == '/entrar' ? null : '/entrar';
      if (loc == '/entrar') return '/';
      final allowed = navFor(role).map((n) => n.path).toSet();
      if (!allowed.contains(loc) && !loc.startsWith('/entrega/')) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/entrar', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/r/:token', builder: (_, s) => TrackingPage(token: s.pathParameters['token']!)),
      ShellRoute(
        builder: (context, state, child) => PanelShell(location: state.matchedLocation, child: child),
        routes: [
          for (final path in {
            for (final r in DemoRole.values) ...navFor(r).map((n) => n.path),
          })
            GoRoute(
              path: path,
              pageBuilder: (context, state) {
                final role = ProviderScope.containerOf(context).read(sessionProvider) ?? DemoRole.merchantOwner;
                final nav = navFor(role).where((n) => n.path == path).firstOrNull;
                return NoTransitionPage(child: Builder(builder: nav?.builder ?? (_) => const SizedBox.shrink()));
              },
            ),
          GoRoute(
            path: '/entrega/:id',
            pageBuilder: (_, s) => NoTransitionPage(child: DeliveryDetailPage(deliveryId: s.pathParameters['id']!)),
          ),
        ],
      ),
    ],
    errorBuilder: (_, _) => const Scaffold(
      body: CorreEmptyState(icon: Icons.link_off, title: 'Página não encontrada'),
    ),
  );
});
