import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/project/data/models/project_model.dart';
import 'package:gaweflutter/features/project/data/repositories/project_repository.dart';

final projectsProvider = FutureProvider.autoDispose<List<ProjectModel>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjects();
});

final projectDetailProvider = FutureProvider.autoDispose.family<ProjectDetailResponse, int>((ref, projectId) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectDetail(projectId);
});
