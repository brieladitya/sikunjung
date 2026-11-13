import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'kunjungan_form_page.dart';
import 'kunjungan_list_page.dart';
import 'peta_kunjungan_page.dart';
import 'sensor_page.dart';
import 'network_page.dart';

class DashboardPage extends StatelessWidget {
  final String namaPetugas;

  const DashboardPage({super.key, required this.namaPetugas});

  void _belumTersedia(BuildContext context, String judulMenu) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menu "$judulMenu" akan diaktifkan pada Bab berikutnya.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SiKunjung'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
        actions: [
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1765D1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF1765D1)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Selamat datang,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  namaPetugas,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sistem Informasi Kunjungan Lapangan',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
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
          _MenuCard(
            icon: Icons.add_location_alt_outlined,
            title: 'Tambah Kunjungan',
            subtitle: 'Catat kunjungan pelanggan baru',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KunjunganFormPage()),
            ),
          ),
          _MenuCard(
            icon: Icons.list_alt,
            title: 'Data Kunjungan',
            subtitle: 'Lihat dan kelola data kunjungan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KunjunganListPage()),
            ),
          ),
          _MenuCard(
            icon: Icons.map_outlined,
            title: 'Peta Kunjungan',
            subtitle: 'Lihat lokasi pelanggan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PetaKunjunganPage()),
            ),
          ),
          _MenuCard(
            icon: Icons.sensors,
            title: 'Sensor Perangkat',
            subtitle: 'Informasi sensor perangkat',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SensorPage()),
            ),
          ),
          _MenuCard(
            icon: Icons.wifi,
            title: 'Status Jaringan',
            subtitle: 'Informasi konektivitas perangkat',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NetworkPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1765D1)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}