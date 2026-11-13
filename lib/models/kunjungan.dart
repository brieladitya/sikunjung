class Kunjungan {
  final int? id;
  final int userId;
  final String namaPelanggan;
  final String alamat;
  final String nomorTelepon;
  final String tanggalKunjungan;
  final double? latitude;
  final double? longitude;
  final double? akurasiGps;
  final String status;
  final String catatan;

  const Kunjungan({
    this.id,
    required this.userId,
    required this.namaPelanggan,
    required this.alamat,
    this.nomorTelepon = '',
    required this.tanggalKunjungan,
    this.latitude,
    this.longitude,
    this.akurasiGps,
    this.status = 'Pending',
    this.catatan = '',
  });

  factory Kunjungan.fromMap(Map<String, Object?> map) {
    return Kunjungan(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 1,
      namaPelanggan: (map['nama_pelanggan'] as String?) ?? '',
      alamat: (map['alamat'] as String?) ?? '',
      nomorTelepon: (map['nomor_telepon'] as String?) ?? '',
      tanggalKunjungan: (map['tanggal_kunjungan'] as String?) ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      akurasiGps: (map['akurasi_gps'] as num?)?.toDouble(),
      status: (map['status'] as String?) ?? 'Pending',
      catatan: (map['catatan'] as String?) ?? '',
    );
  }

  Map<String, Object?> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'nama_pelanggan': namaPelanggan,
      'alamat': alamat,
      'nomor_telepon': nomorTelepon,
      'tanggal_kunjungan': tanggalKunjungan,
      'latitude': latitude,
      'longitude': longitude,
      'akurasi_gps': akurasiGps,
      'status': status,
      'catatan': catatan,
      'created_at': now,
      'updated_at': now,
    };
  }
}