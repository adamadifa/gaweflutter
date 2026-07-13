import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/models/profile_model.dart';
import 'package:gaweflutter/data/repositories/profile_repository.dart';

final profileProvider = FutureProvider.autoDispose<ProfileModel>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile();
});
