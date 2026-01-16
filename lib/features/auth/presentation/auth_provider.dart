import 'package:mesh_app/features/auth/data/auth_repository.dart';
import 'package:mesh_app/features/auth/domain/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<AuthUser?> build() async {
    final repository = ref.read(authRepositoryProvider);
    final userId = await repository.getSessionUserId();
    if (userId != null) {
      return await repository.getUserById(userId);
    }
    return null;
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.login(username, password);
      if (user == null) {
        throw Exception('Invalid credentials');
      }
      return user;
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final repository = ref.read(authRepositoryProvider);
    await repository.clearSession();
    state = const AsyncValue.data(null);
  }
}
