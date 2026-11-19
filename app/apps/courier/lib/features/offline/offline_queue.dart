import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ação guardada enquanto o aparelho está sem internet.
class PendingAction {
  PendingAction(this.label, this.run);
  final String label;
  final Future<void> Function() run;
}

class OfflineState {
  const OfflineState({this.online = true, this.pending = const []});
  final bool online;
  final List<PendingAction> pending;
}

/// Simula a fila offline: com a internet desligada, as ações ficam guardadas
/// e são enviadas na ordem quando a conexão volta.
class OfflineQueue extends Notifier<OfflineState> {
  @override
  OfflineState build() => const OfflineState();

  /// Executa já ou guarda para depois.
  Future<void> run(String label, Future<void> Function() action) async {
    if (state.online) return action();
    state = OfflineState(online: false, pending: [...state.pending, PendingAction(label, action)]);
  }

  Future<void> setOnline(bool online) async {
    if (online == state.online) return;
    if (!online) {
      state = OfflineState(online: false, pending: state.pending);
      return;
    }
    final queue = state.pending;
    state = const OfflineState();
    for (final a in queue) {
      await a.run();
    }
  }
}

final offlineQueueProvider = NotifierProvider<OfflineQueue, OfflineState>(OfflineQueue.new);
