import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/kunjungan_service.dart';
import '../services/prefs_service.dart';
import '../widgets/menu_card.dart';
import 'device_info_page.dart';
import 'kunjungan_form_page.dart';
import 'kunjungan_list_page.dart';
import 'network_page.dart';
import 'peta_kunjungan_page.dart';
import 'sensor_page.dart';
import '../widgets/app_navbar.dart';


class DashboardPage extends StatefulWidget {
  final String namaPetugas;

  const DashboardPage({super.key, required this.namaPetugas});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _isOffline = false;
  int _total = 0;
  int _pending = 0;
  int _selesai = 0;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _cekKoneksiAwal();
    _muatRingkasan();
    _connSub = Connectivity().onConnectivityChanged.listen((res) {
      if (!mounted) return;
      setState(() {
        _isOffline = res.isEmpty || res.contains(ConnectivityResult.none);
      });
    });
  }

  Future<void> _cekKoneksiAwal() async {
    final res = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      _isOffline = res.isEmpty || res.contains(ConnectivityResult.none);
    });
  }

  Future<void> _muatRingkasan() async {
    final semua = await KunjunganService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _total = semua.length;
      _pending = semua.where((e) => e['status'] == 'Pending').length;
      _selesai = semua.where((e) => e['status'] == 'Selesai').length;
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _onNavSelect(int index) async {
    setState(() => _navIndex = index);
    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KunjunganListPage()),
      );
      _muatRingkasan();
    } else if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PetaKunjunganPage()),
      );
    } else if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeviceInfoPage()),
      );
    }
    if (mounted) setState(() => _navIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PrefsService.instance.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SiKunjung'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () async {
              await PrefsService.instance.ubahTema(!isDark);
              setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const AppNavbar(currentIndex: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Offline: Tidak ada koneksi internet. Pencatatan kunjungan tetap dapat dilakukan secara lokal.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1765D1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF1765D1)),
                    ),

                    const SizedBox(width: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat datang,',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          widget.namaPetugas,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kunjungan Terakhir',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ChipRingkasan(label: 'Total', angka: _total),
                    const SizedBox(width: 8),
                    _ChipRingkasan(label: 'Pending', angka: _pending),
                    const SizedBox(width: 8),
                    _ChipRingkasan(label: 'Selesai', angka: _selesai),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Menu Utama',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          MenuCard(
            icon: Icons.add_location_alt_outlined,
            title: 'Tambah Kunjungan',
            subtitle: 'Catat kunjungan pelanggan baru',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KunjunganFormPage()),
              );
              _muatRingkasan();
            },
          ),
          MenuCard(
            icon: Icons.list_alt,
            title: 'Data Kunjungan',
            subtitle: 'Lihat, cari, dan kelola data kunjungan',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KunjunganListPage()),
              );
              _muatRingkasan();
            },
          ),
          MenuCard(
            icon: Icons.map_outlined,
            title: 'Peta Kunjungan',
            subtitle: 'Lihat lokasi pelanggan & jarak rute',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PetaKunjunganPage()),
            ),
          ),
          MenuCard(
            icon: Icons.sensors,
            title: 'Sensor Perangkat',
            subtitle: 'Accelerometer, Gyroscope, dan Kompas',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SensorPage()),
            ),
          ),
          MenuCard(
            icon: Icons.wifi,
            title: 'Status Jaringan',
            subtitle: 'Informasi konektivitas perangkat',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NetworkPage()),
            ),
          ),
          MenuCard(
            icon: Icons.phone_android,
            title: 'Info Perangkat',
            subtitle: 'Sistem operasi, spesifikasi HP, dan versi aplikasi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeviceInfoPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipRingkasan extends StatelessWidget {
  final String label;
  final int angka;

  const _ChipRingkasan({required this.label, required this.angka});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$angka',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}