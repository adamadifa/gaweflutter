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
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:gaweflutter/core/theme/app_theme_scheme.dart';

class PresensiGpsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;
  final bool isActive;
  const PresensiGpsScreen({super.key, this.onBackToHome, this.isActive = true});

  @override
  ConsumerState<PresensiGpsScreen> createState() => _PresensiGpsScreenState();
}

class _PresensiGpsScreenState extends ConsumerState<PresensiGpsScreen> with SingleTickerProviderStateMixin {
  // Camera variables
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String? _cameraError;

  // Location variables
  Position? _currentPosition;
  double _distanceInMeters = 0.0;
  bool _isLocating = true;
  bool _isSubmitting = false;
  String? _locationError;
  StreamSubscription<Position>? _positionStreamSub;
  final MapController _mapController = MapController();

  // Clock variables
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Face scanner variables
  AnimationController? _scannerController;
  String? _faceVerificationStatus; // null, 'checking', 'success', 'failed', 'no_face'
  bool _isFaceDetected = false;
  FaceDetector? _faceDetector;
  bool _isProcessingImage = false;
  DateTime? _lastProcessedTime;
  Size? _previewContainerSize;

  // Office Location parsed from API
  ll.LatLng? _officeLatLng;
  double _officeRadius = 100.0;
  bool _lockLocation = true;
  String _kodeJamKerja = "";

  Color _getBorderColorByStatus() {
    switch (_faceVerificationStatus) {
      case 'checking':
        return Colors.cyanAccent;
      case 'success':
        return Colors.greenAccent;
      case 'failed':
        return Colors.redAccent;
      case 'no_face':
        return Colors.orangeAccent;
      default:
        return _isFaceDetected ? Colors.greenAccent : Colors.redAccent;
    }
  }

  Color _getStatusBgColor() {
    switch (_faceVerificationStatus) {
      case 'checking':
        return Colors.black.withOpacity(0.85);
      case 'success':
        return const Color(0xFF0F5132).withOpacity(0.9);
      case 'failed':
        return const Color(0xFF842029).withOpacity(0.9);
      case 'no_face':
        return const Color(0xFF664D03).withOpacity(0.9);
      default:
        return Colors.black87;
    }
  }

