import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/project/data/datasources/project_remote_data_source.dart';
import 'package:gaweflutter/features/project/data/models/project_model.dart';

abstract class ProjectRepository {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectDetailResponse> getProjectDetail(int projectId);
  Future<bool> updateTaskStatus(int taskId, String status, int progress);
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
  Future<bool> updateTaskStatus(int taskId, String status, int progress) async {
    return await _remoteDataSource.updateTaskStatus(taskId, status, progress);
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final remoteDataSource = ref.watch(projectRemoteDataSourceProvider);
  return ProjectRepositoryImpl(remoteDataSource);
});
