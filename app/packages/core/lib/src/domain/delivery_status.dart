/// Estados da entrega (ver docs/03-produto.md).
enum DeliveryStatus {
  searching('Procurando motoboy'),
  accepted('Motoboy a caminho da coleta'),
  atMerchant('Motoboy no comércio'),
  pickedUp('Pedido coletado'),
  toCustomer('A caminho do cliente'),
  atCustomer('Motoboy no cliente'),
  delivered('Entregue'),
  customerAbsent('Cliente ausente'),
  returning('Voltando ao comércio'),
  returned('Devolvido ao comércio'),
  noCourier('Sem motoboy disponível'),
  cancelledByMerchant('Cancelada pelo comércio'),
  incident('Ocorrência em análise');

  const DeliveryStatus(this.label);
  final String label;

  bool get isFinal => const {delivered, returned, noCourier, cancelledByMerchant}.contains(this);

  /// Entrega com motoboy designado e ainda em curso.
  bool get isActive => !isFinal && this != searching;

  /// Antes da coleta o comércio ainda pode cancelar.
  bool get merchantCanCancel => const {searching, accepted, atMerchant}.contains(this);
}

/// Máquina de estados: quais transições são permitidas.
abstract final class DeliveryFlow {
  static const Map<DeliveryStatus, Set<DeliveryStatus>> _next = {
    DeliveryStatus.searching: {DeliveryStatus.accepted, DeliveryStatus.noCourier, DeliveryStatus.cancelledByMerchant},
    DeliveryStatus.accepted: {
      DeliveryStatus.atMerchant,
      DeliveryStatus.searching, // motoboy desistiu: volta a procurar
      DeliveryStatus.cancelledByMerchant,
      DeliveryStatus.incident,
    },
    DeliveryStatus.atMerchant: {DeliveryStatus.pickedUp, DeliveryStatus.cancelledByMerchant, DeliveryStatus.incident},
    DeliveryStatus.pickedUp: {DeliveryStatus.toCustomer, DeliveryStatus.incident},
    DeliveryStatus.toCustomer: {DeliveryStatus.atCustomer, DeliveryStatus.incident},
    DeliveryStatus.atCustomer: {DeliveryStatus.delivered, DeliveryStatus.customerAbsent, DeliveryStatus.incident},
    DeliveryStatus.customerAbsent: {DeliveryStatus.delivered, DeliveryStatus.returning},
    DeliveryStatus.returning: {DeliveryStatus.returned, DeliveryStatus.incident},
    DeliveryStatus.incident: {
      DeliveryStatus.toCustomer,
      DeliveryStatus.delivered,
      DeliveryStatus.returned,
      DeliveryStatus.cancelledByMerchant,
    },
    DeliveryStatus.delivered: {},
    DeliveryStatus.returned: {},
    DeliveryStatus.noCourier: {},
    DeliveryStatus.cancelledByMerchant: {},
  };

  static bool canTransition(DeliveryStatus from, DeliveryStatus to) => _next[from]!.contains(to);

  static Set<DeliveryStatus> nextOf(DeliveryStatus from) => _next[from]!;

  /// Caminho feliz que o motoboy percorre na tela de corrida.
  static const happyPath = [
    DeliveryStatus.accepted,
    DeliveryStatus.atMerchant,
    DeliveryStatus.pickedUp,
    DeliveryStatus.toCustomer,
    DeliveryStatus.atCustomer,
    DeliveryStatus.delivered,
  ];
}

/// Erro ao tentar uma transição que a regra não permite.
class InvalidTransition implements Exception {
  InvalidTransition(this.from, this.to);
  final DeliveryStatus from, to;
  @override
  String toString() => 'Transição inválida: ${from.name} → ${to.name}';
}
