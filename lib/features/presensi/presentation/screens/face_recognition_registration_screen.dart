import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/repositories/face_recognition_repository.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class FaceRecognitionRegistrationScreen extends ConsumerStatefulWidget {
  const FaceRecognitionRegistrationScreen({super.key});

  @override
  ConsumerState<FaceRecognitionRegistrationScreen> createState() => _FaceRecognitionRegistrationScreenState();
}

class _FaceRecognitionRegistrationScreenState extends ConsumerState<FaceRecognitionRegistrationScreen> with SingleTickerProviderStateMixin {
  Color get primaryColor => Theme.of(context).primaryColor;
  // Screen States: 'loading', 'status', 'scanning', 'uploading', 'success'
  String _screenState = 'loading';
  
  bool _isRegistered = false;
  List<dynamic> _wajahList = [];
  String? _errorMessage;
  String _cacheBuster = '';

  // Camera & Face Detection
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraError;
  
  FaceDetector? _faceDetector;
  bool _isProcessingImage = false;
  DateTime? _lastProcessedTime;
  Size? _previewContainerSize;
  bool _isFaceDetected = false;

  // Scan Capture States
  int _capturedCount = 0;
  final int _totalCapturesNeeded = 5;
  final List<String> _capturedPaths = [];
  bool _isCapturingBatch = false;
  
  AnimationController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _fetchRegistrationStatus();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _faceDetector?.close();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _fetchRegistrationStatus() async {
    setState(() {
      _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
      _screenState = 'loading';
      _errorMessage = null;
    });

    try {
      final repository = ref.read(faceRecognitionRepositoryProvider);
      final data = await repository.getFaceStatus();
      if (mounted) {
        setState(() {
          _isRegistered = data['registered'] ?? false;
          _wajahList = data['wajah_list'] ?? [];
          _screenState = 'status';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _screenState = 'status';
        });
      }
    }
  }

