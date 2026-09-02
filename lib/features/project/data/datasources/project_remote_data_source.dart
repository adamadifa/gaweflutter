import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/project/data/models/project_model.dart';

abstract class ProjectRemoteDataSource {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectDetailResponse> getProjectDetail(int projectId);
  Future<bool> updateProjectStatus(int projectId, String status);
  Future<ProjectTaskDetailModel> getTaskDetail(int taskId);
  Future<bool> updateTaskStatus(int taskId, String status, int progress);
  Future<bool> addComment(int taskId, String komentar);
  Future<bool> uploadAttachment(int taskId, File file);
  Future<bool> deleteAttachment(int attachmentId);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final Dio _dio;

  ProjectRemoteDataSourceImpl(this._dio);

  Map<String, dynamic> _parseResponseData(dynamic rawData) {
    if (rawData == null) {
      throw Exception('Data response kosong');
    }
    if (rawData is String) {
      return jsonDecode(rawData) as Map<String, dynamic>;
    } else if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    } else {
      throw Exception('Format response data tidak valid');
    }
  }

  @override
  Future<List<ProjectModel>> getProjects() async {
    try {
      final response = await _dio.get('/projects');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          final list = data['data'] as List? ?? [];
          return list.map((e) => ProjectModel.fromJson(Map<String, dynamic>.from(e))).toList();
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat data project');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<ProjectDetailResponse> getProjectDetail(int projectId) async {
    try {
      final response = await _dio.get('/projects/$projectId');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          return ProjectDetailResponse.fromJson(Map<String, dynamic>.from(data['data']));
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat detail project');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<bool> updateProjectStatus(int projectId, String status) async {
    try {
      final response = await _dio.post(
        '/projects/$projectId/status',
        data: {
          'status': status,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        return data['success'] == true;
      }
      return false;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<ProjectTaskDetailModel> getTaskDetail(int taskId) async {
    try {
      final response = await _dio.get('/projects/tasks/$taskId');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          return ProjectTaskDetailModel.fromJson(Map<String, dynamic>.from(data['data']));
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat detail task');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<bool> updateTaskStatus(int taskId, String status, int progress) async {
    try {
      final response = await _dio.post(
        '/projects/tasks/$taskId/status',
        data: {
          'status': status,
          'progress': progress,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        return data['success'] == true;
      }
      return false;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<bool> addComment(int taskId, String komentar) async {
    try {
      final response = await _dio.post(
        '/projects/tasks/$taskId/comment',
        data: {
          'komentar': komentar,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        return data['success'] == true;
      }
      return false;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<bool> uploadAttachment(int taskId, File file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/projects/tasks/$taskId/attachment',
        data: formData,
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        return data['success'] == true;
      }
      return false;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<bool> deleteAttachment(int attachmentId) async {
    try {
      final response = await _dio.delete('/projects/tasks/attachments/$attachmentId');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        return data['success'] == true;
      }
      return false;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

final projectRemoteDataSourceProvider = Provider<ProjectRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ProjectRemoteDataSourceImpl(dio);
});

