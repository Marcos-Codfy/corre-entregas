import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:latlong2/latlong.dart';

/// Conversões de domínio para componentes de tela.
extension GeoPointToLatLng on GeoPoint {
  LatLng get latLng => LatLng(lat, lng);
}

extension DeliveryStatusUi on DeliveryStatus {
  CorreTone get tone => switch (this) {
        DeliveryStatus.searching => CorreTone.info,
        DeliveryStatus.delivered => CorreTone.success,
        DeliveryStatus.returned => CorreTone.warning,
        DeliveryStatus.noCourier || DeliveryStatus.cancelledByMerchant || DeliveryStatus.incident => CorreTone.error,
        DeliveryStatus.customerAbsent || DeliveryStatus.returning => CorreTone.warning,
        _ => CorreTone.accent,
      };

  /// Rótulo curto para badges.
  String get shortLabel => switch (this) {
        DeliveryStatus.searching => 'Procurando',
        DeliveryStatus.accepted => 'Indo coletar',
        DeliveryStatus.atMerchant => 'No comércio',
        DeliveryStatus.pickedUp => 'Coletado',
        DeliveryStatus.toCustomer => 'A caminho',
        DeliveryStatus.atCustomer => 'No cliente',
        DeliveryStatus.delivered => 'Entregue',
        DeliveryStatus.customerAbsent => 'Cliente ausente',
        DeliveryStatus.returning => 'Retornando',
        DeliveryStatus.returned => 'Devolvido',
        DeliveryStatus.noCourier => 'Sem motoboy',
        DeliveryStatus.cancelledByMerchant => 'Cancelada',
        DeliveryStatus.incident => 'Ocorrência',
      };
}

/// Linha do tempo para o comércio, o cliente e o suporte.
List<CorreStep> deliverySteps(Delivery d) {
  const order = [
    (DeliveryStatus.searching, 'Procurando motoboy'),
    (DeliveryStatus.accepted, 'Motoboy aceitou'),
    (DeliveryStatus.atMerchant, 'Chegou no comércio'),
    (DeliveryStatus.pickedUp, 'Pedido coletado'),
    (DeliveryStatus.toCustomer, 'A caminho do cliente'),
    (DeliveryStatus.delivered, 'Entregue'),
  ];
  final reached = order.lastIndexWhere((o) => d.timeline.containsKey(o.$1));
  return [
    for (var i = 0; i < order.length; i++)
      CorreStep(
        order[i].$2,
        i < reached || (i == reached && d.status.isFinal)
            ? CorreStepState.done
            : i == reached
                ? CorreStepState.current
                : CorreStepState.pending,
        time: d.timeline[order[i].$1] == null ? null : hhmm(d.timeline[order[i].$1]!),
      ),
  ];
}

String hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String ddmm(DateTime t) => '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';

String km(double v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} km';

/// "há 3 min", "há 2 h", "ontem".
String timeAgo(DateTime t, DateTime now) {
  final d = now.difference(t);
  if (d.inMinutes < 1) return 'agora';
  if (d.inMinutes < 60) return 'há ${d.inMinutes} min';
  if (d.inHours < 24) return 'há ${d.inHours} h';
  if (d.inDays == 1) return 'ontem';
  return 'há ${d.inDays} dias';
}
