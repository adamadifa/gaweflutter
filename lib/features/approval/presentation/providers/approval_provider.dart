import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/approval/data/models/approval_model.dart';
import 'package:gaweflutter/features/approval/data/repositories/approval_repository.dart';

final approvalListProvider = FutureProvider.autoDispose<ApprovalResponseData>((ref) async {
  final repository = ref.watch(approvalRepositoryProvider);
  return repository.getApprovalList();
});

class ApprovalFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) {
    state = filter;
  }
}

final selectedApprovalFilterProvider = NotifierProvider.autoDispose<ApprovalFilterNotifier, String>(() {
  return ApprovalFilterNotifier();
});

final filteredApprovalItemsProvider = Provider.autoDispose<List<ApprovalItem>>((ref) {
  final approvalAsync = ref.watch(approvalListProvider);
  final filter = ref.watch(selectedApprovalFilterProvider);

  return approvalAsync.maybeWhen(
    data: (data) {
      if (filter == 'all') {
        return data.items;
      }
      return data.items.where((item) => item.type == filter).toList();
    },
    orElse: () => [],
  );
});

class ApprovalActionState {
  final bool isLoading;
  final String? message;
  final String? errorMessage;

  ApprovalActionState({
    this.isLoading = false,
    this.message,
    this.errorMessage,
  });
}

class ApprovalActionNotifier extends Notifier<ApprovalActionState> {
  @override
  ApprovalActionState build() => ApprovalActionState();

  Future<bool> process({
    required String type,
    required String kode,
    required String action,
    String? catatan,
  }) async {
    state = ApprovalActionState(isLoading: true);
    try {
      final repository = ref.read(approvalRepositoryProvider);
      final msg = await repository.processApproval(
        type: type,
        kode: kode,
        action: action,
        catatan: catatan,
      );
      state = ApprovalActionState(isLoading: false, message: msg);
      ref.invalidate(approvalListProvider);
      return true;
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      state = ApprovalActionState(isLoading: false, errorMessage: err);
      return false;
    }
  }
}

final approvalActionProvider = NotifierProvider.autoDispose<ApprovalActionNotifier, ApprovalActionState>(() {
  return ApprovalActionNotifier();
});
