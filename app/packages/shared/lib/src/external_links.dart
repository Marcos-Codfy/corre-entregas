import 'package:corre_core/corre_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Atalhos para apps externos (todos grátis, sem integração).
abstract final class ExternalLinks {
  /// Link de rastreio público do cliente.
  static String trackingUrl(String token, {String base = 'https://corre-painel.vinicius-codfy.workers.dev'}) => '$base/#/r/$token';

  /// Mensagem pronta para o comércio mandar ao cliente pelo WhatsApp.
  static String whatsappMessage(Delivery d, {required String merchantName}) =>
      'Olá, ${d.customer.firstName}! Seu pedido do $merchantName saiu para entrega.\n'
      'Acompanhe: ${trackingUrl(d.trackingToken)}\n'
      'Código de entrega: *${d.deliveryCode}* (informe ao motoboy).';

  static Uri whatsapp(String phoneDigits, String message) =>
      Uri.parse('https://wa.me/55$phoneDigits?text=${Uri.encodeComponent(message)}');

  static Uri phone(String digits) => Uri(scheme: 'tel', path: digits);

  static Uri googleMapsTo(GeoPoint p) => Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}&travelmode=driving');

  static Uri wazeTo(GeoPoint p) => Uri.parse('https://waze.com/ul?ll=${p.lat},${p.lng}&navigate=yes');

  static Future<bool> open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
}
