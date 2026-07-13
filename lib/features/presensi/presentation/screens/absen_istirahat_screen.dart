import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:gaweflutter/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:gaweflutter/data/models/dashboard_model.dart';
import 'package:gaweflutter/data/repositories/presensi_repository.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';

class AbsenIstirahatScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;
  const AbsenIstirahatScreen({super.key, this.onBackToHome});

  @override
  ConsumerState<AbsenIstirahatScreen> createState() => _AbsenIstirahatScreenState();
}

class _AbsenIstirahatScreenState extends ConsumerState<AbsenIstirahatScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String? _cameraError;

  Position? _currentPosition;
  bool _isLocating = true;
  bool _isSubmitting = false;
  String? _locationError;
  StreamSubscription<Position>? _positionStreamSub;
  final MapController _mapController = MapController();

  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  String _kodeJamKerja = "";
  ll.LatLng? _officeLatLng;
  double _officeRadius = 100.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initLocationTracking();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _positionStreamSub?.cancel();
    _cameraController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      var status = await Permission.camera.status;
      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      if (status.isPermanentlyDenied) {
        setState(() {
          _cameraError = "Izin kamera ditolak secara permanen. Harap aktifkan di pengaturan.";
        });
        return;
      }

      if (!status.isGranted) {
        setState(() {
          _cameraError = "Izin akses kamera ditolak.";
        });
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _cameraError = "Kamera tidak ditemukan.";
        });
        return;
      }

      CameraDescription? frontCam;
      for (var cam in _cameras!) {
        if (cam.lensDirection == CameraLensDirection.front) {
          frontCam = cam;
          break;
        }
      }
      frontCam ??= _cameras!.first;

      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = "Gagal memuat kamera: $e";
        });
      }
    }
  }

  Future<void> _initLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = "GPS dinonaktifkan. Silakan aktifkan layanan lokasi.";
          _isLocating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = "Izin lokasi ditolak.";
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = "Izin lokasi ditolak permanen.";
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocating = false;
        });
      }

      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          _updateMapCamera();
        }
      }, onError: (e) {
        debugPrint("Location stream error: $e");
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = "Gagal memuat lokasi: $e";
          _isLocating = false;
        });
      }
    }
  }

  void _updateMapCamera() {
    if (_currentPosition == null) return;
    _mapController.move(
      ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      _mapController.camera.zoom,
    );
  }

  void _parseBranchAndSchedule(DashboardModel dashboard) {
    if (dashboard.cabang != null && _officeLatLng == null) {
      final loc = dashboard.cabang!.lokasiCabang.split(',');
      if (loc.length == 2) {
        final lat = double.tryParse(loc[0].trim());
        final lng = double.tryParse(loc[1].trim());
        if (lat != null && lng != null) {
          _officeLatLng = ll.LatLng(lat, lng);
          _officeRadius = dashboard.cabang!.radiusCabang.toDouble();
        }
      }
    }

    if (dashboard.jamKerja != null && _kodeJamKerja.isEmpty) {
      _kodeJamKerja = dashboard.jamKerja!.kodeJamKerja;
    }
  }

  Future<void> _submitAbsenIstirahat(int statusVal) async {
    if (_currentPosition == null || _kodeJamKerja.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi belum terbaca atau jadwal jam kerja tidak tersedia.')),
      );
      return;
    }

    if (_cameraController == null || !_isCameraInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamera belum siap.')),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      final XFile photo = await _cameraController!.takePicture();
      final repository = ref.read(presensiRepositoryProvider);
      final locationString = "${_currentPosition!.latitude},${_currentPosition!.longitude}";

      final Map<String, dynamic> result = await repository.absenIstirahat(
        lokasi: locationString,
        status: statusVal.toString(),
        kodeJamKerja: _kodeJamKerja,
        imagePath: photo.path,
      );

      if (mounted) {
        ref.invalidate(dashboardProvider);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF2D5A4C), size: 28),
                const SizedBox(width: 8),
                Text(
                  statusVal == 1 ? 'Mulai Istirahat Berhasil' : 'Selesai Istirahat Berhasil',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Text(result['message'] ?? 'Presensi istirahat berhasil dicatat.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back screen
                  if (widget.onBackToHome != null) {
                    widget.onBackToHome!();
                  }
                },
                child: const Text('Selesai', style: TextStyle(color: Color(0xFF2D5A4C), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2D5A4C);
    const Color bodyBgColor = Color(0xFFE8F0ED);

    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text('Absen Istirahat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: dashboardAsync.when(
          data: (dashboard) {
            _parseBranchAndSchedule(dashboard);

            if (_locationError != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off_rounded, size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(_locationError!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _locationError = null;
                            _isLocating = true;
                          });
                          _initLocationTracking();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            }

            final bool hasCheckedIn = dashboard.attendance?.jamIn != null;
            final bool hasMulaiIstirahat = dashboard.attendance?.istirahatOut != null;
            final bool hasSelesaiIstirahat = dashboard.attendance?.istirahatIn != null;
            final bool hasIstirahatWorkHours = (dashboard.jamKerja?.istirahat ?? 0) == 1;

            if (!hasCheckedIn) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orangeAccent),
                      SizedBox(height: 16),
                      Text(
                        'Anda belum melakukan presensi masuk hari ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!hasIstirahatWorkHours) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 64, color: Colors.blueAccent),
                      SizedBox(height: 16),
                      Text(
                        'Tidak Ada Istirahat Untuk Jam Kerja Saat Ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            final userLatLng = _currentPosition != null
                ? ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const ll.LatLng(0, 0);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Camera Preview Container
                  Expanded(
                    flex: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Live Camera Feed
                          if (_cameraError != null)
                            Center(child: Text(_cameraError!, style: const TextStyle(color: Colors.white)))
                          else if (_isCameraInitialized && _cameraController != null) ...[
                            FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraController!.value.previewSize!.height,
                                height: _cameraController!.value.previewSize!.width,
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          ] else
                            const Center(child: CircularProgressIndicator(color: Colors.white)),

                          // Digital Clock Top Overlay
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('HH:mm:ss').format(_currentTime),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Date Stamp Top Overlay
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_currentTime),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          // Leaflet Map PiP Overlay
                          Positioned(
                            bottom: 14,
                            right: 14,
                            width: 100,
                            height: 100,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _isLocating
                                  ? Container(
                                      color: Colors.black45,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        ),
                                      ),
                                    )
                                  : FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter: userLatLng,
                                        initialZoom: 16.0,
                                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: userLatLng,
                                              width: 32,
                                              height: 32,
                                              child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // GPS Status Overlay
                          Positioned(
                            bottom: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _currentPosition != null ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _currentPosition != null ? "GPS Terkunci" : "Mencari GPS...",
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Break info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Jadwal Istirahat', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text(
                              dashboard.jamKerja?.namaJamKerja ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${dashboard.jamKerja?.jamAwalIstirahat ?? '--:--'} - ${dashboard.jamKerja?.jamAkhirIstirahat ?? '--:--'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Action Buttons
                  if (!hasMulaiIstirahat) ...[
                    ElevatedButton.icon(
                      onPressed: _isSubmitting || _isLocating ? null : () => _submitAbsenIstirahat(1),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.coffee_rounded, color: Colors.white),
                      label: Text(
                        _isSubmitting ? 'MENGIRIM...' : 'MULAI ISTIRAHAT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                    )
                  ] else if (!hasSelesaiIstirahat) ...[
                    ElevatedButton.icon(
                      onPressed: _isSubmitting || _isLocating ? null : () => _submitAbsenIstirahat(2),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.work_rounded, color: Colors.white),
                      label: Text(
                        _isSubmitting ? 'MENGIRIM...' : 'SELESAI ISTIRAHAT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                    )
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                      label: const Text(
                        'PRESENSI ISTIRAHAT SELESAI',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                    )
                  ]
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (err, stack) => Center(child: Text('Terjadi kesalahan: $err')),
        ),
      ),
    );
  }
}
