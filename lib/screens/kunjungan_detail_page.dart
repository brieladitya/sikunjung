import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/kunjungan.dart';
import '../widgets/app_navbar.dart';
import 'kunjungan_form_page.dart';

class KunjunganDetailPage extends StatelessWidget {
  final Map<String, Object?> kunjunganMap;

  const KunjunganDetailPage({super.key, required this.kunjunganMap});

  Future<void> _bukaMaps(BuildContext context, double lat, double lng) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
      'travelmode': 'driving',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aplikasi navigasi tidak dapat dibuka')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = Kunjungan.fromMap(kunjunganMap);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kunjungan'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Edit Kunjungan',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final berubah = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      KunjunganFormPage(kunjunganEdit: kunjunganMap),
                ),
              );
              if (berubah == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: const AppNavbar(currentIndex: 1),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.namaPelanggan,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Chip(label: Text('Status: ${data.status}')),
                  const Divider(height: 24),
                  _ItemDetail(label: 'Alamat', nilai: data.alamat),
                  _ItemDetail(
                    label: 'Nomor HP',
                    nilai: data.nomorTelepon.isEmpty ? '-' : data.nomorTelepon,
                  ),
                  _ItemDetail(
                    label: 'Tanggal Kunjungan',
                    nilai: data.tanggalKunjungan,
                  ),
                  _ItemDetail(
                    label: 'Koordinat GPS',
                    nilai: (data.latitude != null && data.longitude != null)
                        ? '${data.latitude!.toStringAsFixed(6)}, ${data.longitude!.toStringAsFixed(6)}'
                        : 'Belum direkam',
                  ),
                  if (data.akurasiGps != null)
                    _ItemDetail(
                      label: 'Akurasi GPS',
                      nilai: '${data.akurasiGps!.toStringAsFixed(1)} meter',
                    ),
                  _ItemDetail(
                    label: 'Catatan',
                    nilai: data.catatan.isEmpty ? 'Tidak ada' : data.catatan,
                  ),
                ],
              ),
            ),
          ),
          if (data.latitude != null && data.longitude != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  _bukaMaps(context, data.latitude!, data.longitude!),
              icon: const Icon(Icons.navigation_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('NAVIGASI KE PELANGGAN'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemDetail extends StatelessWidget {
  final String label;
  final String nilai;

  const _ItemDetail({required this.label, required this.nilai});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(nilai, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}