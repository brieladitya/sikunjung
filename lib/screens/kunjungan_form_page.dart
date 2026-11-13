import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../services/gps_service.dart';
import '../services/kunjungan_service.dart';
import '../widgets/app_navbar.dart';
import 'location_picker_page.dart';

class KunjunganFormPage extends StatefulWidget {
  final Map<String, Object?>? kunjunganEdit;

  const KunjunganFormPage({super.key, this.kunjunganEdit});

  @override
  State<KunjunganFormPage> createState() => _KunjunganFormPageState();
}

class _KunjunganFormPageState extends State<KunjunganFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _alamat;
  late final TextEditingController _telepon;
  late final TextEditingController _catatan;

  late String _status;
  double? _latitude;
  double? _longitude;
  double? _akurasi;
  bool _loading = false;
  bool _mengambilGps = false;

  bool get _isEdit => widget.kunjunganEdit != null;

  @override
  void initState() {
    super.initState();
    final lama = widget.kunjunganEdit;
    _nama = TextEditingController(
      text: (lama?['nama_pelanggan'] as String?) ?? '',
    );
    _alamat = TextEditingController(
      text: (lama?['alamat'] as String?) ?? '',
    );
    _telepon = TextEditingController(
      text: (lama?['nomor_telepon'] as String?) ?? '',
    );
    _catatan = TextEditingController(
      text: (lama?['catatan'] as String?) ?? '',
    );
    _status = (lama?['status'] as String?) ?? 'Pending';
    _latitude = (lama?['latitude'] as num?)?.toDouble();
    _longitude = (lama?['longitude'] as num?)?.toDouble();
    _akurasi = (lama?['akurasi_gps'] as num?)?.toDouble();
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _telepon.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _ambilGps() async {
    setState(() => _mengambilGps = true);
    try {
      final posisi = await GpsService.instance.ambilLokasi();
      if (!mounted) return;
      setState(() {
        _latitude = posisi.latitude;
        _longitude = posisi.longitude;
        _akurasi = posisi.accuracy;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _mengambilGps = false);
    }
  }

  Future<void> _pilihDiPeta() async {
    final hasil = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );
    if (hasil != null && mounted) {
      setState(() {
        _latitude = hasil.latitude;
        _longitude = hasil.longitude;
        _akurasi = null;
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Periksa kembali input form yang belum memenuhi syarat.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isEdit) {
        final id = widget.kunjunganEdit!['id'] as int;
        await KunjunganService.instance.ubah(id, {
          'nama_pelanggan': _nama.text.trim(),
          'alamat': _alamat.text.trim(),
          'nomor_telepon': _telepon.text.trim(),
          'catatan': _catatan.text.trim(),
          'status': _status,
          'latitude': _latitude,
          'longitude': _longitude,
          'akurasi_gps': _akurasi,
        });
      } else {
        await KunjunganService.instance.tambah(
          nama: _nama.text,
          alamat: _alamat.text,
          telepon: _telepon.text,
          catatan: _catatan.text,
          status: _status,
          latitude: _latitude,
          longitude: _longitude,
          akurasi: _akurasi,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Data kunjungan berhasil diperbarui'
                : 'Data kunjungan berhasil disimpan',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kunjungan' : 'Tambah Kunjungan'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const AppNavbar(currentIndex: 1),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Informasi Pelanggan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lengkapi data dan lokasi kunjungan sesuai batas minimal karakter.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nama,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan *',
                hintText: 'Minimal 3 karakter',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final teks = v?.trim() ?? '';
                if (teks.isEmpty) return 'Nama pelanggan wajib diisi';
                if (teks.length < 3) return 'Nama pelanggan minimal 3 karakter';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alamat,
              maxLength: 300,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat Pelanggan *',
                hintText: 'Minimal 10 karakter',
                prefixIcon: Icon(Icons.home_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final teks = v?.trim() ?? '';
                if (teks.isEmpty) return 'Alamat pelanggan wajib diisi';
                if (teks.length < 10) {
                  return 'Alamat pelanggan minimal 10 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telepon,
              maxLength: 15,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon *',
                hintText: 'Contoh: 081234567890 (minimal 10 digit)',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final teks = v?.trim() ?? '';
                if (teks.isEmpty) return 'Nomor telepon wajib diisi';
                if (teks.length < 10) return 'Nomor telepon minimal 10 digit';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status Kunjungan',
                prefixIcon: Icon(Icons.fact_check_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                DropdownMenuItem(value: 'Batal', child: Text('Batal')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _catatan,
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan Kunjungan',
                hintText: 'Opsional (minimal 5 karakter jika diisi)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final teks = v?.trim() ?? '';
                if (teks.isNotEmpty && teks.length < 5) {
                  return 'Catatan kunjungan minimal 5 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.my_location, color: Color(0xFF1765D1)),
                      SizedBox(width: 8),
                      Text(
                        'Lokasi GPS Kunjungan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (_latitude != null && _longitude != null)
                        ? 'Latitude: ${_latitude!.toStringAsFixed(6)}\n'
                        'Longitude: ${_longitude!.toStringAsFixed(6)}'
                        '${_akurasi != null ? '\nAkurasi: ${_akurasi!.toStringAsFixed(1)} meter' : '\nSumber: Dipilih manual di peta'}'
                        : 'Lokasi belum diambil. Gunakan GPS otomatis atau pilih di peta.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _mengambilGps ? null : _ambilGps,
                          icon: const Icon(Icons.gps_fixed, size: 18),
                          label: Text(
                            _mengambilGps ? 'MENCARI...' : 'GPS SAAT INI',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pilihDiPeta,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text(
                            'PILIH DI PETA',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _simpan,
              icon: const Icon(Icons.save),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _loading
                      ? 'MENYIMPAN...'
                      : (_isEdit ? 'SIMPAN PERUBAHAN' : 'SIMPAN KUNJUNGAN'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}