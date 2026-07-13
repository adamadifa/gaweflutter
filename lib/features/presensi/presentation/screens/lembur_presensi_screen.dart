import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/repositories/lembur_repository.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

const Color primaryColor = Color(0xFF32745e);

class LemburPresensiScreen extends ConsumerStatefulWidget {
  final int idLembur;
  final int status; // 1 = masuk, 2 = pulang

  const LemburPresensiScreen({
    super.key,
    required this.idLembur,
    required this.status,
  });

  @override
  ConsumerState<LemburPresensiScreen> createState() => _LemburPresensiScreenState();
}

class _LemburPresensiScreenState extends ConsumerState<LemburPresensiScreen> with SingleTickerProviderStateMixin {
  // Camera & Face Detection
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraError;
  
  FaceDetector? _faceDetector;
  bool _isProcessingImage = false;
  DateTime? _lastProcessedTime;
  Size? _previewContainerSize;
  bool _isFaceDetected = false;

  // Location variables
  Position? _currentPosition;
  bool _isLocating = true;
  String? _locationError;

  // Submission State
  bool _isSubmitting = false;

  AnimationController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _initLocationTracking();
    _initCamera();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _faceDetector?.close();
    _cameraController?.dispose();
    super.dispose();
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = "Gagal memuat lokasi: $e";
          _isLocating = false;
        });
      }
    }
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

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Gagal mengakses kamera: $e';
        });
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_faceDetector == null || _isProcessingImage || _isSubmitting) return;

    final now = DateTime.now();
    if (_lastProcessedTime != null && now.difference(_lastProcessedTime!).inMilliseconds < 350) {
      return;
    }
    _lastProcessedTime = now;
    _isProcessingImage = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessingImage = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);
      
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
        final scale = scaleX > scaleY ? scaleX : scaleY;

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

        if (_isFaceDetected && !_isSubmitting && _currentPosition != null) {
          _doSubmitAbsenLembur();
        }
      }
    } catch (e) {
      debugPrint("Face detection error: $e");
    } finally {
      _isProcessingImage = false;
    }
  }

  Future<void> _doSubmitAbsenLembur() async {
    setState(() {
      _isSubmitting = true;
    });

    // Stop camera stream to avoid native driver crash
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      final repository = ref.read(lemburRepositoryProvider);
      final lokasiStr = "${_currentPosition!.latitude},${_currentPosition!.longitude}";

      final result = await repository.absenLembur(
        idLembur: widget.idLembur,
        status: widget.status,
        lokasi: lokasiStr,
        imagePath: photo.path,
      );

      if (mounted) {
        if (result['success'] == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: primaryColor, size: 28),
                  SizedBox(width: 8),
                  Text('Absen Berhasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Text(result['message'] ?? 'Data lembur berhasil disimpan.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Pop screen with success value
                  },
                  child: const Text('Selesai', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else {
          throw Exception(result['message'] ?? 'Gagal memproses absen lembur.');
        }
      }
    } catch (e) {
      if (mounted) {
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
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isSubmitting = false;
                    _isFaceDetected = false;
                  });
                  // Restart image stream
                  if (_cameraController != null && _isCameraInitialized && !_cameraController!.value.isStreamingImages) {
                    _cameraController!.startImageStream(_processCameraImage);
                  }
                },
                child: const Text('Coba Lagi', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        );
      }
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
      final bytes = _yuv420ToNv21(image);
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } else {
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

  @override
  Widget build(BuildContext context) {
    final title = widget.status == 1 ? 'Absen Masuk Lembur' : 'Absen Pulang Lembur';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSubmitting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              widget.status == 1 ? 'Memulai lembur...' : 'Mengakhiri lembur...',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Live Preview
        if (_cameraError != null)
          Center(child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(_cameraError!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ))
        else if (_isCameraInitialized && _cameraController != null) ...[
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize!.height,
              height: _cameraController!.value.previewSize!.width,
              child: CameraPreview(_cameraController!),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: FaceMaskPainter(),
            ),
          ),
        ] else
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        // Location / GPS Loading Status
        if (_isLocating)
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text(
                    'Mencari lokasi GPS Anda...',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        else if (_locationError != null)
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _locationError!,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // Face detection info banner
        if (_isCameraInitialized && _cameraController != null && !_isLocating && _locationError == null)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isFaceDetected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isFaceDetected ? 'Wajah Terdeteksi... Tahan!' : 'Posisikan wajah Anda di dalam oval...',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        // Bounding Guide Oval
        if (_isCameraInitialized && _cameraController != null)
          LayoutBuilder(
            builder: (context, constraints) {
              _previewContainerSize = Size(constraints.maxWidth, constraints.maxHeight);
              return Center(
                child: SizedBox(
                  width: 220,
                  height: 280,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isFaceDetected ? Colors.greenAccent : Colors.redAccent,
                        width: 3.5,
                      ),
                      borderRadius: const BorderRadius.all(Radius.elliptical(220, 280)),
                      boxShadow: [
                        BoxShadow(
                          color: (_isFaceDetected ? Colors.greenAccent : Colors.redAccent).withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class FaceMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final ovalWidth = 220.0;
    final ovalHeight = 280.0;
    final ovalRect = Rect.fromLTWH(
      (size.width - ovalWidth) / 2,
      (size.height - ovalHeight) / 2,
      ovalWidth,
      ovalHeight,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect);

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