  Future<void> _deleteRegisteredFaces() async {
    setState(() {
      _screenState = 'loading';
    });

    try {
      final repository = ref.read(faceRecognitionRepositoryProvider);
      final data = await repository.deleteFace();
      if (data['success'] == true) {
        _isRegistered = false;
        _wajahList = [];
        _startRegistrationFlow();
      } else {
        throw Exception(data['message'] ?? 'Gagal menghapus wajah.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
        _fetchRegistrationStatus();
      }
    }
  }

  void _startRegistrationFlow() {
    setState(() {
      _capturedCount = 0;
      _capturedPaths.clear();
      _isFaceDetected = false;
      _isCapturingBatch = false;
      _cameraError = null;
      _screenState = 'scanning';
    });
    _initCameraAndDetector();
  }

  Future<void> _initCameraAndDetector() async {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

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

        // Start processing the camera image stream for face detection
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
    if (_faceDetector == null || _isProcessingImage || _isCapturingBatch || _screenState != 'scanning') return;

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

        // Trigger batch capture if face is inside oval and not already capturing
        if (_isFaceDetected && !_isCapturingBatch) {
          _startBatchCapture();
        }
      }
    } catch (e) {
      debugPrint("Face detection error: $e");
    } finally {
      _isProcessingImage = false;
    }
  }

  Future<void> _startBatchCapture() async {
    _isCapturingBatch = true;
    
    // Stop image stream to prevent camera resource crash during snapshot captures
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }

    try {
      for (int i = _capturedCount; i < _totalCapturesNeeded; i++) {
        if (!mounted || _screenState != 'scanning') break;
        
        await Future.delayed(const Duration(milliseconds: 300));
        final XFile photo = await _cameraController!.takePicture();
        _capturedPaths.add(photo.path);
        
        if (mounted) {
          setState(() {
            _capturedCount = _capturedPaths.length;
          });
        }
      }

      if (_capturedCount >= _totalCapturesNeeded) {
        _uploadCapturedFaces();
      } else {
        // Retry stream if batch aborted
        _isCapturingBatch = false;
        if (mounted && _cameraController != null) {
          _cameraController!.startImageStream(_processCameraImage);
        }
      }
    } catch (e) {
      debugPrint("Batch Capture error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal merekam wajah. Silakan coba lagi: $e')),
        );
        setState(() {
          _capturedCount = 0;
          _capturedPaths.clear();
          _isCapturingBatch = false;
          _isFaceDetected = false;
        });
        if (_cameraController != null) {
          _cameraController!.startImageStream(_processCameraImage);
        }
      }
    }
  }

  Future<void> _uploadCapturedFaces() async {
    setState(() {
      _screenState = 'uploading';
    });

    try {
      // Close camera and detector first
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
        _isCameraInitialized = false;
      }
      _faceDetector?.close();
      _faceDetector = null;

      final repository = ref.read(faceRecognitionRepositoryProvider);
      final data = await repository.registerFace(_capturedPaths);
      
      if (data['success'] == true) {
        setState(() {
          _screenState = 'success';
        });
        await Future.delayed(const Duration(seconds: 2));
        _fetchRegistrationStatus();
      } else {
        throw Exception(data['message'] ?? 'Gagal menyimpan data wajah ke server.');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gagal Registrasi'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startRegistrationFlow();
                },
                child: const Text('Coba Lagi'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchRegistrationStatus();
                },
                child: const Text('Batal'),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pendaftaran Wajah',
          style: TextStyle(
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
          onPressed: () {
            if (_screenState == 'scanning') {
              _fetchRegistrationStatus();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case 'loading':
        return Center(
          child: CircularProgressIndicator(color: primaryColor),
        );
      case 'status':
        return _buildStatusView();
      case 'scanning':
        return _buildScanningView();
      case 'uploading':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              const Text(
                'Mengunggah data wajah ke server...',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
        );
      case 'success':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Pendaftaran wajah berhasil disimpan.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildStatusView() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 54),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchRegistrationStatus,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_isRegistered) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.face_retouching_natural_rounded, color: primaryColor, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wajah Terdaftar',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Wajah Anda sudah berhasil didaftarkan di sistem.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Dataset Wajah Anda',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),

              // Dataset Grid
              if (_wajahList.isEmpty)
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: const Text('Tidak ada gambar yang dimuat.', style: TextStyle(color: Colors.grey)),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _wajahList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final item = _wajahList[index];
                    final String? url = item['url'];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: url != null
                          ? Image.network(
                              url.contains('?') ? '$url&t=$_cacheBuster' : '$url?t=$_cacheBuster',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                            )
                          : const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              
              const SizedBox(height: 36),

              // Re-register button
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Daftar Ulang Wajah?'),
                      content: const Text('Ini akan menghapus seluruh data wajah Anda yang terdaftar saat ini. Apakah Anda yakin ingin melanjutkannya?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteRegisteredFaces();
                          },
                          child: const Text('Ya, Hapus & Daftar Ulang', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.rotate_left_rounded),
                label: const Text('Hapus & Rekam Ulang Wajah', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.face_retouching_natural_rounded, size: 80, color: primaryColor),
            const SizedBox(height: 24),
            const Text(
              'Belum Terdaftar',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum mendaftarkan data wajah Anda untuk verifikasi presensi. Posisikan wajah Anda di dalam lingkaran oval saat pemindaian.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _startRegistrationFlow,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Mulai Scan Wajah Baru', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildScanningView() {
    return Container(
      color: Colors.black,
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
            // Semi-transparent overlay with oval cut-out
            Positioned.fill(
              child: CustomPaint(
                painter: FaceMaskPainter(),
              ),
            ),
          ] else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Top Info Banner
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
                    _isFaceDetected ? 'Posisikan wajah... Tahan!' : 'Posisikan wajah Anda di dalam oval...',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Center Bounding Guide Oval
          if (_isCameraInitialized && _cameraController != null)
            LayoutBuilder(
              builder: (context, constraints) {
                _previewContainerSize = Size(constraints.maxWidth, constraints.maxHeight);
                return Center(
                  child: SizedBox(
                    width: 220,
                    height: 280,
                    child: Stack(
                      children: [
                        Container(
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
                        // Scanner Line
                        if (_isFaceDetected && _scannerController != null)
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
                );
              },
            ),

          // Progress Overlay (Bottom Area)
          if (_isCapturingBatch)
            Positioned(
              left: 30,
              right: 30,
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Perekaman Wajah...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _capturedCount / _totalCapturesNeeded,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tahan posisi Anda: ${((_capturedCount / _totalCapturesNeeded) * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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
