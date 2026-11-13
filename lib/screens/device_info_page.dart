import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoPage extends StatefulWidget {
  const DeviceInfoPage({super.key});

  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  Map<String, String> _info = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muatInfo();
  }

  Future<void> _muatInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final data = <String, String>{
      'Nama Aplikasi': packageInfo.appName,
      'Package Name': packageInfo.packageName,
      'Versi Aplikasi':
      '${packageInfo.version} (Build ${packageInfo.buildNumber})',
      'Bahasa & Framework': 'Dart & Flutter (Material 3)',
    };

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      data['Sistem Operasi'] = 'Android ${android.version.release}';
      data['API Level (SDK)'] = 'API ${android.version.sdkInt}';
      data['Merek Perangkat'] = android.brand.toUpperCase();
      data['Model Perangkat'] = android.model;
      data['Jenis Perangkat'] =
      android.isPhysicalDevice ? 'Perangkat Fisik' : 'Emulator Android';
    } else {
      data['Sistem Operasi'] = Platform.operatingSystem;
      data['Versi OS'] = Platform.operatingSystemVersion;
    }

    if (!mounted) return;
    setState(() {
      _info = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Perangkat'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phone_android, color: Color(0xFF1765D1)),
                      SizedBox(width: 8),
                      Text(
                        'Platform OS & Spesifikasi Perangkat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ..._info.entries.map(
                        (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 145,
                            child: Text(
                              e.key,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}