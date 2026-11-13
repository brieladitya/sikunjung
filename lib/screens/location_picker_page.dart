import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/gps_service.dart';

class LocationPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  late LatLng _titikDipilih;
  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    _titikDipilih = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : const LatLng(-7.966620, 112.632632);
    if (widget.initialLat == null || widget.initialLng == null) {
      _kePosisiSaya();
    }
  }

  Future<void> _kePosisiSaya() async {
    setState(() => _loadingGps = true);
    try {
      final pos = await GpsService.instance.ambilLokasi();
      if (!mounted) return;
      final baru = LatLng(pos.latitude, pos.longitude);
      setState(() => _titikDipilih = baru);
      _mapController.move(baru, 16);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi di Peta'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Ke Posisi GPS Saya',
            icon: _loadingGps
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.my_location),
            onPressed: _loadingGps ? null : _kePosisiSaya,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _titikDipilih,
              initialZoom: 15,
              onTap: (_, latLng) {
                setState(() => _titikDipilih = latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sikunjung.sikunjung',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _titikDipilih,
                    width: 48,
                    height: 48,
                    rotate: true, // Pin tetap tegak meskipun peta diputar
                    child: const Icon(
                      Icons.location_on,
                      size: 46,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Ketuk titik mana saja pada peta untuk memindahkan pin lokasi.\n'
                      'Koordinat: ${_titikDipilih.latitude.toStringAsFixed(6)}, '
                      '${_titikDipilih.longitude.toStringAsFixed(6)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_titikDipilih),
              icon: const Icon(Icons.check_circle_outline),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('GUNAKAN LOKASI INI'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}