  Widget _getStatusIcon() {
    switch (_faceVerificationStatus) {
      case 'checking':
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
        );
      case 'success':
        return const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20);
      case 'failed':
        return const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20);
      case 'no_face':
        return const Icon(Icons.face_retouching_off_rounded, color: Colors.orangeAccent, size: 20);
      default:
        return const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20);
    }
  }

  String _getStatusText(String userName) {
    switch (_faceVerificationStatus) {
      case 'checking':
        return 'Memverifikasi wajah...';
      case 'success':
        return 'Wajah Dikenali: $userName';
      case 'failed':
        return 'Wajah Tidak Dikenali!';
      case 'no_face':
        return 'Wajah Tidak Terdeteksi!';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    if (widget.isActive) {
      _initCamera();
      _initLocationTracking();
    }
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PresensiGpsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _resumeCameraAndTracking();
      } else {
        _suspendCameraAndTracking();
      }
    }
  }

  void _suspendCameraAndTracking() async {
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
      } catch (e) {
        debugPrint("Error stopping image stream: $e");
      }
      try {
        await _cameraController!.dispose();
      } catch (e) {
        debugPrint("Error disposing camera: $e");
      }
      _cameraController = null;
    }
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
        _isFaceDetected = false;
      });
    }
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }

  void _resumeCameraAndTracking() {
    _initCamera();
    if (_positionStreamSub == null) {
      _initLocationTracking();
    }
  }

  @override
  void dispose() {
    _faceDetector?.close();
    _scannerController?.dispose();
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

      // Find front camera
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
          _isFaceDetected = false;
        });
        _cameraController!.startImageStream((CameraImage image) {
          _processCameraImage(image);
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
            _calculateDistance();
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

  void _calculateDistance() {
    if (_currentPosition == null || _officeLatLng == null) return;

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _officeLatLng!.latitude,
      _officeLatLng!.longitude,
    );

    setState(() {
      _distanceInMeters = distance;
    });
  }

  void _updateMapCamera() {
    if (_currentPosition == null) return;
    _mapController.move(
      ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      _mapController.camera.zoom,
    );
  }

  Future<void> _doAbsen(bool isMasuk) async {
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
        _faceVerificationStatus = 'checking';
      });

      // Stop image stream before taking picture to prevent native crashes
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      final XFile photo = await _cameraController!.takePicture();
      final repository = ref.read(presensiRepositoryProvider);
      final locationString = "${_currentPosition!.latitude},${_currentPosition!.longitude}";

      final Map<String, dynamic> result;
      if (isMasuk) {
        result = await repository.absenMasuk(
          lokasi: locationString,
          kodeJamKerja: _kodeJamKerja,
          imagePath: photo.path,
        );
      } else {
        result = await repository.absenPulang(
          lokasi: locationString,
          kodeJamKerja: _kodeJamKerja,
          imagePath: photo.path,
        );
      }

      if (mounted) {
        setState(() {
          _faceVerificationStatus = 'success';
        });
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
                  isMasuk ? 'Absen Masuk Berhasil' : 'Absen Pulang Berhasil',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Text(result['message'] ?? 'Data kehadiran Anda telah tercatat.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _faceVerificationStatus = null;
                  });
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
        setState(() {
          if (errorMsg.contains('tidak terdeteksi')) {
            _faceVerificationStatus = 'no_face';
          } else if (errorMsg.contains('tidak cocok') || errorMsg.contains('gagal')) {
            _faceVerificationStatus = 'failed';
          } else {
            _faceVerificationStatus = null;
          }
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Absen Gagal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _faceVerificationStatus = null;
                  });
                  // Restart image stream
                  if (_cameraController != null && _isCameraInitialized && !_cameraController!.value.isStreamingImages) {
                    _cameraController!.startImageStream((CameraImage image) {
                      _processCameraImage(image);
                    });
                  }
                },
                child: const Text('OK', style: TextStyle(color: Color(0xFF2D5A4C))),
              ),
            ],
          ),
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

  void _parseBranchAndSchedule(DashboardModel dashboard) {
    if (dashboard.cabang != null && _officeLatLng == null) {
      final loc = dashboard.cabang!.lokasiCabang.split(',');
      if (loc.length == 2) {
        final lat = double.tryParse(loc[0].trim());
        final lng = double.tryParse(loc[1].trim());
        if (lat != null && lng != null) {
          _officeLatLng = ll.LatLng(lat, lng);
          _officeRadius = dashboard.cabang!.radiusCabang.toDouble();
          _lockLocation = dashboard.lockLocation == 1;
          _calculateDistance();
        }
      }
    }

    if (dashboard.jamKerja != null && _kodeJamKerja.isEmpty) {
      _kodeJamKerja = dashboard.jamKerja!.kodeJamKerja;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final themeScheme = dashboardAsync.value?.generalSetting?.mobileThemeScheme;
    final primaryColor = AppThemeScheme.getPrimary(themeScheme);
    final primaryLightColor = AppThemeScheme.getLight(themeScheme);
    final bodyBgColor = AppThemeScheme.getBg(themeScheme);

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text('Presensi GPS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            final bool hasCheckedOut = dashboard.attendance?.jamOut != null;
            final bool isWithinGeofence = _distanceInMeters <= _officeRadius;
            final bool isButtonEnabled = !hasCheckedOut && (!_lockLocation || isWithinGeofence);

            final userLatLng = _currentPosition != null 
                ? ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const ll.LatLng(0, 0);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Live Camera Preview Card with Map PiP Overlay
                  Expanded(
                    flex: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          _previewContainerSize = Size(constraints.maxWidth, constraints.maxHeight);
                          return Stack(
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
                                // Semi-transparent overlay with oval cut-out
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: FaceMaskPainter(),
                                  ),
                                ),
                              ] else
                                const Center(child: CircularProgressIndicator(color: Colors.white)),

                              // Top-Left Date Stamp
                              Positioned(
                                top: 14,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(_currentTime),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),

                              // Top-Right Digital Clock
                              Positioned(
                                top: 14,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
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

                              // Face Silhouette Outline & Scanning Animation
                              if (_isCameraInitialized && _cameraController != null) ...[
                                // Center Oval Guide & Scanning line
                                Center(
                                  child: SizedBox(
                                    width: 220,
                                    height: 280,
                                    child: Stack(
                                      children: [
                                        // Bounding Guide Oval
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: _getBorderColorByStatus(),
                                              width: 3.5,
                                            ),
                                            borderRadius: const BorderRadius.all(Radius.elliptical(220, 280)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getBorderColorByStatus().withOpacity(0.2),
                                                blurRadius: 15,
                                                spreadRadius: 2,
                                              )
                                            ],
                                          ),
                                        ),
                                        // Scanner Line (Moving up and down inside the oval)
                                        if (_faceVerificationStatus == 'checking' && _scannerController != null)
                                          AnimatedBuilder(
                                            animation: _scannerController!,
                                            builder: (context, child) {
                                              return Positioned(
                                                top: _scannerController!.value * 270,
                                                left: 20,
                                                right: 20,
                                                child: Container(
                                                  height: 3,
                                                  decoration: BoxDecoration(
                                                    color: Colors.cyanAccent,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.cyanAccent.withOpacity(0.8),
                                                        blurRadius: 8,
                                                        spreadRadius: 2,
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Status Overlay Card
                                if (_faceVerificationStatus != null)
                                  Positioned(
                                    bottom: 12,
                                    left: 125,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _getStatusBgColor(),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _getBorderColorByStatus().withOpacity(0.5), width: 1.5),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _getStatusIcon(),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _getStatusText(ref.watch(authProvider).user?.name ?? 'Karyawan'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Positioned(
                                    bottom: 12,
                                    left: 125,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.75),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _isFaceDetected ? Colors.greenAccent.withOpacity(0.4) : Colors.redAccent.withOpacity(0.4),
                                          width: 1.5,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isFaceDetected ? Icons.face_rounded : Icons.face_retouching_off_rounded,
                                            color: _isFaceDetected ? Colors.greenAccent : Colors.redAccent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _isFaceDetected
                                                  ? 'Wajah terdeteksi. Silakan absen.'
                                                  : 'Posisikan wajah Anda di dalam oval...',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],

                              // Bottom-Left Mini Map Card (Picture in Picture Overlay)
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  width: 105,
                                  height: 105,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _isLocating || _currentPosition == null
                                      ? Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)))
                                      : FlutterMap(
                                          mapController: _mapController,
                                          options: MapOptions(
                                            initialCenter: userLatLng,
                                            initialZoom: 16.0,
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName: 'com.example.gaweflutter',
                                            ),
                                            if (_officeLatLng != null)
                                              CircleLayer(
                                                circles: [
                                                  CircleMarker(
                                                    point: _officeLatLng!,
                                                    color: primaryColor.withValues(alpha: 0.2),
                                                    borderColor: primaryColor,
                                                    borderStrokeWidth: 1.5,
                                                    radius: _officeRadius,
                                                    useRadiusInMeter: true,
                                                  ),
                                                ],
                                              ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: userLatLng,
                                                  width: 16,
                                                  height: 16,
                                                  child: const Icon(Icons.circle, color: Colors.cyan, size: 10),
                                                ),
                                                if (_officeLatLng != null)
                                                  Marker(
                                                    point: _officeLatLng!,
                                                    width: 16,
                                                    height: 16,
                                                    child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 12),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Schedule Info Card (Synchronized with Laravel Web Design)
                  if (dashboard.jamKerja != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryLightColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          // Column 1: Shift
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded, color: Color(0xFFFFD600), size: 22),
                                const SizedBox(height: 3),
                                const Text(
                                  'Shift',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dashboard.jamKerja!.namaJamKerja,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Container(width: 1, height: 36, color: Colors.white24),
                          // Column 2: Jam Masuk
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.login_rounded, color: Color(0xFFFFD600), size: 22),
                                const SizedBox(height: 3),
                                const Text(
                                  'Jam Masuk',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dashboard.jamKerja!.jamMasuk ?? "--:--",
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Container(width: 1, height: 36, color: Colors.white24),
                          // Column 3: Jam Pulang
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.logout_rounded, color: Color(0xFFFFD600), size: 22),
                                const SizedBox(height: 3),
                                const Text(
                                  'Jam Pulang',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dashboard.jamKerja!.jamPulang ?? "--:--",
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 3. Geofencing status alert
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isWithinGeofence ? const Color(0xFFD1E7DD) : const Color(0xFFF8D7DA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isWithinGeofence ? Icons.check_circle_rounded : Icons.warning_rounded,
                          color: isWithinGeofence ? const Color(0xFF0F5132) : const Color(0xFF842029),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isWithinGeofence
                              ? 'Dalam Radius Kantor (${_distanceInMeters.toStringAsFixed(0)}m)'
                              : 'Luar Radius Kantor (${_distanceInMeters.toStringAsFixed(0)}m)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isWithinGeofence ? const Color(0xFF0F5132) : const Color(0xFF842029),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Action Buttons
                  if (hasCheckedOut)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Absen Selesai Untuk Hari Ini',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  else if (_isSubmitting)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Opacity(
                            opacity: (!hasCheckedIn && isButtonEnabled) ? 1.0 : 0.5,
                            child: ElevatedButton(
                              onPressed: (!hasCheckedIn && isButtonEnabled) ? () => _doAbsen(true) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: const Text('Absen Masuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Opacity(
                            opacity: (hasCheckedIn && isButtonEnabled) ? 1.0 : 0.5,
                            child: ElevatedButton(
                              onPressed: (hasCheckedIn && isButtonEnabled) ? () => _doAbsen(false) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC3545),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: const Text('Absen Pulang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Gagal memuat konfigurasi presensi: ${error.toString().replaceAll('Exception: ', '')}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_faceDetector == null) return;
    if (_isProcessingImage) return;

    final now = DateTime.now();
    if (_lastProcessedTime != null && now.difference(_lastProcessedTime!).inMilliseconds < 350) {
      return;
    }
    _lastProcessedTime = now;
    _isProcessingImage = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        debugPrint("ML Kit inputImage is null!");
        _isProcessingImage = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);
      debugPrint("ML Kit Faces detected: ${faces.length}");
      
      bool faceInsideOval = false;
      if (faces.isNotEmpty && _previewContainerSize != null) {
        final face = faces.first;
        final boundingBox = face.boundingBox;

        final camera = _cameraController!.description;
        final sensorOrientation = camera.sensorOrientation;
        final isRotated = sensorOrientation == 90 || sensorOrientation == 270;
        final imageWidth = isRotated ? image.height : image.width;
        final imageHeight = isRotated ? image.width : image.height;

        final screenWidth = _previewContainerSize!.width;
        final screenHeight = _previewContainerSize!.height;

        final scaleX = screenWidth / imageWidth;
        final scaleY = screenHeight / imageHeight;
        final scale = scaleX > scaleY ? scaleX : scaleY; // BoxFit.cover scale

        final scaledWidth = imageWidth * scale;
        final scaledHeight = imageHeight * scale;
        final offsetX = (screenWidth - scaledWidth) / 2;
        final offsetY = (screenHeight - scaledHeight) / 2;

        final faceLeft = boundingBox.left * scale + offsetX;
        final faceTop = boundingBox.top * scale + offsetY;
        final faceRight = boundingBox.right * scale + offsetX;
        final faceBottom = boundingBox.bottom * scale + offsetY;

        final ovalWidth = 220.0;
        final ovalHeight = 280.0;
        final ovalLeft = (screenWidth - ovalWidth) / 2;
        final ovalTop = (screenHeight - ovalHeight) / 2;
        final ovalRight = ovalLeft + ovalWidth;
        final ovalBottom = ovalTop + ovalHeight;

        // Tolerance in pixels to make the positioning comfortable for users
        const double tolerance = 25.0;

        if (faceLeft >= (ovalLeft - tolerance) &&
            faceRight <= (ovalRight + tolerance) &&
            faceTop >= (ovalTop - tolerance) &&
            faceBottom <= (ovalBottom + tolerance)) {
          faceInsideOval = true;
        }
      }

      if (mounted) {
        setState(() {
          _isFaceDetected = faceInsideOval;
        });
      }
    } catch (e, stack) {
      debugPrint("Face detection error: $e");
      debugPrint("Face detection stack: $stack");
    } finally {
      _isProcessingImage = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    
    rotation ??= InputImageRotation.rotation0deg;

    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : (InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.bgra8888);
    
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    if (Platform.isAndroid) {
      // YUV420_888 needs conversion to NV21 bytes for ML Kit
      final bytes = _yuv420ToNv21(image);
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } else {
      // iOS BGRA8888 has single plane
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final numPixels = (width * height * 1.5).toInt();
    final nv21 = Uint8List(numPixels);

    // Copy Y plane row by row, skipping padding bytes at the end of each row
    int idY = 0;
    final yRowStride = yPlane.bytesPerRow;
    for (int y = 0; y < height; y++) {
      final int rowStart = y * yRowStride;
      for (int x = 0; x < width; x++) {
        if (idY < numPixels) {
          nv21[idY++] = yBuffer[rowStart + x];
        }
      }
    }

    // Interleave U and V plane (NV21: V, U, V, U...)
    int idUV = idY;
    final uRowStride = uPlane.bytesPerRow;
    final vRowStride = vPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    final halfHeight = height ~/ 2;
    final halfWidth = width ~/ 2;

    for (int y = 0; y < halfHeight; y++) {
      final int uRowStart = y * uRowStride;
      final int vRowStart = y * vRowStride;
      for (int x = 0; x < halfWidth; x++) {
        final uIndex = uRowStart + x * uPixelStride;
        final vIndex = vRowStart + x * vPixelStride;

        if (vIndex < vBuffer.length && idUV < numPixels) {
          nv21[idUV++] = vBuffer[vIndex];
        }
        if (uIndex < uBuffer.length && idUV < numPixels) {
          nv21[idUV++] = uBuffer[uIndex];
        }
      }
    }

    return nv21;
  }
}

class FaceMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.65) // Dark overlay color (slightly darker)
      ..style = PaintingStyle.fill;

    final ovalWidth = 220.0;
    final ovalHeight = 280.0;
    final ovalRect = Rect.fromLTWH(
      (size.width - ovalWidth) / 2,
      (size.height - ovalHeight) / 2,
      ovalWidth,
      ovalHeight,
    );

    // Full screen path excluding the oval area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect);

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
