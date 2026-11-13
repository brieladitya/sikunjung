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
  final MapController _mapController = MapController();
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<LatLng> _kumpulkanSemuaTitik() {
    final titik = <LatLng>[];
    if (_posisiPetugas != null) {
      titik.add(LatLng(_posisiPetugas!.latitude, _posisiPetugas!.longitude));
    }
    for (final row in _lokasiTersimpan) {
      titik.add(
        LatLng(
          (row['latitude'] as num).toDouble(),
          (row['longitude'] as num).toDouble(),
        ),
      );
    }
    return titik;
  }

  bool _memilikiBanyakTitikTerpisah(List<LatLng> titik) {
    if (titik.length < 2) return false;
    final pertama = titik.first;
    for (int i = 1; i < titik.length; i++) {
      final jarak = Geolocator.distanceBetween(
        pertama.latitude,
        pertama.longitude,
        titik[i].latitude,
        titik[i].longitude,
      );
      if (jarak > 25) return true;
    }
    return false;
  }

  void _sesuaikanKameraSemuaPin() {
    final titik = _kumpulkanSemuaTitik();
    if (titik.isEmpty) return;

    if (_memilikiBanyakTitikTerpisah(titik)) {
      final bounds = LatLngBounds.fromPoints(titik);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(56, 120, 56, 120),
          maxZoom: 16,
        ),
      );
    } else {
      _mapController.move(titik.first, 15);
    }
  }

  void _fokusKePosisiSaya() {
    if (_posisiPetugas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS perangkat belum aktif')),
      );
      return;
    }
    _mapController.move(
      LatLng(_posisiPetugas!.latitude, _posisiPetugas!.longitude),
      16,
    );
  }

  void _fokusKeTarget() {
    if (_lokasiTersimpan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada lokasi target kunjungan')),
      );
      return;
    }
    final target = _terpilih ?? _lokasiTersimpan.first;
    setState(() => _terpilih = target);
    _mapController.move(
      LatLng(
        (target['latitude'] as num).toDouble(),
        (target['longitude'] as num).toDouble(),
      ),
      16,
    );
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sesuaikanKameraSemuaPin();
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
    final titik = _kumpulkanSemuaTitik();
    final bool pakaiBounds = _memilikiBanyakTitikTerpisah(titik);
    final LatLng pusatDefault = titik.isNotEmpty
        ? titik.first
        : const LatLng(-7.966620, 112.632632);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Kunjungan'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Tampilkan semua pin',
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _sesuaikanKameraSemuaPin,
          ),
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
            mapController: _mapController,
            options: MapOptions(
              initialCenter: pusatDefault,
              initialZoom: 14,
              initialCameraFit: pakaiBounds
                  ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(titik),
                padding: const EdgeInsets.fromLTRB(56, 120, 56, 120),
                maxZoom: 16,
              )
                  : null,
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
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      rotate: true,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white,
                        ),
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
                      alignment: Alignment.topCenter,
                      rotate: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _terpilih = row),
                        child: Icon(
                          Icons.location_on,
                          size: 46,
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
                          '${_posisiPetugas != null ? 'Titik hijau: posisi Anda.' : ''} Ketuk pin biru untuk detail & jarak.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_terpilih == null)
            Positioned(
              bottom: 24,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_lokasiTersimpan.isNotEmpty)
                    FloatingActionButton.small(
                      heroTag: 'btn_target',
                      tooltip: 'Fokus ke Target Kunjungan',
                      onPressed: _fokusKeTarget,
                      child: const Icon(Icons.pin_drop),
                    ),
                  if (_posisiPetugas != null) ...[
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'btn_saya',
                      tooltip: 'Fokus ke Posisi Saya',
                      onPressed: _fokusKePosisiSaya,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
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