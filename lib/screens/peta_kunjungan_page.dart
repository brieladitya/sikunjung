import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gps_service.dart';
import '../services/kunjungan_service.dart';
import '../widgets/app_navbar.dart';

class PetaKunjunganPage extends StatefulWidget {
  const PetaKunjunganPage({super.key});

  @override
  State<PetaKunjunganPage> createState() => _PetaKunjunganPageState();
}

class _PetaKunjunganPageState extends State<PetaKunjunganPage> {
  List _lokasiTersimpan = [];
  Map<String, Object?>? _terpilih;
  Position? _posisiPetugas;
  bool _isOffline = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muatLokasi();
  }

  Future<void> _muatLokasi() async {
    setState(() {
      _loading = true;
      _terpilih = null;
    });

    final conn = await Connectivity().checkConnectivity();
    final offline = conn.isEmpty || conn.contains(ConnectivityResult.none);

    final semua = await KunjunganService.instance.getAll();
    final valid = semua.where((row) {
      return row['latitude'] != null && row['longitude'] != null;
    }).toList();

    Position? pos;
    try {
      pos = await GpsService.instance.ambilLokasi();
    } catch (_) {
      pos = null;
    }

    if (!mounted) return;
    setState(() {
      _isOffline = offline;
      _lokasiTersimpan = valid;
      _posisiPetugas = pos;
      _loading = false;
    });
  }

  String _hitungJarak(double latPelanggan, double lngPelanggan) {
    if (_posisiPetugas == null) return 'Posisi petugas belum aktif';
    final meter = Geolocator.distanceBetween(
      _posisiPetugas!.latitude,
      _posisiPetugas!.longitude,
      latPelanggan,
      lngPelanggan,
    );
    if (meter >= 1000) {
      return '${(meter / 1000).toStringAsFixed(2)} km dari posisi Anda';
    }
    return '${meter.toStringAsFixed(0)} meter dari posisi Anda';
  }

  Future<void> _bukaNavigasi(double lat, double lng) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
      'travelmode': 'driving',
    });

    final berhasil = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!berhasil && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aplikasi navigasi tidak dapat dibuka'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng pusatPeta = _posisiPetugas != null
        ? LatLng(_posisiPetugas!.latitude, _posisiPetugas!.longitude)
        : (_lokasiTersimpan.isNotEmpty
        ? LatLng(
      (_lokasiTersimpan.first['latitude'] as num).toDouble(),
      (_lokasiTersimpan.first['longitude'] as num).toDouble(),
    )
        : const LatLng(-6.175392, 106.827153));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Kunjungan'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _muatLokasi,
          ),
        ],
      ),
      bottomNavigationBar: const AppNavbar(currentIndex: 2),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: pusatPeta,
              initialZoom: 13,
              onTap: (_, __) => setState(() => _terpilih = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sikunjung.sikunjung',
              ),
              MarkerLayer(
                markers: [
                  if (_posisiPetugas != null)
                    Marker(
                      point: LatLng(
                        _posisiPetugas!.latitude,
                        _posisiPetugas!.longitude,
                      ),
                      width: 48,
                      height: 48,
                      rotate: true,
                      child: const Icon(
                        Icons.person_pin_circle,
                        size: 44,
                        color: Colors.green,
                      ),
                    ),
                  ..._lokasiTersimpan.map((row) {
                    final lat = (row['latitude'] as num).toDouble();
                    final lng = (row['longitude'] as num).toDouble();
                    final isSelected = _terpilih?['id'] == row['id'];

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 48,
                      height: 48,
                      rotate: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _terpilih = row),
                        child: Icon(
                          Icons.location_on,
                          size: 42,
                          color: isSelected
                              ? Colors.orange
                              : const Color(0xFF1765D1),
                        ),
                      ),
                    );
                  }),
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
            child: Column(
              children: [
                if (_isOffline)
                  Card(
                    color: Colors.red.shade700,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mode Offline: Peta online memerlukan koneksi internet untuk memuat gambar peta.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      _lokasiTersimpan.isEmpty
                          ? 'Belum ada lokasi kunjungan tersimpan.'
                          : '${_lokasiTersimpan.length} lokasi pelanggan tersimpan. '
                          '${_posisiPetugas != null ? 'Pin hijau: posisi petugas.' : ''} Ketuk marker biru untuk detail & jarak.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_terpilih != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF1765D1),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _terpilih!['nama_pelanggan'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _terpilih = null),
                          ),
                        ],
                      ),
                      Text(_terpilih!['alamat'] as String),
                      const SizedBox(height: 6),
                      Text(
                        'Jarak: ${_hitungJarak((_terpilih!['latitude'] as num).toDouble(), (_terpilih!['longitude'] as num).toDouble())}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1765D1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _bukaNavigasi(
                          (_terpilih!['latitude'] as num).toDouble(),
                          (_terpilih!['longitude'] as num).toDouble(),
                        ),
                        icon: const Icon(Icons.navigation_outlined),
                        label: const Text('NAVIGASI KE PELANGGAN'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}