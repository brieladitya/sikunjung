import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../widgets/app_navbar.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  List<ConnectivityResult> _status = [];
  bool _internetTerverifikasi = false;
  bool _sedangMemeriksa = false;
  DateTime? _terakhirDiperiksa;

  @override
  void initState() {
    super.initState();
    _read();
    _sub = _connectivity.onConnectivityChanged.listen((event) {
      if (!mounted) return;
      setState(() => _status = event);
      _cekInternet();
    });
  }

  Future<void> _read() async {
    final result = await _connectivity.checkConnectivity();
    if (!mounted) return;
    setState(() => _status = result);
    await _cekInternet();
  }

  Future<void> _cekInternet() async {
    if (_sedangMemeriksa) return;
    setState(() => _sedangMemeriksa = true);

    bool ok = false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client
          .getUrl(Uri.parse('https://www.gstatic.com/generate_204'))
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      ok = response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      ok = false;
    } finally {
      client.close(force: true);
    }

    if (!mounted) return;
    setState(() {
      _internetTerverifikasi = ok;
      _terakhirDiperiksa = DateTime.now();
      _sedangMemeriksa = false;
    });
  }

  String _labelKoneksi() {
    if (_status.isEmpty || _status.contains(ConnectivityResult.none)) {
      return 'Tidak ada koneksi (Offline)';
    }
    final daftar = _status.map((e) {
      switch (e) {
        case ConnectivityResult.wifi:
          return 'Wi-Fi';
        case ConnectivityResult.mobile:
          return 'Data Seluler';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.vpn:
          return 'VPN';
        default:
          return e.name;
      }
    }).toList();
    return daftar.join(', ');
  }

  IconData _ikonKoneksi() {
    if (_status.contains(ConnectivityResult.wifi)) return Icons.wifi;
    if (_status.contains(ConnectivityResult.mobile)) {
      return Icons.signal_cellular_alt;
    }
    return Icons.wifi_off;
  }

  String _formatWaktu(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min:$s';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool terhubungJaringan =
        _status.isNotEmpty && !_status.contains(ConnectivityResult.none);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Jaringan'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Perbarui status',
            icon: const Icon(Icons.refresh),
            onPressed: _sedangMemeriksa ? null : _read,
          ),
        ],
      ),
      bottomNavigationBar: const AppNavbar(currentIndex: -1),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _internetTerverifikasi
                  ? const Color(0xFFECF8F0)
                  : const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _internetTerverifikasi
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _sedangMemeriksa
                      ? Icons.sync
                      : (_internetTerverifikasi
                      ? Icons.cloud_done
                      : Icons.cloud_off),
                  size: 48,
                  color: _internetTerverifikasi ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 10),
                Text(
                  _sedangMemeriksa
                      ? 'Memeriksa koneksi...'
                      : (_internetTerverifikasi
                      ? 'Internet terverifikasi'
                      : 'Internet belum terverifikasi'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _internetTerverifikasi
                        ? Colors.green.shade800
                        : Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Monitoring Konektivitas SiKunjung',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.router_outlined, color: Color(0xFF1765D1)),
                      SizedBox(width: 8),
                      Text(
                        'Jenis Koneksi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(
                        _ikonKoneksi(),
                        color: terhubungJaringan
                            ? const Color(0xFF1765D1)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _labelKoneksi(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        terhubungJaringan ? Icons.check_circle : Icons.cancel,
                        color: terhubungJaringan ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.public, color: Color(0xFF1765D1)),
                      SizedBox(width: 8),
                      Text(
                        'Akses Internet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    _internetTerverifikasi
                        ? 'Server verifikasi dapat diakses.'
                        : 'Server verifikasi belum merespons.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pemeriksaan menggunakan HTTPS ke www.gstatic.com/generate_204. '
                        'Hasil gagal tidak selalu berarti semua layanan internet terputus.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_time, color: Color(0xFF1765D1)),
                      SizedBox(width: 8),
                      Text(
                        'Informasi Pemeriksaan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    'Terakhir diperiksa: ${_formatWaktu(_terakhirDiperiksa)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Status diperbarui saat jenis jaringan berubah, saat halaman dibuka, '
                        'atau saat tombol refresh ditekan.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _sedangMemeriksa ? null : _read,
            icon: const Icon(Icons.refresh),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _sedangMemeriksa ? 'MEMERIKSA...' : 'PERBARUI STATUS',
              ),
            ),
          ),
        ],
      ),
    );
  }
}