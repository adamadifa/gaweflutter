import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';

abstract class FaceRecognitionRepository {
  Future<Map<String, dynamic>> getFaceStatus();
  Future<Map<String, dynamic>> registerFace(List<String> imagePaths);
  Future<Map<String, dynamic>> deleteFace();
}

class FaceRecognitionRepositoryImpl implements FaceRecognitionRepository {
  final Dio _dio;

  FaceRecognitionRepositoryImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getFaceStatus() async {
    try {
      final response = await _dio.get('/facerecognition');
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw Exception('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    }
  }

  @override
  Future<Map<String, dynamic>> registerFace(List<String> imagePaths) async {
    try {
      final List<MultipartFile> files = [];
      final List<String> directions = [];

      for (int i = 0; i < imagePaths.length; i++) {
        final path = imagePaths[i];
        final fileName = path.split('/').last;
        files.add(await MultipartFile.fromFile(path, filename: fileName));
        directions.add('front'); // Use 'front' as default for all captures
      }

      final formData = FormData.fromMap({
        'files[]': files,
        'directions[]': directions,
      });

      final response = await _dio.post('/facerecognition', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw Exception('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    }
  }

  @override
  Future<Map<String, dynamic>> deleteFace() async {
    try {
      final response = await _dio.delete('/facerecognition');
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw Exception('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    }
  }
}

final faceRecognitionRepositoryProvider = Provider<FaceRecognitionRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FaceRecognitionRepositoryImpl(dio);
});
