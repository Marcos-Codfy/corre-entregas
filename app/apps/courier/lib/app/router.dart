import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/approval_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/history/history_page.dart';
import '../features/home/home_page.dart';
import '../features/profile/help_page.dart';
import '../features/profile/profile_page.dart';
import '../features/profile/rules_page.dart';
import '../features/run/proof_page.dart';
import '../features/run/run_page.dart';
import '../features/wallet/wallet_page.dart';
import 'shell.dart';

abstract final class Routes {
  static const login = '/entrar';
  static const signup = '/cadastro';
  static const approval = '/cadastro/status';
  static const home = '/';
  static const history = '/corridas';
  static const wallet = '/carteira';
  static const profile = '/perfil';
  static const rules = '/perfil/regras';
  static const help = '/perfil/ajuda';
  static String run(String id) => '/corrida/$id';
  static String proof(String id) => '/corrida/$id/codigo';
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<bool>(ref.read(sessionProvider) != null);
  ref.listen(sessionProvider, (_, next) => session.value = next != null);
  ref.onDispose(session.dispose);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: session,
    redirect: (context, state) {
      final open = state.matchedLocation == Routes.login || state.matchedLocation.startsWith(Routes.signup);
      if (!session.value && !open) return Routes.login;
      if (session.value && state.matchedLocation == Routes.login) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.signup, builder: (_, _) => const SignupPage()),
      GoRoute(path: Routes.approval, builder: (_, _) => const ApprovalPage()),
      GoRoute(
        path: '/corrida/:id',
        builder: (_, s) => RunPage(deliveryId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'codigo',
            builder: (_, s) => ProofPage(deliveryId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: Routes.rules, builder: (_, _) => const RulesPage()),
      GoRoute(path: Routes.help, builder: (_, _) => const HelpPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => CourierShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.history, builder: (_, _) => const HistoryPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.wallet, builder: (_, _) => const WalletPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfilePage())],
          ),
        ],
      ),
    ],
  );
});
