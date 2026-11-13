import 'package:flutter/material.dart';
import '../screens/dashboard_page.dart';
import '../screens/kunjungan_list_page.dart';
import '../screens/peta_kunjungan_page.dart';
import '../services/auth_service.dart';

class AppNavbar extends StatelessWidget {
  final int currentIndex;

  const AppNavbar({super.key, required this.currentIndex});

  Future<void> _pindahTab(BuildContext context, int index) async {
    if (index == currentIndex) return;

    if (index == 0) {
      final user = await AuthService.instance.currentUser();
      final nama = (user?['nama'] as String?) ?? 'Petugas Lapangan';
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => DashboardPage(namaPetugas: nama)),
            (route) => false,
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KunjunganListPage()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PetaKunjunganPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex < 0 ? 0 : currentIndex,
      indicatorColor: currentIndex < 0 ? Colors.transparent : null,
      onDestinationSelected: (index) => _pindahTab(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_outlined),
          selectedIcon: Icon(Icons.list_alt),
          label: 'Kunjungan',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Peta',
        ),
      ],
    );
  }
}