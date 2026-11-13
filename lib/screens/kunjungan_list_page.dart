import 'package:flutter/material.dart';
import '../services/kunjungan_service.dart';
import 'kunjungan_form_page.dart';

class KunjunganListPage extends StatefulWidget {
  const KunjunganListPage({super.key});

  @override
  State<KunjunganListPage> createState() => _KunjunganListPageState();
}

class _KunjunganListPageState extends State<KunjunganListPage> {
  // DIPERBAIKI: Generics List<Map<String, Object?>> lengkap
  late Future<List<Map<String, Object?>>> _futureKunjungan;

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  void _muatUlang() {
    setState(() {
      _futureKunjungan = KunjunganService.instance.getAll();
    });
  }

  String _formatTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Color _warnaStatus(String status) {
    switch (status) {
      case 'Selesai':
        return Colors.green;
      case 'Batal':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _konfirmasiHapus(int id, String namaPelanggan) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kunjungan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kunjungan "$namaPelanggan"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('BATAL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );

    if (setuju == true) {
      await KunjunganService.instance.hapus(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data kunjungan berhasil dihapus')),
      );
      _muatUlang();
    }
  }

  Future<void> _bukaForm({Map<String, Object?>? edit}) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KunjunganFormPage(kunjunganEdit: edit),
      ),
    );
    if (berubah == true) {
      _muatUlang();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Kunjungan'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _muatUlang,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      // DIPERBAIKI: Generics FutureBuilder lengkap
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _futureKunjungan,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const Center(child: Text('Belum ada kunjungan'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 84),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              final id = row['id'] as int;
              final nama = row['nama_pelanggan'] as String;
              final alamat = row['alamat'] as String;
              final status = (row['status'] as String?) ?? 'Pending';
              final catatan = (row['catatan'] as String?) ?? '';
              final lat = (row['latitude'] as num?)?.toDouble();
              final lng = (row['longitude'] as num?)?.toDouble();
              final tanggal = _formatTanggal(
                row['tanggal_kunjungan'] as String?,
              );
              final warna = _warnaStatus(status);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFFE3EEFF),
                            child: Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Color(0xFF1765D1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              nama,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: warna.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: warna,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: Text(alamat)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tanggal: $tanggal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed,
                            size: 14,
                            color: Color(0xFF1765D1),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (lat != null && lng != null)
                                ? 'GPS: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
                                : 'GPS: Belum direkam',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Catatan: ${catatan.isEmpty ? 'tidak ada' : catatan}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _bukaForm(edit: row),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('EDIT'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () => _konfirmasiHapus(id, nama),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('HAPUS'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}