import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/corre_theme.dart';
import '../tokens/corre_tokens.dart';
import 'corre_domain.dart';

/// Ponto marcado no mapa.
class CorreMapPin {
  const CorreMapPin({required this.point, required this.kind, this.label, this.onTap});
  final LatLng point;
  final CorreMarkerKind kind;
  final String? label;
  final VoidCallback? onTap;
}

/// Mapa com tiles do OpenStreetMap (grátis, sem chave), marcadores e rota.
class CorreMapView extends StatefulWidget {
  const CorreMapView({
    super.key,
    required this.pins,
    this.route = const [],
    this.center,
    this.zoom = 14,
    this.followPoint,
    this.onTap,
    this.interactive = true,
    this.borderRadius,
  });

  final List<CorreMapPin> pins;
  final List<LatLng> route;
  final LatLng? center;
  final double zoom;

  /// Quando definido, o mapa acompanha este ponto (ex.: a moto).
  final LatLng? followPoint;
  final void Function(LatLng point)? onTap;
  final bool interactive;
  final BorderRadius? borderRadius;

  /// Centro de Palmas-TO.
  static const palmas = LatLng(-10.1844, -48.3336);

  /// Desligue em testes de widget (sem rede).
  static bool showTiles = true;

  @override
  State<CorreMapView> createState() => _CorreMapViewState();
}

class _CorreMapViewState extends State<CorreMapView> {
  final _controller = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(covariant CorreMapView old) {
    super.didUpdateWidget(old);
    final f = widget.followPoint;
    if (_ready && f != null && f != old.followPoint) {
      _controller.move(f, _controller.camera.zoom);
    }
  }

  LatLng get _initial {
    if (widget.center != null) return widget.center!;
    if (widget.followPoint != null) return widget.followPoint!;
    if (widget.pins.isEmpty) return CorreMapView.palmas;
    final lat = widget.pins.fold<double>(0, (s, p) => s + p.point.latitude) / widget.pins.length;
    final lng = widget.pins.fold<double>(0, (s, p) => s + p.point.longitude) / widget.pins.length;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final map = FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _initial,
        initialZoom: widget.zoom,
        onMapReady: () => _ready = true,
        onTap: widget.onTap == null ? null : (_, point) => widget.onTap!(point),
        interactionOptions: InteractionOptions(
          flags: widget.interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        if (CorreMapView.showTiles)
          ColorFiltered(
            colorFilter: dark
                ? const ColorFilter.matrix([-.8, 0, 0, 0, 220, 0, -.8, 0, 0, 220, 0, 0, -.8, 0, 220, 0, 0, 0, 1, 0])
                : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
            child: TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.com.corre',
              maxZoom: 19,
            ),
          ),
        if (widget.route.length >= 2)
          PolylineLayer(
            polylines: [Polyline(points: widget.route, strokeWidth: 5, color: p.brand.withValues(alpha: .85))],
          ),
        MarkerLayer(
          markers: [
            for (final pin in widget.pins)
              Marker(
                point: pin.point,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: pin.onTap,
                  child: CorreMapMarker(kind: pin.kind, label: pin.label),
                ),
              ),
          ],
        ),
        const SimpleAttributionWidget(source: Text('OpenStreetMap')),
      ],
    );
    return ClipRRect(borderRadius: widget.borderRadius ?? CorreRadius.mdAll, child: map);
  }
}

/// Caminho em "L" entre dois pontos, imitando as avenidas de Palmas.
List<LatLng> correLRoute(LatLng a, LatLng b) => [a, LatLng(b.latitude, a.longitude), b];

/// Espaço reservado com cara de mapa (testes e carregamento).
class CorreMapPlaceholder extends StatelessWidget {
  const CorreMapPlaceholder({super.key, this.height = 200});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(color: context.palette.brandLight, borderRadius: CorreRadius.mdAll),
    alignment: Alignment.center,
    child: Icon(Icons.map_outlined, size: 40, color: context.palette.brand),
  );
}
