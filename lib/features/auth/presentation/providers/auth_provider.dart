import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/models/user_model.dart';
import 'package:gaweflutter/data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.authenticating() => AuthState(status: AuthStatus.authenticating);
  factory AuthState.authenticated(UserModel user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Fetch initial authentication status asynchronously
    Future.microtask(() => checkAuthStatus());
    return AuthState.initial();
  }

  Future<void> checkAuthStatus() async {
    final repository = ref.read(authRepositoryProvider);
    final token = await repository.getCachedToken();
    final user = await repository.getCachedUser();

    if (token != null && user != null) {
      state = AuthState.authenticated(user);
      // Fetch latest profile from server in background to sync state/cache
      _fetchLatestProfile(repository);
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> _fetchLatestProfile(AuthRepository repository) async {
    try {
      final freshUser = await repository.getProfile();
      await repository.saveCachedUser(freshUser);
      state = AuthState.authenticated(freshUser);
    } catch (_) {
      // If offline/error, keep using cached user
    }
  }

  Future<void> refreshProfile() async {
    if (state.status == AuthStatus.authenticated) {
      final repository = ref.read(authRepositoryProvider);
      await _fetchLatestProfile(repository);
    }
  }

  Future<void> login(String username, String password) async {
    state = AuthState.authenticating();
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.login(username, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = AuthState.unauthenticated();
  }

  Future<void> updateFoto(String newFotoUrl) async {
    if (state.status == AuthStatus.authenticated && state.user != null) {
      final updatedUser = UserModel(
        id: state.user!.id,
        name: state.user!.name,
        username: state.user!.username,
        email: state.user!.email,
        nik: state.user!.nik,
        jabatan: state.user!.jabatan,
        departemen: state.user!.departemen,
        cabang: state.user!.cabang,
        foto: newFotoUrl,
      );
      final repository = ref.read(authRepositoryProvider);
      await repository.saveCachedUser(updatedUser);
      state = AuthState.authenticated(updatedUser);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
