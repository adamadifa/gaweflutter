import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/project/data/datasources/project_remote_data_source.dart';
import 'package:gaweflutter/features/project/data/models/project_model.dart';

abstract class ProjectRepository {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectDetailResponse> getProjectDetail(int projectId);
  Future<bool> updateProjectStatus(int projectId, String status);
  Future<ProjectTaskDetailModel> getTaskDetail(int taskId);
  Future<bool> updateTaskStatus(int taskId, String status, int progress);
  Future<bool> addComment(int taskId, String komentar);
  Future<bool> uploadAttachment(int taskId, File file);
  Future<bool> deleteAttachment(int attachmentId);
}

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource _remoteDataSource;

  ProjectRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ProjectModel>> getProjects() async {
    return await _remoteDataSource.getProjects();
  }

  @override
  Future<ProjectDetailResponse> getProjectDetail(int projectId) async {
    return await _remoteDataSource.getProjectDetail(projectId);
  }

  @override
  Future<bool> updateProjectStatus(int projectId, String status) async {
    return await _remoteDataSource.updateProjectStatus(projectId, status);
  }

  @override
  Future<ProjectTaskDetailModel> getTaskDetail(int taskId) async {
    return await _remoteDataSource.getTaskDetail(taskId);
  }

  @override
  Future<bool> updateTaskStatus(int taskId, String status, int progress) async {
    return await _remoteDataSource.updateTaskStatus(taskId, status, progress);
  }

  @override
  Future<bool> addComment(int taskId, String komentar) async {
    return await _remoteDataSource.addComment(taskId, komentar);
  }

  @override
  Future<bool> uploadAttachment(int taskId, File file) async {
    return await _remoteDataSource.uploadAttachment(taskId, file);
  }

  @override
  Future<bool> deleteAttachment(int attachmentId) async {
    return await _remoteDataSource.deleteAttachment(attachmentId);
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final remoteDataSource = ref.watch(projectRemoteDataSourceProvider);
  return ProjectRepositoryImpl(remoteDataSource);
});

